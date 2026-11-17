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

  /// Devuelve una copia con necesidades y cursor actualizados (misma
  /// revisión). Máximo [Balance.maxTicks] bloques por ausencia; el cursor
  /// avanza hasta el último bloque completo y descarta el exceso. Si el reloj
  /// retrocede no se aplica nada ni se mueve el cursor.
  PetState advance(PetState s, int nowUtc) {
    final elapsed = nowUtc - s.needsCursorUtc;
    if (elapsed < balance.tickSeconds) return s;
    final ticks = elapsed ~/ balance.tickSeconds;
    final applied = ticks > balance.maxTicks ? balance.maxTicks : ticks;
    final needs = <Need, int>{};
    for (final n in Need.values) {
      final delta = (balance.deltaPerTick100[n] ?? 0) * applied;
      needs[n] = clampNeed(s.need100(n) + delta);
    }
    return s.copyWith(
      needs100: needs,
      needsCursorUtc: s.needsCursorUtc + ticks * balance.tickSeconds,
    );
  }
}
