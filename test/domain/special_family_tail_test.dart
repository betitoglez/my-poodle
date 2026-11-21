import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

void main() {
  final balance = loadBalance(), rules = Rules(loadBalance());
  final codec = SaveCodec(balance);
  PetState pet() => PetState.adopt(
    validName: 'Rizo',
    nowUtc: t0,
    balance: balance,
  ).copyWith(coins: 20000);
  PetState buy(PetState s, String id, String op) => (rules.applyLook(
    s,
    s.appearance.withSlot(balance.item(id)!.slot, id),
    op,
    t0,
    fullVersion: true,
  ) as Purchased).receipt.after;

  test('solo especiales de la misma familia suben 20%; vestido no afecta jersey, impermeable, peto ni pelaje', () {
    var s = pet();
    s = buy(s, 'outfit.dress_white', 'normal');
    expect(rules.styleCost(s, 'outfit.dress_zebra'), 560);
    s = buy(s, 'outfit.dress_dots', 'special-1');
    expect(rules.styleCost(s, 'outfit.dress_zebra'), 680);
    expect(rules.styleCost(s, 'outfit.sweater_zebra'), 320);
    expect(rules.styleCost(s, 'outfit.raincoat_zebra'), 400);
    expect(rules.styleCost(s, 'outfit.overalls_zebra'), 160);
    expect(rules.styleCost(s, 'coat.zebra'), 1000);
    expect(rules.styleCost(s, 'outfit.dress_black'), 70);
    s = buy(s, 'outfit.dress_redwhite', 'special-2');
    expect(rules.styleCost(s, 'outfit.dress_greenwhite'), 810);
    expect(rules.styleCost(s, 'outfit.dress_dots'), 0);
    s = codec.decode(codec.encode(s));
    expect(rules.styleCost(s, 'outfit.dress_greenwhite'), 810);
    s = buy(s, 'outfit.sweater_dots', 'sweater');
    expect(rules.styleCost(s, 'outfit.sweater_zebra'), 390);
    expect(rules.styleCost(s, 'outfit.dress_greenwhite'), 810);
    s = buy(s, 'coat.zebra', 'coat');
    expect(rules.styleCost(s, 'coat.blue'), 1200);
    expect(rules.styleCost(s, 'outfit.dress_greenwhite'), 810);
    expect(rules.styleCost(s, 'outfit.sweater_zebra'), 390);
    expect(s.coins, 20000 - 70 - 560 - 680 - 320 - 1000);
  });

  for (final full in [false, true]) {
    test(
      'cola estándar gratis sin saldo, conservada al recargar, completa=$full',
      () {
        final s = pet().copyWith(coins: 0);
        expect(Haircuts.stylesFor(HairZone.tail), contains('standard'));
        expect(Haircuts.valid('cut.tail.standard'), isTrue);
        expect(Haircuts.valid('cut.head.standard'), isFalse);
        expect(Haircuts.tier('standard'), Tier.free);
        expect(Haircuts.renderIndex('standard'), 6);
        final target = s.appearance.withCut(HairZone.tail, 'standard');
        expect(rules.lookCost(s, target), 0);
        expect(rules.lockedItems(s, target, fullVersion: full), isEmpty);
        final bought = rules.applyLook(
          s,
          target,
          'tail',
          t0,
          fullVersion: full,
        ) as Purchased;
        final restored = codec.decode(codec.encode(bought.receipt.after));
        expect(restored.appearance.cuts[HairZone.tail], 'standard');
        expect(restored.appearance.cuts[HairZone.head], 'natural');
        expect(restored.appearance.hair, 'hair.natural');
        expect(restored.coins, 0);
        expect(rules.styleCost(restored, 'cut.tail.standard'), 0);
      },
    );
  }
}
