import 'dart:ui';

import 'pet_neck.dart';

abstract final class PetCollars {
  static void paint(Canvas c, String id, String pose, String hair) {
    if (id == 'collar.none') return;
    final back = pose == 'back';
    final front = pose == 'front';
    final neck = PetNeck.forPose(pose, hair);
    final lift = Offset(0, back ? 0.054 : 0.010);
    final fit = PetNeck(neck.at(0.055) - lift, neck.at(0.965) - lift);
    final sag = back ? 0.010 : 0.024;
    if (id.startsWith('collar.pearls')) {
      _pearls(c, fit, sag, front, back, gold: id == 'collar.pearls_gold');
    } else {
      _leather(c, id, fit, sag, front, back);
    }
  }

  static void _leather(
    Canvas c,
    String id,
    PetNeck fit,
    double sag,
    bool front,
    bool back,
  ) {
    final bell = id == 'collar.bell';
    final thickness = back ? 0.019 : 0.033;
    final path = fit.band(thickness, drape: sag);
    final r = path.getBounds();
    final colors = bell
        ? [
            const Color(0xFF75432C),
            const Color(0xFFBA7E54),
            const Color(0xFF562F27),
          ]
        : [
            const Color(0xFF213A47),
            const Color(0xFF4D7886),
            const Color(0xFF182C3B),
          ];
    c.drawPath(
      path.shift(const Offset(0, 0.006)),
      Paint()
        ..color = const Color(0x74422A26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.005),
    );
    c.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(r.topCenter, r.bottomCenter, colors, [
          0,
          0.30,
          1,
        ]),
    );
    c.save();
    c.clipPath(path);
    for (var i = 1; i <= 19; i++) {
      final t = i / 20;
      final a = fit.at(t, drape: sag);
      final b = fit.at(t + 0.027, drape: sag);
      for (final shift in [-thickness * 0.24, thickness * 0.34]) {
        c.drawLine(
          a + Offset(0, shift),
          b + Offset(0, shift),
          Paint()
            ..color = bell ? const Color(0xDDEAC393) : const Color(0xA9B5D4D1)
            ..strokeWidth = 0.0023
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    c.restore();
    if (back) {
      final p = fit.at(0.57, drape: sag);
      final keeper = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 0.023, height: 0.026),
        const Radius.circular(0.003),
      );
      c.drawRRect(
        keeper,
        Paint()
          ..color = const Color(0xFFE1B976)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.004,
      );
      return;
    }
    final p = fit.at(front ? 0.51 : 0.84, drape: sag);
    final ring = p + const Offset(0, 0.024);
    c.drawOval(
      Rect.fromCenter(center: ring, width: 0.019, height: 0.026),
      Paint()
        ..color = const Color(0xFFE6BE86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.004,
    );
    final center = ring + Offset(front ? -0.002 : 0.008, 0.027);
    if (bell) {
      final body = Path()
        ..moveTo(center.dx - 0.016, center.dy + 0.012)
        ..cubicTo(
          center.dx - 0.013,
          center.dy - 0.007,
          center.dx - 0.023,
          center.dy - 0.023,
          center.dx,
          center.dy - 0.023,
        )
        ..cubicTo(
          center.dx + 0.021,
          center.dy - 0.023,
          center.dx + 0.015,
          center.dy - 0.004,
          center.dx + 0.019,
          center.dy + 0.008,
        )
        ..quadraticBezierTo(
          center.dx + 0.023,
          center.dy + 0.020,
          center.dx - 0.016,
          center.dy + 0.018,
        )
        ..close();
      c.drawPath(body, _metal(center, 0.030));
      c.drawArc(
        Rect.fromCenter(
          center: center + const Offset(0, 0.010),
          width: 0.034,
          height: 0.013,
        ),
        0.12,
        2.88,
        false,
        Paint()
          ..color = const Color(0xFF714326)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.004,
      );
      c.drawCircle(
        center + const Offset(0, 0.020),
        0.004,
        Paint()..color = const Color(0xFF603E25),
      );
    } else {
      final tag = Rect.fromCenter(
        center: center,
        width: front ? 0.046 : 0.037,
        height: 0.043,
      );
      c.drawOval(
        tag.shift(const Offset(0.002, 0.003)),
        Paint()..color = const Color(0xFF795B3B),
      );
      c.drawOval(tag, _metal(center, 0.038));
      c.drawOval(
        tag.deflate(0.0045),
        Paint()
          ..color = const Color(0x9985673B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.002,
      );
      for (final d in const [
        Offset(0, 0.005),
        Offset(-0.007, -0.001),
        Offset(0, -0.004),
        Offset(0.006, -0.001),
      ]) {
        c.drawCircle(
          center + d,
          d.dy > 0 ? 0.004 : 0.0024,
          Paint()..color = const Color(0xFF8A6537),
        );
      }
    }
  }

  static Paint _metal(Offset center, double radius) => Paint()
    ..shader = Gradient.radial(
      center - const Offset(0.008, 0.010),
      radius,
      [
        const Color(0xFFFFF5C8),
        const Color(0xFFE7B35F),
        const Color(0xFFA86B36),
      ],
      [0, 0.37, 1],
    );

  static void _pearls(
    Canvas c,
    PetNeck fit,
    double sag,
    bool front,
    bool back, {
    bool gold = false,
  }) {
    final strand = fit.band(0.009, drape: sag);
    c.drawPath(
      strand.shift(const Offset(0, 0.003)),
      Paint()..color = const Color(0xB66D5763),
    );
    const count = 12;
    for (var i = 0; i < count; i++) {
      final t = (i + 0.5) / count;
      final p = fit.at(t, drape: sag);
      final clasp = back && i == 6;
      final r = clasp
          ? 0.008
          : (back
                    ? 0.0085
                    : front
                    ? 0.011
                    : 0.010) *
                (1 - (t - 0.5).abs() * 0.42);
      c.drawCircle(
        p + const Offset(0.001, 0.004),
        r,
        Paint()..color = const Color(0x786D5263),
      );
      c.drawCircle(
        p,
        r,
        clasp
            ? _metal(p, 0.014)
            : (Paint()
                ..shader = Gradient.radial(
                  p - Offset(r * 0.36, r * 0.42),
                  r * 1.58,
                  gold
                      ? const [
                          Color(0xFFFFF6C8),
                          Color(0xFFE9BE4E),
                          Color(0xFF8A5E1E),
                        ]
                      : const [
                          Color(0xFFFFFFF6),
                          Color(0xFFECE5DF),
                          Color(0xFF8F7B8C),
                        ],
                  [0, 0.38, 1],
                )),
      );
    }
  }
}
