import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/games/frisbee_sim.dart';

FrisbeeSim sim() => FrisbeeSim(targets: const [(0, 5), (-1.5, 6), (1.5, 4)]);

void run(FrisbeeSim s, double fps) {
  var g = 0;
  while (s.phase != FrisbeePhase.aim && !s.finished && g++ < 10000) {
    s.advance(1 / fps);
  }
}

void main() {
  test('el reloj cuenta al apuntar y cierra a los 20 segundos', () {
    final game = sim();
    game.advance(19.9);
    expect(game.canThrow, isTrue);
    expect(game.launchAssisted(), isTrue);
    game.advance(.2);
    expect(game.remaining, 0);
    expect(game.finished, isTrue);
    expect(game.launchAssisted(), isFalse);
    expect(game.catches, 0);
  });

  test('tres asistidos → 3 capturas a 30 y 60 fps', () {
    for (final fps in [30.0, 60.0]) {
      final s = sim();
      for (var i = 0; i < 3; i++) {
        expect(s.launchAssisted(), isTrue);
        expect(s.launchAssisted(), isFalse); // en vuelo no se lanza otra vez
        run(s, fps);
      }
      expect(s.finished, isTrue);
      expect([s.attempts, s.catches], [3, 3]);
    }
  });

  test('gesto corto no consume intento; fallos cuentan', () {
    expect(FrisbeeSim.aimFromDrag(0, 0.05), isNull);
    final s = sim();
    final far = FrisbeeSim.aimFromDrag(0.4, 0.6)!; // (3, 8)
    expect(far.x, 3);
    expect(far.depth, 8);
    s.launch(far);
    run(s, 60);
    expect([s.attempts, s.catches, s.lastCaught], [1, 0, false]);
  });

  test('la guía y el vuelo usan la misma función; aterriza en el destino', () {
    const dest = FieldPoint(1, 6);
    final (p, e) = FrisbeeSim.pointAt(dest, 1);
    expect([p.x, p.depth, e], [1, 6, 0]);
    final (_, peak) = FrisbeeSim.pointAt(dest, 0.5);
    expect(peak, closeTo(1.8, 1e-9));
  });

  test('tolerancia de captura ≤ 1 unidad', () {
    final s = sim();
    expect(s.wouldCatch(const FieldPoint(0, 6)), isTrue);
    expect(s.wouldCatch(const FieldPoint(0, 6.01)), isFalse);
  });
}
