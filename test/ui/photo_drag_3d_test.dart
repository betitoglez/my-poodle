import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/ui/screens/photo_screen.dart';
import 'package:my_poodle/ui/widgets/live_poodle_view.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';

import 'app_flow_test.dart' show boot, idle, tapIcon;
import 'decor_test.dart' show openDecor, previewGame;
import 'features_test.dart' show backendWith;

void main() {
  testWidgets('foto 3D: arrastre horizontal gira y vertical no inclina', (
    t,
  ) async {
    if (!const bool.fromEnvironment('POODLE_LIVE_3D')) return;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final rotations = <num>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['id'];
        final channel = MethodChannel('my_poodle/3d/$id');
        messenger.setMockMethodCallHandler(channel, (method) async {
          if (method.method == 'rotate') rotations.add(method.arguments as num);
          return null;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      ),
    );
    await boot(t, backendWith((s) => s));
    await tapIcon(t, Icons.camera_alt_rounded);
    final scene = find.descendant(
      of: find.byType(PhotoScreen),
      matching: find.byType(SceneView),
    );
    expect(t.widget<SceneView>(scene).onDragUpdate, isNotNull);
    expect(find.text('Álbum'), findsOneWidget);
    final live = t.widget<LivePoodleView>(
      find.descendant(
        of: find.byType(PhotoScreen),
        matching: find.byType(LivePoodleView),
      ),
    );
    expect(live.appearance.cuts, isNotEmpty);
    await t.drag(scene, const Offset(90, 0));
    await idle(t);
    expect(rotations.where((n) => n != 0), isNotEmpty);
    expect(rotations.reduce((a, b) => a + b), closeTo(90, 1));
    rotations.clear();
    await t.drag(scene, const Offset(0, 90));
    await idle(t);
    expect(rotations.every((n) => n == 0), isTrue);
    expect(t.takeException(), isNull);
    await t.tap(find.byType(BackButton));
    await idle(t);
    await openDecor(t);
    expect(find.byType(LivePoodleView), findsOneWidget);
    expect(previewGame(t).pet.showSprite, isFalse);
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
}
