import 'dart:math' as math;
import 'dart:ui';

import '../../domain/appearance.dart';
import 'appearance_catalog.dart';
import 'integrated_accessories.dart';
import 'pet_neck.dart';
import 'pet_collars.dart';

/// Piezas limpias y escalables: nunca contienen píxeles del caniche fuente.
/// Todas las variantes comparten construcción y anclajes de cada fotograma.
abstract final class PetAccessories {
  static void paint(
    Canvas c,
    AppearanceCatalog catalog,
    Appearance ids,
    String pose,
    Map<String, Offset> lm,
    double time, {
    bool skipPilot = false,
  }) {
    final front = pose == 'front';
    final back = pose == 'back';
    final top = lm['headTop'] ?? const Offset(0, -0.94);
    final neck = lm['neck'] ?? top + const Offset(0, 0.39);
    final eyes = lm['eyes'] ?? top + const Offset(0.055, 0.17);
    final chest = lm['chest'] ?? neck + Offset(front || back ? 0 : -0.22, 0.12);
    final paws = lm['paws'] ?? const Offset(0, -0.04);
    Color color(String id, Color fallback) => catalog.swatch(id) ?? fallback;
    final edge = Paint()
      ..color = const Color(0xAA392B40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.005
      ..strokeJoin = StrokeJoin.round;
    void shape(Path p, Color fill) {
      final r = p.getBounds();
      c.drawPath(
        p,
        Paint()
          ..shader = Gradient.linear(
            r.topLeft,
            r.bottomRight,
            [
              Color.lerp(fill, const Color(0xFFFFFFFF), 0.2)!,
              fill,
              Color.lerp(fill, const Color(0xFF302941), 0.22)!,
            ],
            [0, 0.5, 1],
          ),
      );
      c.drawPath(p, edge);
    }

    void rounded(Rect r, double radius, Color fill) {
      shape(
        Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))),
        fill,
      );
    }

    void line(Offset a, Offset b, Color color, [double width = 0.005]) {
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    void bow(Offset center, Color fill, double size) {
      for (final sign in [-1.0, 1.0]) {
        shape(
          Path()
            ..moveTo(center.dx, center.dy)
            ..quadraticBezierTo(
              center.dx + sign * size,
              center.dy - size * 0.8,
              center.dx + sign * size,
              center.dy,
            )
            ..quadraticBezierTo(
              center.dx + sign * size,
              center.dy + size * 0.8,
              center.dx,
              center.dy,
            )
            ..close(),
          fill,
        );
      }
      c.drawCircle(
        center,
        size * 0.23,
        Paint()..color = Color.lerp(fill, const Color(0xFF482D4A), 0.25)!,
      );
    }

    if (ids.outfit != 'outfit.none' &&
        !(skipPilot &&
            (IntegratedAccessories.sweater(ids) ||
                IntegratedAccessories.tailoredFamily(ids.outfit) != null))) {
      final fill = color(ids.outfit, const Color(0xFF377F79));
      final side = !front && !back;
      final width = side ? 0.42 : 0.31;
      final height = side ? 0.22 : 0.27;
      final center = chest + Offset(side ? -0.03 : -0.015, side ? 0.0 : 0.015);
      final r = Rect.fromCenter(center: center, width: width, height: height);
      final dress = ids.outfit.contains('dress');
      final overalls =
          ids.outfit.contains('overalls') || ids.outfit == 'outfit.teal';
      final raincoat = ids.outfit.contains('raincoat');
      final garment = Path()
        ..moveTo(r.left + width * 0.12, r.top)
        ..quadraticBezierTo(
          r.center.dx,
          r.top + 0.035,
          r.right - width * 0.12,
          r.top,
        )
        ..lineTo(dress ? r.right + 0.035 : r.right, r.bottom - 0.015)
        ..quadraticBezierTo(
          r.center.dx,
          r.bottom + (dress ? 0.045 : 0.015),
          dress ? r.left - 0.035 : r.left,
          r.bottom - 0.015,
        )
        ..close();
      shape(garment, fill);
      c.save();
      c.clipPath(garment);
      final seam = Color.lerp(fill, const Color(0xFFFFFFFF), 0.4)!;
      if (overalls) {
        for (var x = r.left; x < r.right; x += 0.018) {
          line(
            Offset(x, r.top),
            Offset(x, r.bottom),
            seam.withValues(alpha: 0.4),
            0.002,
          );
        }
        rounded(
          Rect.fromCenter(center: r.center, width: 0.10, height: 0.065),
          0.012,
          Color.lerp(fill, const Color(0xFF263D44), 0.18)!,
        );
      } else if (!raincoat) {
        for (var y = r.top + 0.012; y < r.bottom; y += 0.018) {
          for (var x = r.left; x < r.right; x += 0.02) {
            line(
              Offset(x, y),
              Offset(x + 0.009, y + 0.009),
              seam.withValues(alpha: 0.45),
              0.0025,
            );
          }
        }
      }
      if (dress) {
        for (var x = r.left; x < r.right; x += 0.06) {
          line(
            Offset(x, r.bottom - 0.055),
            Offset(x - 0.012, r.bottom + 0.015),
            seam,
          );
        }
      }
      c.restore();
      line(
        r.bottomLeft + const Offset(0.01, -0.015),
        r.bottomRight - const Offset(0.01, 0.015),
        seam,
      );
      if (overalls) {
        for (final sign in [-1.0, 1.0]) {
          final p = Offset(r.center.dx + sign * width * 0.28, r.top + 0.015);
          line(
            p - const Offset(0, 0.04),
            p + const Offset(0, 0.04),
            fill,
            0.028,
          );
          c.drawCircle(p, 0.01, Paint()..color = const Color(0xFFF3DC9B));
        }
      } else if (raincoat && !back) {
        line(
          Offset(r.center.dx, r.top + 0.02),
          Offset(r.center.dx, r.bottom - 0.02),
          seam,
        );
        for (var i = 0; i < 3; i++) {
          c.drawCircle(
            Offset(r.center.dx + 0.018, r.top + 0.06 + i * 0.055),
            0.007,
            Paint()..color = const Color(0xFFEDE1BA),
          );
        }
      } else if (dress) {
        bow(
          r.topCenter + const Offset(0, 0.035),
          const Color(0xFFFCDFE7),
          0.055,
        );
      }
    }

    if (ids.paws != 'paws.none' && !skipPilot) {
      final fill = ids.paws.contains('rain')
          ? const Color(0xFFE5B73F)
          : ids.paws.contains('sneakers')
          ? const Color(0xFFB75465)
          : const Color(0xFF8E78AE);
      final offsets = front || back ? [-0.095, 0.095] : [-0.22, 0.22];
      for (final x in offsets) {
        final p = paws + Offset(x, 0.015);
        final r = Rect.fromCenter(
          center: p,
          width: 0.095,
          height: ids.paws.contains('rain') ? 0.12 : 0.075,
        );
        rounded(r, 0.022, fill);
        line(r.bottomLeft, r.bottomRight, const Color(0xFFEEE5D9), 0.012);
        if (ids.paws.contains('sneakers')) {
          for (var i = 0; i < 2; i++) {
            line(
              p + Offset(-0.018, -0.015 + i * 0.014),
              p + Offset(0.018, -0.015 + i * 0.014),
              const Color(0xFFF8F1DC),
              0.004,
            );
          }
        }
      }
    }
    if (ids.collar != 'collar.none' || ids.neck != 'neck.none') {
      final atRest = pose == 'eat' || pose == 'sleep';
      final fit = atRest
          ? PetNeck(neck - const Offset(0.10, 0), neck + const Offset(0.10, 0))
          : PetNeck.forPose(pose, ids.hair);
      c.save();
      if (!front && !back && !atRest) {
        // La oreja se interpone entre el cuello y el jugador de perfil.
        c.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(const Rect.fromLTRB(-2, -2, 2, 2))
            ..addPath(PetNeck.earMask(pose, top), Offset.zero),
        );
      }
      final pendant = fit.at(front || back ? 0.5 : 0.84);
      if (skipPilot) {
        PetCollars.paint(c, ids.collar, pose, ids.hair);
      } else if (ids.collar != 'collar.none') {
        final pearls = ids.collar.contains('pearls');
        shape(
          fit.band(back ? 0.016 : 0.026),
          pearls ? const Color(0xFFA49391) : const Color(0xFF447E81),
        );
        if (pearls) {
          for (var i = 0; i < 9; i++) {
            final p = fit.at((i + 0.5) / 9);
            c.drawCircle(
              p,
              back ? 0.008 : 0.013,
              Paint()
                ..shader = Gradient.radial(
                  p - const Offset(0.004, 0.004),
                  0.018,
                  [const Color(0xFFFFFFF4), const Color(0xFFC8B8B8)],
                ),
            );
          }
        } else if (!back) {
          final center = pendant + const Offset(0, 0.036);
          c.drawCircle(
            center,
            0.023,
            Paint()
              ..shader = Gradient.radial(
                center - const Offset(0.006, 0.006),
                0.028,
                [const Color(0xFFFFE2A0), const Color(0xFFB17E37)],
              ),
          );
          if (ids.collar.contains('bell')) {
            line(
              center + const Offset(-0.012, 0.006),
              center + const Offset(0.012, 0.006),
              const Color(0xFF795B36),
              0.004,
            );
          }
        }
      }
      if (ids.neck != 'neck.none' && !skipPilot) {
        final isBow = ids.neck.contains('bowtie');
        final fill = isBow
            ? const Color(0xFF334679)
            : ids.neck.contains('knit')
            ? const Color(0xFF73B49B)
            : const Color(0xFFD76F72);
        shape(
          fit.band(
            back
                ? 0.016
                : isBow
                ? 0.028
                : 0.048,
          ),
          fill,
        );
        if (isBow) {
          if (!back) bow(pendant, fill, front ? 0.075 : 0.057);
        } else if (!back) {
          final left = fit.at(front ? 0.10 : 0.30);
          final right = fit.at(front ? 0.90 : 0.93);
          final tip = pendant + Offset(front ? 0.014 : -0.018, 0.133);
          final fabric = Path()
            ..moveTo(left.dx, left.dy)
            ..quadraticBezierTo(
              fit.at(0.55).dx,
              fit.at(0.55).dy + 0.047,
              right.dx,
              right.dy,
            )
            ..quadraticBezierTo(
              right.dx - 0.025,
              right.dy + 0.078,
              tip.dx,
              tip.dy,
            )
            ..quadraticBezierTo(
              left.dx + 0.033,
              left.dy + 0.080,
              left.dx,
              left.dy,
            )
            ..close();
          shape(fabric, fill);
        }
      }
      c.restore();
    }
    if (ids.eyes != 'eyes.none' && !back && !skipPilot) {
      final fill = ids.eyes.contains('sun')
          ? const Color(0xDB292C43)
          : const Color(0x226CA6B5);
      final count = front ? 2 : 1;
      for (var i = 0; i < count; i++) {
        final center =
            eyes + Offset(front ? (i == 0 ? -0.077 : 0.077) : 0.035, 0.005);
        final r = Rect.fromCenter(center: center, width: 0.125, height: 0.11);
        final p = Path();
        if (ids.eyes.contains('heart')) {
          p.moveTo(center.dx, center.dy + 0.055);
          p.cubicTo(
            center.dx - 0.13,
            center.dy - 0.025,
            center.dx - 0.035,
            center.dy - 0.09,
            center.dx,
            center.dy - 0.03,
          );
          p.cubicTo(
            center.dx + 0.035,
            center.dy - 0.09,
            center.dx + 0.13,
            center.dy - 0.025,
            center.dx,
            center.dy + 0.055,
          );
        } else {
          p.addOval(r);
        }
        c.drawPath(p, Paint()..color = fill);
        c.drawPath(
          p,
          Paint()
            ..color = ids.eyes.contains('heart')
                ? const Color(0xFFBD5986)
                : const Color(0xFFD4B36C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.009,
        );
        line(
          center + const Offset(-0.025, -0.025),
          center + const Offset(0.008, -0.038),
          const Color(0x88FFFFFF),
          0.005,
        );
      }
      if (front) {
        line(
          eyes - const Offset(0.015, 0),
          eyes + const Offset(0.015, 0),
          const Color(0xFFD4B36C),
          0.008,
        );
      }
    }
    if (ids.head == 'head.beanie' && !skipPilot) {
      final center = top + const Offset(0, -0.004);
      final r = Rect.fromCenter(
        center: center,
        width: front || back ? 0.34 : 0.29,
        height: 0.22,
      );
      final hat = Path()
        ..moveTo(r.left, r.bottom)
        ..cubicTo(
          r.left - 0.01,
          r.top - 0.02,
          r.right + 0.01,
          r.top - 0.02,
          r.right,
          r.bottom,
        )
        ..close();
      shape(hat, const Color(0xFFD6A64D));
      c.save();
      c.clipPath(hat);
      for (var x = r.left; x < r.right; x += 0.016) {
        line(
          Offset(x, r.top),
          Offset(x - 0.012, r.bottom),
          const Color(0x77FFF0BE),
          0.004,
        );
      }
      c.restore();
      rounded(
        Rect.fromLTRB(
          r.left - 0.01,
          r.bottom - 0.05,
          r.right + 0.01,
          r.bottom + 0.008,
        ),
        0.014,
        const Color(0xFFC68D3D),
      );
      for (var x = r.left; x < r.right; x += 0.015) {
        line(
          Offset(x, r.bottom - 0.04),
          Offset(x, r.bottom),
          const Color(0x99F3D59D),
          0.003,
        );
      }
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5;
        c.drawCircle(
          r.topCenter + Offset(math.cos(a) * 0.026, math.sin(a) * 0.026),
          0.022,
          Paint()
            ..color = i.isEven
                ? const Color(0xFFEBC875)
                : const Color(0xFFD9AF5C),
        );
      }
    } else if (ids.head == 'head.bow' && !skipPilot) {
      bow(top + const Offset(0.07, 0.035), const Color(0xFFE297B0), 0.09);
    } else if (ids.head == 'head.crown' && !skipPilot) {
      final center = top - const Offset(0, 0.035);
      shape(
        Path()
          ..moveTo(center.dx - 0.14, center.dy + 0.07)
          ..lineTo(center.dx - 0.16, center.dy - 0.06)
          ..lineTo(center.dx - 0.07, center.dy)
          ..lineTo(center.dx, center.dy - 0.10)
          ..lineTo(center.dx + 0.07, center.dy)
          ..lineTo(center.dx + 0.16, center.dy - 0.06)
          ..lineTo(center.dx + 0.14, center.dy + 0.07)
          ..close(),
        const Color(0xFFE6BC54),
      );
      for (var i = -1; i <= 1; i++) {
        c.drawCircle(
          center + Offset(i * 0.075, 0.035),
          0.012,
          Paint()
            ..color = i == 0
                ? const Color(0xFFA771AE)
                : const Color(0xFF75B8B4),
        );
      }
    }
  }
}
