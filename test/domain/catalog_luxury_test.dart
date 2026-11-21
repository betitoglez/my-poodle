import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

/// Catálogo anterior a la ampliación, con los precios por familia de PR #17:
/// ID → (precio, versión). Nada de esto puede cambiar entre versiones.
const _oldStyles = {
  'coat.apricot': (0, Tier.free),
  'coat.silver': (30, Tier.free),
  'coat.lightgray': (30, Tier.full),
  'coat.white': (40, Tier.full),
  'coat.black': (50, Tier.full),
  'hair.natural': (0, Tier.free),
  'hair.show': (400, Tier.free),
  'hair.pom': (200, Tier.free),
  'hair.teddy': (200, Tier.full),
  'hair.puppy': (200, Tier.full),
  'outfit.none': (0, Tier.free),
  'outfit.teal': (20, Tier.free),
  'outfit.overalls_red': (20, Tier.free),
  'outfit.overalls_yellow': (20, Tier.free),
  'outfit.sweater_red': (40, Tier.full),
  'outfit.sweater_blue': (40, Tier.full),
  'outfit.sweater_mustard': (40, Tier.full),
  'outfit.raincoat_yellow': (50, Tier.full),
  'outfit.raincoat_blue': (50, Tier.full),
  'outfit.raincoat_pink': (50, Tier.full),
  'outfit.dress_pink': (70, Tier.full),
  'outfit.dress_lilac': (70, Tier.full),
  'outfit.dress_turquoise': (70, Tier.full),
  'head.none': (0, Tier.free),
  'head.bow': (20, Tier.free),
  'head.beanie': (30, Tier.full),
  'head.crown': (70, Tier.full),
  'eyes.none': (0, Tier.free),
  'eyes.round': (20, Tier.free),
  'eyes.sun': (40, Tier.full),
  'eyes.heart': (60, Tier.full),
  'collar.none': (0, Tier.free),
  'collar.tag': (20, Tier.free),
  'collar.bell': (30, Tier.full),
  'collar.pearls': (50, Tier.full),
  'neck.none': (0, Tier.free),
  'neck.coral': (10, Tier.free),
  'neck.bowtie': (30, Tier.full),
  'neck.knit': (40, Tier.full),
  'paws.none': (0, Tier.free),
  'paws.booties': (30, Tier.free),
  'paws.sneakers': (40, Tier.full),
  'paws.rain': (60, Tier.full),
};
const _oldDecor = {
  'rug.none': (0, Tier.free),
  'rug.round': (40, Tier.free),
  'rug.stripes': (60, Tier.full),
  'rug.bone': (90, Tier.full),
  'wall.none': (0, Tier.free),
  'wall.frame': (50, Tier.free),
  'wall.garland': (70, Tier.full),
  'wall.stars': (110, Tier.full),
  'plant.none': (0, Tier.free),
  'plant.fern': (35, Tier.free),
  'plant.flowers': (80, Tier.full),
  'plant.cactus': (100, Tier.full),
};

/// Familias de prenda: todos sus colores cuestan lo mismo.
const _families = {
  'outfit.overalls': [
    'outfit.teal',
    'outfit.overalls_red',
    'outfit.overalls_yellow',
    'outfit.overalls_denim',
    'outfit.overalls_pink',
  ],
  'outfit.sweater': [
    'outfit.sweater_red',
    'outfit.sweater_blue',
    'outfit.sweater_mustard',
    'outfit.sweater_green',
    'outfit.sweater_purple',
  ],
  'outfit.raincoat': [
    'outfit.raincoat_yellow',
    'outfit.raincoat_blue',
    'outfit.raincoat_pink',
    'outfit.raincoat_red',
    'outfit.raincoat_green',
  ],
  'outfit.dress': [
    'outfit.dress_pink',
    'outfit.dress_lilac',
    'outfit.dress_turquoise',
    'outfit.dress_yellow',
    'outfit.dress_coral',
  ],
};

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);

  group('compatibilidad', () {
    test('los IDs, precios y versiones anteriores siguen intactos', () {
      for (final MapEntry(key: id, value: (cost, tier)) in _oldStyles.entries) {
        final item = balance.item(id);
        expect(item, isNotNull, reason: id);
        expect((item!.cost, item.tier), (cost, tier), reason: id);
      }
      for (final MapEntry(key: id, value: (cost, tier)) in _oldDecor.entries) {
        final item = balance.decorItem(id);
        expect(item, isNotNull, reason: id);
        expect((item!.cost, item.tier), (cost, tier), reason: id);
      }
    });

    test('una partida anterior a la ampliación se abre con sus compras', () {
      final old = jsonEncode({
        'schemaVersion': 1,
        'revision': 9,
        'lastCommitId': 'x',
        'name': 'Coco',
        'needsCursorUtc': t0,
        'satiety100': 6000,
        'hygiene100': 6000,
        'mood100': 6000,
        'energy100': 6000,
        'coins': 77,
        'owned': [
          'coat.apricot',
          'coat.black',
          'hair.natural',
          'outfit.none',
          'outfit.dress_lilac',
          'collar.pearls',
          'rug.bone',
        ],
        'appearance': {
          'coat': 'coat.black',
          'hair': 'hair.natural',
          'outfit': 'outfit.dress_lilac',
          'collar': 'collar.pearls',
        },
        'decor': {'rug': 'rug.bone'},
      });
      final s = SaveCodec(balance).decode(old);
      expect(s.coins, 77);
      expect(s.appearance.coat, 'coat.black');
      expect(s.appearance.outfit, 'outfit.dress_lilac');
      expect(s.appearance.collar, 'collar.pearls');
      expect(s.decor[DecorSlot.rug], 'rug.bone');
      expect(
        s.owned,
        containsAll(['coat.black', 'outfit.dress_lilac', 'collar.pearls']),
      );
      // Lo nuevo no aparece comprado.
      expect(s.owned.contains('coat.golden'), isFalse);
      expect(s.owned.contains('rug.persian'), isFalse);
      // Ida y vuelta con el codec actual.
      final back = SaveCodec(balance).decode(SaveCodec(balance).encode(s));
      expect(back.owned, s.owned);
    });
  });

  group('artículos de lujo', () {
    test('el lujo empieza en 250 y hay metas gratis en armario y salón', () {
      expect(luxuryCost, 250);
      final styleLux = balance.styles.where((s) => s.luxury).toList();
      final decorLux = balance.decor.where((d) => d.luxury).toList();
      // PR #17 ya sitúa cortes y pelajes especiales por encima de 250.
      expect(
        styleLux.map((s) => s.id),
        containsAll(['coat.golden', 'head.crown_jewels', 'collar.pearls_gold']),
      );
      expect(decorLux.map((d) => d.id), [
        'rug.persian',
        'wall.goldframe',
        'plant.lights',
      ]);
      for (final i in [
        ...styleLux.map((s) => s.cost),
        ...decorLux.map((d) => d.cost),
      ]) {
        expect(i, inInclusiveRange(250, 1500));
      }
      expect(styleLux.where((s) => s.tier == Tier.free), isNotEmpty);
      expect(decorLux.where((d) => d.tier == Tier.free), isNotEmpty);
      // Ninguna decoración anterior pasa a ser de lujo.
      expect(decorLux.any((d) => _oldDecor.containsKey(d.id)), isFalse);
    });

    test(
      'variedad nueva entre 30 y 150; colores nuevos al precio familiar',
      () {
        const newCoats = [
          'coat.cream',
          'coat.chocolate',
          'coat.cinnamon',
          'coat.latte',
          'coat.slate',
        ];
        for (final id in newCoats) {
          expect(balance.item(id)!.cost, inInclusiveRange(60, 150), reason: id);
        }
        // El dorado es el pelaje más caro, por encima de los especiales.
        final golden = balance.item('coat.golden')!.cost;
        expect(
          balance.itemsFor(Slot.coat).every((c) => c.cost <= golden),
          isTrue,
        );
        expect(balance.item('coat.golden')!.tier, Tier.full);
        for (final ids in _families.values) {
          final costs = ids.map((id) => balance.item(id)!.cost).toSet();
          expect(costs, hasLength(1), reason: ids.first);
        }
        for (final d in balance.decor) {
          if (_oldDecor.containsKey(d.id) || d.luxury) continue;
          expect(d.cost, inInclusiveRange(30, 150), reason: d.id);
        }
        for (final slot in DecorSlot.values) {
          final added = balance
              .decorFor(slot)
              .where((d) => !_oldDecor.containsKey(d.id))
              .toList();
          expect(added.where((d) => d.luxury), hasLength(1), reason: slot.name);
          expect(added.where((d) => !d.luxury).length, inInclusiveRange(2, 3));
        }
      },
    );

    test('collar de lujo gratis: saldo justo, insuficiente', () {
      final item = balance.item('collar.pearls_gold')!;
      expect((item.tier, item.luxury), (Tier.free, true));
      final look = adopt().appearance.withSlot(Slot.collar, item.id);

      final exact = adopt().copyWith(coins: item.cost);
      final ok = rules.applyLook(exact, look, 'a', t0, fullVersion: false);
      expect(ok, isA<Purchased>());
      final after = (ok as Purchased).receipt.after;
      expect(after.coins, 0);
      expect(after.owned.contains(item.id), isTrue);
      expect(after.appearance.collar, item.id);

      final short = adopt().copyWith(coins: item.cost - 1);
      final no = rules.applyLook(short, look, 'b', t0, fullVersion: false);
      expect(no, isA<InsufficientCoins>());
      expect((no as InsufficientCoins).missing, 1);
      expect(short.owned.contains(item.id), isFalse);
    });

    test('pelaje dorado: exige la versión completa aunque sobren monedas', () {
      final item = balance.item('coat.golden')!;
      final look = adopt().appearance.withSlot(Slot.coat, item.id);
      final rich = adopt().copyWith(coins: 5000);
      final locked = rules.applyLook(rich, look, 'a', t0, fullVersion: false);
      expect(locked, isA<RequiresFull>());
      expect((locked as RequiresFull).itemIds, [item.id]);

      final exact = adopt().copyWith(coins: item.cost);
      final ok = rules.applyLook(exact, look, 'b', t0, fullVersion: true);
      expect((ok as Purchased).receipt.after.coins, 0);
      final short = adopt().copyWith(coins: item.cost - 1);
      expect(
        rules.applyLook(short, look, 'c', t0, fullVersion: true),
        isA<InsufficientCoins>(),
      );
    });

    test('decoración de lujo: gratis y completa', () {
      final persian = balance.decorItem('rug.persian')!;
      expect((persian.tier, persian.luxury), (Tier.free, true));
      final exact = adopt().copyWith(coins: persian.cost);
      final ok = rules.applyDecor(
        exact,
        persian.id,
        'a',
        t0,
        fullVersion: false,
      );
      final after = (ok as Purchased).receipt.after;
      expect(after.coins, 0);
      expect(after.decor[DecorSlot.rug], persian.id);
      final short = adopt().copyWith(coins: persian.cost - 1);
      final no = rules.applyDecor(
        short,
        persian.id,
        'b',
        t0,
        fullVersion: false,
      );
      expect((no as InsufficientCoins).missing, 1);

      final lights = balance.decorItem('plant.lights')!;
      final rich = adopt().copyWith(coins: 5000);
      expect(
        rules.applyDecor(rich, lights.id, 'c', t0, fullVersion: false),
        isA<RequiresFull>(),
      );
      final full = rules.applyDecor(
        adopt().copyWith(coins: lights.cost),
        lights.id,
        'd',
        t0,
        fullVersion: true,
      );
      expect((full as Purchased).receipt.after.coins, 0);
    });
  });
}
