/// Simulación del Frisbee en el prado. Coordenadas lógicas de campo
/// (x lateral ±3, profundidad 2..8); lanzador en (0,0). Dart puro: la guía,
/// el vuelo y la captura usan la misma función [pointAt].
library;

import 'dart:math' as math;

class FieldPoint {
  const FieldPoint(this.x, this.depth);
  final double x;
  final double depth;
  double distanceTo(FieldPoint o) =>
      math.sqrt((x - o.x) * (x - o.x) + (depth - o.depth) * (depth - o.depth));
  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${depth.toStringAsFixed(2)})';
}

enum FrisbeePhase { aim, flight, catchAnim, returning, finished }

class FrisbeeSim {
  FrisbeeSim({
    required List<(double, double)> targets,
    this.flightSeconds = 1.1,
    this.catchRadius = 1,
  }) : targets = [for (final t in targets) FieldPoint(t.$1, t.$2)];

  static const FieldPoint origin = FieldPoint(0, 0);
  static const double minDrag = 0.08;
  static const double fullDrag = 0.6;
  static const double maxX = 3;
  static const double minDepth = 2;
  static const double maxDepth = 8;
  static const double peak = 1.8;
  static const double catchSeconds = 0.6;
  static const double returnSeconds = 0.7;

  final List<FieldPoint> targets;
  final double flightSeconds;
  final double catchRadius;

  FrisbeePhase phase = FrisbeePhase.aim;
  int attempts = 0;
  int catches = 0;
  double _t = 0; // tiempo en la fase actual
  FieldPoint? destination;
  bool? lastCaught;
  final List<bool> history = [];

  int get throws => targets.length;
  FieldPoint get currentTarget => targets[attempts.clamp(0, throws - 1)];
  bool get canThrow => phase == FrisbeePhase.aim;
  bool get finished => phase == FrisbeePhase.finished;
  double get flightProgress => phase == FrisbeePhase.flight
      ? (_t / flightSeconds).clamp(0, 1).toDouble()
      : 0;
  double get phaseTime => _t;

  /// Arrastre normalizado (dx a la derecha, dy hacia arriba, fracciones de
  /// ancho/alto). Devuelve null si es demasiado corto: vuelve a apuntar.
  static FieldPoint? aimFromDrag(double dx, double dyUp) {
    if (dyUp < minDrag) return null;
    final power = ((dyUp - minDrag) / (fullDrag - minDrag)).clamp(0.0, 1.0);
    final depth = minDepth + power * (maxDepth - minDepth);
    final x = (dx / 0.4 * maxX).clamp(-maxX, maxX).toDouble();
    return FieldPoint(x, depth);
  }

  /// Punto de campo y elevación en t∈[0,1] del vuelo hacia [dest].
  static (FieldPoint, double) pointAt(FieldPoint dest, double t) {
    final p = FieldPoint(
      origin.x + (dest.x - origin.x) * t,
      origin.depth + (dest.depth - origin.depth) * t,
    );
    final elevation = 4 * peak * t * (1 - t);
    return (p, elevation);
  }

  bool wouldCatch(FieldPoint dest) =>
      dest.distanceTo(currentTarget) <= catchRadius;

  /// Lanza hacia [dest]. Consume un intento. Ignorado fuera de Apuntar.
  bool launch(FieldPoint dest) {
    if (!canThrow) return false;
    destination = dest;
    phase = FrisbeePhase.flight;
    _t = 0;
    return true;
  }

  /// Lanzamiento asistido: dirección y potencia centradas en el aro.
  bool launchAssisted() => launch(currentTarget);

  void advance(double seconds) {
    if (finished || phase == FrisbeePhase.aim) return;
    _t += seconds;
    switch (phase) {
      case FrisbeePhase.flight:
        if (_t >= flightSeconds) {
          final caught = wouldCatch(destination!);
          lastCaught = caught;
          history.add(caught);
          if (caught) catches++;
          attempts++;
          phase = FrisbeePhase.catchAnim;
          _t = 0;
        }
      case FrisbeePhase.catchAnim:
        if (_t >= catchSeconds) {
          phase = FrisbeePhase.returning;
          _t = 0;
        }
      case FrisbeePhase.returning:
        if (_t >= returnSeconds) {
          _t = 0;
          destination = null;
          phase = attempts >= throws ? FrisbeePhase.finished : FrisbeePhase.aim;
        }
      case FrisbeePhase.aim:
      case FrisbeePhase.finished:
        break;
    }
  }
}
