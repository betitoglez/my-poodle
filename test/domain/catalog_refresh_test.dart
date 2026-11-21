import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/care_options.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/food.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/domain/style_catalog.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final codec = SaveCodec(balance);
  PetState pet() => PetState.adopt(
    validName: 'Rizo',
    nowUtc: t0,
    balance: balance,
  ).copyWith(coins: 20000);
  PetState buy(
    PetState state,
    Appearance target,
    String op, {
    bool full = true,
  }) => (rules.applyLook(
    state,
    target,
    op,
    t0,
    fullVersion: full,
  ) as Purchased).receipt.after;

  test(
    'comprar una zona no regala el pack; el pack descuenta cada pieza propia',
    () {
      var state = pet();
      final look = state.appearance.withCut(HairZone.head, 'teddy');
      expect(rules.lookCost(state, look), 50);
      state = buy(state, look, 'head');
      expect(state.owned, contains('cut.head.teddy'));
      expect(state.owned, isNot(contains('hair.teddy')));
      expect(rules.ownsStyle(state, 'cut.legs.teddy'), isFalse);
      expect(rules.styleCost(state, 'hair.teddy'), 150);
      state = codec.decode(codec.encode(state));
      expect(state.appearance.cuts[HairZone.legs], 'natural');
      expect(rules.styleCost(state, 'hair.teddy'), 150);
      state = buy(
        state,
        state.appearance.withCut(HairZone.tail, 'teddy'),
        'tail',
      );
      expect(rules.styleCost(state, 'hair.teddy'), 100);
      state = buy(
        state,
        state.appearance.withSlot(Slot.hair, 'hair.teddy'),
        'pack',
      );
      expect(state.coins, 19800);
      expect(rules.styleCost(state, 'hair.teddy'), 0);
      expect(
        HairZone.values.every(
          (z) => rules.ownsStyle(state, Haircuts.id(z, 'teddy')),
        ),
        isTrue,
      );
      expect(state.appearance.uniformHair, isTrue);
    },
  );

  test('cinco estilos por zona, concurso cuesta 100 y el resto 50', () {
    for (final zone in HairZone.values) {
      expect(Haircuts.styles.where((s) => s != 'natural'), hasLength(5));
      for (final style in Haircuts.styles.skip(1)) {
        final target = pet().appearance.withCut(zone, style);
        expect(rules.lookCost(pet(), target), style == 'show' ? 100 : 50);
        expect(
          rules.styleCost(pet(), 'hair.$style'),
          style == 'show' ? 400 : 200,
        );
      }
    }
  });

  test('packs antiguos se migran a cuatro piezas sin perder propiedad', () {
    final state = pet().copyWith(owned: {...pet().owned, 'hair.show'});
    final raw = jsonDecode(codec.encode(state)) as Map<String, dynamic>;
    (raw['appearance'] as Map).removeWhere(
      (key, _) => key.toString().startsWith('cut_'),
    );
    (raw['appearance'] as Map)['hair'] = 'hair.show';
    final restored = codec.decode(jsonEncode(raw));
    expect(restored.appearance.cuts.values.toSet(), {'show'});
    for (final zone in HairZone.values) {
      expect(restored.owned, contains(Haircuts.id(zone, 'show')));
      expect(rules.styleCost(restored, Haircuts.id(zone, 'show')), 0);
    }
  });

  test('colores especiales: 1000, 1200, 1440, 1730; persiste y no cobra al reequipar', () {
    var state = pet();
    final ids = ['coat.zebra', 'coat.blue', 'coat.green', 'coat.redwhite'];
    final costs = [1000, 1200, 1440, 1730];
    for (var i = 0; i < ids.length; i++) {
      expect(rules.styleCost(state, ids[i]), costs[i]);
      state = buy(
        state,
        state.appearance.withSlot(Slot.coat, ids[i]),
        'coat-$i',
        full: i != 0,
      );
      state = codec.decode(codec.encode(state));
      expect(rules.styleCost(state, ids[i]), 0);
    }
    expect(state.coins, 20000 - costs.reduce((a, b) => a + b));
    expect(
      rules.applyLook(
        pet(),
        pet().appearance.withSlot(Slot.coat, 'coat.tiger'),
        'locked',
        t0,
        fullVersion: false,
      ),
      isA<RequiresFull>(),
    );
    expect(StyleCatalog.specialCoats, hasLength(6));
  });

  test('ropa: colores normales redondeados y especiales cuestan ocho veces, solo completa', () {
    for (final entry in {
      'overalls': 20,
      'sweater': 40,
      'raincoat': 50,
      'dress': 70,
    }.entries) {
      for (final color in ['blue', 'white', 'black']) {
        expect(balance.item('outfit.${entry.key}_$color')!.cost, entry.value);
      }
      for (final color in ['zebra', 'redwhite', 'greenwhite', 'dots']) {
        final id = 'outfit.${entry.key}_$color';
        expect(balance.item(id)!.cost, entry.value * 8);
        expect(balance.item(id)!.tier, Tier.full);
      }
    }
    expect(balance.styles.every((s) => s.cost % 10 == 0), isTrue);
  });

  test(
    'completa sin cupo, gratuita con cupo global y plazo real tras revocar',
    () {
      var state = pet();
      for (var i = 0; i < 12; i++) {
        state = rules.startGame(
          state,
          'play-$i',
          t0 + i * 10,
          game: GameId.frisbee,
          fullVersion: true,
        );
      }
      state = codec.decode(codec.encode(state));
      expect(rules.gameWaitSeconds(state, t0 + 120, fullVersion: true), 0);
      expect(rules.gameBlocked(state, t0 + 120, fullVersion: true), isNull);
      expect(rules.gameWaitSeconds(state, t0 + 120), 270);
      expect(rules.gameBlocked(state, t0 + 120), contains('versión completa'));
      expect(rules.gameBlocked(state, t0 + 389), isNotNull);
      expect(rules.gameBlocked(state, t0 + 390), isNull);
    },
  );

  test(
    'omitir opción al confirmar no permite repetir la ración predeterminada',
    () {
      expect(
        () => rules.finishCare(
          pet(),
          CareKind.feed,
          'invalid',
          t0,
          option: BathPlan.standard,
        ),
        throwsA(isA<RuleException>()),
      );
      final state = rules.finishCare(pet(), CareKind.feed, 'basic', t0).after;
      expect(
        rules.careBlocked(state, CareKind.feed, t0),
        isNull,
        reason: 'Se puede entrar y elegir otra ración',
      );
      expect(
        () => rules.finishCare(state, CareKind.feed, 'repeat', t0 + 1),
        throwsA(isA<RuleException>()),
      );
      expect(
        () => rules.finishCare(
          state,
          CareKind.feed,
          'repeat-full',
          t0 + 1,
          fullVersion: true,
        ),
        throwsA(isA<RuleException>()),
      );
    },
  );

  test('el plazo antiguo de comida corresponde solo a la ración básica', () {
    var state = pet().copyWith(careCompletedUtc: {'feed': t0});
    expect(
      rules.careWaitSeconds(state, CareKind.feed, t0 + 100, option: Food.basic),
      800,
    );
    expect(
      rules.careBlocked(state, CareKind.feed, t0 + 100, option: Food.premium),
      isNull,
    );
    state = rules
        .finishCare(
          state,
          CareKind.feed,
          'premium',
          t0 + 100,
          option: Food.premium,
        )
        .after;
    state = codec.decode(codec.encode(state));
    expect(
      rules.careWaitSeconds(state, CareKind.feed, t0 + 100, option: Food.basic),
      800,
    );
    expect(
      rules.careWaitSeconds(
        state,
        CareKind.feed,
        t0 + 100,
        option: Food.premium,
      ),
      900,
    );
  });

  test(
    'cuidados sin opciones también esperan 15 minutos en ambas versiones',
    () {
      for (final full in [false, true]) {
        final state = rules
            .finishCare(pet(), CareKind.groom, 'brush', t0, fullVersion: full)
            .after;
        expect(
          rules.careWaitSeconds(
            state,
            CareKind.groom,
            t0 + 899,
            fullVersion: full,
          ),
          1,
        );
        expect(
          rules.careBlocked(state, CareKind.groom, t0 + 899, fullVersion: full),
          isNotNull,
        );
        expect(
          rules.careBlocked(state, CareKind.groom, t0 + 900, fullVersion: full),
          isNull,
        );
      }
    },
  );
}
