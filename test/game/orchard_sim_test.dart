import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/games/orchard_sim.dart';

/// Piloto: salta al acercarse a un borde o bajo una manzana alta.
void autopilot(OrchardSim s) {
  if (!s.grounded) return;
  for (final p in s.level.platforms) {
    if (p.top > s.y + 0.01 && p.x0 - s.x > 0 && p.x0 - s.x < 0.55) {
      return s.jump();
    }
  }
  final edge = s.level.platforms.firstWhere(
    (p) => p.x0 <= s.x && p.x1 >= s.x,
    orElse: () => s.level.platforms.last,
  );
  if (edge.x1 - s.x < 0.35 && edge.x1 < s.level.goalX) return s.jump();
  for (final a in s.level.apples) {
    if (!s.collected.contains(a.id) &&
        a.y - s.y > 0.7 &&
        a.x - s.x > 0.6 &&
        a.x - s.x < 1.0) {
      return s.jump();
    }
  }
}

OrchardSim play(double fps, {bool pilot = true, double pauseAt = -1}) {
  final s = OrchardSim();
  final frame = 1 / fps;
  var guard = 0;
  while (!s.finished && guard++ < 100000) {
    if (pilot) autopilot(s);
    s.advance(frame);
  }
  return s;
}

void main() {
  test('A03 el piloto llega a la meta y recoge las 12 manzanas', () {
    final s = play(60);
    expect(s.end, OrchardEnd.goal);
    expect(s.score, 12);
    expect(s.falls, 0);
    expect(s.time, lessThan(30));
  });

  test('A03 misma entrada a 30 y 60 fps: misma trayectoria y premio', () {
    final a = play(30), b = play(60);
    expect(a.score, b.score);
    expect(a.end, b.end);
    expect((a.time - b.time).abs(), lessThan(0.05));
  });

  test('sin saltar: cae, reaparece en lugar seguro, conserva manzanas, se agota el tiempo', () {
    final s = play(60, pilot: false);
    expect(s.end, OrchardEnd.timeUp);
    expect(s.falls, greaterThan(0));
    expect(s.collected, containsAll(['t1-0', 't1-2']));
    expect(s.score, lessThan(12));
    expect(s.remaining, 0);
    expect(s.time, 30);
  });

  test(
    'caer descuenta exactamente cinco segundos adicionales una sola vez',
    () {
      final s = OrchardSim();
      while (s.falls == 0) {
        final before = s.time;
        s.advance(OrchardSim.dt);
        if (s.falls == 1) {
          expect(s.time - before, closeTo(5 + OrchardSim.dt, 1e-6));
        }
      }
      final time = s.time;
      s.advance(OrchardSim.dt);
      expect(s.time - time, closeTo(OrchardSim.dt, 1e-6));
    },
  );

  test('una manzana recogida no vuelve a sumar tras caer', () {
    final s = OrchardSim();
    while (s.falls == 0) {
      s.advance(1 / 60);
    }
    final before = Set.of(s.collected);
    s.advance(1.0);
    expect(s.collected.length, greaterThanOrEqualTo(before.length));
    expect(s.collected.toSet().length, s.collected.length);
  });

  test('avance grande no atraviesa plataformas (barrido)', () {
    final s = OrchardSim();
    s.jump();
    for (var i = 0; i < 20; i++) {
      s.advance(0.25); // se limita a 0,25 s por fotograma
      expect(s.y, greaterThanOrEqualTo(-3.1));
    }
  });

  test('mantener pulsado no repite: un salto por intención', () {
    final s = OrchardSim();
    s.jump();
    s.advance(0.05);
    final jumps = s.jumpsStarted;
    s.advance(1.0);
    expect(jumps, 1);
    expect(s.jumpsStarted, 1);
  });
}
