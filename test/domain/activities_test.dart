import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/activities.dart';

void main() {
  test('comida: toques durante la masticación no acumulan', () {
    final a = FeedActivity();
    expect(a.bite(), isTrue);
    expect(a.bite(), isFalse);
    a.chewDone();
    expect(a.bite(), isTrue);
    a.chewDone();
    expect(a.bite(), isTrue);
    expect(a.completed, isFalse); // aún mastica
    a.chewDone();
    expect(a.completed, isTrue);
    expect(a.bite(), isFalse);
  });

  test('baño: cinco segundos activos por herramienta y todas las zonas', () {
    final b = BathActivity();
    expect(b.soap(BathZone.paws), isFalse);
    b.wet(4.9);
    expect(b.phase, BathPhase.wet);
    b.wet(0.1);
    for (final z in BathZone.values) {
      b.soap(z, 1);
      expect(b.soap(z, 1), isFalse);
    }
    expect(b.phase, BathPhase.rinse);
    b.rinse(5);
    expect(b.phase, BathPhase.dry);
    expect(b.completed, isFalse);
    b.dry(4.9);
    expect(b.completed, isFalse);
    b.dry(0.1);
    expect(b.completed, isTrue);
    expect(b.done, b.total);
  });

  test('paseo: fuera de orden no avanza; olfatear antes de la siguiente', () {
    final w = WalkActivity();
    expect(w.tapStop(1), isFalse);
    expect(w.tapStop(0), isTrue);
    expect(w.tapStop(1), isFalse); // en movimiento
    w.arrived();
    expect(w.tapStop(1), isFalse); // olfateando
    w.sniffDone();
    for (final i in [1, 2]) {
      expect(w.tapStop(i), isTrue);
      w.arrived();
      w.sniffDone();
    }
    expect(w.completed, isTrue);
  });

  test(
    'peluquería: peine, tijeras y secador requieren tres mechones cada uno',
    () {
      final g = GroomActivity();
      for (final tool in GroomTool.values) {
        expect(g.tool, tool);
        g.brush(Strand.ears, 1);
        expect(g.brush(Strand.ears, 1), isFalse);
        g.brush(Strand.back, 1);
        expect(g.completed, isFalse);
        g.brush(Strand.forelock, 1);
      }
      expect(g.completed, isTrue);
      expect(g.done, 9);
      expect(g.brush(Strand.forelock), isFalse);
    },
  );
}
