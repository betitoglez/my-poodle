import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/game/care/care_games.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';

import 'app_flow_test.dart' show boot, frames, fullStore, idle, tapText;
import 'features_test.dart' show backendWith;

Future<void> waitScene(WidgetTester t, FlameGame g) async {
  for (var i = 0; i < 40; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 16));
    if (i >= 5 && g.isLoaded && g.children.every((c) => c.isLoaded)) break;
  }
  expect(g.isLoaded, isTrue);
  g.update(0);
}

Future<void> capture(WidgetTester t, String name) async {
  final g = t.widget<SceneView>(find.byType(SceneView)).game as FlameGame;
  await waitScene(t, g);
  await frames(t, seconds: 0.1);
  await t.runAsync(() async {
    final rec = ui.PictureRecorder();
    g.render(ui.Canvas(rec));
    final picture = rec.endRecording();
    final img = await picture.toImage(g.size.x.round(), g.size.y.round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);
    if (Platform.environment['POODLE_REVIEW'] == '1') {
      File('docs/reviews/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    }
    img.dispose();
    picture.dispose();
  });
}

void main() {
  setUp(rootBundle.clear);
  testWidgets('composición real del hocico y el cuenco durante un bocado', (
    t,
  ) async {
    await boot(t, backendWith((s) => s));
    await t.tap(find.byType(NeedMeter).first);
    await idle(t);
    await tapText(t, 'Pienso diario · Gratis');
    final g = t.widget<SceneView>(find.byType(SceneView)).game as FeedGame;
    await waitScene(t, g);
    await frames(t, seconds: 0.1);
    g.bite();
    await frames(t, seconds: 0.3);
    await capture(t, 'feed');
  });
  testWidgets(
    'composición real de cama, cuerpo y manta dejando la cara visible',
    (t) async {
      await boot(t, backendWith((s) => s));
      await t.tap(find.byType(NeedMeter).at(3));
      await idle(t);
      final g = t.widget<SceneView>(find.byType(SceneView)).game as SleepGame;
      await waitScene(t, g);
      await frames(t, seconds: 0.1);
      g.goToBed();
      await frames(t, seconds: 1.8);
      g.tuckIn();
      await frames(t, seconds: 1.8);
      await capture(t, 'sleep');
    },
  );
  testWidgets('composición del huerto con terreno y frutas', (t) async {
    await boot(t, backendWith((s) => s), store: fullStore());
    await tapText(t, 'Juegos');
    await t.tap(find.text('Jugar').hitTestable().first);
    await idle(t);
    await tapText(t, 'Jugar');
    await frames(t, seconds: 0.5);
    await capture(t, 'orchard');
  });
}
