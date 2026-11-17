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

  test('baño: repetir pata solo marca una zona; aclarar tras tres zonas', () {
    final b = BathActivity();
    expect(b.soap(BathZone.paws), isFalse); // primero mojar
    expect(b.rinse(), isFalse);
    b.wet();
    expect(b.soap(BathZone.paws), isTrue);
    expect(b.soap(BathZone.paws), isFalse);
    expect(b.zonesDone, 1);
    expect(b.rinse(), isFalse);
    b.soap(BathZone.back, 0.5);
    b.soap(BathZone.back, 0.5);
    b.soap(BathZone.chest);
    expect(b.phase, BathPhase.rinse);
    expect(b.rinse(), isTrue);
    expect(b.completed, isTrue);
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

  test('peluquería: mechón resuelto no vuelve a contar', () {
    final g = GroomActivity();
    g.brush(Strand.ears, 1);
    expect(g.brush(Strand.ears, 1), isFalse);
    expect(g.done, 1);
    g.brush(Strand.back, 1);
    g.brush(Strand.forelock, 0.5);
    expect(g.completed, isFalse);
    g.brush(Strand.forelock, 0.5);
    expect(g.completed, isTrue);
  });
}
