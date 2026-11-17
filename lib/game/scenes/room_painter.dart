import 'dart:math' as math;
import 'dart:ui';

/// Escenarios vectoriales provisionales. Cada sala usa su paleta para
/// reconocer la actividad: casa crema y madera, baño lavanda, exteriores
/// verdes. Sustituibles por ilustraciones finales con el mismo encuadre.
enum RoomKind { living, kitchen, bath, salon, wardrobe, nursery }

/// Ilustración de sala con el punto de apoyo del caniche en coordenadas
/// relativas de la imagen y su altura relativa. Generadas con Meshy
/// (image-to-image) a partir de las referencias de docs/arte.
class RoomArt {
  const RoomArt(this.asset, this.feet, this.petHeight);
  final String asset;
  final Offset feet;
  final double petHeight;

  static const Map<RoomKind, RoomArt> of = {
    RoomKind.living: RoomArt('rooms/living.jpg', Offset(0.5, 0.8), 0.42),
    RoomKind.kitchen: RoomArt('rooms/kitchen.jpg', Offset(0.48, 0.8), 0.42),
    RoomKind.bath: RoomArt('rooms/bath.jpg', Offset(0.5, 0.78), 0.42),
    RoomKind.salon: RoomArt('rooms/salon.jpg', Offset(0.36, 0.9), 0.42),
    RoomKind.wardrobe: RoomArt('rooms/wardrobe.jpg', Offset(0.45, 0.86), 0.54),
    RoomKind.nursery: RoomArt('rooms/nursery.jpg', Offset(0.52, 0.69), 0.4),
  };
}

class RoomPainter {
  static Paint _p(int c) => Paint()..color = Color(c);

  /// [floorY] es la altura (0..1) donde empieza el suelo.
  static void paint(
    Canvas c,
    Size s,
    RoomKind kind, {
    double floorY = 0.8,
    double t = 0,
  }) {
    switch (kind) {
      case RoomKind.living:
        _wall(c, s, floorY, 0xFFF6E7CC, 0xFFEBD6B4);
        _arch(
          c,
          Rect.fromLTWH(
            s.width * 0.08,
            s.height * 0.08,
            s.width * 0.34,
            s.height * (floorY - 0.2),
          ),
          t,
        );
        _arch(
          c,
          Rect.fromLTWH(
            s.width * 0.58,
            s.height * 0.08,
            s.width * 0.34,
            s.height * (floorY - 0.2),
          ),
          t,
        );
        _wood(c, s, floorY);
        _rug(c, s, floorY, 0xFFD9C6A0, 0xFF8FA98A);
        _plant(c, Offset(s.width * 0.92, s.height * floorY), s.height * 0.22);
      case RoomKind.nursery:
        _wall(c, s, floorY, 0xFFF3E3CB, 0xFFE6CFAF);
        _arch(
          c,
          Rect.fromLTWH(
            s.width * 0.55,
            s.height * 0.06,
            s.width * 0.38,
            s.height * (floorY - 0.18),
          ),
          t,
        );
        _wood(c, s, floorY);
        _flowers(
          c,
          Offset(s.width * 0.13, s.height * (floorY - 0.06)),
          s.height * 0.16,
        );
      case RoomKind.kitchen:
        _wall(c, s, floorY, 0xFFF1E4CF, 0xFFE2D2B6);
        // Encimera y alacenas.
        final top = s.height * (floorY - 0.28);
        c.drawRect(
          Rect.fromLTWH(0, top, s.width, s.height * 0.05),
          _p(0xFFE9DCC6),
        );
        c.drawRect(
          Rect.fromLTWH(0, top + s.height * 0.05, s.width, s.height * 0.23),
          _p(0xFFCFC3A2),
        );
        for (var i = 0; i < 4; i++) {
          final r = Rect.fromLTWH(
            s.width * (0.03 + i * 0.25),
            top + s.height * 0.07,
            s.width * 0.21,
            s.height * 0.19,
          );
          c.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)),
            _p(0xFFDCD2B3),
          );
          c.drawCircle(
            r.topRight + Offset(-10, r.height / 2),
            3,
            _p(0xFFA38B5B),
          );
        }
        // Cazos de cobre.
        for (var i = 0; i < 3; i++) {
          c.drawCircle(
            Offset(s.width * (0.6 + i * 0.12), s.height * 0.15),
            s.width * 0.04,
            _p(0xFFC87A45),
          );
        }
        c.drawRect(
          Rect.fromLTWH(s.width * 0.55, s.height * 0.09, s.width * 0.4, 4),
          _p(0xFFB18A3E),
        );
        _checker(c, s, floorY, 0xFFF4E8E1, 0xFFDDA3A6);
      case RoomKind.bath:
        _wall(c, s, floorY, 0xFFE7DDF1, 0xFFD5C6E6);
        _arch(
          c,
          Rect.fromLTWH(
            s.width * 0.62,
            s.height * 0.06,
            s.width * 0.3,
            s.height * (floorY - 0.3),
          ),
          t,
        );
        // Azulejos.
        final tile = Paint()
          ..color = const Color(0x22FFFFFF)
          ..style = PaintingStyle.stroke;
        for (var y = s.height * 0.45; y < s.height * floorY; y += 22) {
          c.drawLine(Offset(0, y), Offset(s.width, y), tile);
        }
        c.drawRect(
          Rect.fromLTWH(0, s.height * floorY, s.width, s.height * (1 - floorY)),
          _p(0xFFCDBEDF),
        );
        _lavender(
          c,
          Offset(s.width * 0.1, s.height * (floorY + 0.02)),
          s.height * 0.2,
          t,
        );
        _bubbles(c, s, t);
      case RoomKind.salon:
        _wall(c, s, floorY, 0xFFE9E6D3, 0xFFD8D3B8);
        _wood(c, s, floorY);
        // Lámpara.
        c.drawLine(
          Offset(s.width * 0.3, 0),
          Offset(s.width * 0.3, s.height * 0.1),
          _p(0xFFB18A3E)..strokeWidth = 3,
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(s.width * 0.3, s.height * 0.12),
            width: 40,
            height: 26,
          ),
          _p(0xFFF7E3B5),
        );
      case RoomKind.wardrobe:
        _wall(c, s, floorY, 0xFFF2CDBD, 0xFFE6B8A6);
        // Perchero con ropa.
        final rail = s.height * 0.14;
        c.drawLine(
          Offset(s.width * 0.04, rail),
          Offset(s.width * 0.42, rail),
          _p(0xFFB18A3E)..strokeWidth = 4,
        );
        const colors = [
          0xFFE9D7C3,
          0xFF9C5B6E,
          0xFF7E9C8C,
          0xFFE3C07A,
          0xFFC98B8E,
        ];
        for (var i = 0; i < 5; i++) {
          final x = s.width * (0.07 + i * 0.07);
          final path = Path()
            ..moveTo(x - 14, rail + 10)
            ..lineTo(x + 14, rail + 10)
            ..lineTo(x + 18, rail + s.height * 0.22)
            ..lineTo(x - 18, rail + s.height * 0.22)
            ..close();
          c.drawPath(path, _p(colors[i]));
        }
        _mirror(
          c,
          Rect.fromLTWH(
            s.width * 0.66,
            s.height * 0.08,
            s.width * 0.26,
            s.height * (floorY - 0.14),
          ),
        );
        _wood(c, s, floorY);
        _rug(c, s, floorY, 0xFFF0DCCF, 0xFFD7A1A0);
    }
  }

  static void _wall(Canvas c, Size s, double floorY, int top, int bottom) {
    final r = Rect.fromLTWH(0, 0, s.width, s.height * floorY);
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(r.topCenter, r.bottomCenter, [
          Color(top),
          Color(bottom),
        ]),
    );
    // Moldura.
    c.drawRect(
      Rect.fromLTWH(0, s.height * floorY - 8, s.width, 8),
      _p(0xFFE4D1AE),
    );
  }

  static void _wood(Canvas c, Size s, double floorY) {
    final y0 = s.height * floorY;
    c.drawRect(Rect.fromLTWH(0, y0, s.width, s.height - y0), _p(0xFFC69C6D));
    final line = Paint()
      ..color = const Color(0x339A6B3F)
      ..strokeWidth = 2;
    for (var y = y0 + 14; y < s.height; y += 18) {
      c.drawLine(Offset(0, y), Offset(s.width, y), line);
    }
  }

  static void _checker(Canvas c, Size s, double floorY, int a, int b) {
    final y0 = s.height * floorY;
    const n = 8;
    final w = s.width / n;
    for (var row = 0; y0 + row * w * 0.5 < s.height; row++) {
      for (var i = 0; i < n; i++) {
        c.drawRect(
          Rect.fromLTWH(i * w, y0 + row * w * 0.5, w, w * 0.5),
          _p((i + row).isEven ? a : b),
        );
      }
    }
  }

  static void _rug(Canvas c, Size s, double floorY, int fill, int border) {
    final r = Rect.fromCenter(
      center: Offset(s.width * 0.5, s.height * (floorY + (1 - floorY) * 0.42)),
      width: s.width * 0.8,
      height: s.height * (1 - floorY) * 0.55,
    );
    c.drawOval(r, _p(border));
    c.drawOval(r.deflate(6), _p(fill));
  }

  static void _arch(Canvas c, Rect r, double t) {
    final path = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + r.width / 2)
      ..arcToPoint(
        Offset(r.right, r.top + r.width / 2),
        radius: Radius.circular(r.width / 2),
      )
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(path, _p(0xFFFFFFFF));
    c.save();
    c.clipPath(path);
    final sky = r.deflate(5);
    c.drawRect(
      sky,
      Paint()
        ..shader = Gradient.linear(sky.topCenter, sky.bottomCenter, [
          const Color(0xFFAFD4F0),
          const Color(0xFFEAF3E4),
        ]),
    );
    // Colinas toscanas y cipreses.
    c.drawOval(
      Rect.fromLTWH(
        sky.left - 20,
        sky.bottom - sky.height * 0.28,
        sky.width * 0.9,
        sky.height * 0.5,
      ),
      _p(0xFF9DB77F),
    );
    c.drawOval(
      Rect.fromLTWH(
        sky.left + sky.width * 0.3,
        sky.bottom - sky.height * 0.22,
        sky.width,
        sky.height * 0.5,
      ),
      _p(0xFF7FA06A),
    );
    for (var i = 0; i < 3; i++) {
      final x = sky.left + sky.width * (0.25 + i * 0.22);
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, sky.bottom - sky.height * 0.3),
          width: 8,
          height: sky.height * 0.22,
        ),
        _p(0xFF3F6A4A),
      );
    }
    final cloudX = sky.left + ((t * 6) % (sky.width + 60)) - 30;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cloudX, sky.top + sky.height * 0.22),
        width: 46,
        height: 16,
      ),
      _p(0xEEFFFFFF),
    );
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD9C3A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    c.drawLine(
      Offset(r.center.dx, r.top + 6),
      Offset(r.center.dx, r.bottom),
      _p(0xFFD9C3A0)..strokeWidth = 4,
    );
  }

  static void _mirror(Canvas c, Rect r) {
    final frame = RRect.fromRectAndRadius(r, Radius.circular(r.width / 2));
    c.drawRRect(frame, _p(0xFFC9A54D));
    final glass = RRect.fromRectAndRadius(
      r.deflate(7),
      Radius.circular(r.width / 2 - 7),
    );
    c.drawRRect(
      glass,
      Paint()
        ..shader = Gradient.linear(r.topLeft, r.bottomRight, [
          const Color(0xFFEFF3F2),
          const Color(0xFFC8D6D6),
        ]),
    );
    c.drawLine(
      r.topLeft + Offset(r.width * 0.3, r.height * 0.25),
      r.topLeft + Offset(r.width * 0.55, r.height * 0.1),
      _p(0x88FFFFFF)..strokeWidth = 5,
    );
  }

  /// Espejo de peluquería (expuesto para dibujar el reflejo encima).
  static Rect salonMirror(Size s, double floorY) => Rect.fromLTWH(
    s.width * 0.66,
    s.height * 0.1,
    s.width * 0.28,
    s.height * (floorY - 0.12),
  );

  static void paintSalonMirror(Canvas c, Size s, double floorY) =>
      _mirror(c, salonMirror(s, floorY));

  static void _plant(Canvas c, Offset base, double h) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + Offset(0, -h * 0.15),
          width: h * 0.35,
          height: h * 0.3,
        ),
        const Radius.circular(6),
      ),
      _p(0xFFC77D55),
    );
    final leaf = _p(0xFF5E8A5C);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * 0.35;
      c.drawOval(
        Rect.fromCenter(
          center:
              base +
              Offset(math.cos(a) * h * 0.35, -h * 0.3 + math.sin(a) * h * 0.4),
          width: h * 0.16,
          height: h * 0.3,
        ),
        leaf,
      );
    }
  }

  static void _flowers(Canvas c, Offset base, double h) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: h * 0.4, height: h * 0.45),
        const Radius.circular(8),
      ),
      _p(0xFFE8E3DA),
    );
    const colors = [0xFFF2A7B5, 0xFFF6C7D0, 0xFFE58FA0];
    for (var i = 0; i < 7; i++) {
      c.drawCircle(
        base + Offset((i - 3) * h * 0.08, -h * 0.35 - (i % 2) * h * 0.08),
        h * 0.09,
        _p(colors[i % 3]),
      );
    }
  }

  static void _lavender(Canvas c, Offset base, double h, double t) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: h * 0.4, height: h * 0.4),
        const Radius.circular(6),
      ),
      _p(0xFFC9935F),
    );
    for (var i = 0; i < 6; i++) {
      final x = base.dx + (i - 2.5) * h * 0.07;
      final sway = math.sin(t * 1.5 + i) * 3;
      c.drawLine(
        Offset(x, base.dy - h * 0.2),
        Offset(x + sway, base.dy - h * 0.8),
        _p(0xFF6B8A57)..strokeWidth = 2,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + sway, base.dy - h * 0.82),
          width: 8,
          height: h * 0.25,
        ),
        _p(0xFF9A7CC8),
      );
    }
  }

  static void _bubbles(Canvas c, Size s, double t) {
    final p = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 9; i++) {
      final x = s.width * ((i * 0.137 + 0.05) % 1);
      final y = s.height * (0.7 - ((t * 0.05 + i * 0.11) % 0.7));
      c.drawCircle(Offset(x, y), 4 + (i % 3) * 3, p);
    }
  }
}
