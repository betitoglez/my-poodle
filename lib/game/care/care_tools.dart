import 'dart:math' as math;
import 'dart:ui';

enum CareTool {
  shower,
  sponge,
  dryer,
  comb,
  scissors,
  stethoscope,
  magnifier,
  pill,
  nailClippers,
  curler,
  salts,
  massage,
}

/// Herramientas vectoriales que siguen al dedo, independientes de fuentes.
void paintCareTool(
  Canvas c,
  CareTool tool,
  Offset at,
  double size,
  double time, [
  Image? atlas,
]) {
  if (atlas != null) {
    final extras = tool.index >= CareTool.nailClippers.index;
    final columns = extras ? 2 : 3;
    final index = extras
        ? tool.index - CareTool.nailClippers.index
        : tool.index;
    final tile = atlas.width / columns;
    c.drawImageRect(
      atlas,
      Rect.fromLTWH(
        index % columns * tile,
        index ~/ columns * tile,
        tile,
        tile,
      ),
      Rect.fromCenter(center: at, width: size * 1.20, height: size * 1.20),
      Paint()..filterQuality = FilterQuality.medium,
    );
    return;
  }
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(size / 48);
  final ink = Paint()
    ..color = const Color(0xFF4D405B)
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  void box(Rect r, Color color, [double radius = 5]) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = color);
    c.drawRRect(rr, ink);
  }

  switch (tool) {
    case CareTool.shower:
      c.drawPath(
        Path()
          ..moveTo(18, 18)
          ..quadraticBezierTo(32, 32, 20, 43),
        ink..strokeWidth = 3,
      );
      box(const Rect.fromLTWH(-2, -9, 27, 13), const Color(0xFF91BDC6));
      box(const Rect.fromLTWH(15, 1, 9, 23), const Color(0xFFE5D4E4), 3);
    case CareTool.sponge:
      box(const Rect.fromLTWH(-18, -11, 36, 24), const Color(0xFFEACB75), 9);
      for (var i = 0; i < 7; i++) {
        c.drawCircle(
          Offset(-11 + i % 4 * 7, -4 + i ~/ 4 * 10),
          1.6,
          Paint()..color = const Color(0xFFC39C4C),
        );
      }
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(-19 + i * 10, -14),
          4,
          Paint()..color = const Color(0xCCFFFFFF),
        );
      }
    case CareTool.dryer:
      box(const Rect.fromLTWH(-15, -10, 29, 20), const Color(0xFFCF8CA3), 10);
      box(const Rect.fromLTWH(10, -7, 14, 14), const Color(0xFFE8B4BC), 3);
      box(const Rect.fromLTWH(-9, 8, 10, 21), const Color(0xFFAE758D), 3);
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromLTWH(28, -9 + i * 7, 20, 7),
          math.pi,
          math.pi,
          false,
          ink
            ..color = const Color(0xBBF4D8A4)
            ..strokeWidth = 2,
        );
      }
    case CareTool.comb:
      box(const Rect.fromLTWH(-19, -10, 38, 10), const Color(0xFFAB96C4), 4);
      for (var i = 0; i < 8; i++) {
        c.drawLine(
          Offset(-16 + i * 4.5, 0),
          Offset(-16 + i * 4.5, 15),
          ink
            ..color = const Color(0xFF78628F)
            ..strokeWidth = 2.5,
        );
      }
    case CareTool.scissors:
      final open = math.sin(time * 8) * 0.12;
      for (final sign in [-1.0, 1.0]) {
        c.save();
        c.rotate(sign * (0.3 + open));
        c.drawOval(
          const Rect.fromLTWH(-7, 5, 14, 16),
          ink
            ..color = const Color(0xFF916BA3)
            ..strokeWidth = 3,
        );
        c.drawLine(
          const Offset(0, 5),
          Offset(sign * 5, -23),
          ink
            ..color = const Color(0xFFAFB6C5)
            ..strokeWidth = 4,
        );
        c.restore();
      }
      c.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFF5D526E));
    case CareTool.stethoscope:
      c.drawPath(
        Path()
          ..moveTo(-20, -22)
          ..cubicTo(-32, 25, 34, 30, 8, -5),
        ink
          ..color = const Color(0xFF54697C)
          ..strokeWidth = 3,
      );
      c.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xFFBDC6CF));
      c.drawCircle(
        Offset.zero,
        9,
        ink
          ..color = const Color(0xFF748598)
          ..strokeWidth = 2,
      );
      c.drawCircle(
        const Offset(-3, -3),
        3,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    case CareTool.magnifier:
      c.drawCircle(Offset.zero, 15, Paint()..color = const Color(0x447BC4DA));
      c.drawCircle(
        Offset.zero,
        15,
        ink
          ..color = const Color(0xFF9E7E54)
          ..strokeWidth = 4,
      );
      c.drawLine(
        const Offset(11, 11),
        const Offset(25, 26),
        ink
          ..color = const Color(0xFF735A49)
          ..strokeWidth = 7,
      );
      c.drawArc(
        const Rect.fromLTWH(-10, -10, 20, 20),
        3.5,
        1.2,
        false,
        ink
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = 2,
      );
    case CareTool.pill:
      c.rotate(-0.5);
      box(const Rect.fromLTWH(-17, -8, 34, 16), const Color(0xFFFFF9ED), 8);
      c.save();
      c.clipRect(const Rect.fromLTWH(-17, -8, 17, 16));
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-17, -8, 34, 16),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFD9838E),
      );
      c.restore();
    case CareTool.nailClippers:
      c.drawPath(
        Path()
          ..moveTo(-13, -15)
          ..quadraticBezierTo(-11, -28, 1, -19)
          ..quadraticBezierTo(7, -27, 16, -16)
          ..lineTo(7, 3)
          ..lineTo(-7, 3)
          ..close(),
        Paint()..color = const Color(0xff9cacbb),
      );
      for (final side in [-1.0, 1.0]) {
        c.save();
        c.rotate(side * .35);
        box(const Rect.fromLTWH(-6, 1, 12, 24), const Color(0xff438f84));
        c.restore();
      }
      c.drawCircle(
        const Offset(0, -2),
        3,
        Paint()..color = const Color(0xffdddfe2),
      );
    case CareTool.curler:
      c.rotate(.46);
      box(const Rect.fromLTWH(-5, -24, 10, 31), const Color(0xfff0dbbb), 4);
      box(const Rect.fromLTWH(-7, 5, 14, 20), const Color(0xff9c79ae), 5);
      c.drawCircle(
        const Offset(0, 13),
        2,
        Paint()..color = const Color(0xffdcf8d7),
      );
    case CareTool.salts:
      box(const Rect.fromLTWH(-15, -12, 30, 30), const Color(0xffedc6d2), 7);
      box(const Rect.fromLTWH(-12, -19, 24, 8), const Color(0xffecc8a7), 3);
      for (var i = 0; i < 13; i++) {
        c.drawCircle(
          Offset(-10 + (i * 7 % 20).toDouble(), (i * 11 % 18).toDouble() - 5),
          1.5,
          Paint()..color = const Color(0xfffaece1),
        );
      }
    case CareTool.massage:
      for (final (x, y, width) in [(-8.0, 9.0, 27.0), (7.0, -5.0, 22.0)]) {
        final stone = Rect.fromCenter(
          center: Offset(x, y),
          width: width,
          height: 14,
        );
        c.drawOval(stone, Paint()..color = const Color(0xff555169));
        c.drawArc(
          stone.deflate(3),
          3.35,
          1.45,
          false,
          ink
            ..color = const Color(0xffaaa1ae)
            ..strokeWidth = 1.8,
        );
      }
  }
  c.restore();
}
