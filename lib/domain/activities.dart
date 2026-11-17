/// Máquinas de pasos de los cuidados. Dart puro: la escena Flame las
/// representa y los widgets emiten intenciones; aquí se decide qué cuenta.
library;

abstract class StepActivity {
  int get done;
  int get total;
  bool get completed;
  double get progress => total == 0 ? 0 : done / total;
}

/// Cocina: tres bocados. Un toque mientras mastica no cuenta.
class FeedActivity extends StepActivity {
  int _bites = 0;
  bool _chewing = false;

  bool get chewing => _chewing;
  @override
  int get done => _bites;
  @override
  int get total => 3;
  @override
  bool get completed => _bites == total && !_chewing;
  bool get canBite => !_chewing && _bites < total;

  /// Comida restante en el cuenco (1, 2/3, 1/3, 0).
  double get bowlFill => 1 - _bites / total;

  bool bite() {
    if (!canBite) return false;
    _bites++;
    _chewing = true;
    return true;
  }

  void chewDone() => _chewing = false;
}

enum BathPhase { wet, soap, rinse, done }

enum BathZone { back, paws, chest }

/// Baño: mojar, enjabonar tres zonas distintas y aclarar.
class BathActivity extends StepActivity {
  BathPhase _phase = BathPhase.wet;
  final Map<BathZone, double> _foam = {for (final z in BathZone.values) z: 0};

  BathPhase get phase => _phase;
  double foam(BathZone z) => _foam[z]!;
  bool zoneDone(BathZone z) => _foam[z]! >= 1;
  int get zonesDone => BathZone.values.where(zoneDone).length;

  @override
  int get done => switch (_phase) {
    BathPhase.wet => 0,
    BathPhase.soap => 1 + zonesDone,
    BathPhase.rinse => 4,
    BathPhase.done => 5,
  };
  @override
  int get total => 5;
  @override
  bool get completed => _phase == BathPhase.done;

  bool wet() {
    if (_phase != BathPhase.wet) return false;
    _phase = BathPhase.soap;
    return true;
  }

  /// Toque (amount 1) o pasada de esponja (fracción). Repetir una zona ya
  /// enjabonada no cuenta otra vez.
  bool soap(BathZone z, [double amount = 1]) {
    if (_phase != BathPhase.soap || zoneDone(z)) return false;
    _foam[z] = (_foam[z]! + amount).clamp(0, 1).toDouble();
    if (zonesDone == BathZone.values.length) _phase = BathPhase.rinse;
    return true;
  }

  bool rinse() {
    if (_phase != BathPhase.rinse) return false;
    _phase = BathPhase.done;
    for (final z in BathZone.values) {
      _foam[z] = 0;
    }
    return true;
  }
}

enum WalkPhase { waiting, moving, sniffing }

/// Paseo: tres paradas en orden; olfatear antes de habilitar la siguiente.
class WalkActivity extends StepActivity {
  int _reached = 0;
  WalkPhase _phase = WalkPhase.waiting;

  WalkPhase get phase => _phase;

  /// Índice de la parada habilitada (0..2) o null si no se puede tocar.
  int? get enabledStop =>
      _phase == WalkPhase.waiting && _reached < total ? _reached : null;
  @override
  int get done => _reached;
  @override
  int get total => 3;
  @override
  bool get completed => _reached == total && _phase == WalkPhase.waiting;

  bool tapStop(int index) {
    if (enabledStop != index) return false;
    _phase = WalkPhase.moving;
    return true;
  }

  void arrived() {
    if (_phase == WalkPhase.moving) _phase = WalkPhase.sniffing;
  }

  void sniffDone() {
    if (_phase != WalkPhase.sniffing) return;
    _reached++;
    _phase = WalkPhase.waiting;
  }
}

enum Strand { forelock, ears, back }

/// Peluquería: tres mechones; un mechón resuelto no vuelve a contar.
class GroomActivity extends StepActivity {
  final Map<Strand, double> _brushed = {for (final s in Strand.values) s: 0};

  double brushed(Strand s) => _brushed[s]!;
  bool strandDone(Strand s) => _brushed[s]! >= 1;
  @override
  int get done => Strand.values.where(strandDone).length;
  @override
  int get total => 3;
  @override
  bool get completed => done == total;

  bool brush(Strand s, [double amount = 0.5]) {
    if (strandDone(s)) return false;
    _brushed[s] = (_brushed[s]! + amount).clamp(0, 1).toDouble();
    return true;
  }
}

enum SleepPhase { toBed, blanket, lights, sleeping, done }

/// Dormir: llevarlo a su cama, arroparlo, apagar la luz y esperar a que
/// se duerma (el tiempo de sueño lo cuenta la escena con tiempo de juego).
class SleepActivity extends StepActivity {
  SleepPhase _phase = SleepPhase.toBed;

  SleepPhase get phase => _phase;
  @override
  int get done => switch (_phase) {
    SleepPhase.toBed => 0,
    SleepPhase.blanket => 1,
    SleepPhase.lights => 2,
    SleepPhase.sleeping => 3,
    SleepPhase.done => 3,
  };
  @override
  int get total => 3;
  @override
  bool get completed => _phase == SleepPhase.done;

  /// Avanza un paso si [from] es la fase actual; repetir un toque no cuenta.
  bool advance(SleepPhase from) {
    if (_phase != from) return false;
    _phase = SleepPhase.values[_phase.index + 1];
    return true;
  }

  /// La escena avisa cuando termina el sueño.
  bool wake() => advance(SleepPhase.sleeping);
}

enum VetPhase { heart, paws, pill, done }

/// Veterinario: escuchar el corazón, revisar las patas y, si está malito,
/// darle la pastilla. Sano, la consulta es una revisión de dos pasos.
class VetActivity extends StepActivity {
  VetActivity({required this.sick});
  final bool sick;
  VetPhase _phase = VetPhase.heart;

  VetPhase get phase => _phase;
  @override
  int get total => sick ? 3 : 2;
  @override
  int get done => switch (_phase) {
    VetPhase.heart => 0,
    VetPhase.paws => 1,
    VetPhase.pill => 2,
    VetPhase.done => total,
  };
  @override
  bool get completed => _phase == VetPhase.done;

  bool listen() => _step(VetPhase.heart, VetPhase.paws);

  bool checkPaws() =>
      _step(VetPhase.paws, sick ? VetPhase.pill : VetPhase.done);

  bool givePill() => sick && _step(VetPhase.pill, VetPhase.done);

  bool _step(VetPhase from, VetPhase to) {
    if (_phase != from) return false;
    _phase = to;
    return true;
  }
}
