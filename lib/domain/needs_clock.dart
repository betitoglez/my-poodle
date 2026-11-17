import 'balance.dart';
import 'pet_state.dart';

/// Reloj inyectable: segundos UTC de pared.
abstract class Clock {
  int nowUtcSeconds();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  int nowUtcSeconds() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
}

class FakeClock implements Clock {
  FakeClock(this.now);
  int now;
  void advance(int seconds) => now += seconds;
  @override
  int nowUtcSeconds() => now;
}

/// Paso del tiempo por bloques completos de 15 minutos.
class NeedsClock {
  const NeedsClock(this.balance);
  final Balance balance;

  /// Devuelve una copia con necesidades, salud y cursor actualizados (misma
  /// revisión). Máximo [Balance.maxTicks] bloques por ausencia; el cursor
  /// avanza hasta el último bloque completo y descarta el exceso. Si el reloj
  /// retrocede no se aplica nada ni se mueve el cursor.
  PetState advance(PetState s, int nowUtc) {
    final elapsed = nowUtc - s.needsCursorUtc;
    if (elapsed < balance.tickSeconds) return s;
    final ticks = elapsed ~/ balance.tickSeconds;
    final applied = ticks > balance.maxTicks ? balance.maxTicks : ticks;
    final needs = Map<Need, int>.of(s.needs100);
    var sickSince = s.sickSinceUtc;
    var lastSick = s.lastSickUtc;
    for (var i = 1; i <= applied; i++) {
      final tickTime = s.needsCursorUtc + i * balance.tickSeconds;
      for (final n in Need.values) {
        var d = balance.deltaPerTick100[n] ?? 0;
        if (n == Need.mood && sickSince != null) {
          d += balance.health.sickMoodPerTick100;
        }
        needs[n] = clampNeed((needs[n] ?? 0) + d);
      }
      if (sickSince == null &&
          tickTime - lastSick >= balance.health.cooldownSeconds) {
        if (_rollSick(s.sickSeed, tickTime, needs)) {
          sickSince = tickTime;
          lastSick = tickTime;
        }
      }
    }
    return s.copyWith(
      needs100: needs,
      needsCursorUtc: s.needsCursorUtc + ticks * balance.tickSeconds,
      sickSinceUtc: sickSince,
      lastSickUtc: lastSick,
    );
  }

  /// Tirada determinista (misma partida y mismo instante, mismo resultado):
  /// azar de fondo más un riesgo mayor si está hambriento, sucio o agotado.
  bool _rollSick(int seed, int tickTime, Map<Need, int> needs) {
    final h = balance.health;
    final neglected =
        (needs[Need.satiety] ?? 0) < h.neglectSatietyBelow * 100 ||
        (needs[Need.hygiene] ?? 0) < h.neglectHygieneBelow * 100 ||
        (needs[Need.energy] ?? 0) < h.neglectEnergyBelow * 100;
    final chance = h.randomChance + (neglected ? h.neglectChance : 0);
    return rollPer10000(seed, tickTime) < chance;
  }

  /// Número pseudoaleatorio 0..9999 sin estado. Los productos se mantienen
  /// por debajo de 2^53 para que dé lo mismo en móvil y en web.
  static int rollPer10000(int seed, int t) {
    var x = (seed + t * 40503) & 0x7fffffff;
    x = ((x ^ (x >> 15)) * 73244) & 0x7fffffff;
    x = ((x ^ (x >> 13)) * 65599) & 0x7fffffff;
    x = x ^ (x >> 16);
    return x % 10000;
  }
}
