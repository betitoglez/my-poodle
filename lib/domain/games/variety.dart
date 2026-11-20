/// Variedad determinista de cada partida. La misma partida (semilla propia) y
/// el mismo identificador de sesión producen siempre la misma disposición,
/// igual en móvil y web. Dart puro: sin Flutter ni Flame.
library;

import 'orchard_sim.dart';

/// Semilla de una partida a partir de la semilla de la mascota y la sesión.
/// FNV-1a de 31 bits: estable entre plataformas y ejecuciones.
int runSeed(int petSeed, String session) {
  var h = 0x811c9dc5 ^ (petSeed & 0x7fffffff);
  for (final unit in session.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// Generador congruencial pequeño y reproducible (no criptográfico).
class SeededRandom {
  SeededRandom(int seed) : _state = (seed & 0x7fffffff) | 1;
  int _state;

  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max');
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state >> 8) % max;
  }

  /// Fisher–Yates sobre una copia.
  List<T> shuffled<T>(List<T> items) {
    final out = List<T>.of(items);
    for (var i = out.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = out[i];
      out[i] = out[j];
      out[j] = t;
    }
    return out;
  }
}

/// Objetivos del Frisbee para una partida: el primero es siempre el de
/// calentamiento de [base]; el resto se toma, sin repetir, de [pool].
/// Si la reserva no alcanza, se usan los objetivos fijos de [base].
List<(double, double)> frisbeeTargetsFor(
  int seed,
  List<(double, double)> base,
  List<(double, double)> pool,
) {
  final throws = base.length;
  if (throws == 0) return const [];
  final candidates = [
    for (final p in pool)
      if (p != base.first) p,
  ];
  if (candidates.length < throws - 1) return List.unmodifiable(base);
  final picked = SeededRandom(seed).shuffled(candidates).take(throws - 1);
  return List.unmodifiable([base.first, ...picked]);
}

/// Frutas doradas del Huerto: una por cada pareja de tramos (t1–t2, t3–t4,
/// t5–t6). Las frutas siguen sumando igual; las doradas solo cuentan para
/// la tercera estrella.
Set<String> goldenFruitsFor(int seed, OrchardLevel level, {int count = 3}) {
  final rng = SeededRandom(seed);
  final out = <String>{};
  for (var group = 0; group < count; group++) {
    final first = group * 2 + 1;
    final options = [
      for (final a in level.apples)
        if (a.id.startsWith('t$first-') || a.id.startsWith('t${first + 1}-'))
          a.id,
    ];
    if (options.isEmpty) continue;
    out.add(options[rng.nextInt(options.length)]);
  }
  return Set.unmodifiable(out);
}
