import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/pet/pet_sprites.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'A01/A02 atlas: 16 combinaciones en las tres poses y todas las reacciones',
    (t) async {
      final balance = loadBalance();
      final looks = AppearanceCatalog.fromJson(
        jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final sprites = await t.runAsync(() => PetSprites.load(rootBundle));
      expect(sprites, isNotNull);
      for (final hair in balance.itemsFor(Slot.hair)) {
        for (final pose in ['front', 'side', 'jump']) {
          expect(
            sprites!.hair(hair.id, pose),
            isNotNull,
            reason: '${hair.id} $pose',
          );
        }
      }
      for (final id in ['outfit.teal', 'neck.coral']) {
        for (final pose in ['front', 'side', 'jump']) {
          expect(sprites!.item(id, pose), isNotNull, reason: '$id $pose');
        }
      }
      expect(sprites!.coatMatrix('coat.silver'), hasLength(20));
      final painter = PetPainter(looks)..sprites = sprites;
      final base = balance.initialAppearance;
      var painted = 0;
      for (final coat in ['coat.apricot', 'coat.silver']) {
        for (final hair in ['hair.natural', 'hair.pom']) {
          for (final outfit in ['outfit.none', 'outfit.teal']) {
            for (final neck in ['neck.none', 'neck.coral']) {
              final a = base
                  .withSlot(Slot.coat, coat)
                  .withSlot(Slot.hair, hair)
                  .withSlot(Slot.outfit, outfit)
                  .withSlot(Slot.neck, neck);
              for (final pose in PetPose.values) {
                for (final anim in PetAnim.values) {
                  final rec = ui.PictureRecorder();
                  painter.paint(
                    ui.Canvas(rec),
                    looks.resolve(a),
                    pose: pose,
                    anim: anim,
                    t: 1.3,
                    size: 200,
                    fx: const PetFx(wet: true, foam: [1, 1, 1]),
                  );
                  rec.endRecording().dispose();
                  painted++;
                }
              }
            }
          }
        }
      }
      expect(painted, 16 * 2 * PetAnim.values.length);
    },
  );
}
