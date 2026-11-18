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
    size: pose == PetPose.front ? 238 : 223,
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

void main() {
  testWidgets(
    'piloto integrado: 3 prendas × 3 pelajes × frente, perfil y 3 fotogramas',
    (t) async {
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
        for (final (slot, id, title, filename) in articles) {
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
              final a = b.initialAppearance
                  .withSlot(Slot.coat, coat.$1)
                  .withSlot(slot, id);
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
          await export(rec, 1400, 1170, filename);
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
          for (var row = 0; row < 2; row++) {
            final a = b.initialAppearance
                .withSlot(Slot.coat, coat.$1)
                .withSlot(Slot.head, 'head.beanie')
                .withSlot(Slot.outfit, 'outfit.sweater_red')
                .withSlot(Slot.neck, 'neck.coral');
            final image = await dog(
              painter,
              a,
              row == 0 ? PetPose.front : PetPose.side,
              row == 0 ? PetAnim.idle : PetAnim.run,
              row == 0 ? 1 : 0.0,
            );
            combinations.add(image);
            final at = ui.Offset(col * 300 + 10, row * 355 + 70);
            combo.drawImage(image, at, ui.Paint());
            label(combo, coat.$2, at + const ui.Offset(22, 321), 15);
          }
        }
        await export(comboRec, 920, 790, 'combination');
        for (final image in combinations) {
          image.dispose();
        }
        painter.integratedPilot = true;
        expect(
          painter.integratedAccessories.readyFor(
            b.initialAppearance.withSlot(Slot.head, 'head.beanie'),
          ),
          isTrue,
        );
      });
    },
  );

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
}
