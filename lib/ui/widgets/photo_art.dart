import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Nombre visible (clave de traducción) de cada pack de fotos.
String photoPackLabel(String id) => switch (id) {
  'photo.basic' => 'Pegatinas básicas',
  'photo.party' => 'Fiesta',
  'photo.nature' => 'Naturaleza',
  'photo.bubbles' => 'Bocadillos de diálogo',
  'photo.frames_basic' => 'Marco sencillo',
  'photo.frames_color' => 'Marcos de colores',
  'photo.frames_luxury' => 'Marcos de lujo',
  'photo.text_basic' => 'Texto sencillo',
  'photo.text_styles' => 'Texto con estilos',
  _ => id,
};

/// Nombre visible (clave de traducción) de cada pieza de foto.
String photoPieceLabel(String id) => switch (id) {
  'sticker.heart' => 'Corazón',
  'sticker.star' => 'Estrella',
  'sticker.bone' => 'Hueso',
  'sticker.paw' => 'Huella',
  'sticker.smile' => 'Sonrisa',
  'sticker.balloon' => 'Globo',
  'sticker.cake' => 'Tarta',
  'sticker.party_hat' => 'Gorro de fiesta',
  'sticker.confetti' => 'Confeti',
  'sticker.gift' => 'Regalo',
  'sticker.flower' => 'Flor',
  'sticker.leaf' => 'Hoja',
  'sticker.sun' => 'Sol',
  'sticker.rainbow' => 'Arcoíris',
  'sticker.cloud' => 'Nube',
  'sticker.bubble_woof' => 'Bocadillo «¡Guau!»',
  'sticker.bubble_hello' => 'Bocadillo «¡Hola!»',
  'sticker.bubble_love' => 'Bocadillo «¡Te quiero!»',
  'sticker.bubble_yum' => 'Bocadillo «¡Ñam!»',
  'frame.none' => 'Sin marco',
  'frame.white' => 'Marco blanco',
  'frame.pink' => 'Marco rosa',
  'frame.sky' => 'Marco celeste',
  'frame.mint' => 'Marco menta',
  'frame.dots' => 'Marco de lunares',
  'frame.gold' => 'Marco dorado',
  'frame.polaroid' => 'Marco polaroid',
  'frame.stamp' => 'Marco de sello',
  'text.plain' => 'Texto simple',
  'text.outline' => 'Texto con borde',
  'text.ribbon' => 'Texto en cinta',
  _ => id,
};

/// Palabra (clave de traducción) que lleva un bocadillo; null si no es uno.
String? photoBubbleWord(String id) => switch (id) {
  'sticker.bubble_woof' => '¡Guau!',
  'sticker.bubble_hello' => '¡Hola!',
  'sticker.bubble_love' => '¡Te quiero!',
  'sticker.bubble_yum' => '¡Ñam!',
  _ => null,
};

/// Colores del texto de la foto (gratuitos con cualquier estilo).
const photoTextColors = <(String, Color)>[
  ('Blanco', Colors.white),
  ('Morado', AppColors.plum),
  ('Coral', AppColors.coral),
  ('Amarillo', AppColors.coin),
];

/// Pegatina colocada: centro normalizado (0..1 de la foto), escala y giro.
class PlacedSticker {
  PlacedSticker({
    required this.uid,
    required this.id,
    this.center = const Offset(.5, .45),
    this.scale = 1,
    this.rotation = 0,
  });
  final int uid;
  final String id;
  Offset center;
  double scale;
  double rotation;

  static const minScale = .4;
  static const maxScale = 3.0;

  /// Lado de una pegatina a escala 1 para una foto de [size].
  static double baseSide(Size size) => size.shortestSide * .22;
}

/// Capa de decoración de una foto: marco, texto y pegatinas. Todo vectorial
/// y empaquetado; el texto del jugador se pinta siempre como texto plano.
class PhotoDecoration {
  const PhotoDecoration({
    this.frame,
    this.stickers = const [],
    this.text = '',
    this.textStyle = 'text.plain',
    this.textColor = Colors.white,
    this.words = const {},
  });
  final String? frame;
  final List<PlacedSticker> stickers;
  final String text;
  final String textStyle;
  final Color textColor;

  /// Palabras ya traducidas de los bocadillos.
  final Map<String, String> words;

  /// Marco y texto (debajo de las pegatinas).
  void paintBase(Canvas canvas, Size size) {
    final f = frame;
    if (f != null) PhotoArt.paintFrame(canvas, size, f);
    if (text.isNotEmpty) {
      PhotoArt.paintCaption(
        canvas,
        size,
        text,
        style: textStyle,
        color: textColor,
        polaroid: f == 'frame.polaroid',
      );
    }
  }

  void paintStickers(Canvas canvas, Size size) {
    final base = PlacedSticker.baseSide(size);
    for (final s in stickers) {
      canvas.save();
      canvas.translate(s.center.dx * size.width, s.center.dy * size.height);
      canvas.rotate(s.rotation);
      PhotoArt.paintSticker(canvas, s.id, base * s.scale, word: words[s.id]);
      canvas.restore();
    }
  }

  /// Compone [photo] con la decoración y devuelve el PNG final.
  Future<Uint8List> compose(ui.Image photo) async {
    final size = Size(photo.width.toDouble(), photo.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photo, Offset.zero, Paint());
    paintBase(canvas, size);
    paintStickers(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(photo.width, photo.height);
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

/// Dibujos vectoriales de pegatinas, marcos y estilos de texto.
abstract final class PhotoArt {
  static const _outline = Colors.white;

  static Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Rellena [path] con el borde blanco típico de una pegatina.
  static void _sticker(Canvas c, Path path, Color color, double side) {
    c.drawPath(path, _stroke(_outline, side * .09));
    c.drawPath(path, _fill(color));
  }

  static Path _star(double r, double inner, {int points = 5}) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final o = Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  static Path _heart(double s) {
    final w = s * .42;
    return Path()
      ..moveTo(0, s * .36)
      ..cubicTo(-w * 1.6, -s * .02, -w * .9, -s * .5, 0, -s * .18)
      ..cubicTo(w * .9, -s * .5, w * 1.6, -s * .02, 0, s * .36)
      ..close();
  }

  static void _words(Canvas c, String word, Rect box, Color color) {
    var size = box.height * .55;
    TextPainter layout() => TextPainter(
      text: TextSpan(
        text: word,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    var tp = layout();
    if (tp.width > box.width) {
      size *= box.width / tp.width;
      tp.dispose();
      tp = layout();
    }
    tp.paint(c, box.center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }

  /// Dibuja la pegatina [id] centrada en el origen, en un cuadrado de [side].
  static void paintSticker(Canvas c, String id, double side, {String? word}) {
    final s = side;
    switch (id) {
      case 'sticker.heart':
        _sticker(c, _heart(s), AppColors.coral, s);
      case 'sticker.star':
        _sticker(c, _star(s * .46, .45), AppColors.coin, s);
      case 'sticker.bone':
        final bone = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: s * .6,
                height: s * .2,
              ),
              Radius.circular(s * .1),
            ),
          );
        for (final dx in [-.32, .32]) {
          for (final dy in [-.1, .1]) {
            bone.addOval(
              Rect.fromCircle(center: Offset(dx * s, dy * s), radius: s * .12),
            );
          }
        }
        _sticker(c, bone, AppColors.creamDeep, s);
      case 'sticker.paw':
        final paw = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(0, s * .14),
              width: s * .46,
              height: s * .38,
            ),
          );
        for (final (dx, dy) in [
          (-.3, -.06),
          (-.12, -.26),
          (.12, -.26),
          (.3, -.06),
        ]) {
          paw.addOval(
            Rect.fromCircle(center: Offset(dx * s, dy * s), radius: s * .1),
          );
        }
        _sticker(c, paw, AppColors.coinDeep, s);
      case 'sticker.smile':
        final face = Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: s * .42));
        _sticker(c, face, AppColors.coin, s);
        final ink = _fill(AppColors.ink);
        c.drawCircle(Offset(-s * .14, -s * .1), s * .05, ink);
        c.drawCircle(Offset(s * .14, -s * .1), s * .05, ink);
        c.drawArc(
          Rect.fromCircle(center: Offset(0, s * .02), radius: s * .22),
          .3,
          math.pi - .6,
          false,
          _stroke(AppColors.ink, s * .05),
        );
      case 'sticker.balloon':
        c.drawLine(
          Offset(0, s * .2),
          Offset(-s * .06, s * .48),
          _stroke(AppColors.inkSoft, s * .025),
        );
        final balloon = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(0, -s * .08),
              width: s * .56,
              height: s * .64,
            ),
          )
          ..addPolygon([
            Offset(-s * .05, s * .27),
            Offset(s * .05, s * .27),
            Offset(0, s * .2),
          ], true);
        _sticker(c, balloon, AppColors.coral, s);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(-s * .1, -s * .2),
            width: s * .1,
            height: s * .16,
          ),
          _fill(Colors.white.withValues(alpha: .6)),
        );
      case 'sticker.cake':
        final cake = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-s * .38, -s * .02, s * .76, s * .38),
              Radius.circular(s * .06),
            ),
          )
          ..addRect(Rect.fromLTWH(-s * .03, -s * .3, s * .06, s * .3));
        _sticker(c, cake, AppColors.plumSoft, s);
        c.drawRect(
          Rect.fromLTWH(-s * .38, s * .12, s * .76, s * .07),
          _fill(AppColors.coral),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0, -s * .37),
            width: s * .09,
            height: s * .15,
          ),
          _fill(AppColors.coin),
        );
      case 'sticker.party_hat':
        final hat = Path()
          ..moveTo(0, -s * .38)
          ..lineTo(s * .3, s * .36)
          ..lineTo(-s * .3, s * .36)
          ..close();
        _sticker(c, hat, AppColors.lavender, s);
        c.save();
        c.clipPath(hat);
        final stripe = _stroke(AppColors.coin, s * .07);
        for (var i = -2; i <= 2; i++) {
          c.drawLine(
            Offset(-s * .4, i * s * .2),
            Offset(s * .4, i * s * .2 - s * .2),
            stripe,
          );
        }
        c.restore();
        c.drawCircle(Offset(0, -s * .4), s * .08, _fill(AppColors.coral));
      case 'sticker.confetti':
        const colors = [
          AppColors.coral,
          AppColors.coin,
          AppColors.lavender,
          AppColors.leaf,
          AppColors.hygiene,
        ];
        for (var i = 0; i < 9; i++) {
          final a = i * 2.4;
          final r = s * (.12 + (i % 3) * .12);
          c.save();
          c.translate(math.cos(a) * r, math.sin(a) * r);
          c.rotate(a);
          final piece = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * .14,
              height: s * .07,
            ),
            Radius.circular(s * .02),
          );
          c.drawRRect(piece.inflate(s * .02), _fill(_outline));
          c.drawRRect(piece, _fill(colors[i % colors.length]));
          c.restore();
        }
      case 'sticker.gift':
        final box = Path()
          ..addRect(Rect.fromLTWH(-s * .34, -s * .12, s * .68, s * .48));
        _sticker(c, box, AppColors.hygiene, s);
        final ribbon = _fill(AppColors.coin);
        c.drawRect(Rect.fromLTWH(-s * .05, -s * .12, s * .1, s * .48), ribbon);
        c.drawRect(Rect.fromLTWH(-s * .34, s * .06, s * .68, s * .09), ribbon);
        for (final dx in [-1.0, 1.0]) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(dx * s * .12, -s * .2),
              width: s * .22,
              height: s * .14,
            ),
            _stroke(AppColors.coin, s * .06),
          );
        }
      case 'sticker.flower':
        final petals = Path();
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          petals.addOval(
            Rect.fromCircle(
              center: Offset(math.cos(a) * s * .2, math.sin(a) * s * .2),
              radius: s * .17,
            ),
          );
        }
        _sticker(c, petals, AppColors.mood, s);
        c.drawCircle(Offset.zero, s * .13, _fill(AppColors.coin));
      case 'sticker.leaf':
        final leaf = Path()
          ..moveTo(-s * .36, s * .36)
          ..quadraticBezierTo(-s * .4, -s * .3, s * .38, -s * .38)
          ..quadraticBezierTo(s * .3, s * .32, -s * .36, s * .36)
          ..close();
        _sticker(c, leaf, AppColors.energy, s);
        c.drawLine(
          Offset(-s * .3, s * .3),
          Offset(s * .26, -s * .26),
          _stroke(AppColors.leafSoft, s * .03),
        );
      case 'sticker.sun':
        final rays = _star(s * .48, .7, points: 12);
        _sticker(c, rays, AppColors.satiety, s);
        c.drawCircle(Offset.zero, s * .26, _fill(AppColors.coin));
      case 'sticker.rainbow':
        const bands = [
          AppColors.coral,
          AppColors.satiety,
          AppColors.coin,
          AppColors.energy,
          AppColors.hygiene,
        ];
        final w = s * .07;
        c.drawArc(
          Rect.fromCircle(center: Offset(0, s * .2), radius: s * .4),
          math.pi,
          math.pi,
          false,
          _stroke(_outline, w * bands.length + s * .08),
        );
        for (var i = 0; i < bands.length; i++) {
          c.drawArc(
            Rect.fromCircle(
              center: Offset(0, s * .2),
              radius: s * .4 - i * w + w * 2,
            ),
            math.pi,
            math.pi,
            false,
            _stroke(bands[i], w)..strokeCap = StrokeCap.butt,
          );
        }
      case 'sticker.cloud':
        final cloud = Path()
          ..addOval(
            Rect.fromCircle(center: Offset(-s * .18, s * .06), radius: s * .17),
          )
          ..addOval(
            Rect.fromCircle(center: Offset(s * .02, -s * .08), radius: s * .22),
          )
          ..addOval(
            Rect.fromCircle(center: Offset(s * .22, s * .06), radius: s * .16),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-s * .34, s * .02, s * .68, s * .2),
              Radius.circular(s * .1),
            ),
          );
        c.drawPath(cloud, _stroke(AppColors.hygiene, s * .05));
        c.drawPath(cloud, _fill(Colors.white));
      default:
        if (id.startsWith('sticker.bubble_')) {
          final body = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -s * .06),
              width: s,
              height: s * .5,
            ),
            Radius.circular(s * .2),
          );
          final bubble = Path()
            ..addRRect(body)
            ..addPolygon([
              Offset(-s * .2, s * .16),
              Offset(-s * .3, s * .4),
              Offset(-s * .02, s * .18),
            ], true);
          c.drawPath(bubble, _stroke(AppColors.ink, s * .04));
          c.drawPath(bubble, _fill(Colors.white));
          _words(
            c,
            word ?? photoBubbleWord(id) ?? '',
            body.outerRect.deflate(s * .08),
            AppColors.plum,
          );
        } else {
          c.drawCircle(Offset.zero, s * .3, _fill(AppColors.disabled));
        }
    }
  }

  /// Dibuja el marco [id] sobre una foto de [size].
  static void paintFrame(Canvas c, Size size, String id) {
    final rect = Offset.zero & size;
    final w = size.shortestSide * .05;
    void band(Paint p, {double? bottom}) {
      final inner = Rect.fromLTRB(
        w,
        w,
        size.width - w,
        size.height - (bottom ?? w),
      );
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect)
        ..addRRect(RRect.fromRectAndRadius(inner, Radius.circular(w * .6)));
      c.drawPath(path, p);
    }

    switch (id) {
      case 'frame.white':
        band(_fill(Colors.white));
      case 'frame.pink':
        band(_fill(AppColors.mood));
      case 'frame.sky':
        band(_fill(AppColors.hygiene));
      case 'frame.mint':
        band(_fill(AppColors.energy));
      case 'frame.dots':
        band(_fill(AppColors.cream));
        const colors = [AppColors.coral, AppColors.coin, AppColors.lavender];
        var i = 0;
        final step = w * 1.6;
        for (var x = w / 2; x < size.width; x += step) {
          for (final y in [w / 2, size.height - w / 2]) {
            c.drawCircle(Offset(x, y), w * .28, _fill(colors[i++ % 3]));
          }
        }
        for (var y = w / 2 + step; y < size.height - step; y += step) {
          for (final x in [w / 2, size.width - w / 2]) {
            c.drawCircle(Offset(x, y), w * .28, _fill(colors[i++ % 3]));
          }
        }
      case 'frame.gold':
        band(
          Paint()
            ..shader = ui.Gradient.linear(
              rect.topLeft,
              rect.bottomRight,
              const [
                Color(0xFFB8862B),
                Color(0xFFF6D77A),
                Color(0xFFB8862B),
                Color(0xFFF1CB63),
              ],
              const [0, .35, .7, 1],
            ),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(w * 1.15),
            Radius.circular(w * .5),
          ),
          _stroke(const Color(0xFF8A5A1C), w * .12),
        );
      case 'frame.polaroid':
        band(_fill(const Color(0xFFFDFBF6)), bottom: size.height * .18);
      case 'frame.stamp':
        band(_fill(Colors.white));
        final hole = _fill(AppColors.ink);
        final r = w * .3;
        final step = r * 3;
        for (var x = 0.0; x <= size.width; x += step) {
          c.drawCircle(Offset(x, 0), r, hole);
          c.drawCircle(Offset(x, size.height), r, hole);
        }
        for (var y = 0.0; y <= size.height; y += step) {
          c.drawCircle(Offset(0, y), r, hole);
          c.drawCircle(Offset(size.width, y), r, hole);
        }
        c.drawRect(rect.deflate(w * .75), _stroke(AppColors.coral, w * .08));
    }
  }

  /// Pinta [text] como texto plano en la parte inferior de la foto.
  static void paintCaption(
    Canvas c,
    Size size,
    String text, {
    required String style,
    required Color color,
    bool polaroid = false,
    double? centerY,
    double? fontSize,
  }) {
    var font = fontSize ?? size.shortestSide * .085;
    final maxWidth = size.width * .8;
    final dark = color.computeLuminance() < .4;
    TextPainter layout({Paint? foreground}) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: foreground == null ? color : null,
          foreground: foreground,
          fontSize: font,
          fontWeight: FontWeight.w900,
          height: 1.1,
          shadows: style == 'text.plain' && !polaroid
              ? [
                  Shadow(
                    color: dark ? Colors.white70 : Colors.black54,
                    blurRadius: font * .15,
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    var tp = layout();
    if (tp.width > maxWidth) {
      font *= maxWidth / tp.width;
      tp.dispose();
      tp = layout();
    }
    final y =
        centerY ??
        (polaroid
            ? size.height - size.height * .09
            : size.height - size.shortestSide * .14);
    final origin = Offset((size.width - tp.width) / 2, y - tp.height / 2);
    switch (style) {
      case 'text.outline':
        final border = layout(
          foreground: _stroke(dark ? Colors.white : AppColors.ink, font * .16),
        );
        border.paint(c, origin);
        border.dispose();
      case 'text.ribbon':
        final box = (origin & tp.size).inflate(font * .3);
        final ribbon = Path()
          ..moveTo(box.left - font * .4, box.top)
          ..lineTo(box.right + font * .4, box.top)
          ..lineTo(box.right, box.center.dy)
          ..lineTo(box.right + font * .4, box.bottom)
          ..lineTo(box.left - font * .4, box.bottom)
          ..lineTo(box.left, box.center.dy)
          ..close();
        c.drawPath(ribbon, _fill(dark ? AppColors.cream : AppColors.plum));
    }
    tp.paint(c, origin);
    tp.dispose();
  }

  /// Muestra de un estilo de texto para su ficha.
  static void paintTextSample(Canvas c, Size size, String style) {
    paintCaption(
      c,
      size,
      'Aa',
      style: style,
      color: AppColors.coral,
      centerY: size.height / 2,
      fontSize: size.shortestSide * .45,
    );
  }
}
