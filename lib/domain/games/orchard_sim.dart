/// Simulación del Huerto saltarín. Coordenadas X derecha / Y arriba, en
/// unidades de juego. Paso fijo de 1/120 s con acumulador; Dart puro para que
/// la misma entrada produzca el mismo resultado a 30 o 60 fps.
library;

class Platform {
  const Platform(this.x0, this.x1, this.top);
  final double x0;
  final double x1;
  final double top;
}

class Apple {
  const Apple(this.id, this.x, this.y);
  final String id; // tramo/índice
  final double x;
  final double y;
}

class OrchardLevel {
  const OrchardLevel({
    required this.platforms,
    required this.apples,
    required this.goalX,
    required this.startX,
  });

  final List<Platform> platforms;
  final List<Apple> apples;
  final double goalX;
  final double startX;

  /// Tres tramos manuales de 20 unidades con cuatro manzanas cada uno:
  /// suelo continuo, dos bancales y plataformas con meta.
  static const OrchardLevel v1 = OrchardLevel(
    startX: 1,
    goalX: 59,
    platforms: [
      // Tramo 1: suelo continuo.
      Platform(-4, 21, 0),
      // Tramo 2: dos bancales (+0.35) separados por huecos de 0.7–1.0.
      Platform(21.8, 26, 0.35),
      Platform(26.9, 30, 0),
      Platform(30.7, 35, 0.35),
      Platform(36, 41, 0),
      // Tramo 3: plataformas y meta.
      Platform(41.9, 44.5, 0.35),
      Platform(45.4, 48, 0.7),
      Platform(49, 52, 0.35),
      Platform(53, 64, 0),
    ],
    apples: [
      Apple('t1-0', 4, 0.45),
      Apple('t1-1', 7.5, 1.45),
      Apple('t1-2', 11, 0.45),
      Apple('t1-3', 15.5, 1.45),
      Apple('t2-0', 21.4, 1.2),
      Apple('t2-1', 24, 0.8),
      Apple('t2-2', 26.8, 1.45),
      Apple('t2-3', 33, 0.8),
      Apple('t3-0', 43.2, 1.2),
      Apple('t3-1', 45.3, 1.45),
      Apple('t3-2', 48.8, 1.8),
      Apple('t3-3', 56, 0.45),
    ],
  );
}

enum OrchardEnd { none, goal, timeUp }

class OrchardSim {
  OrchardSim({this.level = OrchardLevel.v1, this.timeLimit = 30})
    : x = level.startX,
      y = 0,
      safeX = level.startX,
      safeY = 0;

  static const double dt = 1 / 120;
  static const double speed = 3;
  static const double gravity = -20;
  static const double jumpVelocity = 7;
  static const double coyote = 0.10;
  static const double jumpBuffer = 0.12;
  static const double halfWidth = 0.25;
  static const double height = 0.6;
  static const double appleRadius = 0.25;
  static const double fallLimit = -3;
  static const double respawnPause = 0.5;
  static const double maxFrame = 0.25;

  final OrchardLevel level;
  final double timeLimit;

  double x;
  double y;
  double vy = 0;
  double safeX;
  double safeY;
  bool grounded = true;
  double time = 0;
  double _accumulator = 0;
  double _sinceGround = 0;
  double _bufferedJump = -1;
  double _respawnLeft = 0;
  bool _blocked = false;
  final Set<String> collected = {};
  OrchardEnd end = OrchardEnd.none;

  /// Eventos del último avance, para feedback visual (no conceden premio).
  final List<String> justCollected = [];
  int jumpsStarted = 0;
  int falls = 0;

  int get score => collected.length;
  bool get finished => end != OrchardEnd.none;
  double get remaining => (timeLimit - time).clamp(0, timeLimit).toDouble();
  bool get respawning => _respawnLeft > 0;
  bool get blocked => _blocked;

  /// Toque o botón Saltar: encola una intención consumida en el siguiente
  /// paso. Mantener pulsado no repite (solo se llama al pulsar).
  void jump() {
    if (finished) return;
    _bufferedJump = jumpBuffer;
  }

  /// Avanza [frameSeconds] de tiempo activo (no llamar durante la pausa).
  void advance(double frameSeconds) {
    if (finished) return;
    justCollected.clear();
    _accumulator += frameSeconds.clamp(0, maxFrame);
    while (_accumulator >= dt - 1e-9 && !finished) {
      _accumulator -= dt;
      _step();
    }
  }

  void _step() {
    time += dt;
    if (_respawnLeft > 0) {
      _respawnLeft -= dt;
    } else {
      _physics();
    }
    if (x >= level.goalX) {
      end = OrchardEnd.goal;
    } else if (time >= timeLimit - 1e-9) {
      end = OrchardEnd.timeUp;
      time = timeLimit;
    }
  }

  Platform? _supportAt(double px, double py) {
    for (final p in level.platforms) {
      if (px + halfWidth > p.x0 &&
          px - halfWidth < p.x1 &&
          (py - p.top).abs() < 1e-6) {
        return p;
      }
    }
    return null;
  }

  void _physics() {
    if (_bufferedJump > 0) _bufferedJump -= dt;
    if (grounded) {
      _sinceGround = 0;
    } else {
      _sinceGround += dt;
    }
    if (_bufferedJump > 0 && (grounded || _sinceGround <= coyote) && vy <= 0) {
      vy = jumpVelocity;
      grounded = false;
      _sinceGround = coyote + 1;
      _bufferedJump = -1;
      jumpsStarted++;
    }

    // Horizontal con barrido contra los laterales de los bloques.
    var nx = x + speed * dt;
    _blocked = false;
    for (final p in level.platforms) {
      final wasLeft = x + halfWidth <= p.x0 + 1e-9;
      final nowInside = nx + halfWidth > p.x0 && nx - halfWidth < p.x1;
      if (wasLeft && nowInside && y < p.top - 1e-6) {
        nx = p.x0 - halfWidth;
        _blocked = true;
      }
    }
    x = nx;

    // Vertical con barrido contra la cara superior.
    if (grounded) {
      final s = _supportAt(x, y);
      if (s == null) {
        grounded = false;
      } else if (x - halfWidth >= s.x0 && x + halfWidth <= s.x1) {
        safeX = x;
        safeY = s.top;
      }
    }
    if (!grounded) {
      vy += gravity * dt;
      final ny = y + vy * dt;
      Platform? landing;
      if (vy <= 0) {
        for (final p in level.platforms) {
          final overlap = x + halfWidth > p.x0 && x - halfWidth < p.x1;
          if (overlap && y >= p.top - 1e-6 && ny <= p.top) {
            if (landing == null || p.top > landing.top) landing = p;
          }
        }
      }
      if (landing != null) {
        y = landing.top;
        vy = 0;
        grounded = true;
      } else {
        y = ny;
      }
    }

    // Manzanas: una sola vez por ID.
    for (final a in level.apples) {
      if (collected.contains(a.id)) continue;
      final cx = a.x.clamp(x - halfWidth, x + halfWidth);
      final cy = a.y.clamp(y, y + height);
      final dx = a.x - cx, dy = a.y - cy;
      if (dx * dx + dy * dy <= appleRadius * appleRadius) {
        collected.add(a.id);
        justCollected.add(a.id);
      }
    }

    if (y < fallLimit) {
      x = safeX;
      y = safeY;
      vy = 0;
      grounded = true;
      _respawnLeft = respawnPause;
      _bufferedJump = -1;
      falls++;
      time +=
          5; // Penalización única por caída, además del tiempo de recuperación.
    }
  }

  /// Siguiente borde de hueco o subida por delante (para el encuadre).
  double nextObstacleX() {
    for (final p in level.platforms) {
      if (p.x1 > x + 0.01 && p.x1 < level.goalX) return p.x1;
    }
    return level.goalX;
  }
}
