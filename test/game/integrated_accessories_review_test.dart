import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/pet/pet_sprites.dart';

import '../support.dart';

const out = 'docs/reviews/integrated-pilot';
const coats = [
  ('coat.apricot', 'Albaricoque'),
  ('coat.white', 'Blanco'),
  ('coat.black', 'Negro'),
];
const views = [
  (PetPose.front, PetAnim.idle, 1.0, 'Frente'),
  (PetPose.side, PetAnim.idle, 1.0, 'Perfil'),
  (PetPose.side, PetAnim.run, 0.0, 'Carrera · recogida'),
  (PetPose.side, PetAnim.run, 1 / 9, 'Carrera · extensión'),
  (PetPose.side, PetAnim.run, 2 / 9, 'Carrera · vuelo'),
  (PetPose.back, PetAnim.idle, 1.0, 'Espalda'),
];
const articles = [
  (Slot.head, 'head.beanie', 'Gorro de lana', 'beanie'),
  (Slot.outfit, 'outfit.sweater_red', 'Jersey', 'sweater'),
  (Slot.neck, 'neck.coral', 'Pañuelo', 'bandana'),
];

void label(
  ui.Canvas c,
  String text,
  ui.Offset at,
  double size, {
  ui.Color color = const ui.Color(0xFF423A41),
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Review', fontSize: size, color: color),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  painter.paint(c, at);
}

Future<ui.Image> dog(
  PetPainter painter,
  Appearance a,
  PetPose pose,
  PetAnim anim,
  double time, {
  bool integrated = true,
  double width = 280,
  double height = 330,
}) async {
  painter.integratedPilot = integrated;
  await painter.warm(a, poses: [painter.spritePoseName(pose, anim, time)]);
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.translate(width / 2, height - 32);
  painter.paint(
    c,
    painter.catalog.resolve(a),
    pose: pose,
    anim: anim,
    t: time,
    size: pose == PetPose.side ? 223 : 238,
  );
  final pic = rec.endRecording();
  final img = await pic.toImage(width.round(), height.round());
  pic.dispose();
  return img;
}

Future<void> export(
  ui.PictureRecorder rec,
  int width,
  int height,
  String filename,
) async {
  final picture = rec.endRecording();
  final bitmap = await picture.toImage(width, height);
  final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
  expect(png, isNotNull);
  if (Platform.environment['POODLE_REVIEW'] == '1') {
    Directory(out).createSync(recursive: true);
    File('$out/$filename.png').writeAsBytesSync(png!.buffer.asUint8List());
  }
  bitmap.dispose();
  picture.dispose();
}

Future<void> captureNeckAccessories(PetPainter painter, Appearance base) async {
  const items = [
    (Slot.neck, 'neck.coral', 'Pañuelo coral'),
    (Slot.neck, 'neck.knit', 'Pañuelo de punto'),
    (Slot.neck, 'neck.bowtie', 'Pajarita'),
    (Slot.collar, 'collar.tag', 'Collar con chapa'),
    (Slot.collar, 'collar.bell', 'Collar con cascabel'),
    (Slot.collar, 'collar.pearls', 'Collar de perlas'),
  ];
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.drawColor(const ui.Color(0xFFF3EDE5), ui.BlendMode.src);
  label(canvas, 'Accesorios del cuello', const ui.Offset(24, 20), 25);
  final previews = <ui.Image>[];
  for (final (row, (slot, id, name)) in items.indexed) {
    final appearance = base
        .withSlot(Slot.coat, 'coat.white')
        .withSlot(slot, id);
    for (final (column, view) in [views[0], views[1], views.last].indexed) {
      final image = await dog(painter, appearance, view.$1, view.$2, view.$3);
      previews.add(image);
      const panelWidth = 280.0, panelHeight = 206.0;
      final at = ui.Offset(column * panelWidth, row * panelHeight + 70);
      canvas.drawImageRect(
        image,
        const ui.Rect.fromLTWH(0, 41, 280, 178),
        ui.Rect.fromLTWH(at.dx, at.dy, panelWidth, 178),
        ui.Paint(),
      );
      label(canvas, '$name · ${view.$4}', at + const ui.Offset(18, 183), 14);
    }
  }
  await export(rec, 840, 1310, 'neck-fit');
  for (final image in previews) {
    image.dispose();
  }
}

void main() {
  testWidgets('piloto integrado en tres pelajes y todas las vistas', (t) async {
    final b = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        await (FontLoader('Review')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
      for (final (slot, id, title, filename) in [
        ...articles,
        (Slot.neck, 'neck.coral', 'Pañuelo + jersey', 'bandana-sweater'),
      ]) {
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        c.drawColor(const ui.Color(0xFFF3EDE5), ui.BlendMode.src);
        label(c, '$title · piloto integrado', const ui.Offset(24, 18), 25);
        label(
          c,
          'Captura del pintor real del juego · tejido, volumen, sombra y pelaje por delante',
          const ui.Offset(24, 54),
          14,
        );
        final bitmaps = <ui.Image>[];
        for (final (row, coat) in coats.indexed) {
          for (final (col, view) in views.indexed) {
            var a = b.initialAppearance
                .withSlot(Slot.coat, coat.$1)
                .withSlot(slot, id);
            if (filename == 'bandana-sweater') {
              a = a.withSlot(Slot.outfit, 'outfit.sweater_red');
            }
            final image = await dog(painter, a, view.$1, view.$2, view.$3);
            bitmaps.add(image);
            final at = ui.Offset(col * 280, row * 355 + 105);
            c.drawImage(image, at, ui.Paint());
            label(
              c,
              '${coat.$2} · ${view.$4}',
              at + const ui.Offset(14, 321),
              13,
            );
          }
        }
        await export(rec, views.length * 280, 1170, filename);
        for (final image in bitmaps) {
          image.dispose();
        }
      }
      // Antes y después: mismo perro, color, cámara y reloj de animación.
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawColor(const ui.Color(0xFFF3EDE5), ui.BlendMode.src);
      label(c, 'Integración · antes y después', const ui.Offset(24, 20), 25);
      label(c, 'Anterior', const ui.Offset(90, 65), 18);
      label(c, 'Piloto integrado', const ui.Offset(370, 65), 18);
      final bitmaps = <ui.Image>[];
      for (final (row, article) in articles.indexed) {
        for (var col = 0; col < 2; col++) {
          final a = b.initialAppearance
              .withSlot(Slot.coat, 'coat.white')
              .withSlot(article.$1, article.$2);
          final image = await dog(
            painter,
            a,
            PetPose.front,
            PetAnim.idle,
            1,
            integrated: col == 1,
          );
          bitmaps.add(image);
          final at = ui.Offset(col * 300 + 10, row * 355 + 95);
          c.drawImage(image, at, ui.Paint());
          label(c, article.$3, at + const ui.Offset(22, 321), 14);
        }
      }
      await export(rec, 620, 1170, 'before-after');
      for (final image in bitmaps) {
        image.dispose();
      }
      // Las tres piezas juntas: prueba de orden de capas en una combinación real.
      final comboRec = ui.PictureRecorder();
      final combo = ui.Canvas(comboRec);
      combo.drawColor(const ui.Color(0xFFF3EDE5), ui.BlendMode.src);
      label(combo, 'Gorro + jersey + pañuelo', const ui.Offset(24, 20), 25);
      final combinations = <ui.Image>[];
      for (final (col, coat) in coats.indexed) {
        for (final (row, view) in [
          views[0],
          views[1],
          views.last,
          views[2],
        ].indexed) {
          final a = b.initialAppearance
              .withSlot(Slot.coat, coat.$1)
              .withSlot(Slot.head, 'head.beanie')
              .withSlot(Slot.outfit, 'outfit.sweater_red')
              .withSlot(Slot.neck, 'neck.coral');
          final image = await dog(painter, a, view.$1, view.$2, view.$3);
          combinations.add(image);
          final at = ui.Offset(col * 300 + 10, row * 355 + 70);
          combo.drawImage(image, at, ui.Paint());
          label(
            combo,
            '${coat.$2} · ${view.$4}',
            at + const ui.Offset(22, 321),
            15,
          );
        }
      }
      await export(comboRec, 920, 1500, 'combination');
      for (final image in combinations) {
        image.dispose();
      }
      if (Platform.environment['POODLE_REVIEW'] == '1') {
        await captureNeckAccessories(painter, b.initialAppearance);
      }
      painter.integratedPilot = true;
      expect(
        painter.integratedAccessories.readyFor(
          b.initialAppearance.withSlot(Slot.head, 'head.beanie'),
        ),
        isTrue,
      );
    });
  });

  testWidgets('un artículo fuera del piloto conserva exactamente su render', (
    t,
  ) async {
    final b = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      final a = b.initialAppearance
          .withSlot(Slot.outfit, 'outfit.dress_pink')
          .withSlot(Slot.head, 'head.crown');
      final old = await dog(
        painter,
        a,
        PetPose.front,
        PetAnim.idle,
        1,
        integrated: false,
      );
      final next = await dog(painter, a, PetPose.front, PetAnim.idle, 1);
      final before = await old.toByteData(), after = await next.toByteData();
      expect(
        after!.buffer.asUint8List(),
        orderedEquals(before!.buffer.asUint8List()),
      );
      old.dispose();
      next.dispose();
    });
  });
  testWidgets('el piloto conserva ojos y hocico de los tres pelajes', (
    t,
  ) async {
    final b = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      for (final (coat, _) in coats) {
        final base = b.initialAppearance.withSlot(Slot.coat, coat);
        final dressed = base
            .withSlot(Slot.head, 'head.beanie')
            .withSlot(Slot.outfit, 'outfit.sweater_red')
            .withSlot(Slot.neck, 'neck.coral');
        final plain = await dog(painter, base, PetPose.front, PetAnim.idle, 1);
        final clothed = await dog(
          painter,
          dressed,
          PetPose.front,
          PetAnim.idle,
          1,
        );
        final a = (await plain.toByteData())!.buffer.asUint8List();
        final z = (await clothed.toByteData())!.buffer.asUint8List();
        for (final at in [
          const ui.Offset(-0.02, -0.659),
          const ui.Offset(-0.10, -0.79),
          const ui.Offset(0.03, -0.79),
        ]) {
          final px = (140 + at.dx * 238).round(),
              py = (298 + at.dy * 238).round();
          for (var y = py - 1; y <= py + 1; y++) {
            for (var x = px - 1; x <= px + 1; x++) {
              final i = (y * 280 + x) * 4;
              // Una segunda pasada de pelaje puede redondear el alfa de
              // 254 a 255. La comparación permite solo ese margen de raster.
              for (var channel = 0; channel < 4; channel++) {
                expect(
                  (z[i + channel] - a[i + channel]).abs(),
                  lessThanOrEqualTo(2),
                  reason: '$coat: facciones',
                );
              }
            }
          }
        }
        plain.dispose();
        clothed.dispose();
      }
    });
  });

  testWidgets('el pelaje sale por el cuello y los puños del jersey', (t) async {
    final balance = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      final base = balance.initialAppearance.withSlot(Slot.coat, 'coat.white');
      final dressed = base.withSlot(Slot.outfit, 'outfit.sweater_red');
      final openings = [
        (
          views[0],
          const [
            ui.Offset(-0.021, -0.601),
            ui.Offset(-0.105, -0.218),
            ui.Offset(0.097, -0.214),
          ],
        ),
        (views[1], const [ui.Offset(0.31, -0.685), ui.Offset(0.224, -0.193)]),
        (views[2], const [ui.Offset(0.220, -0.556)]),
      ];
      for (final (view, points) in openings) {
        final (pose, animation, time, caption) = view;
        final fur = await dog(painter, base, pose, animation, time);
        final jersey = await dog(painter, dressed, pose, animation, time);
        final bareSample = (await fur.toByteData())!.buffer.asUint8List();
        final dressedSample = (await jersey.toByteData())!.buffer.asUint8List();
        final size = pose == PetPose.front ? 238 : 223;
        for (final point in points) {
          final x = (140 + point.dx * size).round();
          final y = (298 + point.dy * size).round();
          final i = (y * 280 + x) * 4;
          expect(
            bareSample[i + 3],
            greaterThan(225),
            reason: '$caption $point',
          );
          for (var channel = 0; channel < 3; channel++) {
            expect(
              (bareSample[i + channel] - dressedSample[i + channel]).abs(),
              lessThanOrEqualTo(12),
              reason: '$caption $point',
            );
          }
        }
        jersey.dispose();
        fur.dispose();
      }
    });
  });

  testWidgets('el jersey cubre el pecho y cierra sobre ambas patas traseras', (
    t,
  ) async {
    final balance = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      final dressed = balance.initialAppearance
          .withSlot(Slot.coat, 'coat.white')
          .withSlot(Slot.outfit, 'outfit.sweater_red');
      final coverage = [
        (
          views[1],
          const [
            ui.Offset(0.394, -0.57),
            ui.Offset(0.386, -0.49),
            ui.Offset(-0.278, -0.334),
            ui.Offset(-0.322, -0.210),
            ui.Offset(-0.198, -0.228),
          ],
        ),
        (views[2], const [ui.Offset(0.31, -0.335), ui.Offset(-0.397, -0.22)]),
        (views[3], const [ui.Offset(0.298, -0.286), ui.Offset(-0.423, -0.169)]),
        (views[4], const [ui.Offset(0.322, -0.487), ui.Offset(-0.32, -0.42)]),
        (
          views.last,
          const [
            ui.Offset(-0.10, -0.217),
            ui.Offset(-0.015, -0.235),
            ui.Offset(0.086, -0.217),
          ],
        ),
      ];
      for (final (view, points) in coverage) {
        final (pose, animation, time, caption) = view;
        final image = await dog(painter, dressed, pose, animation, time);
        final rgba = (await image.toByteData())!.buffer.asUint8List();
        final size = pose == PetPose.side ? 223 : 238;
        for (final point in points) {
          final x = (140 + point.dx * size).round();
          final y = (298 + point.dy * size).round();
          final i = (y * 280 + x) * 4;
          expect(
            rgba[i] - rgba[i + 1],
            greaterThan(45),
            reason: '$caption $point',
          );
          expect(rgba[i + 3], greaterThan(225), reason: '$caption $point');
        }
        image.dispose();
      }
      final (pose, animation, time, _) = views[3];
      final image = await dog(painter, dressed, pose, animation, time);
      final rgba = (await image.toByteData())!.buffer.asUint8List();
      // La mandíbula baja queda libre cuando el cuello se estira.
      final x = (140 + 0.296 * 223).round();
      final y = (298 - 0.423 * 223).round();
      final i = (y * 280 + x) * 4;
      expect(rgba[i + 3], greaterThan(225));
      expect(rgba[i] - rgba[i + 1], lessThan(30));
      image.dispose();
    });
  });

  testWidgets('el pañuelo rodea el cuello y deja visible la cola de espaldas', (
    t,
  ) async {
    final balance = loadBalance();
    final catalog = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
    );
    final painter = PetPainter(catalog)
      ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    await t.runAsync(() async {
      final base = balance.initialAppearance.withSlot(Slot.coat, 'coat.white');
      final dressed = base.withSlot(Slot.neck, 'neck.coral');
      final edges = [
        (views[0], const [ui.Offset(-0.142, -0.603), ui.Offset(0.073, -0.596)]),
        (views[1], const [ui.Offset(0.161, -0.626), ui.Offset(0.395, -0.604)]),
        (views.last, const [ui.Offset(-0.03, -0.675)]),
      ];
      for (final (view, points) in edges) {
        final (pose, animation, time, caption) = view;
        final image = await dog(painter, dressed, pose, animation, time);
        final rgba = (await image.toByteData())!.buffer.asUint8List();
        final size = pose == PetPose.side ? 223 : 238;
        for (final point in points) {
          final x = (140 + point.dx * size).round();
          final y = (298 + point.dy * size).round();
          final i = (y * 280 + x) * 4;
          expect(
            rgba[i] - rgba[i + 1],
            greaterThan(45),
            reason: '$caption $point',
          );
          expect(rgba[i + 3], greaterThan(225), reason: '$caption $point');
        }
        image.dispose();
      }
      final jersey = base.withSlot(Slot.outfit, 'outfit.sweater_red');
      final back = await dog(painter, jersey, PetPose.back, PetAnim.idle, 1);
      final dressedBack = await dog(
        painter,
        dressed.withSlot(Slot.outfit, 'outfit.sweater_red'),
        PetPose.back,
        PetAnim.idle,
        1,
      );
      final bareTail = (await back.toByteData())!.buffer.asUint8List();
      final withBandana = (await dressedBack.toByteData())!.buffer
          .asUint8List();
      for (final point in const [
        ui.Offset(-0.034, -0.55),
        ui.Offset(-0.08, -0.597),
        ui.Offset(0.04, -0.59),
      ]) {
        final x = (140 + point.dx * 238).round();
        final y = (298 + point.dy * 238).round();
        final i = (y * 280 + x) * 4;
        expect(bareTail[i + 3], greaterThan(225), reason: 'Cola $point');
        for (var channel = 0; channel < 4; channel++) {
          expect(
            (bareTail[i + channel] - withBandana[i + channel]).abs(),
            lessThanOrEqualTo(2),
            reason: 'Cola $point',
          );
        }
      }
      back.dispose();
      dressedBack.dispose();
    });
  });
}
