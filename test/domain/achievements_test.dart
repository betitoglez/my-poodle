import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/achievements.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final ach = rules.achievements;
  final codec = SaveCodec(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);
  const day = secondsPerDay;

  /// Partida con todos los logros de [page] ya guardados.
  PetState withPage(PetState s, AlbumPage page) =>
      ach.record(s, [for (final a in Achievements.onPage(page)) a.id], t0);

  group('catálogo', () {
    test('23 logros con ID estable, 5 páginas y bonos del balance', () {
      expect(Achievements.catalog.length, 23);
      expect(Achievements.catalog.map((a) => a.id).toSet().length, 23);
      expect(Achievements.catalog.every((a) => a.id.startsWith('ach.')), true);
      expect(
        {
          for (final p in AlbumPage.values)
            p.name: Achievements.onPage(p).length,
        },
        {'care': 7, 'games': 6, 'wardrobe': 4, 'photos': 2, 'special': 4},
      );
      expect(
        {for (final p in AlbumPage.values) p.name: ach.pageBonus(p)},
        {'care': 40, 'games': 50, 'wardrobe': 60, 'photos': 30, 'special': 80},
      );
    });

    test('una partida nueva no tiene ningún logro', () {
      final s = adopt();
      expect(ach.newlyUnlocked(s, s), isEmpty);
      expect(rules.syncAchievements(s, t0), isNull);
    });
  });

  group('desbloqueo en operaciones confirmadas', () {
    test(
      'primera comida: se guarda en la misma escritura y va en el recibo',
      () {
        final r = rules.finishCare(adopt(), CareKind.feed, 'c1', t0 + 10);
        expect(r.newAchievements, ['ach.care.feed']);
        expect(r.after.achievements['ach.care.feed'], t0 + 10);
        expect(r.after.revision, adopt().revision + 1);
        expect(r.after.careDayCount, 1);
      },
    );

    test('idempotente: repetir el cuidado no repite el logro ni la fecha', () {
      final r1 = rules.finishCare(adopt(), CareKind.feed, 'c1', t0 + 10);
      final r2 = rules.finishCare(r1.after, CareKind.feed, 'c2', t0 + 1000);
      expect(r2.newAchievements, isEmpty);
      expect(r2.after.achievements['ach.care.feed'], t0 + 10);
      expect(ach.newlyUnlocked(r2.after, r2.after), isEmpty);
      // Mismo día UTC: no suma otro día de cuidado.
      expect(r2.after.careDayCount, 1);
    });

    test('días distintos de cuidado: 3 y 7', () {
      var s = adopt();
      final got = <String>[];
      for (var d = 0; d < 7; d++) {
        final r = rules.finishCare(s, CareKind.walk, 'w$d', t0 + d * day + 5);
        got.addAll(r.newAchievements);
        s = r.after;
      }
      expect(s.careDayCount, 7);
      expect(got, containsAll(['ach.care.days3', 'ach.care.days7']));
      expect(got.indexOf('ach.care.days3'), lessThan(got.length));
    });

    test('partida, estrellas y monedas ganadas', () {
      var s = adopt();
      final r = rules.finishGame(s, GameId.frisbee, 5, 'f1', t0 + 1);
      expect(
        r.newAchievements,
        containsAll(['ach.game.frisbee.first', 'ach.game.frisbee.stars3']),
      );
      expect(r.after.coinsEarnedTotal, r.coinsEarned);
      s = r.after;
      // 200 monedas jugando al frisbee perfecto (18 por partida).
      var unlockedAt = -1;
      for (var i = 0; i < 12; i++) {
        final g = rules.finishGame(s, GameId.frisbee, 5, 'g$i', t0 + 2 + i);
        if (g.newAchievements.contains('ach.coins.200')) unlockedAt = i;
        s = g.after;
      }
      expect(s.coinsEarnedTotal, 18 * 13);
      expect(unlockedAt, 10); // 18 × 12 = 216 ≥ 200
    });

    test('tres estrellas en todos los juegos', () {
      final s = adopt().copyWith(
        bestStars: {'fruit': 3, 'pairs': 3, 'memory': 3},
      );
      final r = rules.finishGame(s, GameId.frisbee, 5, 'f', t0);
      expect(r.newAchievements, contains('ach.game.allStars'));
    });

    test('armario: primera compra; decoración: primer hueco', () {
      final s = adopt().copyWith(coins: 100);
      final look = s.appearance.withSlot(Slot.neck, 'neck.coral');
      final p = rules.applyLook(s, look, 'l', t0, fullVersion: false);
      expect((p as Purchased).receipt.newAchievements, ['ach.wardrobe.first']);
      final d = rules.applyDecor(
        p.receipt.after,
        'plant.fern',
        'd',
        t0,
        fullVersion: false,
      );
      expect((d as Purchased).receipt.newAchievements, ['ach.decor.first']);
    });

    test('todos los artículos gratuitos del armario y 10 compras', () {
      final free = balance.styles
          .where((i) => !i.initial && i.tier == Tier.free)
          .map((i) => i.id);
      final s = adopt().copyWith(owned: {...adopt().owned, ...free});
      final ids = ach.newlyUnlocked(s, s);
      expect(ids, containsAll(['ach.wardrobe.first', 'ach.wardrobe.allFree']));
      expect(
        ids.contains('ach.wardrobe.ten'),
        wardrobeBought(s, balance) >= wardrobeMany,
      );
    });

    test('cortes por zona: cuentan como compras y completan los gratuitos', () {
      // Un único corte por zona ya es la primera compra del armario.
      final one = adopt().copyWith(
        owned: {...adopt().owned, Haircuts.id(HairZone.tail, 'pom')},
      );
      expect(wardrobeBought(one, balance), 1);
      expect(ach.newlyUnlocked(one, one), contains('ach.wardrobe.first'));
      // Los peinados gratuitos comprados zona a zona, sin el ID completo.
      final free = balance.styles
          .where((i) => !i.initial && i.tier == Tier.free)
          .map((i) => i.id)
          .where((id) => !id.startsWith('hair.'));
      final cuts = {
        for (final style in ['pom', 'show'])
          for (final z in HairZone.values) Haircuts.id(z, style),
      };
      final s = adopt().copyWith(owned: {...adopt().owned, ...free, ...cuts});
      expect(
        s.owned.any((id) => id.startsWith('hair.') && id != 'hair.natural'),
        isFalse,
      );
      expect(ach.newlyUnlocked(s, s), contains('ach.wardrobe.allFree'));
    });

    test('fotos: primera y diez', () {
      var s = adopt();
      final got = <String>[];
      for (var i = 0; i < 10; i++) {
        final r = rules.recordPhoto(s, 'p$i', t0 + i);
        got.addAll(r.newAchievements);
        s = r.after;
      }
      expect(s.photosTaken, 10);
      expect(got, ['ach.photo.first', 'ach.photo.ten']);
    });
  });

  group('bono de página', () {
    test('se recoge una sola vez y no cuenta como ganado jugando', () {
      final s = withPage(adopt(), AlbumPage.photos);
      expect(ach.canCollect(s, AlbumPage.photos), true);
      expect(ach.pendingPages(s), 1);
      final r = rules.collectAlbumPage(s, AlbumPage.photos, 'a1', t0);
      expect(r.coinsEarned, 30);
      expect(r.after.coins, s.coins + 30);
      expect(r.after.coinsEarnedTotal, s.coinsEarnedTotal);
      expect(r.after.albumCollected, {'photos'});
      expect(ach.canCollect(r.after, AlbumPage.photos), false);
      expect(
        () => rules.collectAlbumPage(r.after, AlbumPage.photos, 'a2', t0),
        throwsA(isA<RuleException>()),
      );
    });

    test('una página incompleta no paga', () {
      final s = ach.record(adopt(), ['ach.photo.first'], t0);
      expect(
        () => rules.collectAlbumPage(s, AlbumPage.photos, 'a', t0),
        throwsA(isA<RuleException>()),
      );
    });
  });

  group('partida antigua', () {
    Map<String, dynamic> legacyJson(PetState s) {
      final j = jsonDecode(codec.encode(s)) as Map<String, dynamic>;
      for (final k in [
        'achievements',
        'albumCollected',
        'coinsEarnedTotal',
        'careDayCount',
        'lastCareDay',
        'photosTaken',
      ]) {
        j.remove(k);
      }
      return j;
    }

    test('carga sin campos nuevos, deduce contadores y obtiene lo cumplido '
        'sin pagar nada', () {
      final old = adopt().copyWith(
        coins: 15,
        owned: {...adopt().owned, 'neck.coral', 'plant.fern'},
        careCompletedUtc: {
          'feed': t0,
          'bath': t0 + day,
          'walk': t0 + 2 * day,
          'greeting': t0 + 9 * day,
        },
        bestStars: {'frisbee': 3},
        decor: {...adopt().decor, DecorSlot.plant: 'plant.fern'},
      );
      final loaded = codec.decode(jsonEncode(legacyJson(old)));
      expect(loaded.achievements, isEmpty);
      expect(loaded.careDayCount, 3);
      expect(loaded.lastCareDay, (t0 + 2 * day) ~/ day);
      // Cota inferior: saldo 15 + pañuelo 10 + helecho 35.
      expect(loaded.coinsEarnedTotal, 60);
      expect(loaded.photosTaken, 0);

      final synced = rules.syncAchievements(loaded, t0 + 10 * day)!;
      expect(synced.coins, loaded.coins);
      expect(synced.revision, loaded.revision + 1);
      expect(synced.needs100, loaded.needs100);
      expect(
        synced.achievements.keys,
        containsAll([
          'ach.care.feed',
          'ach.care.bath',
          'ach.care.walk',
          'ach.care.days3',
          'ach.game.frisbee.first',
          'ach.game.frisbee.stars3',
          'ach.wardrobe.first',
          'ach.decor.first',
        ]),
      );
      expect(synced.achievements.values.toSet(), {t0 + 10 * day});
      expect(synced.albumCollected, isEmpty);
      expect(rules.syncAchievements(synced, t0 + 11 * day), isNull);
    });

    test('récord anterior a las estrellas cuenta como primera partida', () {
      final s = adopt().copyWith(bestFruit: 12);
      expect(ach.newlyUnlocked(s, s), contains('ach.game.fruit.first'));
    });
  });

  group('SaveCodec', () {
    test('ida y vuelta de logros, álbum y contadores', () {
      final s = adopt().copyWith(
        achievements: {'ach.care.feed': t0, 'ach.photo.first': t0 + 5},
        albumCollected: {'photos'},
        coinsEarnedTotal: 123,
        careDayCount: 4,
        lastCareDay: t0 ~/ day,
        photosTaken: 3,
      );
      final back = codec.decode(codec.encode(s));
      expect(back.achievements, s.achievements);
      expect(back.albumCollected, {'photos'});
      expect(back.coinsEarnedTotal, 123);
      expect(back.careDayCount, 4);
      expect(back.lastCareDay, t0 ~/ day);
      expect(back.photosTaken, 3);
    });

    for (final (field, value) in <(String, Object)>[
      ('achievements', ['ach.care.feed']),
      ('achievements', {'ach.care.feed': -1}),
      ('achievements', {'ach.care.feed': 'ayer'}),
      ('albumCollected', 'photos'),
      ('albumCollected', [1]),
      ('coinsEarnedTotal', -5),
      ('coinsEarnedTotal', '10'),
      ('careDayCount', -1),
      ('lastCareDay', 1.5),
      ('photosTaken', -2),
    ]) {
      test('rechaza $field = $value', () {
        final j = jsonDecode(codec.encode(adopt())) as Map<String, dynamic>;
        j[field] = value;
        expect(
          () => codec.decode(jsonEncode(j)),
          throwsA(isA<SaveFormatException>()),
        );
      });
    }
  });
}
