import 'appearance.dart';
import 'balance.dart';
import 'needs_clock.dart';
import 'pet_state.dart';

/// Actividades con resultado confirmable. Los IDs coinciden con balance-v1.
enum CareKind { feed, bath, walk, groom, vet }

enum GameId { fruit, frisbee }

/// Recibo de una operación confirmada. El mismo opId devuelve el mismo recibo.
class Receipt {
  const Receipt({
    required this.opId,
    required this.before,
    required this.after,
    this.coinsEarned = 0,
    this.score = 0,
    this.newBest = false,
  });

  final String opId;
  final PetState before;
  final PetState after;
  final int coinsEarned;
  final int score;
  final bool newBest;

  int needChange(Need n) => after.needPoints(n) - before.needPoints(n);
}

class RuleException implements Exception {
  RuleException(this.message);
  final String message;
  @override
  String toString() => 'RuleException: $message';
}

/// Reglas puras: calculan el siguiente estado a partir de una copia ya
/// actualizada con el tiempo. Nunca escriben en disco.
class Rules {
  Rules(this.balance) : clock = NeedsClock(balance);
  final Balance balance;
  final NeedsClock clock;

  PetState _commit(PetState s, String opId) =>
      s.copyWith(revision: s.revision + 1, lastCommitId: opId);

  Map<Need, int> _applyDelta(PetState s, Map<Need, int> deltaPoints) {
    final out = Map<Need, int>.of(s.needs100);
    deltaPoints.forEach((n, d) => out[n] = clampNeed(s.need100(n) + d * 100));
    return out;
  }

  /// Cuidado completado: aplica el efecto del catálogo, sin monedas.
  Receipt finishCare(PetState s, CareKind kind, String opId, int nowUtc) {
    final rule = balance.care[kind.name];
    if (rule == null) throw RuleException('Cuidado desconocido: ${kind.name}');
    final before = clock.advance(s, nowUtc);
    final after = _commit(
      before.copyWith(needs100: _applyDelta(before, rule.delta)),
      opId,
    );
    return Receipt(opId: opId, before: before, after: after);
  }

  int fruitCoins(int apples) {
    final r = balance.fruit;
    if (apples < 0 || apples > r.maxScore) {
      throw RuleException('Manzanas fuera de rango: $apples');
    }
    return r.baseCoins + r.coinsPerPoint * apples;
  }

  int frisbeeCoins(int catches) {
    final r = balance.frisbee;
    if (catches < 0 || catches > r.maxScore) {
      throw RuleException('Capturas fuera de rango: $catches');
    }
    return r.baseCoins + r.coinsPerPoint * catches;
  }

  /// Minijuego terminado: monedas + ánimo/energía + récord.
  Receipt finishGame(
    PetState s,
    GameId game,
    int score,
    String opId,
    int nowUtc,
  ) {
    final coins = switch (game) {
      GameId.fruit => fruitCoins(score),
      GameId.frisbee => frisbeeCoins(score),
    };
    final before = clock.advance(s, nowUtc);
    final best = game == GameId.fruit ? before.bestFruit : before.bestFrisbee;
    final newBest = score > best;
    final after = _commit(
      before.copyWith(
        needs100: _applyDelta(before, balance.gameCompleteDelta),
        coins: before.coins + coins,
        bestFruit: game == GameId.fruit && newBest ? score : null,
        bestFrisbee: game == GameId.frisbee && newBest ? score : null,
      ),
      opId,
    );
    return Receipt(
      opId: opId,
      before: before,
      after: after,
      coinsEarned: coins,
      score: score,
      newBest: newBest,
    );
  }

  /// Coste de llevar el aspecto [target]: suma de artículos no poseídos.
  int lookCost(PetState s, Appearance target) {
    var total = 0;
    for (final slot in Slot.values) {
      final id = target.of(slot);
      final item = balance.item(id);
      if (item == null || item.slot != slot) {
        throw RuleException('Artículo inválido para ${slot.name}: $id');
      }
      if (!s.owned.contains(id)) total += item.cost;
    }
    return total;
  }

  /// Compra los artículos no poseídos de [target] y lo equipa en una sola
  /// operación. Usar artículos en propiedad cuesta cero.
  PurchaseOutcome applyLook(
    PetState s,
    Appearance target,
    String opId,
    int nowUtc,
  ) {
    final cost = lookCost(s, target);
    if (cost > s.coins) return InsufficientCoins(cost - s.coins, cost);
    final before = clock.advance(s, nowUtc);
    final owned = {...before.owned, ...target.ids};
    final after = _commit(
      before.copyWith(
        coins: before.coins - cost,
        owned: owned,
        appearance: target,
      ),
      opId,
    );
    return Purchased(Receipt(opId: opId, before: before, after: after), cost);
  }

  /// Necesidad más baja a sugerir. Energía baja sugiere descansar.
  /// Empates entre saciedad/higiene/ánimo: comida, baño y juego.
  Need lowestNeed(PetState s) {
    var best = Need.satiety;
    for (final n in [Need.satiety, Need.hygiene, Need.mood, Need.energy]) {
      if (s.need100(n) < s.need100(best)) best = n;
    }
    return best;
  }
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class Purchased extends PurchaseOutcome {
  const Purchased(this.receipt, this.cost);
  final Receipt receipt;
  final int cost;
}

class InsufficientCoins extends PurchaseOutcome {
  const InsufficientCoins(this.missing, this.cost);
  final int missing;
  final int cost;
}
