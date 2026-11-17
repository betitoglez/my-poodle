import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final ent = EntitlementRules(balance.fullVersionProductId);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);

  test('catálogo: 18 artículos gratis, 24 completos, Frisbee gratis', () {
    final free = balance.styles.where((s) => s.tier == Tier.free).toList();
    expect(free.length, 18);
    expect(balance.styles.length - free.length, 24);
    expect(rules.gameTier(GameId.frisbee), Tier.free);
    expect(rules.gameTier(GameId.fruit), Tier.full);
    expect(balance.item('outfit.sweater_red')!.tier, Tier.full);
    expect(balance.item('neck.coral')!.tier, Tier.free);
    expect(ent.canAccess(Tier.free, Entitlement.none), isTrue);
    expect(ent.canAccess(Tier.full, Entitlement.none), isFalse);
  });

  test('E11 · sin versión completa: lo completo pide versión, lo demás no', () {
    final s = adopt().copyWith(coins: 100);
    final sweater = s.appearance.withSlot(Slot.outfit, 'outfit.sweater_red');
    final r = rules.applyLook(s, sweater, 'a', t0, fullVersion: false);
    expect(r, isA<RequiresFull>());
    expect((r as RequiresFull).itemIds, ['outfit.sweater_red']);
    expect(s.coins, 100);
    expect(s.owned.contains('outfit.sweater_red'), isFalse);

    final s12 = adopt().copyWith(coins: 12);
    final scarf = s12.appearance.withSlot(Slot.neck, 'neck.coral');
    final ok = rules.applyLook(s12, scarf, 'b', t0, fullVersion: false);
    expect((ok as Purchased).receipt.after.coins, 2);

    // Mezcla de gratis y completo: se rechaza todo, sin compra parcial.
    final mixed = scarf.withSlot(Slot.head, 'head.crown');
    expect(
      rules.applyLook(s, mixed, 'c', t0, fullVersion: false),
      isA<RequiresFull>(),
    );

    expect(
      ent.canAccess(rules.gameTier(GameId.fruit), Entitlement.none),
      isFalse,
    );
    expect(
      ent.canAccess(rules.gameTier(GameId.frisbee), Entitlement.none),
      isTrue,
    );
    // Los cuidados no consultan la versión.
    var p = adopt();
    for (final k in CareKind.values) {
      p = rules.finishCare(p, k, 'care-${k.name}', t0).after;
    }
    expect(p.revision, greaterThan(adopt().revision));
  });

  test('E12 · con versión completa compra; tras revocar conserva lo suyo', () {
    final s = adopt().copyWith(coins: 32);
    final sweater = s.appearance.withSlot(Slot.outfit, 'outfit.sweater_red');
    final bought = (rules.applyLook(
      s,
      sweater,
      'a',
      t0,
      fullVersion: true,
    ) as Purchased).receipt.after;
    expect(bought.coins, 0);
    expect(bought.appearance.outfit, 'outfit.sweater_red');

    const full = Entitlement(state: EntitlementState.purchased);
    final revoked = ent
        .apply(
          full,
          StoreEvent(
            StoreEventKind.revoked,
            eventId: 'r1',
            productId: balance.fullVersionProductId,
          ),
          t0,
        )
        .next;
    expect(revoked.full, isFalse);
    // Lo comprado sigue en propiedad y se puede quitar y volver a poner gratis.
    final off = (rules.applyLook(
      bought,
      bought.appearance.withSlot(Slot.outfit, 'outfit.none'),
      'b',
      t0,
      fullVersion: revoked.full,
    ) as Purchased).receipt.after;
    final on = rules.applyLook(
      off,
      sweater,
      'c',
      t0,
      fullVersion: revoked.full,
    );
    expect((on as Purchased).cost, 0);
    expect(on.receipt.after.appearance.outfit, 'outfit.sweater_red');
    // Algo completo nuevo y el Huerto vuelven a pedir la versión.
    expect(
      rules.applyLook(
        on.receipt.after.copyWith(coins: 100),
        sweater.withSlot(Slot.head, 'head.crown'),
        'd',
        t0,
        fullVersion: revoked.full,
      ),
      isA<RequiresFull>(),
    );
    expect(ent.canAccess(rules.gameTier(GameId.fruit), revoked), isFalse);
  });

  test('E13 · eventos: idempotencia, pendiente, cancelado, otro producto', () {
    final id = balance.fullVersionProductId;
    var e = Entitlement.none;
    EntitlementChange step(StoreEventKind k, String eid, [String? pid]) {
      final c = ent.apply(
        e,
        StoreEvent(k, eventId: eid, productId: pid ?? id),
        t0,
      );
      e = c.next;
      return c;
    }

    expect(step(StoreEventKind.pending, 'p1').changed, isTrue);
    expect(e.pending, isTrue);
    expect(e.full, isFalse);
    expect(step(StoreEventKind.canceled, 'c1').changed, isTrue);
    expect(e.state, EntitlementState.none);
    expect(step(StoreEventKind.error, 'x1').changed, isFalse);
    expect(
      step(StoreEventKind.purchased, 'b1', 'otro.producto').changed,
      isFalse,
    );
    expect(e.full, isFalse);
    expect(step(StoreEventKind.purchased, 'b1').changed, isTrue);
    expect(e.full, isTrue);
    expect(step(StoreEventKind.purchased, 'b1').changed, isFalse);
    expect(step(StoreEventKind.restored, 'r1').changed, isTrue);
    expect(e.full, isTrue);
    expect(step(StoreEventKind.pending, 'p2').changed, isFalse);
    expect(step(StoreEventKind.canceled, 'c2').changed, isFalse);
    expect(step(StoreEventKind.error, 'x2').changed, isFalse);
    expect(e.full, isTrue);
    // Memoria de IDs acotada.
    for (var i = 0; i < 30; i++) {
      step(StoreEventKind.restored, 'm$i');
    }
    expect(e.lastEventIds.length, EntitlementRules.memory);
  });
}
