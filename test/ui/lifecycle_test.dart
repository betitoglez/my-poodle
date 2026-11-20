import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/game/frisbee_game.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import '../support.dart';
import 'app_flow_test.dart' show boot, frames, idle, saved, tapText;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);

  testWidgets(
    'volver a Casa actualiza necesidades sin esperar al temporizador',
    (t) async {
      final backend = backendWith(
        (s) => s.copyWith(needs100: {...s.needs100, Need.satiety: 3100}),
      );
      final clock = FakeClock(t0);
      await boot(t, backend, clock: clock);
      Set<PetCondition> active() =>
          t.widget<StatusBubbles>(find.byType(StatusBubbles)).active;
      expect(active(), isNot(contains(PetCondition.hungry)));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.advance(3600);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump(const Duration(milliseconds: 100));
      expect(active(), contains(PetCondition.hungry));
      expect(
        saved(backend).revision,
        1,
        reason: 'actualizar la UI no escribe una partida',
      );
    },
  );

  testWidgets('al reanudar consulta propiedad Android sin cambiar la partida', (
    t,
  ) async {
    final backend = backendWith((s) => s);
    final store = SimulatedStore(owned: true, delay: Duration.zero);
    await boot(t, backend, store: store);
    final controller = AppScope.read(t.element(find.byType(StatusBubbles)));
    expect(controller.fullVersion, isTrue);
    final before = backend.files[SaveStore.primary];
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    store.owned = false;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await idle(t);
    expect(controller.fullVersion, isFalse);
    expect(backend.files[SaveStore.primary], before);
  });

  testWidgets('frisbee se congela en segundo plano hasta Continuar', (t) async {
    final backend = backendWith((s) => s);
    await boot(t, backend);
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await tapText(t, 'Frisbee en el prado');
    await tapText(t, 'Jugar');
    await tapText(t, 'Lanzar al aro');
    await frames(t, seconds: 0.2);
    final game =
        t.widget<SceneView>(find.byType(SceneView)).game as FrisbeeGame;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    final phase = game.sim.phase;
    final time = game.sim.phaseTime;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(t, seconds: 5);
    expect(game.paused, isTrue);
    expect(game.sim.phase, phase);
    expect(game.sim.phaseTime, time);
    expect(saved(backend).coins, 0);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(game.paused, isTrue);
    expect(find.text('En pausa'), findsOneWidget);
    await tapText(t, 'Continuar');
    expect(game.paused, isFalse);
    await frames(t, seconds: 0.2);
    expect(game.sim.phaseTime, isNot(time));
    await idle(t);
    expect(saved(backend).coins, 0);
  });
}
