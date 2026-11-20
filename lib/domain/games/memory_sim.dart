enum MemoryPhase { showing, input, feedback, finished }

/// Simón: prefijos de una secuencia aleatoria de diez señales. Hay diez
/// segundos para el turno completo de respuesta; la muestra no consume tiempo.
class MemorySim {
  MemorySim(List<int> sequence) : sequence = List.unmodifiable(sequence) {
    if (sequence.length != 10 || sequence.any((n) => n < 0 || n > 3)) {
      throw ArgumentError('Secuencia inválida');
    }
  }
  final List<int> sequence;
  MemoryPhase phase = MemoryPhase.showing;
  int length = 3;
  int completed = 0;
  int inputIndex = 0;
  int _showIndex = -1;
  int? lit;
  double remaining = 10;
  double _phaseTime = .55;
  bool _gap = true;
  double _inputFlash = 0;
  bool get finished => phase == MemoryPhase.finished;
  bool get won => completed == 10;
  int get coins => completed < 3 ? 0 : (completed - 2) * 5;

  /// Devuelve true solo si la señal pertenece al turno de respuesta.
  bool press(int signal) {
    if (phase != MemoryPhase.input || signal < 0 || signal > 3) return false;
    lit = signal;
    _inputFlash = .2;
    if (sequence[inputIndex] != signal) {
      phase = MemoryPhase.finished;
      return true;
    }
    inputIndex++;
    if (inputIndex == length) {
      completed = length;
      if (length == 10) {
        phase = MemoryPhase.finished;
      } else {
        phase = MemoryPhase.feedback;
        _phaseTime = .8;
      }
    }
    return true;
  }

  /// Cada transición encendida emite una nota; el espaciado distingue
  /// señales iguales consecutivas y no admite respuestas antes de tiempo.
  void update(double dt, {void Function(int)? onSignal}) {
    if (finished || dt <= 0 || !dt.isFinite) return;
    if (phase == MemoryPhase.input) {
      _inputFlash -= dt;
      if (_inputFlash <= 0) lit = null;
      remaining = (remaining - dt).clamp(0, 10);
      if (remaining == 0) phase = MemoryPhase.finished;
      return;
    }
    _phaseTime -= dt;
    while (_phaseTime <= 0 && phase != MemoryPhase.input && !finished) {
      if (phase == MemoryPhase.feedback) {
        length++;
        inputIndex = 0;
        _showIndex = -1;
        _gap = true;
        lit = null;
        phase = MemoryPhase.showing;
        _phaseTime += .55;
      } else if (_gap) {
        _showIndex++;
        if (_showIndex == length) {
          lit = null;
          phase = MemoryPhase.input;
          inputIndex = 0;
          remaining = 10;
        } else {
          lit = sequence[_showIndex];
          onSignal?.call(lit!);
          _gap = false;
          _phaseTime += .6;
        }
      } else {
        lit = null;
        _gap = true;
        _phaseTime += .25;
      }
    }
    // Un salto de fotograma no regala tiempo extra al entrar en respuesta.
    if (phase == MemoryPhase.input && _phaseTime < 0) {
      remaining = (remaining + _phaseTime).clamp(0, 10);
      if (remaining == 0) phase = MemoryPhase.finished;
    }
  }
}
