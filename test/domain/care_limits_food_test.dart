import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/care_options.dart';
import 'package:my_poodle/domain/food.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';

import '../support.dart';

void main() {
  final b = loadBalance();
  final rules = Rules(b);
  PetState pet() => PetState.adopt(
    validName: 'Nube',
    nowUtc: t0,
    balance: b,
  ).copyWith(coins: 100, needs100: {for (final n in Need.values) n: 2000});

  test('cada ración descuenta su coste y suma exactamente sus efectos', () {
    for (final food in Food.values) {
      final before = pet();
      final receipt = rules.finishCare(
        before,
        CareKind.feed,
        food.name,
        t0,
        option: food,
        fullVersion: true,
      );
      expect(receipt.after.coins, 100 - food.cost);
      for (final n in Need.values) {
        expect(
          receipt.needChange(n),
          food.delta[n] ?? 0,
          reason: '${food.name} $n',
        );
      }
    }
  });

  test('sin saldo ni versión completa no cobra ni alimenta', () {
    final before = pet().copyWith(coins: 9);
    expect(
      () => rules.finishCare(
        before,
        CareKind.feed,
        'x',
        t0,
        option: Food.premium,
      ),
      throwsA(isA<RuleException>()),
    );
    expect(
      () =>
          rules.finishCare(pet(), CareKind.feed, 'x', t0, option: Food.salmon),
      throwsA(isA<RuleException>()),
    );
    expect(before.coins, 9);
    expect(rules.finishCare(before, CareKind.feed, 'free', t0).after.coins, 9);
  });

  test('comidas comparten plazo; 299 bloquea, 300 permite tras reiniciar', () {
    final after = rules.finishCare(pet(), CareKind.feed, 'a', t0).after;
    final loaded = SaveCodec(b).decode(SaveCodec(b).encode(after));
    expect(
      rules.careBlocked(loaded, CareKind.feed, t0 + 299, option: Food.premium),
      isNotNull,
    );
    expect(
      rules.careBlocked(loaded, CareKind.feed, t0 + 300, option: Food.premium),
      isNull,
    );
    expect(rules.careBlocked(loaded, CareKind.bath, t0), isNull);
  });

  test('beber suma 60 puntos y la versión completa permite repetir', () {
    final receipt = rules.finishCare(pet(), CareKind.drink, 'agua', t0);
    expect(receipt.needChange(Need.hydration), 60);
    expect(rules.careWaitSeconds(receipt.after, CareKind.drink, t0), 300);
    expect(
      rules.careBlocked(receipt.after, CareKind.drink, t0, fullVersion: true),
      isNull,
    );
  });

  test('todas las bebidas están disponibles pagando monedas', () {
    for (final drink in Drink.values) {
      final before = pet().copyWith(
        needs100: {...pet().needs100, Need.hydration: 1000},
      );
      final receipt = rules.finishCare(
        before,
        CareKind.drink,
        drink.name,
        t0,
        option: drink,
      );
      expect(receipt.after.coins, 100 - drink.cost);
      for (final need in Need.values) {
        expect(receipt.needChange(need), drink.delta[need] ?? 0);
      }
    }
  });

  test('el masaje requiere versión completa y los baños comparten plazo', () {
    expect(
      rules.careBlocked(pet(), CareKind.bath, t0, option: BathPlan.massage),
      contains('versión completa'),
    );
    final premium = rules.finishCare(
      pet(),
      CareKind.bath,
      'baño premium',
      t0,
      option: BathPlan.premium,
    );
    expect(premium.after.coins, 70);
    expect(premium.needChange(Need.hygiene), 60);
    expect(
      rules.careBlocked(premium.after, CareKind.bath, t0 + 299),
      contains('Podrás repetir'),
    );
  });

  test('descansar recupera minutos completos sin duplicarlos al reabrir', () {
    final codec = SaveCodec(b);
    final clock = NeedsClock(b);
    final resting = pet().copyWith(
      restingSinceUtc: t0,
      restEnergyCursorUtc: t0,
    );
    final at16 = clock.advance(codec.decode(codec.encode(resting)), t0 + 985);
    expect(at16.needPoints(Need.energy), 36);
    final reloaded = codec.decode(codec.encode(at16));
    expect(clock.advance(reloaded, t0 + 1019).needPoints(Need.energy), 36);
    expect(clock.advance(reloaded, t0 + 1020).needPoints(Need.energy), 37);
  });

  test('la sed baja el ánimo y los guardados antiguos reciben hidratación', () {
    final codec = SaveCodec(b);
    final old = jsonDecode(codec.encode(pet())) as Map<String, dynamic>;
    old.remove('hydration100');
    final restored = codec.decode(jsonEncode(old));
    expect(restored.needPoints(Need.hydration), 90);
    final clock = NeedsClock(b);
    final dry = clock.advance(pet(), t0 + b.tickSeconds);
    final wet = clock.advance(restored, t0 + b.tickSeconds);
    expect(dry.need100(Need.mood), wet.need100(Need.mood) - 100);
  });

  test('el saludo suma 10 de ánimo y conserva su plazo al reabrir', () {
    final greeted = rules.rewardGreeting(pet(), 'saludo', t0)!;
    expect(greeted.needPoints(Need.mood), 30);
    final loaded = SaveCodec(b).decode(SaveCodec(b).encode(greeted));
    expect(rules.rewardGreeting(loaded, 'pronto', t0 + 299), isNull);
    expect(
      rules.rewardGreeting(loaded, 'a tiempo', t0 + 300)!.needPoints(Need.mood),
      40,
    );
    expect(rules.careBlocked(loaded, CareKind.feed, t0), isNull);
  });

  test('3 partidas globales por ventana móvil; se conserva al reiniciar', () {
    var s = pet();
    for (var i = 0; i < 3; i++) {
      s = rules.startGame(s, 'start-$i', t0 + i * 10);
    }
    s = SaveCodec(b).decode(SaveCodec(b).encode(s));
    expect(rules.gameBlocked(s, t0 + 299), isNotNull);
    expect(
      () => rules.startGame(s, 'fourth', t0 + 299),
      throwsA(isA<RuleException>()),
    );
    expect(rules.gameBlocked(s, t0 + 300), isNull);
    final next = rules.startGame(s, 'fourth', t0 + 300);
    expect(next.gameStartedUtc, [t0 + 10, t0 + 20, t0 + 300]);
  });

  test('energía cero permite solo dormir; dormir +60 energía, +10 ánimo', () {
    final s = pet().copyWith(needs100: {...pet().needs100, Need.energy: 0});
    for (final care in CareKind.values) {
      expect(rules.careBlocked(s, care, t0) == null, care == CareKind.sleep);
    }
    expect(rules.gameBlocked(s, t0), isNotNull);
    final r = rules.finishCare(s, CareKind.sleep, 'sleep', t0);
    expect(r.needChange(Need.energy), 60);
    expect(r.needChange(Need.mood), 10);
  });

  test(
    'veterinario cobra 30 y cura en la misma operación; bloquea sin saldo',
    () {
      final s = pet().copyWith(coins: 30, sickSinceUtc: t0);
      final after = rules.finishCare(s, CareKind.vet, 'vet', t0).after;
      expect(after.coins, 0);
      expect(after.isSick, isFalse);
      expect(
        () => rules.finishCare(s.copyWith(coins: 29), CareKind.vet, 'fail', t0),
        throwsA(isA<RuleException>()),
      );
      expect(s.isSick, isTrue);
    },
  );

  test('jugar resta 20 energía y 10 saciedad, limitadas a cero', () {
    final r = rules.finishGame(pet(), GameId.frisbee, 5, 'game', t0);
    expect(r.after.coins, 118);
    expect(r.needChange(Need.energy), -20);
    expect(r.needChange(Need.satiety), -10);
    expect(r.after.bestFrisbee, 5);
  });

  test('peluquería guarda un corte adquirido junto al cuidado', () {
    final before = pet();
    final owned = before.copyWith(owned: {...before.owned, 'hair.pom'});
    final after = rules
        .finishCare(
          owned,
          CareKind.groom,
          'groom-pom',
          t0,
          groomingHair: 'hair.pom',
        )
        .after;
    expect(after.appearance.hair, 'hair.pom');
    expect(after.careCompletedUtc['groom'], t0);
    expect(after.coins, owned.coins);

    final preview = rules
        .finishCare(
          before,
          CareKind.groom,
          'groom-preview',
          t0,
          groomingHair: 'hair.pom',
        )
        .after;
    expect(preview.appearance, before.appearance);
    expect(preview.owned, before.owned);
  });

  test('higiene: seis fases distintas y umbral exacto en 65', () {
    expect(const PetFx(hygiene: 65).dirtStage, 0);
    expect(
      [
        for (final h in [64, 51, 38, 25, 12, 0]) PetFx(hygiene: h).dirtStage,
      ],
      [1, 2, 3, 4, 5, 6],
    );
  });
}
