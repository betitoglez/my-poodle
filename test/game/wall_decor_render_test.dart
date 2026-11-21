import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/scenes/decor_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'guirnalda real llega a ambos bordes y estrellas tienen halo estable',
    (t) async {
      await t.runAsync(() async {
        await DecorPainter.loadAssets();
        for (final width in [320.0, 600.0]) {
          final scene = DecorScene(
            art: ui.Rect.fromLTWH(-50, 0, width + 100, 500),
            view: ui.Rect.fromLTWH(0, 0, width, 500),
            feet: ui.Offset(width / 2, 430),
            petSize: 250,
            illustrated: true,
          );
          final box = DecorPainter.boxIn(DecorSlot.wall, 'wall.garland', scene);
          expect(box.left, 0);
          expect(box.right, width);
          final recorder = ui.PictureRecorder();
          // Use the actual scene path, including transparent margin trimming.
          final c = ui.Canvas(recorder);
          DecorPainter.paint(
            c,
            DecorSlot.wall,
            'wall.garland',
            scene,
            reducedMotion: true,
          );
          final picture = recorder.endRecording(),
              image = await picture.toImage(width.toInt(), 500);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          int column(int x) {
            var count = 0;
            for (var y = 0; y < 150; y++) {
              if (bytes[(y * width.toInt() + x) * 4 + 3] > 8) count++;
            }
            return count;
          }

          expect(column(0), greaterThan(0));
          expect(column(width.toInt() - 1), greaterThan(0));
          image.dispose();
          picture.dispose();
        }
        final recorder = ui.PictureRecorder(), c = ui.Canvas(recorder);
        DecorPainter.paintItem(
          c,
          'wall.stars',
          const ui.Rect.fromLTWH(20, 20, 300, 200),
          reducedMotion: true,
        );
        final picture = recorder.endRecording(),
            glow = await picture.toImage(340, 240);
        final raw = await rootBundle.load(
          'assets/images/decor/wall.stars.webp',
        );
        final codec = await ui.instantiateImageCodec(
          raw.buffer.asUint8List(),
          targetWidth: 300,
          targetHeight: 200,
        );
        final source = (await codec.getNextFrame()).image;
        final a = (await glow.toByteData())!.buffer.asUint8List(),
            b = (await source.toByteData())!.buffer.asUint8List();
        var litEdges = 0;
        for (var y = 0; y < 200; y++) {
          for (var x = 0; x < 300; x++) {
            if (b[(y * 300 + x) * 4 + 3] < 4 &&
                a[((y + 20) * 340 + x + 20) * 4 + 3] > 20) {
              litEdges++;
            }
          }
        }
        expect(
          litEdges,
          greaterThan(500),
          reason: 'halo visible fuera de la silueta del recurso',
        );
        if (const bool.fromEnvironment('CATALOG_CAPTURE')) {
          final out = Directory('docs/reviews/catalog-tuning')
            ..createSync(recursive: true);
          File('${out.path}/stars-glow.png').writeAsBytesSync(
            (await glow.toByteData(format: ui.ImageByteFormat.png))!.buffer
                .asUint8List(),
          );
        }
        glow.dispose();
        picture.dispose();
        source.dispose();
        codec.dispose();
      });
    },
  );
}
