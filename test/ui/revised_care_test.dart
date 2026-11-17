import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/activities.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/care/care_games.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/domain/rules.dart';

import 'app_flow_test.dart' show boot, frames, idle, saved, tapText;
import 'features_test.dart' show backendWith;
import 'care_composition_review_test.dart' show waitScene;

T sceneGame<T>(WidgetTester t) =>
    t.widget<SceneView>(find.byType(SceneView)).game as T;
Future<void> hold(WidgetTester t, Finder finder, double seconds) async {
  final pointer = await t.startGesture(t.getCenter(finder));
  await frames(t, seconds: seconds);
  await pointer.up();
  await idle(t);
}

void main() {
  setUp(rootBundle.clear);

  testWidgets(
    'paneles sanos navegan; energía cero bloquea cuidados y permite dormir',
    (t) async {
      final backend = backendWith(
        (s) => s.copyWith(needs100: {...s.needs100, Need.energy: 0}),
      );
      await boot(t, backend);
      await t.tap(find.byType(NeedMeter).at(1));
      await idle(t);
      expect(find.textContaining('Necesita dormir'), findsOneWidget);
      expect(find.text('En casa'.toUpperCase()), findsOneWidget);
      await t.tap(find.byType(NeedMeter).at(3));
      await idle(t);
      expect(sceneGame<SleepGame>(t), isA<SleepGame>());
      await tapText(t, 'Llevar a su cama');
      await frames(t, seconds: 1.8);
      await tapText(t, 'Arropar');
      await frames(t, seconds: 1.7);
      await tapText(t, 'Apagar la luz');
      await frames(t, seconds: 5);
      await idle(t);
      expect(saved(backend).needPoints(Need.energy), 60);
      expect(saved(backend).needPoints(Need.mood), 85);
    },
  );

  testWidgets(
    'baño: soltar detiene la ducha, cabeza obligatoria y secado final',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      await t.tap(find.byType(NeedMeter).at(1));
      await idle(t);
      final g = sceneGame<BathGame>(t);
      await waitScene(t, g);
      await idle(t);
      await hold(t, find.text('Mantén: ducha'), 2);
      expect(g.activity.phase, BathPhase.wet);
      final before = g.activity.toolProgress;
      await frames(t, seconds: 2);
      expect(g.activity.toolProgress, before);
      await hold(t, find.text('Mantén: ducha'), 3.2);
      expect(g.activity.phase, BathPhase.soap);
      for (final label in ['Lomo', 'Patas', 'Pecho', 'Cabeza']) {
        for (var i = 0; i < 7; i++) {
          await t.tap(find.text(label));
          await t.pump();
        }
      }
      await idle(t);
      expect(g.activity.phase, BathPhase.rinse);
      expect(saved(backend).revision, 1);
      await hold(t, find.text('Mantén: ducha'), 5.2);
      expect(g.activity.phase, BathPhase.dry);
      expect(saved(backend).revision, 1);
      await hold(t, find.text('Mantén: secador'), 5.2);
      expect(saved(backend).needPoints(Need.hygiene), 95);
      expect(saved(backend).careCompletedUtc['bath'], isNotNull);
    },
  );

  testWidgets(
    'peluquería: requiere peine, tijeras y secador antes de guardar',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      await tapText(t, 'Cuidados');
      await tapText(t, 'Peluquería');
      final g = sceneGame<GroomGame>(t);
      await waitScene(t, g);
      await idle(t);
      for (final tool in GroomTool.values) {
        expect(g.activity.tool, tool);
        for (final label in ['Flequillo', 'Orejas', 'Lomo']) {
          for (var i = 0; i < 7; i++) {
            await t.tap(find.text(label));
            await t.pump();
          }
        }
      }
      await idle(t);
      expect(g.activity.completed, isTrue);
      expect(saved(backend).revision, 1);
      await tapText(t, 'Terminar cepillado');
      expect(saved(backend).needPoints(Need.hygiene), 78);
    },
  );

  testWidgets(
    'reservas de juego serializadas: tres, cuarta rechazada y cancelar consume intento',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      final context = t.element(find.byType(NeedMeter).first);
      final c = AppScope.read(context);
      final starts = await Future.wait([
        for (var i = 0; i < 4; i++) c.beginGame(GameId.frisbee),
      ]);
      expect(starts.whereType<String>().length, 3);
      c.cancelActivity(starts.first!);
      expect(await c.beginGame(GameId.frisbee), isNull);
      expect(saved(backend).gameStartedUtc.length, 3);
      expect(saved(backend).coins, 0);
    },
  );
}
