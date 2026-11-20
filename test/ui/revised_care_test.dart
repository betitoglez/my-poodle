import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/activities.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/care/care_games.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/domain/rules.dart';

import 'app_flow_test.dart' show boot, frames, fullStore, idle, saved, tapText;
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

  for (final massage in [false, true]) {
    final plan = massage ? 'Baño con Masaje' : 'Baño Premium';
    testWidgets('$plan aplica precio y efectos después de sus pasos propios', (
      t,
    ) async {
      final backend = backendWith(
        (s) => s.copyWith(
          coins: 30,
          needs100: {...s.needs100, Need.hygiene: 2000, Need.mood: 4000},
        ),
      );
      await boot(t, backend, store: massage ? fullStore() : null);
      await t.tap(find.byType(NeedMeter).at(1));
      await idle(t);
      await tapText(t, plan);
      await tapText(t, 'Empezar el baño');
      expect(find.text('Confirmar el baño'), findsOneWidget);
      await tapText(t, 'Aceptar');
      final game = sceneGame<BathGame>(t);
      await waitScene(t, game);
      if (massage) {
        expect(game.activity.phase, BathPhase.salts);
        await hold(t, find.text('Añadir sales de baño relajantes'), 1.4);
        expect(game.activity.phase, BathPhase.wet);
      }
      await hold(t, find.text('Mantén: ducha'), 5.3);
      for (final zone in BathZone.values) {
        game.soap(zone, 1);
      }
      await idle(t);
      await hold(t, find.text('Mantén: ducha'), 5.3);
      if (massage) {
        expect(game.activity.phase, BathPhase.massage);
        await hold(t, find.text('Masaje perruno'), 4.8);
      }
      await hold(t, find.text('Mantén: secador'), 5.3);
      if (!massage) {
        expect(game.activity.phase, BathPhase.nails);
        await hold(t, find.text('Cortador de uñas de perro'), 1.9);
        expect(game.activity.phase, BathPhase.curl);
        expect(saved(backend).coins, 30);
        await hold(t, find.text('Rizado Extra'), 2.9);
      }
      expect(saved(backend).coins, 0);
      expect(saved(backend).needPoints(Need.hygiene), massage ? 70 : 80);
      expect(saved(backend).needPoints(Need.mood), massage ? 65 : 40);
      expect(saved(backend).revision, 2);
    });
  }

  testWidgets(
    'baño: soltar detiene la ducha, cabeza obligatoria y secado final',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      await t.tap(find.byType(NeedMeter).at(1));
      await idle(t);
      await tapText(t, 'Baño estándar · Gratis');
      await tapText(t, 'Empezar el baño');
      final g = sceneGame<BathGame>(t);
      await waitScene(t, g);
      await idle(t);
      await hold(t, find.text('Mantén: ducha'), 2);
      expect(g.activity.phase, BathPhase.wet);
      final before = g.activity.toolProgress;
      await frames(t, seconds: 2);
      expect(g.activity.toolProgress, before);
      final head =
          t.getTopLeft(find.byType(SceneView)) +
          g.pet.landmarkScene('headTop') +
          Offset(0, g.pet.petSize * 0.1);
      final shower = await t.startGesture(head);
      await frames(t, seconds: 3.2);
      await shower.up();
      await idle(t);
      expect(g.activity.phase, BathPhase.soap);
      expect(g.activity.foam(BathZone.head), 0);
      for (final label in ['Lomo', 'Patas', 'Pecho']) {
        for (var i = 0; i < 7; i++) {
          await t.tap(find.text(label));
          await t.pump();
        }
      }
      expect(g.activity.phase, BathPhase.soap);
      final sponge = await t.startGesture(head);
      final scrub = Offset(g.pet.petSize * 0.1, 0);
      for (var i = 0; i < 9; i++) {
        await sponge.moveTo(head + scrub);
        await sponge.moveTo(head - scrub);
      }
      await sponge.up();
      await idle(t);
      expect(g.activity.phase, BathPhase.rinse);
      expect(saved(backend).revision, 1);
      await hold(t, find.text('Mantén: ducha'), 5.2);
      expect(g.activity.phase, BathPhase.dry);
      expect(saved(backend).revision, 1);
      await hold(t, find.text('Mantén: secador'), 5.2);
      expect(saved(backend).needPoints(Need.hygiene), 100);
      expect(saved(backend).careCompletedUtc['bath'], isNotNull);
    },
  );

  testWidgets('paseo: cada parada espera una indicación de olfatear', (
    t,
  ) async {
    final backend = backendWith((s) => s);
    await boot(t, backend);
    await tapText(t, 'Cuidados');
    await tapText(t, 'Pasear');
    final g = sceneGame<WalkGame>(t);
    await waitScene(t, g);
    for (final (i, label) in [
      (0, 'Ir a las flores'),
      (1, 'Ir al banco'),
      (2, 'Ir a la fuente'),
    ]) {
      await tapText(t, label);
      await frames(t, seconds: 2.5);
      expect(g.activity.phase, WalkPhase.atStop);
      await frames(t, seconds: 1.55);
      expect(g.activity.done, i);
      expect(saved(backend).revision, 1);
      await tapText(t, 'Olfatear');
      await frames(t, seconds: 1.55);
      expect(g.activity.done, i + 1);
    }
    await idle(t);
    expect(saved(backend).careCompletedUtc['walk'], isNotNull);
    expect(saved(backend).needPoints(Need.mood), 90);
    expect(saved(backend).needPoints(Need.energy), 75);
  });

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
