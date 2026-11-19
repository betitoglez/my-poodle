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

const _views = [
  (PetPose.front, PetAnim.idle, 1.0, 'Frente'),
  (PetPose.side, PetAnim.idle, 1.0, 'Perfil'),
  (PetPose.back, PetAnim.idle, 1.0, 'Espalda'),
  (PetPose.side, PetAnim.run, 1 / 9, 'Carrera · extensión'),
  (PetPose.side, PetAnim.run, 0.0, 'Carrera · recogida'),
];
const _cuts = [('hair.teddy', 'Corte osito'), ('hair.pom', 'Corte pompón')];
const _width = 354;
const _height = 299;

void main() {
  testWidgets('el vestuario sigue las mismas patas con ambos peinados', (
    t,
  ) async {
    await t.runAsync(() async {
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        await (FontLoader('Review')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
      final catalog = AppearanceCatalog.fromJson(
        jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
      );
      final painter = PetPainter(catalog, articulatedPilot: true)
        ..sprites = await PetSprites.load(rootBundle);
      addTearDown(painter.dispose);
      final outfit = loadBalance().initialAppearance
          .withSlot(Slot.outfit, 'outfit.teal')
          .withSlot(Slot.neck, 'neck.coral')
          .withSlot(Slot.paws, 'paws.rain');

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xFFF3EEE6), BlendMode.src);
      _label(
        canvas,
        'Peto, pañuelo coral y botas de lluvia',
        const Offset(20, 18),
        24,
      );
      final reference = <Uint8List>[];
      for (final (row, (hair, name)) in _cuts.indexed) {
        _label(canvas, name, Offset(20, 83 + row * 329), 19);
        final appearance = outfit.withSlot(Slot.hair, hair);
        await painter.warm(appearance);
        for (final (column, view) in _views.indexed) {
          final image = await _preview(painter, appearance, view);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          const lowerBody = _width * 4 * 193;
          if (row == 0) {
            reference.add(bytes);
          } else {
            expect(
              Uint8List.sublistView(bytes, lowerBody),
              orderedEquals(
                Uint8List.sublistView(reference[column], lowerBody),
              ),
              reason: view.$4,
            );
            expect(
              Uint8List.sublistView(bytes, 0, lowerBody),
              isNot(
                orderedEquals(
                  Uint8List.sublistView(reference[column], 0, lowerBody),
                ),
              ),
              reason: 'Cambio de peinado en ${view.$4}',
            );
          }
          if (view.$1 == PetPose.back) {
            // Debe haber pelaje entre el corte y el borde trasero del pañuelo.
            for (var y = 106; y < 128; y++) {
              expect(
                bytes[4 * (y * _width + _width ~/ 2) + 3],
                greaterThan(245),
              );
            }
          }
          final y = 102.0 + row * 329;
          canvas.drawImage(
            image,
            Offset(column * _width.toDouble(), y),
            Paint(),
          );
          if (row == 0) {
            _label(canvas, view.$4, Offset(column * _width + 20, 57), 16);
          }
          image.dispose();
        }
      }
      await _export(recorder, 'cinco-poses', _width * _views.length, 730);

      final full = outfit.withSlot(Slot.hair, 'hair.pom');
      final intermediate = await _preview(painter, full, (
        PetPose.side,
        PetAnim.run,
        1 / 18,
        '',
      ));
      final extension = await _preview(painter, full, _views[3]);
      final gathered = await _preview(painter, full, _views[4]);
      final moving = await intermediate.toByteData();
      expect(
        moving!.buffer.asUint8List(),
        isNot(
          orderedEquals((await extension.toByteData())!.buffer.asUint8List()),
        ),
      );
      expect(
        moving.buffer.asUint8List(),
        isNot(
          orderedEquals((await gathered.toByteData())!.buffer.asUint8List()),
        ),
      );
      intermediate.dispose();
      extension.dispose();
      gathered.dispose();

      // Comprobar que el calzado y el cuello pueden probarse independientemente.
      final separates = ui.PictureRecorder();
      final parts = Canvas(separates)
        ..drawColor(const Color(0xFFF3EEE6), BlendMode.src);
      final options = [
        ('Conjunto completo', full),
        ('Peto y pañuelo', full.withSlot(Slot.paws, 'paws.none')),
        ('Peto y botas', full.withSlot(Slot.neck, 'neck.none')),
      ];
      for (final (column, (title, appearance)) in options.indexed) {
        await painter.warm(appearance, poses: ['side']);
        final image = await _preview(painter, appearance, _views[1]);
        final x = column * _width.toDouble();
        _label(parts, title, Offset(x + 20, 21), 18);
        parts.drawImage(image, Offset(x, 42), Paint());
        image.dispose();
      }
      await _export(
        separates,
        'piezas-por-separado',
        _width * options.length,
        341,
      );
    });
  });
}

Future<ui.Image> _preview(
  PetPainter painter,
  Appearance appearance,
  (PetPose, PetAnim, double, String) view,
) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec)..translate(_width / 2, _height - 24);
  painter.paint(
    canvas,
    painter.catalog.resolve(appearance),
    pose: view.$1,
    anim: view.$2,
    t: view.$3,
    size: 240,
  );
  final picture = rec.endRecording();
  final image = await picture.toImage(_width, _height);
  picture.dispose();
  return image;
}

void _label(Canvas canvas, String text, Offset at, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Review',
        fontSize: size,
        color: const Color(0xFF3F3834),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, at);
  painter.dispose();
}

Future<void> _export(ui.PictureRecorder rec, String file, int w, int h) async {
  final picture = rec.endRecording();
  if (Platform.environment['POODLE_REVIEW'] == '1') {
    final image = await picture.toImage(w, h);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('docs/reviews/vestuario-articulado')
      ..createSync(recursive: true);
    File('${dir.path}/$file.png').writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
  }
  picture.dispose();
}
