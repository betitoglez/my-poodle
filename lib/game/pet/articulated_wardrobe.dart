import 'dart:math' as math;
import 'dart:ui';

import '../../domain/appearance.dart';
import 'appearance_catalog.dart';
import 'integrated_accessories.dart';
import 'pet_neck.dart';

/// A shared 2D skeleton for the wardrobe pilot. The head illustrations are
/// interchangeable. Every garment uses the same body and joint coordinates.
class ArticulatedWardrobe {
  static const referenceHair = 'hair.teddy';

  static bool supports(Appearance ids) =>
      (ids.hair == referenceHair || ids.hair == 'hair.pom') &&
      (ids.outfit == 'outfit.none' || ids.outfit == 'outfit.teal') &&
      (ids.neck == 'neck.none' || ids.neck == 'neck.coral') &&
      (ids.paws == 'paws.none' || ids.paws == 'paws.rain') &&
      ids.collar == 'collar.none' &&
      ids.eyes == 'eyes.none' &&
      ids.head == 'head.none';

  ArticulatedWardrobe(this.materials);
  final IntegratedAccessories materials;

  void paint(
    Canvas canvas,
    PetLook look,
    PetPose view, {
    required Image bodyFur,
    required Image hair,
    required Paint coatPaint,
    double? stride,
  }) {
    final ids = look.ids!;
    final side = view == PetPose.side;
    final back = view == PetPose.back;
    final pom = ids.hair == 'hair.pom';
    final rig = switch (view) {
      PetPose.front => _front,
      PetPose.side => _side,
      PetPose.back => _back,
    };
    final (lift, pitch, nod) = stride == null
        ? (0.0, 0.0, 0.0)
        : _runFrame(stride);

    canvas.save();
    canvas.scale(1 / 260);
    canvas.translate(-rig.origin.dx, -rig.origin.dy);
    canvas.translate(rig.pivot.dx, rig.pivot.dy - lift);
    canvas.rotate(pitch);
    canvas.translate(-rig.pivot.dx, -rig.pivot.dy);

    final parts = [
      for (final (index, leg) in rig.legs.indexed)
        leg.solve(stride == null ? leg.rest : _runAngles(index, stride)),
    ];
    final dressed = ids.outfit == 'outfit.teal';
    final boots = ids.paws == 'paws.rain';
    final bandana = ids.neck == 'neck.coral';
    final fur = look.coat;
    final fabric = dressed ? materials.articulatedCorduroy : null;

    if (!back) _tail(canvas, view, bodyFur, coatPaint);
    final silhouette = rig.body;
    final furPatch = _furPatch(view);
    for (final part in parts.take(2)) {
      _leg(
        canvas,
        part,
        side,
        fabric,
        boots,
        bodyFur,
        furPatch,
        coatPaint,
        fur,
      );
    }

    if (fabric == null) {
      _fur(canvas, silhouette, bodyFur, furPatch, coatPaint, fur);
    }
    if (fabric != null) {
      _corduroy(canvas, silhouette, fabric);
      _panelDetails(canvas, view);
      _neckline(canvas, rig.neck);
    }
    for (final part in parts.skip(2)) {
      _leg(
        canvas,
        part,
        side,
        fabric,
        boots,
        bodyFur,
        furPatch,
        coatPaint,
        fur,
        torso: silhouette,
      );
    }
    if (side && dressed) {
      // The bib panel laps under the foreleg at the shoulder, above its cuff.
      _stroke(
        canvas,
        Path()
          ..moveTo(216, 146)
          ..quadraticBezierTo(197, 153, 176, 173),
        const Color(0x88AABEB0),
        1.4,
      );
      _button(canvas, const Offset(210, 149), 4);
    }

    if (back) {
      // El corte pompón deja la nuca visible entre las orejas y el cuello.
      final nape = Path()
        ..moveTo(66, 71)
        ..quadraticBezierTo(85, 70, 105, 71)
        ..quadraticBezierTo(102, 92, 110, 107)
        ..quadraticBezierTo(85, 113, 60, 107)
        ..quadraticBezierTo(69, 92, 66, 71)
        ..close();
      _fur(
        canvas,
        nape,
        pom ? hair : bodyFur,
        pom ? const Rect.fromLTRB(140, 127, 201, 161) : furPatch,
        coatPaint,
        fur,
      );
    }
    if (bandana) {
      materials.paintArticulatedBandana(
        canvas,
        rig.neck,
        side: side,
        back: back,
      );
    }
    _head(canvas, view, hair, coatPaint, nod, rig.head, pom);
    if (back) _tail(canvas, view, bodyFur, coatPaint);
    canvas.restore();
  }

  static const _side = _Projection(
    Offset(134, 277),
    Offset(126, 161),
    Offset(196, 114),
    PetNeck(Offset(155, 122), Offset(224, 116)),
    [
      _Leg(Offset(69, 163), 42, 50, 0.79, (0.14, -0.49)),
      _Leg(Offset(202, 155), 48, 54, 0.79, (0.06, 0.07)),
      _Leg(Offset(47, 162), 47, 57, 1, (0.21, -0.28)),
      _Leg(Offset(184, 163), 49, 55, 1, (0.08, -0.09)),
    ],
    PetPose.side,
  );

  static const _front = _Projection(
    Offset(83, 276),
    Offset(83, 170),
    Offset(83, 105),
    PetNeck(Offset(54, 114), Offset(112, 114)),
    [
      _Leg(Offset(52, 173), 36, 44, 0.76, (-0.19, -0.16)),
      _Leg(Offset(113, 173), 36, 44, 0.76, (0.19, 0.16)),
      _Leg(Offset(61, 166), 45, 54, 1, (-0.05, -0.08)),
      _Leg(Offset(105, 166), 45, 54, 1, (0.05, 0.08)),
    ],
    PetPose.front,
  );

  static const _back = _Projection(
    Offset(85, 276),
    Offset(85, 170),
    Offset(85, 106),
    PetNeck(Offset(57, 102), Offset(113, 102)),
    [
      _Leg(Offset(68, 177), 37, 40, 0.78, (-0.01, 0.03)),
      _Leg(Offset(102, 177), 37, 40, 0.78, (0.01, -0.03)),
      _Leg(Offset(63, 166), 45, 54, 1, (-0.04, -0.10)),
      _Leg(Offset(107, 166), 45, 54, 1, (0.04, 0.10)),
    ],
    PetPose.back,
  );

  // Keys are gathered, extended and flight. Each entry drives thigh and
  // shin rotation. Interpolation keeps continuous motion between the keys.
  static const _stride = [
    [(0.75, 0.24), (-0.77, 0.46), (0.51, 0.70), (-0.91, 0.28)],
    [(-0.75, -0.95), (0.89, 1.12), (-0.98, -0.87), (0.74, 1.01)],
    [(-0.57, -0.95), (0.44, -0.53), (-0.69, -0.46), (0.38, -0.22)],
  ];
  static const _bodyKeys = [
    (25.0, -0.09, 0.08),
    (25.0, 0.04, 0.23),
    (31.0, -0.03, 0.01),
  ];

  static double _blend(double a, double b, double t) => a + (b - a) * t;

  static (int, int, double) _key(double stride) {
    final i = stride.floor() % 3;
    final t = stride % 1;
    return (i, (i + 1) % 3, t * t * (3 - 2 * t));
  }

  static (double, double) _runAngles(int leg, double stride) {
    final (i, j, t) = _key(stride);
    final a = _stride[i][leg], b = _stride[j][leg];
    return (_blend(a.$1, b.$1, t), _blend(a.$2, b.$2, t));
  }

  static (double, double, double) _runFrame(double stride) {
    final (i, j, t) = _key(stride);
    final a = _bodyKeys[i], b = _bodyKeys[j];
    return (
      _blend(a.$1, b.$1, t),
      _blend(a.$2, b.$2, t),
      _blend(a.$3, b.$3, t),
    );
  }

  static void _head(
    Canvas canvas,
    PetPose view,
    Image image,
    Paint paint,
    double angle,
    Offset pivot,
    bool pom,
  ) {
    // Only the head and hanging ears change with the haircut. The cut
    // follows the underside of the muzzle and overlaps the neck behind it.
    final cut = switch (view) {
      PetPose.front =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(166, 0)
          ..lineTo(166, 113)
          ..quadraticBezierTo(130, pom ? 112 : 105, 112, 108)
          ..quadraticBezierTo(83, 126, 54, 108)
          ..quadraticBezierTo(39, pom ? 111 : 105, 0, 112)
          ..close(),
      PetPose.side =>
        Path()
          ..moveTo(140, 0)
          ..lineTo(267, 0)
          ..lineTo(267, 109)
          ..quadraticBezierTo(238, 106, 222, 114)
          ..quadraticBezierTo(213, 120, 198, pom ? 133 : 122)
          ..quadraticBezierTo(176, pom ? 144 : 133, 158, 126)
          ..lineTo(140, 116)
          ..close(),
      PetPose.back =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(174, 0)
          ..lineTo(174, 111)
          ..quadraticBezierTo(123, pom ? 112 : 102, 109, pom ? 81 : 105)
          ..quadraticBezierTo(85, pom ? 85 : 117, 64, pom ? 81 : 105)
          ..quadraticBezierTo(43, pom ? 112 : 104, 0, 112)
          ..close(),
    };
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.clipPath(cut);
    _sprite(canvas, image, paint);
    canvas.restore();
  }

  static void _tail(Canvas c, PetPose view, Image image, Paint paint) {
    final cut = switch (view) {
      PetPose.side =>
        Path()
          ..moveTo(0, 73)
          ..lineTo(52, 73)
          ..lineTo(60, 125)
          ..lineTo(51, 145)
          ..lineTo(36, 141)
          ..lineTo(0, 130)
          ..close(),
      PetPose.back =>
        Path()
          ..moveTo(82, 102)
          ..cubicTo(104, 104, 114, 124, 108, 141)
          ..cubicTo(101, 162, 74, 168, 66, 147)
          ..cubicTo(60, 131, 60, 110, 82, 102)
          ..close(),
      PetPose.front => Path()..addOval(const Rect.fromLTRB(39, 111, 64, 143)),
    };
    c.save();
    if (view == PetPose.back) c.translate(0, 17);
    c.clipPath(cut);
    _sprite(c, image, paint);
    c.restore();
  }

  static void _sprite(Canvas c, Image image, Paint paint) {
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    c.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, image.width / 2, image.height / 2),
      paint,
    );
  }

  static void _leg(
    Canvas c,
    _BentLeg leg,
    bool side,
    Image? fabric,
    bool boots,
    Image bodyFur,
    Rect furPatch,
    Paint coatPaint,
    CoatPalette coat, {
    Path? torso,
  }) {
    final (root, knee, foot) = (leg.root, leg.knee, leg.foot);
    final scale = leg.scale;
    final shin = (foot - knee) / (foot - knee).distance;
    final cuff = Offset.lerp(knee, foot, 0.67)!;
    if (fabric == null || !boots) {
      final furEnd = boots ? foot - shin * (19 * scale) : foot;
      final fur = _tube(root, knee, furEnd, 17 * scale, 11 * scale, 11 * scale);
      _fur(c, fur, bodyFur, furPatch, coatPaint, coat);
      if (!boots) {
        final toes = Path()
          ..addOval(
            Rect.fromCenter(
              center: foot,
              width: 27 * scale,
              height: 23 * scale,
            ),
          );
        _fur(c, toes, bodyFur, furPatch, coatPaint, coat);
      }
    }
    if (boots) {
      c.save();
      c.translate(foot.dx, foot.dy);
      c.rotate(side ? -leg.shinAngle : -leg.shinAngle * 0.36);
      c.scale(scale);
      _boot(c, side, far: scale < 0.9);
      c.restore();
    }

    if (fabric == null) return;
    final trouser = _tube(root, knee, cuff, 20 * scale, 16 * scale, 14 * scale);
    final axis = cuff - root;
    _corduroy(
      c,
      trouser,
      fabric,
      dark: scale < 0.9,
      angle: math.atan2(-axis.dx, axis.dy),
    );
    c.save();
    if (torso != null) {
      // La pernera nace dentro del peto. Su contorno exterior aparece donde
      // sale del tronco, y la costura se prolonga hacia el puño.
      c.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(trouser.getBounds().inflate(3)),
          torso,
        ),
      );
    }
    _stroke(c, trouser, const Color(0xA625413C), 1.2);
    c.restore();
    final normal = Offset(shin.dy, -shin.dx);
    final outer = normal * (root.dx < 85 ? -1 : 1);
    final seamTop = Offset.lerp(root, knee, 0.42)! + outer * (14 * scale);
    final seamMid = knee + outer * (12 * scale);
    final seamEnd = cuff + outer * (11 * scale);
    _stitch(
      c,
      Path()
        ..moveTo(seamTop.dx, seamTop.dy)
        ..quadraticBezierTo(seamMid.dx, seamMid.dy, seamEnd.dx, seamEnd.dy),
      const Color(0x7FB8C6AE),
    );

    final edge = cuff + shin * (2 * scale);
    final welt = Path()
      ..moveTo(
        edge.dx - normal.dx * 14 * scale,
        edge.dy - normal.dy * 14 * scale,
      )
      ..quadraticBezierTo(
        edge.dx + shin.dx * 9 * scale,
        edge.dy + shin.dy * 9 * scale,
        edge.dx + normal.dx * 14 * scale,
        edge.dy + normal.dy * 14 * scale,
      );
    _stroke(c, welt, const Color(0xFF233F3C), 9 * scale);
    _stroke(
      c,
      welt.shift(-shin * 2 * scale),
      const Color(0xFF779187),
      1.7 * scale,
    );
  }

  static Path _tube(
    Offset root,
    Offset knee,
    Offset end,
    double top,
    double mid,
    double bottom,
  ) {
    Offset normal(Offset a, Offset b) {
      final d = b - a;
      return Offset(d.dy, -d.dx) / d.distance;
    }

    final first = normal(root, knee) * top;
    final second = (normal(root, knee) + normal(knee, end)) * (mid / 2);
    final third = normal(knee, end) * bottom;
    final taper = (end - knee) * 0.16;
    final a = root - first, b = knee - second, d = end - third;
    final e = end + third, f = knee + second, g = root + first;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(b.dx, b.dy, d.dx, d.dy)
      ..quadraticBezierTo(end.dx + taper.dx, end.dy + taper.dy, e.dx, e.dy)
      ..quadraticBezierTo(f.dx, f.dy, g.dx, g.dy)
      ..quadraticBezierTo(root.dx, root.dy - top, a.dx, a.dy)
      ..close();
  }

  static void _boot(Canvas c, bool side, {required bool far}) {
    final toe = side ? 22.0 : 16.0;
    final rubber = Path()
      ..moveTo(-13, -26)
      ..quadraticBezierTo(0, -30, 14, -26)
      ..cubicTo(12, -18, 11, -8, toe - 3, -7)
      ..cubicTo(toe + 4, -4, toe + 3, 7, toe - 1, 10)
      ..quadraticBezierTo(5, 15, -13, 11)
      ..cubicTo(-18, 9, -16, -12, -13, -26)
      ..close();
    _shade(c, rubber, const [
      Color(0xFF916018),
      Color(0xFFF6CF66),
      Color(0xFFDBA735),
      Color(0xFF8F591A),
    ]);
    _stroke(c, rubber, const Color(0x995B411F), 1);
    if (far) c.drawPath(rubber, Paint()..color = const Color(0x4D543A21));
    c.save();
    c.clipPath(rubber);
    _stroke(
      c,
      Path()
        ..moveTo(-16, 7)
        ..quadraticBezierTo(2, 14, toe + 2, 6),
      const Color(0xFF624926),
      5.5,
    );
    _stroke(
      c,
      Path()
        ..moveTo(-10, -16)
        ..quadraticBezierTo(-12, -5, -9, 1),
      const Color(0x90FFF0AD),
      1.7,
    );
    c.restore();
    c.drawOval(
      const Rect.fromLTRB(-13, -29, 14, -22),
      Paint()..color = const Color(0xFF644718),
    );
  }

  static Rect _furPatch(PetPose view) => switch (view) {
    PetPose.front => const Rect.fromLTRB(117, 241, 206, 337),
    PetPose.side => const Rect.fromLTRB(176, 251, 295, 349),
    PetPose.back => const Rect.fromLTRB(128, 291, 218, 361),
  };

  static void _fur(
    Canvas c,
    Path path,
    Image image,
    Rect patch,
    Paint paint,
    CoatPalette coat,
  ) {
    _shade(c, path, [coat.shade, coat.base, coat.light, coat.base]);
    c.save();
    c.clipPath(path);
    c.drawImageRect(image, patch, path.getBounds(), paint);
    c.restore();
  }

  static void _corduroy(
    Canvas c,
    Path path,
    Image image, {
    bool dark = false,
    double angle = 0,
  }) {
    final rect = path.getBounds();
    final source = Rect.fromLTRB(
      image.width * 0.418,
      image.height * 0.168,
      image.width * 0.575,
      image.height * 0.467,
    );
    c.save();
    c.clipPath(path);
    // La pana corre a lo largo de la pernera. La textura comparte el eje
    // de la tela en todas las fases, incluso con las patas extendidas.
    c.save();
    c.translate(rect.center.dx, rect.center.dy);
    final rotation = math.pi / 2 + angle;
    final cos = math.cos(rotation).abs(), sin = math.sin(rotation).abs();
    c.rotate(rotation);
    c.drawImageRect(
      image,
      source,
      Rect.fromCenter(
        center: Offset.zero,
        width: rect.width * cos + rect.height * sin,
        height: rect.width * sin + rect.height * cos,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
    c.restore();
    c.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            const Color(0x554D7368),
            const Color(0x326F958A),
            dark ? const Color(0xA3132928) : const Color(0x75122623),
          ],
          [0, 0.45, 1],
        ),
    );
    c.restore();
  }

  static void _panelDetails(Canvas c, PetPose view) {
    final side = view == PetPose.side;
    final pocket = switch (view) {
      PetPose.side =>
        Path()
          ..moveTo(69, 140)
          ..quadraticBezierTo(88, 131, 110, 133)
          ..lineTo(107, 152)
          ..quadraticBezierTo(85, 166, 68, 161)
          ..close(),
      PetPose.front =>
        Path()
          ..moveTo(66, 150)
          ..lineTo(100, 150)
          ..lineTo(98, 174)
          ..quadraticBezierTo(83, 182, 68, 174)
          ..close(),
      PetPose.back =>
        Path()
          ..moveTo(69, 154)
          ..lineTo(99, 155)
          ..lineTo(97, 180)
          ..quadraticBezierTo(83, 188, 70, 181)
          ..close(),
    };
    c.drawPath(pocket, Paint()..color = const Color(0x3766907F));
    _stroke(c, pocket, const Color(0xAE203F3A), 2.4);
    _stitch(c, pocket, const Color(0xB6A1B29C));
    if (!side && view == PetPose.front) {
      _button(c, const Offset(54, 146), 4.3);
      _button(c, const Offset(112, 146), 4.3);
    }
  }

  static void _neckline(Canvas c, PetNeck neck) {
    final binding = Path()
      ..moveTo(neck.left.dx, neck.left.dy + 6)
      ..quadraticBezierTo(
        (neck.left.dx + neck.right.dx) / 2,
        (neck.left.dy + neck.right.dy) / 2 + 23,
        neck.right.dx,
        neck.right.dy + 6,
      );
    _stroke(c, binding, const Color(0xFF234A44), 7);
    _stroke(c, binding.shift(const Offset(0, 1)), const Color(0xFF85A095), 1.3);
  }

  static void _button(Canvas c, Offset at, double radius) {
    c.drawCircle(
      at + const Offset(0, 1),
      radius + 0.8,
      Paint()..color = const Color(0xAA233833),
    );
    c.drawCircle(at, radius, Paint()..color = const Color(0xFFCFBB8A));
    c.drawCircle(at, radius - 1.2, Paint()..color = const Color(0xFFAA9466));
    for (final x in [-1.0, 1.0]) {
      c.drawCircle(
        at + Offset(x, 0),
        0.7,
        Paint()..color = const Color(0xFF534B39),
      );
    }
  }

  static void _shade(Canvas c, Path path, List<Color> colors) {
    final r = path.getBounds();
    c.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          r.topLeft,
          r.bottomRight,
          colors,
          List.generate(colors.length, (i) => i / (colors.length - 1)),
        ),
    );
  }

  static void _stitch(Canvas c, Path path, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 1.0; d < metric.length - 1.4; d += 4) {
        final a = metric.getTangentForOffset(d)!.position;
        final b = metric.getTangentForOffset(d + 1.4)!.position;
        c.drawLine(a, b, paint);
      }
    }
  }

  static void _stroke(Canvas c, Path path, Color color, double width) {
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _Projection {
  const _Projection(
    this.origin,
    this.pivot,
    this.head,
    this.neck,
    this.legs,
    this.view,
  );
  final Offset origin;
  final Offset pivot;
  final Offset head;
  final PetNeck neck;
  final List<_Leg> legs;
  final PetPose view;

  Path get body => switch (view) {
    PetPose.side =>
      Path()
        ..moveTo(neck.left.dx, neck.left.dy)
        ..cubicTo(139, 131, 71, 123, 46, 134)
        ..cubicTo(27, 143, 26, 166, 35, 190)
        ..cubicTo(48, 207, 72, 211, 90, 199)
        ..cubicTo(117, 177, 145, 217, 194, 204)
        ..cubicTo(226, 194, 232, 153, neck.right.dx, neck.right.dy)
        ..quadraticBezierTo(185, 102, neck.left.dx, neck.left.dy)
        ..close(),
    PetPose.front =>
      Path()
        ..moveTo(neck.left.dx, neck.left.dy)
        ..cubicTo(48, 129, 34, 159, 38, 184)
        ..cubicTo(41, 228, 123, 228, 128, 184)
        ..cubicTo(132, 158, 118, 128, neck.right.dx, neck.right.dy)
        ..quadraticBezierTo(83, 105, neck.left.dx, neck.left.dy)
        ..close(),
    PetPose.back =>
      Path()
        ..moveTo(neck.left.dx, neck.left.dy)
        ..cubicTo(55, 127, 41, 137, 39, 174)
        ..cubicTo(36, 214, 63, 227, 85, 214)
        ..cubicTo(113, 228, 132, 208, 132, 173)
        ..cubicTo(129, 138, 118, 129, neck.right.dx, neck.right.dy)
        ..quadraticBezierTo(85, 96, neck.left.dx, neck.left.dy)
        ..close(),
  };
}

class _Leg {
  const _Leg(this.root, this.thigh, this.shin, this.scale, this.rest);
  final Offset root;
  final double thigh;
  final double shin;
  final double scale;
  final (double, double) rest;

  _BentLeg solve((double, double) angles) {
    Offset segment(double length, double angle) =>
        Offset(math.sin(angle), math.cos(angle)) * length;
    final knee = root + segment(thigh, angles.$1);
    final foot = knee + segment(shin, angles.$2);
    return _BentLeg(root, knee, foot, angles.$2, scale);
  }
}

class _BentLeg {
  const _BentLeg(this.root, this.knee, this.foot, this.shinAngle, this.scale);
  final Offset root;
  final Offset knee;
  final Offset foot;
  final double shinAngle;
  final double scale;
}
