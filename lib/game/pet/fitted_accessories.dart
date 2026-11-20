import 'dart:math' as math;
import 'dart:ui';

import '../../domain/appearance.dart';

/// Las piezas pequeñas siguen los ojos, la frente y cada pata del sprite.
abstract final class FittedAccessories {
  static void paint(
    Canvas c,
    Appearance ids,
    String pose,
    Offset head,
    void Function(Path) fur,
  ) {
    if (ids.paws != 'paws.none') _shoes(c, ids.paws, pose, fur);
    if (ids.eyes != 'eyes.none' && pose != 'back') _glasses(c, ids.eyes, pose);
    switch (ids.head) {
      case 'head.bow':
        _ribbon(c, pose, head, fur);
      case 'head.crown':
        _crown(c, pose, head, fur);
      case 'head.crown_jewels':
        _crown(c, pose, head, fur, jewels: true);
    }
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static void _material(Canvas c, Path p, Color color, {bool metal = false}) {
    final r = p.getBounds();
    final shadow = _mix(color, const Color(0xFF301E32), metal ? 0.55 : 0.40);
    final light = _mix(color, const Color(0xFFFFF4DD), metal ? 0.76 : 0.53);
    c.drawPath(
      p,
      Paint()
        ..shader = Gradient.linear(
          r.topLeft,
          r.bottomRight,
          [shadow, light, color, shadow, color],
          [0, 0.22, 0.47, 0.81, 1],
        ),
    );
    _stroke(c, p, shadow.withValues(alpha: 0.7), 0.002);
  }

  static void _stroke(Canvas c, Path p, Color color, double width) {
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _line(Canvas c, Offset a, Offset b, Color color, double width) =>
      _stroke(
        c,
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy),
        color,
        width,
      );

  static void _shoes(
    Canvas c,
    String id,
    String pose,
    void Function(Path) fur,
  ) {
    // Centro del empeine, orientación del pie y escala de la pata lejana.
    final feet = switch (pose) {
      'front' => const [
        (-0.222, -0.118, -0.09, 0.70),
        (-0.010, -0.107, 0.10, 0.63),
        (-0.113, -0.041, 0.06, 1.0),
        (0.105, -0.041, -0.06, 1.0),
      ],
      'back' => const [
        (-0.206, -0.119, 0.05, 0.56),
        (0.017, -0.108, -0.10, 0.62),
        (-0.109, -0.041, 0.12, 1.0),
        (0.110, -0.039, -0.10, 1.0),
      ],
      'run_a' => const [
        (-0.355, -0.062, 0.15, 0.62),
        (0.504, -0.025, -1.05, 0.68),
        (-0.496, -0.105, 0.68, 0.82),
        (0.454, -0.053, -1.02, 0.88),
      ],
      'run_b' => const [
        (-0.350, -0.082, 0.30, 0.70),
        (0.356, -0.132, 0.33, 0.69),
        (-0.449, -0.070, 0.45, 0.82),
        (0.240, -0.068, 0.42, 0.90),
      ],
      'jump' => const [
        (-0.348, -0.069, 0.53, 0.65),
        (0.489, -0.274, -0.74, 0.73),
        (-0.488, -0.070, 0.57, 0.82),
        (0.417, -0.164, -0.66, 0.89),
      ],
      _ => const [
        (-0.170, -0.082, -0.10, 0.73),
        (0.352, -0.065, -0.15, 0.76),
        (-0.327, -0.058, -0.11, 0.91),
        (0.238, -0.047, -0.17, 1.0),
      ],
    };
    final opening = switch (id) {
      'paws.rain' => -0.129,
      'paws.booties' => -0.069,
      _ => -0.037,
    };
    for (final (x, y, tilt, scale) in feet) {
      c.save();
      c.translate(x, y);
      c.rotate(tilt);
      c.scale(scale);
      _shoe(c, id, pose != 'front' && pose != 'back', scale < 0.80, opening);
      c.restore();
      final sin = math.sin(tilt), cos = math.cos(tilt);
      Offset at(double dx, double dy) => Offset(
        x + scale * (dx * cos - dy * sin),
        y + scale * (dx * sin + dy * cos),
      );
      final a = at(-0.047, opening - 0.005);
      final b = at(0.038, opening - 0.004);
      final mid = at(-0.007, opening + 0.039);
      fur(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, a.dx, a.dy)
          ..close(),
      );
    }
  }

  static void _shoe(Canvas c, String id, bool profile, bool far, double top) {
    final knit = id == 'paws.booties';
    final rain = id == 'paws.rain';
    final tone = knit
        ? const Color(0xFFB685A4)
        : rain
        ? const Color(0xFFE6B831)
        : const Color(0xFFB54555);
    final color = far ? _mix(tone, const Color(0xFF33243A), 0.30) : tone;
    final toe = profile ? 0.083 : 0.068;
    final p = Path()
      ..moveTo(-0.062, top + 0.008)
      ..quadraticBezierTo(-0.007, top + 0.030, 0.056, top)
      ..cubicTo(0.034, -0.004, toe, -0.020, toe, 0.020)
      ..cubicTo(toe, 0.056, -0.064, 0.059, -0.069, 0.028)
      ..quadraticBezierTo(-0.072, 0, -0.062, top + 0.008)
      ..close();
    _material(c, p, color);
    c.save();
    c.clipPath(p);
    final trim = _mix(color, const Color(0xFFFFF1DD), 0.55);
    final opening = Path()
      ..moveTo(-0.066, top + 0.016)
      ..quadraticBezierTo(-0.012, top + 0.046, 0.061, top + 0.013);
    _stroke(c, opening, _mix(color, const Color(0xFF493140), 0.45), 0.010);
    if (knit) {
      for (var x = -0.066; x < toe; x += 0.014) {
        for (var y = top + 0.026; y < 0.047; y += 0.014) {
          _line(
            c,
            Offset(x - 0.005, y - 0.005),
            Offset(x, y + 0.003),
            trim.withValues(alpha: 0.48),
            0.003,
          );
          _line(
            c,
            Offset(x, y + 0.003),
            Offset(x + 0.005, y - 0.005),
            trim.withValues(alpha: 0.32),
            0.003,
          );
        }
      }
    } else {
      _stroke(
        c,
        Path()
          ..moveTo(-0.077, 0.025)
          ..quadraticBezierTo(-0.012, 0.058, toe + 0.012, 0.024),
        rain ? const Color(0xFF6D4C28) : const Color(0xFFEFE4D2),
        0.014,
      );
      if (!rain) {
        for (final y in [-0.003, 0.010]) {
          _line(
            c,
            Offset(-0.029, y + 0.003),
            Offset(0.027, y),
            const Color(0xFFF5E8DB),
            0.004,
          );
        }
      }
    }
    c.restore();
  }

  static void _glasses(Canvas c, String id, String pose) {
    final front = pose == 'front';
    final sun = id == 'eyes.sun';
    final heart = id == 'eyes.heart';
    final frame = heart
        ? const Color(0xFF962446)
        : sun
        ? const Color(0xFF4E322D)
        : const Color(0xFF756B5C);
    final shine = _mix(frame, const Color(0xFFFFE7B8), 0.66);
    final at = switch (pose) {
      'front' => const Offset(-0.085, -0.791),
      'run_a' => const Offset(0.306, -0.534),
      'run_b' => const Offset(0.346, -0.702),
      'jump' => const Offset(0.347, -0.718),
      _ => const Offset(0.421, -0.816),
    };
    final right = at + const Offset(0.132, -0.012);
    final lenses = [
      _lens(at, front, sun, heart),
      if (front) _lens(right, true, sun, heart),
    ];

    // Las bisagras y el puente acaban en el canto, detrás de las lentes.
    c.save();
    c.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(const Rect.fromLTRB(-2, -2, 2, 2))
        ..addPath(lenses.first, Offset.zero)
        ..addPath(front ? lenses.last : Path(), Offset.zero),
    );
    final leftHinge = at - const Offset(0.043, 0.013);
    final leftTip = at - Offset(front ? 0.075 : 0.128, front ? -0.002 : 0.025);
    _temple(c, leftHinge, leftTip, frame, shine);
    if (front) {
      _temple(
        c,
        right + const Offset(0.043, -0.013),
        right + const Offset(0.074, -0.004),
        frame,
        shine,
      );
      final bridge = Path()
        ..moveTo(at.dx + 0.045, at.dy - 0.004)
        ..quadraticBezierTo(
          at.dx + 0.064,
          at.dy - 0.026,
          right.dx - 0.044,
          right.dy,
        );
      _stroke(c, bridge, frame, sun ? 0.010 : 0.007);
      _stroke(c, bridge.shift(const Offset(0, -0.002)), shine, 0.002);
    } else {
      final nose = at + const Offset(0.049, 0.018);
      _line(c, at + const Offset(0.036, 0.011), nose, frame, 0.007);
    }
    c.restore();

    for (final lens in lenses) {
      final r = lens.getBounds();
      c.drawPath(
        lens,
        Paint()
          ..shader = Gradient.linear(
            r.topLeft,
            r.bottomRight,
            sun
                ? [
                    const Color(0xF3242433),
                    const Color(0xDD515465),
                    const Color(0xEC272631),
                  ]
                : [
                    const Color(0x3986B7C7),
                    const Color(0x07C9EAF4),
                    const Color(0x53618B9E),
                  ],
            const [0, 0.48, 1],
          ),
      );
      c.save();
      c.clipPath(lens);
      // Reflejo suave de una superficie curva, más translúcida en el centro.
      final glint = Path()
        ..moveTo(r.left - 0.004, r.center.dy + 0.009)
        ..quadraticBezierTo(
          r.center.dx - 0.012,
          r.top + 0.004,
          r.right + 0.004,
          r.top - 0.004,
        )
        ..lineTo(r.right + 0.004, r.top + 0.012)
        ..quadraticBezierTo(
          r.center.dx,
          r.top + 0.019,
          r.left - 0.006,
          r.center.dy + 0.022,
        )
        ..close();
      c.drawPath(
        glint,
        Paint()
          ..shader = Gradient.linear(r.topLeft, r.bottomRight, [
            const Color(0x93F7FDFF),
            const Color(0x0BFFFFFF),
          ]),
      );
      if (!sun) {
        _stroke(c, lens, const Color(0x4079A0AA), 0.012);
      }
      c.restore();
      _stroke(c, lens, frame, sun ? 0.010 : 0.007);
      _stroke(
        c,
        lens.shift(const Offset(0, -0.001)),
        shine.withValues(alpha: 0.72),
        0.002,
      );
    }
  }

  static void _temple(
    Canvas c,
    Offset hinge,
    Offset end,
    Color body,
    Color light,
  ) {
    final arm = Path()
      ..moveTo(hinge.dx, hinge.dy)
      ..quadraticBezierTo(
        (hinge.dx + end.dx) / 2,
        end.dy - 0.013,
        end.dx,
        end.dy,
      );
    _stroke(c, arm, body, 0.010);
    _stroke(c, arm.shift(const Offset(0, -0.002)), light, 0.003);
  }

  static Path _lens(Offset p, bool front, bool sun, bool heart) {
    final rx = front ? 0.053 : 0.040;
    final ry = sun ? 0.043 : 0.048;
    if (heart) {
      return Path()
        ..moveTo(p.dx, p.dy + 0.044)
        ..cubicTo(
          p.dx - rx * 1.78,
          p.dy - 0.008,
          p.dx - rx * 0.88,
          p.dy - 0.072,
          p.dx,
          p.dy - 0.027,
        )
        ..cubicTo(
          p.dx + rx * 0.88,
          p.dy - 0.072,
          p.dx + rx * 1.78,
          p.dy - 0.008,
          p.dx,
          p.dy + 0.044,
        )
        ..close();
    }
    final bounds = Rect.fromCenter(center: p, width: 2 * rx, height: 2 * ry);
    return sun
        ? (Path()..addRRect(
            RRect.fromRectAndRadius(bounds, const Radius.circular(0.024)),
          ))
        : (Path()..addOval(bounds));
  }

  static void _ribbon(
    Canvas c,
    String pose,
    Offset head,
    void Function(Path) fur,
  ) {
    final p =
        head +
        switch (pose) {
          'front' => const Offset(0.13, 0.068),
          'back' => const Offset(-0.13, 0.086),
          _ => const Offset(-0.070, 0.099),
        };
    final pink = const Color(0xFFCE6A8D);
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(pose == 'front' ? 0.25 : -0.22);
    for (final sign in [-1.0, 1.0]) {
      c.save();
      c.scale(sign, 1);
      _material(
        c,
        Path()
          ..moveTo(0.002, 0.009)
          ..cubicTo(0.040, 0.001, 0.072, 0.071, 0.043, 0.090)
          ..quadraticBezierTo(0.031, 0.064, 0.009, 0.065)
          ..close(),
        const Color(0xFFB45A7F),
      );
      _material(
        c,
        Path()
          ..moveTo(0.002, 0.008)
          ..cubicTo(0.026, -0.028, 0.076, -0.063, 0.086, -0.045)
          ..cubicTo(0.101, -0.018, 0.096, 0.038, 0.072, 0.036)
          ..quadraticBezierTo(0.043, 0.038, 0.002, 0.008)
          ..close(),
        pink,
      );
      _stroke(
        c,
        Path()
          ..moveTo(0.013, 0.005)
          ..quadraticBezierTo(0.044, -0.010, 0.067, -0.008),
        const Color(0x90FFF1EC),
        0.005,
      );
      c.restore();
    }
    _material(
      c,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(-0.017, -0.021, 0.022, 0.026),
          const Radius.circular(0.012),
        ),
      ),
      pink,
    );
    c.restore();
    fur(
      Path()..addOval(
        Rect.fromCenter(
          center: p + Offset(pose == 'front' ? -0.054 : 0.052, 0.051),
          width: 0.055,
          height: 0.033,
        ),
      ),
    );
  }

  static void _crown(
    Canvas c,
    String pose,
    Offset head,
    void Function(Path) fur, {
    bool jewels = false,
  }) {
    final profile = pose != 'front' && pose != 'back';
    final p = head + Offset(profile ? 0.008 : 0, 0.012);
    final w = profile ? 0.103 : 0.121;
    // Corona real: oro más claro y piedras de rubí, zafiro y esmeralda.
    final gold = jewels ? const Color(0xFFF2C64E) : const Color(0xFFDEAD47);
    c.save();
    c.translate(p.dx, p.dy);
    _material(
      c,
      Path()..addOval(Rect.fromLTRB(-w, -0.046, w, 0.030)),
      const Color(0xFF9C653B),
      metal: true,
    );
    final front = Path()
      ..moveTo(-w, -0.078)
      ..quadraticBezierTo(-w * 0.62, -0.038, -w * 0.48, -0.027)
      ..quadraticBezierTo(-w * 0.19, -0.041, 0, -0.110)
      ..quadraticBezierTo(w * 0.20, -0.042, w * 0.49, -0.025)
      ..lineTo(w, -0.076)
      ..lineTo(w * 0.85, 0.030)
      ..quadraticBezierTo(0, 0.066, -w * 0.85, 0.030)
      ..close();
    _material(c, front, gold, metal: true);
    _stroke(
      c,
      Path()
        ..moveTo(-w * 0.85, 0.023)
        ..quadraticBezierTo(0, 0.056, w * 0.85, 0.023),
      const Color(0xFF855D32),
      0.007,
    );
    for (final x in [-w, 0.0, w]) {
      _material(
        c,
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(x, x == 0 ? -0.11 : -0.078),
            radius: 0.011,
          ),
        ),
        gold,
        metal: true,
      );
    }
    if (pose != 'back') {
      for (final x in [-w * 0.57, 0.0, w * 0.57]) {
        _material(
          c,
          Path()..addOval(
            Rect.fromCenter(
              center: Offset(x, 0.007),
              width: 0.019,
              height: 0.023,
            ),
          ),
          jewels
              ? (x == 0
                    ? const Color(0xFFC81E3A)
                    : x < 0
                    ? const Color(0xFF2A5FD0)
                    : const Color(0xFF1E9A5A))
              : x == 0
              ? const Color(0xFF804A99)
              : const Color(0xFF5C9A93),
          metal: true,
        );
      }
    }
    if (jewels) {
      // Perlas en las puntas, sobre los remates.
      for (final x in [-w, 0.0, w]) {
        c.drawCircle(
          Offset(x, (x == 0 ? -0.11 : -0.078) - 0.016),
          0.008,
          Paint()..color = const Color(0xFFFFF8EE),
        );
      }
    }
    c.restore();
    fur(
      Path()..addOval(
        Rect.fromCenter(
          center: p + const Offset(-0.025, 0.056),
          width: w * 1.30,
          height: 0.037,
        ),
      ),
    );
  }
}
