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

  test('baño: mojar, aclarar y secar afectan primero a la zona apuntada', () {
    final bath = BathActivity();
    bath.wet(.625, BathZone.chest);
    expect(bath.wetness(BathZone.chest), .5);
    expect(bath.wetness(BathZone.head), 0);
    expect(bath.toolZone(BathZone.chest), BathZone.chest);
    bath.wet(.625, BathZone.chest);
    expect(bath.toolZone(BathZone.chest), BathZone.head);
    bath.wet(3.75);
    for (final zone in BathZone.values) {
      bath.soap(zone, 1);
      expect(bath.wetness(zone), 1);
    }
    bath.rinse(1.25, BathZone.paws);
    expect(bath.visibleFoam(BathZone.paws), 0);
    expect(bath.visibleFoam(BathZone.back), 1);
    bath.rinse(3.75);
    bath.dry(.625, BathZone.head);
    expect(bath.wetness(BathZone.head), .5);
    expect(bath.wetness(BathZone.back), 1);
    bath.dry(4.375);
    expect(bath.completed, isTrue);
    expect(BathZone.values.map(bath.wetness), everyElement(0));
  });

  test('paseo: fuera de orden no avanza; olfatear antes de la siguiente', () {
    final w = WalkActivity();
    expect(w.tapStop(1), isFalse);
    expect(w.tapStop(0), isTrue);
    expect(w.tapStop(1), isFalse); // en movimiento
    expect(w.beginSniff(), isFalse);
    w.arrived();
    w.sniffDone();
    expect(w.done, 0);
    expect(w.tapStop(1), isFalse); // espera que el jugador le indique olfatear
    expect(w.beginSniff(), isTrue);
    expect(w.beginSniff(), isFalse);
    expect(w.tapStop(1), isFalse); // olfateando
    w.sniffDone();
    for (final i in [1, 2]) {
      expect(w.tapStop(i), isTrue);
      w.arrived();
      expect(w.beginSniff(), isTrue);
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
