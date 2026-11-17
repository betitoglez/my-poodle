import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/activities.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

const hour = 3600;
const day = 24 * hour;

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);

  PetState neglected(PetState s) => s.copyWith(
    needs100: {
      Need.satiety: 500,
      Need.hygiene: 500,
      Need.mood: 8000,
      Need.energy: 8000,
    },
  );

  /// Avanza [days] días en pasos de 8 h; si enferma, la cura al instante
  /// (el veterinario). Devuelve los instantes en que enfermó.
  List<int> simulate(PetState start, int days, {required bool neglect}) {
    var s = start;
    final sickAt = <int>[];
    for (var t = t0; t < t0 + days * day; t += 8 * hour) {
      // Descuidado: necesidades por los suelos. Cuidado: bien alimentado.
      s = neglect
          ? neglected(s)
          : s.copyWith(needs100: {for (final n in Need.values) n: 7000});
      s = rules.clock.advance(s, t + 8 * hour);
      if (s.isSick) {
        sickAt.add(s.sickSinceUtc!);
        s = s.copyWith(cured: true);
      }
    }
    return sickAt;
  }

  group('enfermedad', () {
    test('el primer día no enferma aunque esté descuidado', () {
      var s = neglected(adopt());
      for (var h = 8; h <= 24; h += 8) {
        s = neglected(s);
        s = rules.clock.advance(s, t0 + h * hour);
        expect(s.isSick, isFalse, reason: 'a las $h h');
      }
    });

    test('como máximo una vez por semana, con descuido y con azar', () {
      for (final neglect in [true, false]) {
        final times = simulate(adopt(), 200, neglect: neglect);
        for (var i = 1; i < times.length; i++) {
          expect(
            times[i] - times[i - 1],
            greaterThanOrEqualTo(7 * day),
            reason: 'neglect=$neglect enfermedad ${i + 1}',
          );
        }
        expect(times.first - t0, greaterThanOrEqualTo(day));
      }
    });

    test('descuidado enferma pronto; con cuidados enferma pocas veces', () {
      final neglected_ = simulate(adopt(), 60, neglect: true);
      expect(neglected_.length, greaterThanOrEqualTo(6)); // ≈ cada 8 días
      final cared = simulate(adopt(), 200, neglect: false);
      expect(cared.length, inInclusiveRange(6, 26));
    });

    test('es determinista: mismos datos, mismo resultado', () {
      final a = simulate(adopt(), 90, neglect: false);
      final b = simulate(adopt(), 90, neglect: false);
      expect(a, b);
    });

    test('malito baja el ánimo más deprisa y no vuelve a enfermar', () {
      final healthy = adopt();
      final sick = healthy.copyWith(sickSinceUtc: t0);
      final h = rules.clock.advance(healthy, t0 + 2 * hour);
      final s = rules.clock.advance(sick, t0 + 2 * hour);
      expect(s.need100(Need.mood), lessThan(h.need100(Need.mood)));
      expect(
        h.need100(Need.mood) - s.need100(Need.mood),
        400,
      ); // −2 puntos/h extra
      expect(s.isSick, isTrue);
    });

    test('el veterinario cura sin reiniciar el plazo semanal', () {
      final sick = adopt().copyWith(sickSinceUtc: t0, lastSickUtc: t0);
      final r = rules.finishCare(sick, CareKind.vet, 'vet-1', t0);
      expect(r.before.isSick, isTrue);
      expect(r.after.isSick, isFalse);
      expect(r.after.lastSickUtc, t0);
      expect(r.after.needPoints(Need.mood), 80);
      expect(r.after.coins, 0);
      // Sano, la revisión no cambia la salud.
      final healthy = rules.finishCare(adopt(), CareKind.vet, 'vet-2', t0);
      expect(healthy.after.isSick, isFalse);
    });

    test('otras actividades no curan', () {
      final sick = adopt().copyWith(sickSinceUtc: t0, lastSickUtc: t0);
      for (final k in [CareKind.feed, CareKind.bath, CareKind.sleep]) {
        expect(rules.finishCare(sick, k, 'x-$k', t0).after.isSick, isTrue);
      }
    });
  });

  group('iconos de estado', () {
    test('se encienden bajo el umbral y por salud', () {
      expect(rules.conditions(adopt()), isEmpty);
      final s = adopt().copyWith(
        needs100: {
          Need.satiety: 2900,
          Need.hygiene: 3000,
          Need.mood: 2000,
          Need.energy: 2400,
        },
        sickSinceUtc: t0,
      );
      expect(rules.conditions(s), {
        PetCondition.hungry,
        PetCondition.sad,
        PetCondition.tired,
        PetCondition.sick,
      });
    });

    test('lo más urgente: enfermo primero, luego la necesidad más baja', () {
      final low = adopt().copyWith(
        needs100: {
          Need.satiety: 2000,
          Need.hygiene: 1000,
          Need.mood: 8000,
          Need.energy: 8000,
        },
      );
      expect(rules.mostUrgent(low), PetCondition.dirty);
      expect(
        rules.mostUrgent(low.copyWith(sickSinceUtc: t0)),
        PetCondition.sick,
      );
      expect(rules.mostUrgent(adopt()), isNull);
    });
  });

  group('dormir y veterinario', () {
    test(
      'dormir: tres pasos en orden y despertar; toques repetidos no cuentan',
      () {
        final a = SleepActivity();
        expect(a.advance(SleepPhase.blanket), isFalse);
        expect(a.advance(SleepPhase.toBed), isTrue);
        expect(a.advance(SleepPhase.toBed), isFalse);
        expect(a.advance(SleepPhase.blanket), isTrue);
        expect(a.advance(SleepPhase.lights), isTrue);
        expect(a.completed, isFalse);
        expect(a.wake(), isTrue);
        expect(a.completed, isTrue);
      },
    );

    test('dormir recupera 45 de energía con tope 100', () {
      final s = adopt().copyWith(
        needs100: {...adopt().needs100, Need.energy: 3000},
      );
      final r = rules.finishCare(s, CareKind.sleep, 'z', t0);
      expect(r.after.needPoints(Need.energy), 75);
      expect(r.after.needPoints(Need.mood), 78);
      final full = rules.finishCare(adopt(), CareKind.sleep, 'z2', t0);
      expect(full.after.needPoints(Need.energy), 100);
    });

    test('veterinario: sano son dos pasos; malito, tres con pastilla', () {
      final healthy = VetActivity(sick: false);
      expect(healthy.givePill(), isFalse);
      expect(healthy.listen(), isTrue);
      expect(healthy.checkPaws(), isTrue);
      expect(healthy.completed, isTrue);
      expect(healthy.total, 2);
      final sick = VetActivity(sick: true);
      expect(sick.checkPaws(), isFalse); // primero el corazón
      expect(sick.listen(), isTrue);
      expect(sick.checkPaws(), isTrue);
      expect(sick.completed, isFalse);
      expect(sick.givePill(), isTrue);
      expect(sick.givePill(), isFalse);
      expect(sick.completed, isTrue);
      expect(sick.total, 3);
    });
  });

  group('partidas y catálogo', () {
    test(
      'una partida anterior a la salud y a las ranuras nuevas se abre sana',
      () {
        final codec = SaveCodec(balance);
        final old = jsonEncode({
          'schemaVersion': 1,
          'revision': 4,
          'lastCommitId': 'x',
          'name': 'Coco',
          'needsCursorUtc': t0,
          'satiety100': 6000,
          'hygiene100': 6000,
          'mood100': 6000,
          'energy100': 6000,
          'coins': 20,
          'owned': [
            'coat.apricot',
            'hair.natural',
            'outfit.none',
            'neck.none',
            'neck.coral',
          ],
          'appearance': {
            'coat': 'coat.apricot',
            'hair': 'hair.natural',
            'outfit': 'outfit.none',
            'neck': 'neck.coral',
          },
        });
        final s = codec.decode(old);
        expect(s.isSick, isFalse);
        expect(s.appearance.neck, 'neck.coral');
        expect(
          [
            s.appearance.head,
            s.appearance.eyes,
            s.appearance.collar,
            s.appearance.paws,
          ],
          ['head.none', 'eyes.none', 'collar.none', 'paws.none'],
        );
        expect(s.owned, containsAll(['head.none', 'paws.none']));
        // La salud se guarda y se recupera.
        final sick = s.copyWith(sickSinceUtc: t0 + 5, lastSickUtc: t0 + 5);
        final back = codec.decode(codec.encode(sick));
        expect(
          [back.sickSinceUtc, back.lastSickUtc, back.sickSeed],
          [t0 + 5, t0 + 5, s.sickSeed],
        );
        final cured = codec.decode(codec.encode(back.copyWith(cured: true)));
        expect(cured.isSick, isFalse);
      },
    );

    test(
      'catálogo: precios crecientes por categoría y mismo precio por variedad',
      () {
        for (final slot in Slot.values) {
          final prices = balance.itemsFor(slot).map((i) => i.cost).toList();
          expect(prices.first, 0, reason: slot.name);
          expect(prices, orderedEquals([...prices]..sort()), reason: slot.name);
        }
        int cost(String id) => balance.item(id)!.cost;
        for (final v in ['overalls', 'sweater', 'raincoat', 'dress']) {
          final prices = balance.styles
              .where(
                (i) =>
                    i.id.startsWith(
                      'outfit.${v == 'overalls' ? 'overalls_' : '${v}_'}',
                    ) ||
                    (v == 'overalls' && i.id == 'outfit.teal'),
              )
              .map((i) => i.cost)
              .toSet();
          expect(prices, hasLength(1), reason: v);
        }
        expect(cost('outfit.teal') < cost('outfit.sweater_red'), isTrue);
        expect(
          cost('outfit.sweater_red') < cost('outfit.raincoat_pink'),
          isTrue,
        );
        expect(
          cost('outfit.raincoat_pink') < cost('outfit.dress_pink'),
          isTrue,
        );
        // Compatibilidad: los IDs y precios originales no cambian.
        expect(
          [
            cost('coat.silver'),
            cost('hair.pom'),
            cost('outfit.teal'),
            cost('neck.coral'),
          ],
          [24, 30, 18, 10],
        );
      },
    );

    test('comprar varios artículos de ranuras distintas suma sus costes', () {
      final a = adopt().appearance
          .withSlot(Slot.head, 'head.bow')
          .withSlot(Slot.eyes, 'eyes.sun')
          .withSlot(Slot.paws, 'paws.rain');
      final s = adopt().copyWith(coins: 200);
      expect(rules.lookCost(s, a), 14 + 36 + 56);
      final r = rules.applyLook(s, a, 'o', t0, fullVersion: true) as Purchased;
      expect(r.receipt.after.coins, 200 - 106);
      expect(
        r.receipt.after.owned,
        containsAll(['head.bow', 'eyes.sun', 'paws.rain']),
      );
    });
  });
}
