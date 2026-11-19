import 'appearance.dart';
import 'balance.dart';
import 'care_options.dart';
import 'entitlements.dart';
import 'food.dart';
import 'needs_clock.dart';
import 'pet_state.dart';

/// Actividades con resultado confirmable. Los IDs coinciden con balance-v1.
enum CareKind { feed, bath, walk, groom, sleep, vet, drink }

/// Estados que enciende el visor, estilo tamagotchi. [need] es la medida
/// que lo enciende; la enfermedad es un estado aparte.
enum PetCondition {
  hungry(Need.satiety),
  dirty(Need.hygiene),
  sad(Need.mood),
  tired(Need.energy),
  thirsty(Need.hydration),
  sick(null);

  const PetCondition(this.need);
  final Need? need;
}

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

  static const activityWindow = 300;
  static const vetCost = 30;
  static const thirstyBelow = 35;

  CareOption? _careOption(CareKind kind, CareOption? selection) {
    final CareOption? fallback = switch (kind) {
      CareKind.feed => Food.basic,
      CareKind.bath => BathPlan.standard,
      CareKind.drink => Drink.water,
      _ => null,
    };
    if (selection == null) return fallback;
    return switch ((kind, selection)) {
      (CareKind.feed, Food()) ||
      (CareKind.bath, BathPlan()) ||
      (CareKind.drink, Drink()) => selection,
      _ => null,
    };
  }

  int careWaitSeconds(
    PetState s,
    CareKind kind,
    int nowUtc, {
    bool fullVersion = false,
  }) {
    final last = s.careCompletedUtc[kind.name];
    if (fullVersion || last == null) return 0;
    return (activityWindow - (nowUtc - last)).clamp(0, activityWindow);
  }

  PetState? rewardGreeting(PetState s, String opId, int nowUtc) {
    final before = clock.advance(s, nowUtc);
    final last = before.careCompletedUtc['greeting'];
    if (before.isSick ||
        before.need100(Need.energy) == 0 ||
        last != null && nowUtc - last < activityWindow) {
      return null;
    }
    return _commit(
      before.copyWith(
        needs100: _applyDelta(before, {Need.mood: 10}),
        careCompletedUtc: {...before.careCompletedUtc, 'greeting': nowUtc},
      ),
      opId,
    );
  }

  String? careBlocked(
    PetState s,
    CareKind kind,
    int nowUtc, {
    CareOption? option,
    bool fullVersion = false,
  }) {
    if (s.need100(Need.energy) == 0 && kind != CareKind.sleep) {
      return 'Necesita dormir: su energía está a cero.';
    }
    final wait = careWaitSeconds(s, kind, nowUtc, fullVersion: fullVersion);
    if (wait > 0) {
      return 'Podrás repetir este cuidado en ${wait ~/ 60} min ${wait % 60} s.';
    }
    final selected = _careOption(kind, option);
    if (option != null && selected == null) {
      return 'Opción de cuidado inválida.';
    }
    if (selected != null && selected.tier == Tier.full && !fullVersion) {
      return kind == CareKind.feed
          ? 'Esta comida necesita la versión completa.'
          : '${selected.label} necesita la versión completa.';
    }
    final cost = kind == CareKind.vet ? vetCost : selected?.cost ?? 0;
    if (s.coins < cost) return 'Necesitas $cost monedas (tienes ${s.coins}).';
    return null;
  }

  String? gameBlocked(PetState s, int nowUtc) {
    if (s.need100(Need.energy) == 0) {
      return 'Necesita dormir: su energía está a cero.';
    }
    final recent = s.gameStartedUtc
        .where((t) => nowUtc - t < activityWindow)
        .toList();
    if (recent.length >= 3) {
      recent.sort();
      final wait = activityWindow - (nowUtc - recent.first);
      return 'Ya has jugado 3 veces. Vuelve en ${wait ~/ 60} min ${wait % 60} s.';
    }
    return null;
  }

  static const premiumTrialWindow = 24 * 60 * 60;

  int premiumTrialRemaining(PetState s, GameId game, int nowUtc) {
    if (gameTier(game) != Tier.full) return 0;
    final last = s.premiumTrialStartedUtc[game.name];
    if (last == null) return 0;
    final remaining = premiumTrialWindow - (nowUtc - last);
    return remaining > 0 ? remaining : 0;
  }

  PetState startGame(
    PetState s,
    String opId,
    int nowUtc, {
    required GameId game,
    bool fullVersion = false,
  }) {
    final before = clock.advance(s, nowUtc);
    final blocked = gameBlocked(before, nowUtc);
    if (blocked != null) throw RuleException(blocked);
    final trial = gameTier(game) == Tier.full && !fullVersion;
    if (trial && premiumTrialRemaining(before, game, nowUtc) > 0) {
      throw RuleException('La prueba gratuita se renueva cada 24 horas.');
    }
    return _commit(
      before.copyWith(
        wake: true,
        gameStartedUtc: [
          ...before.gameStartedUtc.where((t) => nowUtc - t < activityWindow),
          nowUtc,
        ],
        premiumTrialStartedUtc: trial
            ? {...before.premiumTrialStartedUtc, game.name: nowUtc}
            : before.premiumTrialStartedUtc,
      ),
      opId,
    );
  }

  /// Efecto, coste y plazo se confirman juntos, sin dobles cobros.
  Receipt finishCare(
    PetState s,
    CareKind kind,
    String opId,
    int nowUtc, {
    CareOption? option,
    bool fullVersion = false,
    String? groomingHair,
  }) {
    final rule = balance.care[kind.name];
    if (rule == null) throw RuleException('Cuidado desconocido: ${kind.name}');
    final before = clock.advance(s, nowUtc);
    final blocked = careBlocked(
      before,
      kind,
      nowUtc,
      option: option,
      fullVersion: fullVersion,
    );
    if (blocked != null) throw RuleException(blocked);
    final selected = _careOption(kind, option);
    final cost = kind == CareKind.vet ? vetCost : selected?.cost ?? 0;
    final appearance =
        kind == CareKind.groom &&
            groomingHair != null &&
            balance.item(groomingHair)?.slot == Slot.hair &&
            before.owned.contains(groomingHair)
        ? before.appearance.withSlot(Slot.hair, groomingHair)
        : before.appearance;
    final after = _commit(
      before.copyWith(
        appearance: appearance,
        coins: before.coins - cost,
        careCompletedUtc: {...before.careCompletedUtc, kind.name: nowUtc},
        needs100: _applyDelta(before, selected?.delta ?? rule.delta),
        cured: rule.cures,
        wake: true,
      ),
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

  /// Versión a la que pertenece un minijuego.
  Tier gameTier(GameId game) => switch (game) {
    GameId.fruit => balance.fruit.tier,
    GameId.frisbee => balance.frisbee.tier,
  };

  /// Artículos de [target] que no se poseen y exigen la versión completa.
  /// Lo ya poseído se puede usar siempre, aunque sea de la versión completa.
  List<String> lockedItems(
    PetState s,
    Appearance target, {
    required bool fullVersion,
  }) {
    if (fullVersion) return const [];
    return [
      for (final slot in Slot.values)
        if (!s.owned.contains(target.of(slot)) &&
            balance.item(target.of(slot))?.tier == Tier.full)
          target.of(slot),
    ];
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
  /// operación. Usar artículos en propiedad cuesta cero. Sin la versión
  /// completa, un artículo `full` no poseído rechaza toda la operación.
  PurchaseOutcome applyLook(
    PetState s,
    Appearance target,
    String opId,
    int nowUtc, {
    required bool fullVersion,
  }) {
    final cost = lookCost(s, target);
    final locked = lockedItems(s, target, fullVersion: fullVersion);
    if (locked.isNotEmpty) return RequiresFull(locked);
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

  /// Iconos que deben estar encendidos en el visor.
  Set<PetCondition> conditions(PetState s) {
    final st = balance.status;
    return {
      if (s.needPoints(Need.satiety) < st.hungryBelow) PetCondition.hungry,
      if (s.needPoints(Need.hygiene) < st.dirtyBelow) PetCondition.dirty,
      if (s.needPoints(Need.mood) < st.sadBelow) PetCondition.sad,
      if (s.needPoints(Need.energy) < st.tiredBelow) PetCondition.tired,
      if (s.needPoints(Need.hydration) < thirstyBelow) PetCondition.thirsty,
      if (s.isSick) PetCondition.sick,
    };
  }

  /// Lo más urgente que atender (enfermo primero), o null si está bien.
  PetCondition? mostUrgent(PetState s) {
    final c = conditions(s);
    if (c.contains(PetCondition.sick)) return PetCondition.sick;
    PetCondition? best;
    var bestValue = 1 << 30;
    for (final cond in PetCondition.values) {
      final need = cond.need;
      if (need == null) continue;
      if (c.contains(cond) && s.need100(need) < bestValue) {
        best = cond;
        bestValue = s.need100(need);
      }
    }
    return best;
  }

  /// Necesidad más baja a sugerir. Energía baja sugiere descansar.
  /// Empates entre saciedad/higiene/ánimo: comida, baño y juego.
  Need lowestNeed(PetState s) {
    var best = Need.satiety;
    for (final n in Need.values) {
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

/// Algún artículo exige la versión completa: no se compra nada.
class RequiresFull extends PurchaseOutcome {
  const RequiresFull(this.itemIds);
  final List<String> itemIds;
}
