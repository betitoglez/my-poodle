import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final codec = SaveCodec(balance);
  PetState pet() =>
      PetState.adopt(validName: 'Casa', nowUtc: t0, balance: balance);
  test('premium trial persists and renews exactly after 24 hours', () {
    final started = rules.startGame(pet(), 'trial', t0, game: GameId.fruit);
    final restored = codec.decode(codec.encode(started));
    expect(restored.premiumTrialStartedUtc, {'fruit': t0});
    expect(
      rules.premiumTrialRemaining(restored, GameId.fruit, t0 + 86399),
      1,
    );
    expect(
      rules.premiumTrialRemaining(restored, GameId.fruit, t0 + 86400),
      0,
    );
    expect(
      () => rules.startGame(restored, 'again', t0 + 300, game: GameId.fruit),
      throwsA(isA<RuleException>()),
    );
    expect(
      rules.premiumTrialRemaining(restored, GameId.fruit, t0 - 60),
      86460,
    );
  });
  test('full ownership bypasses trial and free games do not consume it', () {
    final used = rules.startGame(pet(), 'trial', t0, game: GameId.fruit);
    final full = rules.startGame(
      used,
      'full',
      t0 + 301,
      game: GameId.fruit,
      fullVersion: true,
    );
    expect(full.premiumTrialStartedUtc, {'fruit': t0});
    final free = rules.startGame(used, 'free', t0 + 301, game: GameId.frisbee);
    expect(free.premiumTrialStartedUtc, {'fruit': t0});
    expect(rules.premiumTrialRemaining(free, GameId.frisbee, t0), 0);
  });
  test(
    'old saves start with unused trials; malformed records are rejected',
    () {
      final data = jsonDecode(codec.encode(pet())) as Map<String, dynamic>;
      data.remove('premiumTrialStartedUtc');
      expect(codec.decode(jsonEncode(data)).premiumTrialStartedUtc, isEmpty);
      for (final bad in [
        {'orchard': -1},
        {'orchard': 'yesterday'},
        [],
      ]) {
        data['premiumTrialStartedUtc'] = bad;
        expect(() => codec.decode(jsonEncode(data)), throwsException);
      }
    },
  );
}
