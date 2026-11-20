import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/games/orchard_sim.dart';
import 'package:my_poodle/domain/games/variety.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/domain/tutorial.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final codec = SaveCodec(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);
  PetState rich(int coins) => adopt().copyWith(coins: coins);

  group('V01 variedad determinista', () {
    test('misma partida y sesión dan la misma semilla; otra sesión cambia', () {
      expect(runSeed(42, 'frisbee-1'), runSeed(42, 'frisbee-1'));
      expect(runSeed(42, 'frisbee-1'), isNot(runSeed(42, 'frisbee-2')));
      expect(runSeed(42, 'frisbee-1'), isNot(runSeed(43, 'frisbee-1')));
      expect(runSeed(42, 'x'), inInclusiveRange(0, 0x7fffffff));
    });

    test('frisbee: primer objetivo fijo, resto de la reserva sin repetir', () {
      final rule = balance.frisbee;
      final layouts = <String>{};
      for (var i = 0; i < 40; i++) {
        final t = frisbeeTargetsFor(i * 7919, rule.targetsField, rule.targetPool);
        expect(t.length, rule.throws);
        expect(t.first, rule.targetsField.first);
        expect(t.toSet().length, t.length, reason: 'sin repetidos');
        for (final p in t.skip(1)) {
          expect(rule.targetPool, contains(p));
        }
        for (final (x, depth) in t) {
          expect(x.abs(), lessThanOrEqualTo(3));
          expect(depth, inInclusiveRange(2, 8));
        }
        layouts.add(t.toString());
      }
      expect(layouts.length, greaterThan(10), reason: 'hay variedad real');
    });

    test('frisbee sin reserva usa los objetivos fijos', () {
      const base = [(0.0, 5.0), (1.0, 4.0)];
      expect(frisbeeTargetsFor(1, base, const []), base);
    });

    test('huerto: tres doradas, una por cada pareja de tramos', () {
      for (var seed = 0; seed < 30; seed++) {
        final g = goldenFruitsFor(seed * 31, OrchardLevel.v1).toList()..sort();
        expect(g.length, 3);
        expect(g[0], matches(RegExp(r'^t[12]-')));
        expect(g[1], matches(RegExp(r'^t[34]-')));
        expect(g[2], matches(RegExp(r'^t[56]-')));
        expect(goldenFruitsFor(seed * 31, OrchardLevel.v1), g.toSet());
      }
    });

    test('la simulación cuenta doradas sin cambiar la puntuación', () {
      final golden = {'t1-0', 't3-1', 't5-0'};
      final sim = OrchardSim(golden: golden);
      sim.collected.addAll({'t1-0', 't1-1', 't3-1'});
      expect(sim.score, 3);
      expect(sim.goldenCollected, 2);
    });
  });

  group('V02 estrellas', () {
    test('frisbee: una por umbral de capturas 2, 4 y 5', () {
      expect(
        [for (var c = 0; c <= 5; c++) rules.starsFor(GameId.frisbee, c)],
        [0, 0, 1, 1, 2, 3],
      );
    });

    test('huerto: 8 y 16 frutas; la tercera exige las 3 doradas', () {
      expect(rules.starsFor(GameId.fruit, 7), 0);
      expect(rules.starsFor(GameId.fruit, 8), 1);
      expect(rules.starsFor(GameId.fruit, 16, golden: 2), 2);
      expect(rules.starsFor(GameId.fruit, 15, golden: 3), 1);
      expect(rules.starsFor(GameId.fruit, 16, golden: 3), 3);
    });

    test('el premio en monedas no cambia con las estrellas', () {
      final a = rules.finishGame(adopt(), GameId.fruit, 16, 'a', t0);
      final b = rules.finishGame(
        adopt(),
        GameId.fruit,
        16,
        'b',
        t0,
        golden: 3,
      );
      expect(a.coinsEarned, b.coinsEarned);
      expect(a.coinsEarned, 2 + 2 * 16);
      expect((a.stars, b.stars), (2, 3));
    });

    test('mejor marca: se registra la primera partida y solo sube', () {
      var s = adopt();
      final first = rules.finishGame(s, GameId.frisbee, 1, 'f1', t0);
      expect(first.stars, 0);
      expect(first.newBestStars, isFalse);
      expect(first.after.bestStars, {'frisbee': 0});
      s = rules.finishGame(first.after, GameId.frisbee, 4, 'f2', t0).after;
      expect(s.bestStars['frisbee'], 2);
      final worse = rules.finishGame(s, GameId.frisbee, 2, 'f3', t0);
      expect(worse.after.bestStars['frisbee'], 2);
      expect(worse.newBestStars, isFalse);
      final better = rules.finishGame(worse.after, GameId.frisbee, 5, 'f4', t0);
      expect(better.newBestStars, isTrue);
      expect(better.after.bestStars['frisbee'], 3);
    });

    test('métricas de doradas inválidas se rechazan', () {
      expect(
        () => rules.finishGame(adopt(), GameId.fruit, 2, 'x', t0, golden: 3),
        throwsA(isA<RuleException>()),
      );
      expect(
        () => rules.finishGame(adopt(), GameId.fruit, 9, 'x', t0, golden: 4),
        throwsA(isA<RuleException>()),
      );
      expect(
        () => rules.finishGame(adopt(), GameId.frisbee, 3, 'x', t0, golden: 1),
        throwsA(isA<RuleException>()),
      );
    });
  });

  group('V03 decoración del salón', () {
    test('catálogo: 12 artículos, uno inicial y uno gratis por hueco', () {
      expect(balance.decor.length, 12);
      for (final slot in DecorSlot.values) {
        final items = balance.decorFor(slot);
        expect(items.where((d) => d.initial).length, 1);
        expect(items.any((d) => !d.initial && d.tier.name == 'free'), isTrue);
      }
      final free = balance.decor
          .where((d) => d.tier.name == 'free')
          .fold<int>(0, (a, d) => a + d.cost);
      final full = balance.decor
          .where((d) => d.tier.name == 'full')
          .fold<int>(0, (a, d) => a + d.cost);
      expect((free, full), (125, 510));
    });

    test('la adopción empieza con el salón vacío', () {
      expect(adopt().decor, {
        DecorSlot.rug: 'rug.none',
        DecorSlot.wall: 'wall.none',
        DecorSlot.plant: 'plant.none',
      });
    });

    test('39, 40 y 41 monedas ante la alfombra de 40', () {
      expect(
        rules.applyDecor(rich(39), 'rug.round', 'd', t0, fullVersion: false),
        isA<InsufficientCoins>().having((o) => o.missing, 'missing', 1),
      );
      final exact =
          rules.applyDecor(rich(40), 'rug.round', 'd', t0, fullVersion: false)
              as Purchased;
      expect(exact.cost, 40);
      expect(exact.receipt.after.coins, 0);
      expect(exact.receipt.after.decor[DecorSlot.rug], 'rug.round');
      expect(exact.receipt.after.owned, contains('rug.round'));
      final more =
          rules.applyDecor(rich(41), 'rug.round', 'd', t0, fullVersion: false)
              as Purchased;
      expect(more.receipt.after.coins, 1);
    });

    test('recolocar lo propio o quitarlo cuesta cero', () {
      final bought =
          (rules.applyDecor(rich(40), 'rug.round', 'a', t0, fullVersion: false)
                  as Purchased)
              .receipt
              .after;
      final removed =
          (rules.applyDecor(bought, 'rug.none', 'b', t0, fullVersion: false)
                  as Purchased);
      expect(removed.cost, 0);
      expect(removed.receipt.after.decor[DecorSlot.rug], 'rug.none');
      final again =
          rules.applyDecor(
                removed.receipt.after,
                'rug.round',
                'c',
                t0,
                fullVersion: false,
              )
              as Purchased;
      expect(again.cost, 0);
      expect(again.receipt.after.coins, 0);
    });

    test('la versión completa decide si se compra, no si se usa', () {
      expect(
        rules.applyDecor(rich(500), 'wall.stars', 'd', t0, fullVersion: false),
        isA<RequiresFull>(),
      );
      final full =
          rules.applyDecor(rich(500), 'wall.stars', 'd', t0, fullVersion: true)
              as Purchased;
      // Tras un reembolso lo comprado se sigue pudiendo colocar.
      final reuse = rules.applyDecor(
        full.receipt.after.copyWith(
          decor: {...full.receipt.after.decor, DecorSlot.wall: 'wall.none'},
        ),
        'wall.stars',
        'e',
        t0,
        fullVersion: false,
      );
      expect(reuse, isA<Purchased>().having((p) => p.cost, 'cost', 0));
    });

    test('colocar otro hueco conserva los demás', () {
      var s = rich(200);
      s = (rules.applyDecor(s, 'rug.round', 'a', t0, fullVersion: false)
              as Purchased)
          .receipt
          .after;
      s = (rules.applyDecor(s, 'plant.fern', 'b', t0, fullVersion: false)
              as Purchased)
          .receipt
          .after;
      expect(s.decor[DecorSlot.rug], 'rug.round');
      expect(s.decor[DecorSlot.plant], 'plant.fern');
      expect(s.coins, 200 - 40 - 35);
    });
  });

  group('V04 guardado compatible', () {
    test('estrellas y decoración sobreviven a guardar y cargar', () {
      var s = rich(100);
      s = (rules.applyDecor(s, 'plant.fern', 'a', t0, fullVersion: false)
              as Purchased)
          .receipt
          .after;
      s = rules.finishGame(s, GameId.frisbee, 4, 'g', t0).after;
      final back = codec.decode(codec.encode(s));
      expect(back.decor, s.decor);
      expect(back.bestStars, {'frisbee': 2});
      expect(back.owned, contains('plant.fern'));
    });

    test('una partida anterior carga con salón vacío y sin estrellas', () {
      final j =
          jsonDecode(codec.encode(adopt())) as Map<String, dynamic>
            ..remove('decor')
            ..remove('bestStars');
      final back = codec.decode(jsonEncode(j));
      expect(back.decor, balance.initialDecor);
      expect(back.bestStars, isEmpty);
    });

    test('decoración no poseída o retirada vuelve al hueco vacío', () {
      final j = jsonDecode(codec.encode(adopt())) as Map<String, dynamic>;
      j['decor'] = {'rug': 'rug.bone', 'wall': 'wall.retirada', 'plant': 7};
      final back = codec.decode(jsonEncode(j));
      expect(back.decor, balance.initialDecor);
    });

    test('estrellas fuera de rango invalidan el documento', () {
      final j = jsonDecode(codec.encode(adopt())) as Map<String, dynamic>;
      j['bestStars'] = {'fruit': 4};
      expect(() => codec.decode(jsonEncode(j)), throwsA(isA<SaveFormatException>()));
    });
  });

  group('V05 primera partida guiada', () {
    test('comer, jugar y estrenar algo, en ese orden', () {
      var s = adopt();
      expect(Tutorial.next(s, balance), TutorialStep.feed);
      s = s.copyWith(careCompletedUtc: {'feed': t0});
      expect(Tutorial.next(s, balance), TutorialStep.play);
      s = rules.finishGame(s, GameId.frisbee, 0, 'g', t0).after;
      expect(Tutorial.next(s, balance), TutorialStep.dress);
      s = s.copyWith(owned: {...s.owned, 'neck.coral'});
      expect(Tutorial.next(s, balance), isNull);
    });

    test('saltar la guía la oculta para siempre', () {
      final s = adopt().copyWith(
        prefs: adopt().prefs.copyWith(seenHints: {Tutorial.skipHint}),
      );
      expect(Tutorial.next(s, balance), isNull);
    });

    test('decorar también cuenta como estrenar', () {
      final s = adopt().copyWith(
        careCompletedUtc: {'feed': t0},
        bestStars: {'fruit': 0},
        decor: {...adopt().decor, DecorSlot.plant: 'plant.fern'},
      );
      expect(Tutorial.next(s, balance), isNull);
    });
  });
}
