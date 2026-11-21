import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/pet/pet_sprites.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'cada variante nueva del jersey se distingue con materiales integrados cargados',
    (t) async {
      await t.runAsync(() async {
        final catalog = AppearanceCatalog.fromJson(
          jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync())
              as Map<String, dynamic>,
        );
        final painter = PetPainter(catalog)
          ..sprites = await PetSprites.load(rootBundle);
        final base = Appearance({
          for (final slot in Slot.values)
            slot: switch (slot) {
              Slot.coat => 'coat.apricot',
              Slot.hair => 'hair.natural',
              _ => '${slot.name}.none',
            },
        });
        for (final pose in [PetPose.front, PetPose.side, PetPose.back]) {
          final renders = <String, List<int>>{};
          for (final color in [
            'red',
            'white',
            'black',
            'zebra',
            'redwhite',
            'greenwhite',
            'dots',
          ]) {
            final appearance = base.withSlot(
              Slot.outfit,
              'outfit.sweater_$color',
            );
            await painter.warm(appearance);
            final recorder = ui.PictureRecorder(),
                c = ui.Canvas(recorder)..translate(200, 380);
            painter.paint(
              c,
              catalog.resolve(appearance),
              pose: pose,
              anim: PetAnim.idle,
              t: 0,
              size: 300,
              reducedMotion: true,
            );
            final picture = recorder.endRecording(),
                image = await picture.toImage(400, 400);
            final pixels = (await image.toByteData())!.buffer.asUint8List();
            for (final previous in renders.entries) {
              var changed = 0;
              for (var i = 0; i < pixels.length; i += 4) {
                if ((pixels[i] - previous.value[i]).abs() +
                        (pixels[i + 1] - previous.value[i + 1]).abs() +
                        (pixels[i + 2] - previous.value[i + 2]).abs() >
                    30) {
                  changed++;
                }
              }
              expect(
                changed,
                greaterThan(100),
                reason: '$pose: $color no debe verse igual que ${previous.key}',
              );
            }
            renders[color] = List<int>.from(pixels);
            image.dispose();
            picture.dispose();
          }
        }
      });
    },
  );
}
