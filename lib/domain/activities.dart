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

enum BathPhase { wet, soap, rinse, dry, done }

enum BathZone { back, paws, chest, head }

/// Cinco segundos de ducha y aclarado; frotar todo el cuerpo y secar.
class BathActivity extends StepActivity {
  BathPhase _phase = BathPhase.wet;
  final Map<BathZone, double> _foam = {for (final z in BathZone.values) z: 0};
  double _seconds = 0;
  BathPhase get phase => _phase;
  double get toolProgress => (_seconds / 5).clamp(0, 1);
  double foam(BathZone z) => _foam[z]!;
  bool zoneDone(BathZone z) => _foam[z]! >= 1;
  int get zonesDone => BathZone.values.where(zoneDone).length;
  @override
  int get done => switch (_phase) {
    BathPhase.wet => 0,
    BathPhase.soap => 1 + zonesDone,
    BathPhase.rinse => 5,
    BathPhase.dry => 6,
    BathPhase.done => 7,
  };
  @override
  int get total => 7;
  @override
  bool get completed => _phase == BathPhase.done;
  bool _hold(BathPhase from, BathPhase to, double seconds) {
    if (_phase != from || !seconds.isFinite || seconds <= 0) return false;
    _seconds = (_seconds + seconds).clamp(0, 5);
    if (_seconds >= 5 - 1e-6) {
      _phase = to;
      _seconds = 0;
      if (from == BathPhase.rinse) {
        for (final z in BathZone.values) {
          _foam[z] = 0;
        }
      }
    }
    return true;
  }

  bool wet([double seconds = 0.1]) =>
      _hold(BathPhase.wet, BathPhase.soap, seconds);
  bool rinse([double seconds = 0.1]) =>
      _hold(BathPhase.rinse, BathPhase.dry, seconds);
  bool dry([double seconds = 0.1]) =>
      _hold(BathPhase.dry, BathPhase.done, seconds);
  bool soap(BathZone z, [double amount = 0.15]) {
    if (_phase != BathPhase.soap ||
        zoneDone(z) ||
        !amount.isFinite ||
        amount <= 0) {
      return false;
    }
    _foam[z] = (_foam[z]! + amount).clamp(0, 1).toDouble();
    if (zonesDone == BathZone.values.length) _phase = BathPhase.rinse;
    return true;
  }
}

enum WalkPhase { waiting, moving, atStop, sniffing }

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
    if (_phase == WalkPhase.moving) _phase = WalkPhase.atStop;
  }

  bool beginSniff() {
    if (_phase != WalkPhase.atStop) return false;
    _phase = WalkPhase.sniffing;
    return true;
  }

  void sniffDone() {
    if (_phase != WalkPhase.sniffing) return;
    _reached++;
    _phase = WalkPhase.waiting;
  }
}

enum Strand { forelock, ears, back }

/// Peluquería: tres mechones; un mechón resuelto no vuelve a contar.
enum GroomTool { comb, scissors, dryer }

class GroomActivity extends StepActivity {
  GroomTool _tool = GroomTool.comb;
  final Map<GroomTool, Map<Strand, double>> _progress = {
    for (final t in GroomTool.values) t: {for (final s in Strand.values) s: 0},
  };
  GroomTool get tool => _tool;
  double strandProgress(GroomTool tool, Strand strand) =>
      _progress[tool]![strand]!;
  double brushed(Strand s) => strandProgress(_tool, s);
  bool strandDone(Strand s) => brushed(s) >= 1;
  @override
  int get done => _progress.values.fold(
    0,
    (n, m) => n + m.values.where((v) => v >= 1).length,
  );
  @override
  int get total => 9;
  @override
  bool get completed => done == total;
  bool brush(Strand s, [double amount = 0.15]) {
    if (completed || strandDone(s) || !amount.isFinite || amount <= 0) {
      return false;
    }
    _progress[_tool]![s] = (brushed(s) + amount).clamp(0, 1);
    if (Strand.values.every(strandDone) && _tool != GroomTool.dryer) {
      _tool = GroomTool.values[_tool.index + 1];
    }
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
