import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/scenes/decor_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'pared completa en cinco anchos sin deformar banderines ni estrellas',
    (t) async {
      await t.runAsync(() async {
        await DecorPainter.loadAssets();
        for (final id in ['wall.garland', 'wall.stars']) {
          Uint8List? narrow;
          for (final width in [320, 390, 600, 844, 1024]) {
            final scene = DecorScene(
              art: ui.Rect.fromLTWH(-50, 0, width + 100, 500),
              view: ui.Rect.fromLTWH(0, 0, width.toDouble(), 500),
              feet: ui.Offset(width / 2, 430),
              petSize: 250,
              illustrated: true,
            );
            final box = DecorPainter.boxIn(DecorSlot.wall, id, scene);
            expect(box.left, 0);
            expect(box.right, width);
            final recorder = ui.PictureRecorder(), canvas = ui.Canvas(recorder);
            DecorPainter.paint(
              canvas,
              DecorSlot.wall,
              id,
              scene,
              reducedMotion: true,
            );
            final picture = recorder.endRecording(),
                image = await picture.toImage(width, 500);
            final bytes = (await image.toByteData())!.buffer.asUint8List();
            int column(int x) {
              var count = 0;
              for (var y = 0; y < 140; y++) {
                if (bytes[(y * width + x) * 4 + 3] > 8) count++;
              }
              return count;
            }

            expect(
              column(0),
              greaterThan(0),
              reason: '$id, borde izquierdo a $width',
            );
            expect(
              column(width - 1),
              greaterThan(0),
              reason: '$id, borde derecho a $width',
            );
            if (narrow == null) {
              narrow = Uint8List.fromList(bytes);
            } else {
              var changed = 0;
              // Widening the room adds more decorations. The first flags/stars
              // retain their exact silhouette and scale instead of stretching.
              for (var y = 0; y < 140; y++) {
                for (var x = 0; x < 300; x++) {
                  final a = (y * 320 + x) * 4, b = (y * width + x) * 4;
                  if (List.generate(
                    4,
                    (c) => (narrow![a + c] - bytes[b + c]).abs(),
                  ).any((d) => d > 2)) {
                    changed++;
                  }
                }
              }
              expect(
                changed,
                lessThan(10),
                reason: '$id conserva proporción al pasar de 320 a $width',
              );
            }
            if (const bool.fromEnvironment('WALL_CAPTURE')) {
              final out = Directory('docs/reviews/wall-spans')
                ..createSync(recursive: true);
              File('${out.path}/${id.split('.').last}-$width.png')
                  .writeAsBytesSync(
                    (await image.toByteData(format: ui.ImageByteFormat.png))!
                        .buffer
                        .asUint8List(),
                  );
            }
            image.dispose();
            picture.dispose();
          }
        }
        final raw = await rootBundle.load(
          'assets/images/decor/wall.stars.webp',
        );
        final codec = await ui.instantiateImageCodec(raw.buffer.asUint8List());
        final source = (await codec.getNextFrame()).image;
        final rgba = (await source.toByteData())!.buffer.asUint8List();
        var lights = 0, halo = 0;
        for (var i = 0; i < rgba.length; i += 4) {
          if (rgba[i] > 225 &&
              rgba[i + 1] > 200 &&
              rgba[i + 2] > 100 &&
              rgba[i + 3] > 150) {
            lights++;
          }
          if (rgba[i + 3] > 8 && rgba[i + 3] < 180 && rgba[i] > rgba[i + 2]) {
            halo++;
          }
        }
        expect(
          lights,
          greaterThan(500),
          reason: 'contorno LED luminoso del nuevo recurso',
        );
        expect(
          halo,
          greaterThan(500),
          reason: 'brillo cálido con transparencia real',
        );
        source.dispose();
        codec.dispose();
      });
    },
  );
}
