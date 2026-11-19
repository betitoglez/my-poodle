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

void main() {
  testWidgets(
    'render del catálogo completo sobre blanco, colores, cortes y fases',
    (t) async {
      final b = loadBalance();
      final looks = AppearanceCatalog.fromJson(
        jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync()),
      );
      final painter = PetPainter(looks)
        ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
      final base = b.initialAppearance.withSlot(Slot.coat, 'coat.white');
      final cases = <(String, Appearance, PetPose, PetAnim, double, PetFx)>[];
      for (final item in b.styles.where(
        (i) => i.slot == Slot.coat || i.slot == Slot.hair,
      )) {
        cases.add((
          item.id,
          base.withSlot(item.slot, item.id),
          PetPose.front,
          PetAnim.idle,
          1,
          PetFx.none,
        ));
      }
      for (final item in b.styles.where(
        (i) => !i.initial && i.slot != Slot.coat && i.slot != Slot.hair,
      )) {
        cases.add((
          item.id,
          base.withSlot(item.slot, item.id),
          PetPose.front,
          PetAnim.idle,
          1,
          PetFx.none,
        ));
      }
      for (final phase in [65, 64, 51, 38, 25, 12]) {
        cases.add((
          'higiene $phase',
          base,
          PetPose.front,
          PetAnim.idle,
          1,
          PetFx(hygiene: phase),
        ));
      }
      for (final time in [0.0, 1 / 9, 2 / 9]) {
        cases.add((
          'carrera $time',
          base.withSlot(Slot.head, 'head.beanie'),
          PetPose.side,
          PetAnim.run,
          time,
          PetFx.none,
        ));
      }
      if (Platform.environment['POODLE_REVIEW'] == '1') {
        final file = File('/System/Library/Fonts/Supplemental/Arial.ttf');
        if (file.existsSync()) {
          await t.runAsync(() async {
            final loader = FontLoader('Review')
              ..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
              );
            await loader.load();
          });
        }
      }
      const cell = 210.0, columns = 5;
      final height = (cases.length / columns).ceil() * cell;
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      canvas.drawColor(const ui.Color(0xFFF3EDE5), ui.BlendMode.src);
      await t.runAsync(() async {
        final cells = <ui.Image>[];
        for (final (index, entry) in cases.indexed) {
          final (label, look, pose, anim, time, fx) = entry;
          await painter.warm(
            look,
            poses: [painter.spritePoseName(pose, anim, time)],
          );
          final cellRecorder = ui.PictureRecorder();
          final cellCanvas = ui.Canvas(cellRecorder);
          cellCanvas.translate(cell / 2, cell - 26);
          painter.paint(
            cellCanvas,
            looks.resolve(look),
            pose: pose,
            anim: anim,
            t: time,
            size: 154,
            fx: fx,
          );
          final text = TextPainter(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: ui.Color(0xFF44384A),
                fontSize: 10,
                fontFamily: 'Review',
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout(maxWidth: cell);
          text.paint(cellCanvas, ui.Offset(-text.width / 2, 8));
          final cellPicture = cellRecorder.endRecording();
          final bitmap = await cellPicture.toImage(cell.round(), cell.round());
          cells.add(bitmap);
          canvas.drawImage(
            bitmap,
            ui.Offset(index % columns * cell, index ~/ columns * cell),
            ui.Paint(),
          );
          cellPicture.dispose();
        }
        final picture = rec.endRecording();
        final image = await picture.toImage(
          (columns * cell).round(),
          height.round(),
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(png, isNotNull);
        if (Platform.environment['POODLE_REVIEW'] == '1') {
          File('docs/reviews/catalogue.png')
              .writeAsBytesSync(png!.buffer.asUint8List());
        }
        image.dispose();
        picture.dispose();
        for (final bitmap in cells) {
          bitmap.dispose();
        }
      });
    },
  );
}
