import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/domain/pet_name.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/domain/sessions.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final clock = NeedsClock(balance);
  PetState adopt([String name = 'Miel']) =>
      PetState.adopt(validName: name, nowUtc: t0, balance: balance);

  group('E01 nombre', () {
    test('recorta y conserva tildes y espacios internos', () {
      expect((PetName.validate('  Miel  ') as ValidName).value, 'Miel');
      expect((PetName.validate('María José') as ValidName).value, 'María José');
    });
    test('compone acento combinante a NFC', () {
      final v = (PetName.validate('María') as ValidName).value;
      expect(v, 'María');
      expect(v.runes.length, 5);
    });
    test('16 grafemas sí, 17 no, vacío no, salto de línea no', () {
      expect(PetName.validate('a' * 16), isA<ValidName>());
      expect(
        (PetName.validate('a' * 17) as InvalidName).error,
        NameError.tooLong,
      );
      expect((PetName.validate('   ') as InvalidName).error, NameError.empty);
      expect(
        (PetName.validate('Mi\nel') as InvalidName).error,
        NameError.invalidCharacters,
      );
      expect(
        PetName.validate('ñandú🐩🐩🐩🐩🐩🐩🐩🐩🐩🐩'),
        isA<ValidName>(),
      ); // 16 grafemas
    });
  });

  test('adopción: revisión 1, 0 monedas, un artículo base por ranura', () {
    final s = adopt();
    expect(s.revision, 1);
    expect(s.coins, 0);
    expect(s.isSick, isFalse);
    expect(s.owned, {
      'coat.apricot',
      'hair.natural',
      'outfit.none',
      'head.none',
      'eyes.none',
      'collar.none',
      'neck.none',
      'paws.none',
    });
    expect([for (final n in Need.values) s.needPoints(n)], [65, 70, 75, 80]);
  });

  group('E02/E03 reloj', () {
    test('899 s no cambia, 900 s resta 0,75, 2 h → 59', () {
      final s = adopt();
      expect(clock.advance(s, t0 + 899).need100(Need.satiety), 6500);
      final a = clock.advance(s, t0 + 900);
      expect(a.need100(Need.satiety), 6425);
      expect(clock.advance(a, t0 + 7200).need100(Need.satiety), 5900);
      expect(clock.advance(s, t0 + 7200).need100(Need.satiety), 5900);
      expect(clock.advance(s, t0 + 7200).need100(Need.energy), 8800);
    });
    test('48 h limitado a 8 h: saciedad 41; reloj atrás no cambia', () {
      final s = adopt();
      final late = clock.advance(s, t0 + 48 * 3600 + 120);
      expect(late.need100(Need.satiety), 4100);
      expect(late.needsCursorUtc, t0 + 48 * 3600); // conserva la fracción
      final back = clock.advance(late, t0 + 47 * 3600);
      expect(identical(back, late), isTrue);
      expect(
        clock.advance(late, t0 + 48 * 3600 + 120).need100(Need.satiety),
        4100,
      );
    });
    test('energía se limita a 100', () {
      expect(
        clock.advance(adopt(), t0 + 8 * 3600).needPoints(Need.energy),
        100,
      );
    });
  });

  group('E04 cuidados', () {
    test('comer +20 con tope 100; paseo con energía 2 → 0', () {
      var s = adopt();
      s = s.copyWith(
        needs100: {...s.needs100, Need.satiety: 9500, Need.energy: 200},
      );
      expect(
        rules
            .finishCare(s, CareKind.feed, 'op1', t0)
            .after
            .needPoints(Need.satiety),
        100,
      );
      final w = rules.finishCare(s, CareKind.walk, 'op2', t0).after;
      expect(w.needPoints(Need.energy), 0);
      expect(w.needPoints(Need.mood), 90);
    });
    test('valores de referencia de cada cuidado y sin monedas', () {
      final s = adopt();
      expect(
        rules
            .finishCare(s, CareKind.feed, 'a', t0)
            .after
            .needPoints(Need.satiety),
        85,
      );
      expect(
        rules
            .finishCare(s, CareKind.bath, 'b', t0)
            .after
            .needPoints(Need.hygiene),
        95,
      );
      expect(
        rules
            .finishCare(s, CareKind.groom, 'c', t0)
            .after
            .needPoints(Need.hygiene),
        78,
      );
      final w = rules.finishCare(s, CareKind.walk, 'd', t0).after;
      expect(
        [w.needPoints(Need.mood), w.needPoints(Need.energy), w.coins],
        [90, 75, 0],
      );
    });
  });

  group('E05 cartera', () {
    final scarf = adopt().appearance.withSlot(Slot.neck, 'neck.coral');
    test('9 insuficiente, 10 → 0, 12 → 2', () {
      final s9 = adopt().copyWith(coins: 9);
      final r9 = rules.applyLook(s9, scarf, 'x', t0, fullVersion: true);
      expect(r9, isA<InsufficientCoins>());
      expect((r9 as InsufficientCoins).missing, 1);
      final r10 = rules.applyLook(
        adopt().copyWith(coins: 10),
        scarf,
        'y',
        t0,
        fullVersion: true,
      ) as Purchased;
      expect(r10.receipt.after.coins, 0);
      final r12 = rules.applyLook(
        adopt().copyWith(coins: 12),
        scarf,
        'z',
        t0,
        fullVersion: true,
      ) as Purchased;
      final after = r12.receipt.after;
      expect(after.coins, 2);
      expect(after.owned.contains('neck.coral'), isTrue);
      // Quitar y volver a equipar sin otro descuento.
      final off = (rules.applyLook(
        after,
        after.appearance.withSlot(Slot.neck, 'neck.none'),
        'q',
        t0,
        fullVersion: true,
      ) as Purchased).receipt.after;
      final on = (rules.applyLook(
        off,
        off.appearance.withSlot(Slot.neck, 'neck.coral'),
        'r',
        t0,
        fullVersion: true,
      ) as Purchased).receipt.after;
      expect([off.coins, on.coins, on.appearance.neck], [2, 2, 'neck.coral']);
      expect(on.owned.where((i) => i == 'neck.coral').length, 1);
    });
    test('cambiar una ranura conserva las otras tres (16 combinaciones)', () {
      final base = adopt().appearance;
      final combos = <Appearance>{};
      for (final c in ['coat.apricot', 'coat.silver']) {
        for (final h in ['hair.natural', 'hair.pom']) {
          for (final o in ['outfit.none', 'outfit.teal']) {
            for (final n in ['neck.none', 'neck.coral']) {
              final a = base
                  .withSlot(Slot.coat, c)
                  .withSlot(Slot.hair, h)
                  .withSlot(Slot.outfit, o)
                  .withSlot(Slot.neck, n);
              expect(a.withSlot(Slot.hair, 'hair.pom').coat, c);
              combos.add(a);
            }
          }
        }
      }
      expect(combos.length, 16);
      expect(
        rules.lookCost(
          adopt(),
          combos.firstWhere(
            (a) =>
                a.coat != base.coat &&
                a.hair != base.hair &&
                a.outfit != base.outfit &&
                a.neck != base.neck,
          ),
        ),
        24 + 30 + 18 + 10,
      );
    });
  });

  group('E08/E09 premios y sesiones', () {
    test('fórmulas y rango', () {
      expect([0, 7, 12].map(rules.fruitCoins), [2, 9, 14]);
      expect([0, 1, 2, 3].map(rules.frisbeeCoins), [3, 6, 9, 12]);
      expect(() => rules.fruitCoins(13), throwsA(isA<RuleException>()));
      expect(() => rules.frisbeeCoins(-1), throwsA(isA<RuleException>()));
    });
    test('juego terminado: +8 ánimo, −20 energía y −10 saciedad, récord', () {
      final r = rules.finishGame(adopt(), GameId.frisbee, 3, 'g', t0);
      expect(
        [
          r.after.coins,
          r.after.needPoints(Need.mood),
          r.after.needPoints(Need.energy),
        ],
        [12, 83, 60],
      );
      expect(r.newBest, isTrue);
      expect(r.after.bestFrisbee, 3);
    });
    test('sesión cancelada o duplicada no paga dos veces', () {
      final reg = SessionRegistry();
      final a = reg.begin('fruit');
      reg.cancel(a);
      expect(reg.isOpen(a), isFalse);
      expect(reg.wasCancelled(a), isTrue);
      final b = reg.begin('fruit');
      reg.complete(b, 'recibo');
      expect(reg.receiptOf<String>(b), 'recibo');
      expect(reg.isOpen(b), isFalse);
    });
    test('recorrido de control: 0 → 12 → 2 → 11', () {
      var s = adopt();
      s = rules.finishGame(s, GameId.frisbee, 3, 'f1', t0).after;
      expect(s.coins, 12);
      s = (rules.applyLook(
        s,
        s.appearance.withSlot(Slot.neck, 'neck.coral'),
        'b1',
        t0,
        fullVersion: true,
      ) as Purchased).receipt.after;
      expect(s.coins, 2);
      s = rules.finishGame(s, GameId.fruit, 7, 'o1', t0).after;
      expect(s.coins, 11);
      s = (rules.applyLook(
        s,
        s.appearance.withSlot(Slot.neck, 'neck.coral'),
        'e1',
        t0,
        fullVersion: true,
      ) as Purchased).receipt.after;
      expect(s.coins, 11);
    });
  });

  test('E10 catálogo inválido falla', () {
    expect(
      () => Balance(
        startCoins: 0,
        tickSeconds: 900,
        maxTicks: 32,
        initial100: balance.initial100,
        deltaPerTick100: balance.deltaPerTick100,
        care: balance.care,
        fruit: balance.fruit,
        frisbee: balance.frisbee,
        gameCompleteDelta: balance.gameCompleteDelta,
        health: balance.health,
        status: balance.status,
        styles: [...balance.styles, balance.styles.first],
      ),
      throwsA(isA<BalanceFormatException>()),
    );
  });
}
