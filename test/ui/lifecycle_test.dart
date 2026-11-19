import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/game/frisbee_game.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import '../support.dart';
import 'app_flow_test.dart' show boot, frames, idle, saved, tapText;
import 'features_test.dart' show backendWith;

class _FailOnceBackend extends MemoryBackend {
  bool failNextWrite = false;

  @override
  Future<void> write(String name, String text) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Error de escritura de prueba');
    }
    await super.write(name, text);
  }
}

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

  testWidgets('Casa recupera energía al volver del segundo plano', (t) async {
    final backend = backendWith((s) => s);
    final clock = FakeClock(t0);
    await boot(t, backend, clock: clock);
    await tapText(t, 'Descansar en su cama');
    expect(saved(backend).restingSinceUtc, t0);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(16 * 60 + 45);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    final energy = t
        .widgetList<NeedMeter>(find.byType(NeedMeter))
        .singleWhere((meter) => meter.need == Need.energy);
    expect(energy.value, 96);
    await tapText(t, 'Despertar');
    expect(saved(backend).restingSinceUtc, isNull);
    expect(saved(backend).needPoints(Need.energy), 96);
  });

  testWidgets('Casa permite reintentar o descartar un fallo al descansar', (
    t,
  ) async {
    final backend = _FailOnceBackend()
      ..files.addAll(backendWith((s) => s).files);
    await boot(t, backend);
    backend.failNextWrite = true;
    await tapText(t, 'Descansar en su cama');
    expect(find.text('No se ha podido guardar'), findsOneWidget);
    expect(saved(backend).restingSinceUtc, isNull);
    await tapText(t, 'Reintentar');
    expect(saved(backend).restingSinceUtc, t0);

    backend.failNextWrite = true;
    await tapText(t, 'Hidratación');
    expect(find.text('No se ha podido guardar'), findsOneWidget);
    await tapText(t, 'Volver');
    expect(saved(backend).restingSinceUtc, t0);
    expect(find.text('Hora de beber'), findsNothing);

    await tapText(t, 'Hidratación');
    expect(find.text('Hora de beber'), findsOneWidget);
    expect(saved(backend).restingSinceUtc, isNull);
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
