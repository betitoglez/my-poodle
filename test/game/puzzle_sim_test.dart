import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/games/pairs_sim.dart';
import 'package:my_poodle/domain/games/memory_sim.dart';
import 'package:my_poodle/domain/games/puzzle_deals.dart';

void showRound(MemorySim sim) {
  for (
    var i = 0;
    i < 1000 && sim.phase != MemoryPhase.input && !sim.finished;
    i++
  ) {
    sim.update(.05);
  }
  expect(sim.phase, MemoryPhase.input);
}

void main() {
  test(
    'Parejas: tamaños, dos cartas por caniche y repartos sin repetición',
    () {
      for (final count in [4, 6, 8]) {
        final history = <String>[];
        final random = Random(27);
        for (var i = 0; i < 200; i++) {
          final signature = PuzzleDeals.pairs(count, history, random: random);
          expect(history, isNot(contains(signature)));
          history.add(signature);
          final sim = PairsSim(PuzzleDeals.decode(signature));
          expect(sim.pairCount, count);
          expect(sim.cards.toSet().length, count);
        }
      }
    },
  );

  test('descarta un reparto que colisiona con el historial', () {
    final first = PuzzleDeals.pairs(4, [], random: Random(11));
    final next = PuzzleDeals.pairs(4, [first], random: Random(11));
    expect(next, isNot(first));
    final sequence = PuzzleDeals.memory([], random: Random(12));
    final another = PuzzleDeals.memory([sequence], random: Random(12));
    expect(another, isNot(sequence));
  });

  test('rechaza cartas/secuencias inválidas', () {
    expect(() => PairsSim([0, 0]), throwsArgumentError);
    expect(() => PairsSim(List.filled(8, 0)), throwsArgumentError);
    expect(() => MemorySim(List.filled(10, 4)), throwsArgumentError);
    expect(() => MemorySim([0, 1, 2]), throwsArgumentError);
  });

  test('Parejas: doble toque y tercer toque no gastan intentos', () {
    final sim = PairsSim([0, 1, 2, 3, 0, 1, 2, 3]);
    expect(sim.flip(0), isTrue);
    expect(sim.flip(0), isFalse);
    expect(sim.attempts, 5);
    expect(sim.flip(1), isTrue);
    expect(sim.attempts, 4);
    expect(sim.flip(2), isFalse);
    expect(sim.visible(0), isTrue);
    sim.update(.84);
    expect(sim.visible(0), isTrue);
    sim.update(.02);
    expect(sim.visible(0), isFalse);
    expect(sim.flip(2), isTrue);
  });

  test(
    'Parejas: aciertos conservan intentos y terminan con puntuación de nivel',
    () {
      for (final count in [4, 6, 8]) {
        final sim = PairsSim([
          ...List.generate(count, (i) => i),
          ...List.generate(count, (i) => i),
        ]);
        for (var i = 0; i < count; i++) {
          sim.flip(i);
          sim.flip(i + count);
          expect(sim.attempts, 5);
          expect(sim.flip(i), isFalse);
        }
        expect(sim.won, isTrue);
        expect(sim.finished, isTrue);
        expect(sim.score, count);
      }
    },
  );

  test('Parejas: cinco fallos o 60 segundos terminan sin premio', () {
    final sim = PairsSim([0, 1, 2, 3, 0, 1, 2, 3]);
    for (var i = 0; i < 5; i++) {
      sim.flip(0);
      sim.flip(1);
      sim.update(1);
    }
    expect(sim.attempts, 0);
    expect(sim.finished, isTrue);
    expect(sim.score, 0);
    expect(sim.flip(4), isFalse);
    final expired = PairsSim([0, 1, 2, 3, 0, 1, 2, 3]);
    expired.update(59.999);
    expect(expired.finished, isFalse);
    expired.update(.002);
    expect(expired.remaining, 0);
    expect(expired.finished, isTrue);
    expect(expired.score, 0);
  });

  test('Memory: muestras de luz y sonido, pausa entre señales repetidas', () {
    final sim = MemorySim(List.filled(10, 2));
    final notes = <int>[];
    expect(sim.press(2), isFalse);
    sim.update(.55, onSignal: notes.add);
    expect(sim.lit, 2);
    sim.update(.6, onSignal: notes.add);
    expect(sim.lit, isNull);
    sim.update(.25, onSignal: notes.add);
    expect(sim.lit, 2);
    expect(notes, [2, 2]);
    expect(sim.remaining, 10);
  });

  test(
    'Memory: diez segundos para el turno; un acierto no reinicia el reloj',
    () {
      final sim = MemorySim([0, 1, 2, 3, 0, 1, 2, 3, 0, 1]);
      showRound(sim);
      sim.update(9.9);
      expect(sim.finished, isFalse);
      expect(sim.press(0), isTrue);
      expect(sim.remaining, closeTo(.1, .06));
      sim.update(.02);
      expect(sim.press(1), isTrue);
      sim.update(.1);
      expect(sim.finished, isTrue);
      expect(sim.completed, 0);
      expect(sim.coins, 0);
      expect(sim.press(2), isFalse);
    },
  );

  test('Memory: de 3 a 10 pasos, premio total 5..40 sin sumar rondas', () {
    final sim = MemorySim([0, 1, 2, 3, 0, 1, 2, 3, 0, 1]);
    for (var length = 3; length <= 10; length++) {
      showRound(sim);
      expect(sim.length, length);
      for (var i = 0; i < length; i++) {
        expect(sim.press(sim.sequence[i]), isTrue);
      }
      expect(sim.completed, length);
      expect(sim.coins, (length - 2) * 5);
    }
    expect(sim.finished, isTrue);
    expect(sim.won, isTrue);
    expect(sim.coins, 40);
  });

  test(
    'Memory: error/tiempo en ronda siguiente conserva el premio anterior',
    () {
      for (final timeout in [false, true]) {
        final sim = MemorySim(List.filled(10, 0));
        showRound(sim);
        for (var i = 0; i < 3; i++) {
          sim.press(0);
        }
        expect(sim.press(0), isFalse);
        showRound(sim);
        if (timeout) {
          sim.update(10);
        } else {
          sim.press(1);
        }
        expect(sim.finished, isTrue);
        expect(sim.completed, 3);
        expect(sim.coins, 5);
      }
    },
  );

  test('Memory: no repite secuencias completas', () {
    final history = <String>[];
    final random = Random(31);
    for (var i = 0; i < 500; i++) {
      final signature = PuzzleDeals.memory(history, random: random);
      expect(history, isNot(contains(signature)));
      history.add(signature);
    }
  });
}
