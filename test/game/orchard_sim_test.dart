import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/games/orchard_sim.dart';

// Entradas de un recorrido completo, registradas cada 1/30 s. El paso
// interno se mantiene en 1/120 s con independencia del refresco.
const routeJumps = [
  2.5191,
  4.7131,
  6.9880,
  9.3467,
  12.5076,
  15.0698,
  18.2435,
  21.0172,
  23.7537,
  27.0197,
  30.1168,
  35.2161,
  40.9509,
  44.3867,
  47.9430,
  52.1872,
  56.6031,
  61.1975,
  65.5546,
  69.8534,
  74.5295,
  79.3780,
  84.6491,
  89.8706,
  95.0223,
  100.6262,
  106.4367,
  112.4613,
];

OrchardSim play(int fps, {bool pilot = true}) {
  final s = OrchardSim();
  var nextJump = 0;
  for (var frame = 0; !s.finished && frame <= 60 * fps; frame++) {
    if (pilot &&
        frame % (fps ~/ 30) == 0 &&
        nextJump < routeJumps.length &&
        s.x >= routeJumps[nextJump]) {
      s.jump();
      nextJump++;
    }
    s.advance(1 / fps);
  }
  return s;
}

void main() {
  test(
    'A03 el piloto llega a la meta y recoge las 24 frutas de seis tipos',
    () {
      final s = play(60);
      expect(s.end, OrchardEnd.goal);
      expect(s.score, 24);
      expect(s.pace, 3 * OrchardSim.speed);
      expect(s.level.goalX - s.level.startX, 116);
      expect(s.falls, 0);
      expect(s.collisions, 0);
      expect(s.time, lessThan(60));
      expect({
        for (final fruit in s.level.apples) fruit.kind,
      }, FruitKind.values.toSet());
    },
  );

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
    expect(s.score, lessThan(24));
    expect(s.remaining, 0);
    expect(s.time, 60);
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

  test(
    'valla: resta cinco segundos una vez y conserva el progreso de velocidad',
    () {
      const level = OrchardLevel(
        platforms: [Platform(0, 20, 0)],
        apples: [],
        barriers: [OrchardBarrier(5, 0, .24, .48, BarrierKind.fence)],
        goalX: 18,
        startX: 1,
      );
      final s = OrchardSim(level: level);
      while (s.collisions == 0) {
        expect(s.finished, isFalse);
        final time = s.time, before = s.pace;
        s.advance(OrchardSim.dt);
        if (s.collisions == 1) {
          expect(s.time - time, closeTo(5 + OrchardSim.dt, 1e-6));
          expect(before, greaterThan(OrchardSim.speed));
          expect(s.pace, greaterThanOrEqualTo(before));
        }
      }
      while (!s.finished) {
        s.advance(1 / 60);
      }
      expect(s.collisions, 1);
      expect(s.end, OrchardEnd.goal);
      expect(s.pace, greaterThan(OrchardSim.speed));
    },
  );

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
