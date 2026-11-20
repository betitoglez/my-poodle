import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/data/save_codec.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final codec = SaveCodec(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);

  test('premios exactos, récords independientes y métricas inválidas', () {
    for (final (score, coins) in [(0, 0), (4, 5), (6, 15), (8, 25)]) {
      final receipt = rules.finishGame(
        adopt(),
        GameId.pairs,
        score,
        'pairs',
        t0,
      );
      expect(receipt.coinsEarned, coins);
      expect(receipt.after.bestPairs, score);
      expect(receipt.after.bestFrisbee, 0);
      expect(receipt.after.bestFruit, 0);
    }
    expect(rules.memoryCoins(0), 0);
    for (var score = 3; score <= 10; score++) {
      final receipt = rules.finishGame(
        adopt(),
        GameId.memory,
        score,
        'memory',
        t0,
      );
      expect(receipt.coinsEarned, (score - 2) * 5);
      expect(receipt.after.bestMemory, score);
      expect(receipt.after.bestPairs, 0);
    }
    for (final n in [-1, 1, 2, 3, 5, 7, 9]) {
      expect(() => rules.pairsCoins(n), throwsA(isA<RuleException>()));
    }
    for (final n in [-1, 1, 2, 11]) {
      expect(() => rules.memoryCoins(n), throwsA(isA<RuleException>()));
    }
  });

  test('Memory exige compra y no ofrece la prueba de 24 horas', () {
    expect(rules.gameTier(GameId.pairs), Tier.free);
    expect(rules.gameTier(GameId.memory), Tier.full);
    expect(rules.offersGameTrial(GameId.memory), isFalse);
    expect(
      () => rules.startGame(adopt(), 'locked', t0, game: GameId.memory),
      throwsA(isA<RuleException>()),
    );
    final unlocked = rules.startGame(
      adopt(),
      'full',
      t0,
      game: GameId.memory,
      fullVersion: true,
    );
    expect(unlocked.puzzleDeals['memory']!.single.length, 10);
    expect(unlocked.premiumTrialStartedUtc, isEmpty);
    final free = rules.startGame(
      adopt(),
      'free',
      t0,
      game: GameId.pairs,
      pairs: 8,
    );
    expect(free.puzzleDeals['pairs-8']!.single.length, 16);
  });

  test(
    'repartos e historial sobreviven reinicio, abandono y nuevas partidas',
    () {
      var state = adopt();
      for (var i = 0; i < 15; i++) {
        state = rules.startGame(
          state,
          'start-$i',
          t0 + i * 301,
          game: GameId.pairs,
          pairs: 4,
        );
        state = codec.decode(codec.encode(state));
      }
      final history = state.puzzleDeals['pairs-4']!;
      expect(history.length, 15);
      expect(history.toSet().length, 15);
      expect(state.coins, adopt().coins);
    },
  );

  test('guardados antiguos cargan sin récords ni historial nuevos', () {
    final old = jsonDecode(codec.encode(adopt())) as Map<String, dynamic>;
    old.remove('puzzleDeals');
    old.remove('bestPairs');
    old.remove('bestMemory');
    final restored = codec.decode(jsonEncode(old));
    expect(restored.puzzleDeals, isEmpty);
    expect(restored.bestPairs, 0);
    expect(restored.bestMemory, 0);
  });
}
