import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/pet/pet_sprites.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);
  final balance = loadBalance();
  final looks = AppearanceCatalog.fromJson(
    jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final rules = Rules(balance);
  final codec = SaveCodec(balance);

  Future<ui.Image> render(
    PetPainter painter,
    Appearance look,
    PetPose pose, {
    PetAnim anim = PetAnim.idle,
  }) async {
    await painter.warm(look);
    final recording = ui.PictureRecorder();
    final canvas = ui.Canvas(recording)..translate(215, 405);
    painter.paint(
      canvas,
      looks.resolve(look),
      pose: pose,
      anim: anim,
      t: 0,
      size: 320,
      reducedMotion: anim == PetAnim.idle,
    );
    final picture = recording.endRecording();
    final image = await picture.toImage(450, 450);
    picture.dispose();
    return image;
  }

  Future<int> differences(ui.Image first, ui.Image second) async {
    final a = (await first.toByteData())!.buffer.asUint8List();
    final b = (await second.toByteData())!.buffer.asUint8List();
    var changed = 0;
    for (var i = 0; i < a.length; i += 4) {
      if ((a[i] - b[i]).abs() +
              (a[i + 1] - b[i + 1]).abs() +
              (a[i + 2] - b[i + 2]).abs() +
              (a[i + 3] - b[i + 3]).abs() >
          24) {
        changed++;
      }
    }
    return changed;
  }

  for (final atlas in [true, false]) {
    testWidgets(
      'moderno comprado y recargado cambia cada zona y pack en 2D, atlas=$atlas',
      (t) async {
        final painter = PetPainter(looks);
        if (atlas) {
          painter.sprites = await t.runAsync(() => PetSprites.load(rootBundle));
        }
        final state = PetState.adopt(
          validName: 'Rizo',
          nowUtc: t0,
          balance: balance,
        ).copyWith(coins: 1000);
        await t.runAsync(() async {
          final normal = await render(painter, state.appearance, PetPose.side);
          for (final zone in <HairZone?>[null, ...HairZone.values]) {
            final look = zone == null
                ? state.appearance.withSlot(Slot.hair, 'hair.modern')
                : state.appearance.withCut(zone, 'modern');
            final purchased = rules.applyLook(
              state,
              look,
              'buy-${zone?.name}',
              t0,
              fullVersion: true,
            ) as Purchased;
            expect(purchased.cost, zone == null ? 200 : 50);
            final saved = codec.decode(codec.encode(purchased.receipt.after));
            final modern = await render(
              painter,
              saved.appearance,
              PetPose.side,
            );
            expect(
              await differences(normal, modern),
              greaterThan(100),
              reason: 'La compra ${zone?.name ?? 'pack'} debe verse',
            );
            modern.dispose();
          }
          normal.dispose();
        });
      },
    );
  }

  testWidgets(
    'moderno: frente, espalda, correr, saltar, comer y dormir tienen silueta propia',
    (t) async {
      final painter = PetPainter(looks)
        ..sprites = await t.runAsync(() => PetSprites.load(rootBundle));
      await t.runAsync(() async {
        for (final (pose, anim) in [
          (PetPose.front, PetAnim.idle),
          (PetPose.back, PetAnim.idle),
          (PetPose.side, PetAnim.run),
          (PetPose.side, PetAnim.jump),
          (PetPose.front, PetAnim.eat),
          (PetPose.front, PetAnim.sleep),
        ]) {
          final natural = await render(
            painter,
            balance.initialAppearance,
            pose,
            anim: anim,
          );
          final modern = await render(
            painter,
            balance.initialAppearance.withSlot(Slot.hair, 'hair.modern'),
            pose,
            anim: anim,
          );
          expect(
            await differences(natural, modern),
            greaterThan(100),
            reason: '$pose $anim',
          );
          natural.dispose();
          modern.dispose();
        }
        if (const bool.fromEnvironment('REVIEW_CAPTURE')) {
          final recording = ui.PictureRecorder();
          final canvas = ui.Canvas(recording)
            ..drawColor(const ui.Color(0xfff7efdf), ui.BlendMode.src);
          for (var i = 0; i < 6; i++) {
            final zone = i < 2 ? null : HairZone.values[i - 2];
            final look = i == 0
                ? balance.initialAppearance
                : zone == null
                ? balance.initialAppearance.withSlot(Slot.hair, 'hair.modern')
                : balance.initialAppearance.withCut(zone, 'modern');
            for (var row = 0; row < 3; row++) {
              final image = await render(painter, look, PetPose.values[row]);
              canvas.drawImageRect(
                image,
                const ui.Rect.fromLTWH(0, 0, 450, 450),
                ui.Rect.fromLTWH(i * 225, row * 225, 225, 225),
                ui.Paint(),
              );
              image.dispose();
            }
          }
          final picture = recording.endRecording();
          final image = await picture.toImage(1350, 675);
          final file = File('docs/reviews/pr17-fixes/modern-2d.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(
            (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
                .asUint8List(),
          );
          image.dispose();
          picture.dispose();
        }
      });
    },
  );
}
