import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/activities.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/game/care/care_games.dart';

import '../support.dart';
import 'app_flow_test.dart'
    show boot, frames, fullStore, idle, saved, scrollTo, tapIcon, tapText;

/// Partida guardada antes de arrancar, para empezar en un estado concreto.
MemoryBackend backendWith(PetState Function(PetState) tweak) {
  final balance = loadBalance();
  final s = tweak(
    PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance),
  );
  return MemoryBackend()
    ..files[SaveStore.primary] = SaveCodec(balance).encode(s);
}

Set<PetCondition> lit(WidgetTester t) =>
    t.widget<StatusBubbles>(find.byType(StatusBubbles)).active;

Future<void> holdVet(WidgetTester t, String target) async {
  final scene = t.widget<SceneView>(find.byType(SceneView));
  final g = scene.game as VetGame;
  final point =
      t.getTopLeft(find.byType(SceneView)) + g.pet.landmarkScene(target);
  final touch = await t.startGesture(point);
  await frames(t, seconds: 3.2);
  await touch.up();
  await frames(t, seconds: 1.6);
  await idle(t);
}

void main() {
  setUp(rootBundle.clear);

  testWidgets(
    'iconos de estado: se encienden según el estado y llevan a la actividad',
    (t) async {
      final backend = backendWith(
        (s) => s.copyWith(
          needs100: {
            Need.satiety: 1500,
            Need.hygiene: 8000,
            Need.mood: 2000,
            Need.energy: 8000,
          },
          sickSinceUtc: t0,
          lastSickUtc: t0,
        ),
      );
      await boot(t, backend);
      expect(find.byType(StatusBubbles), findsOneWidget);
      expect(lit(t), {
        PetCondition.hungry,
        PetCondition.sad,
        PetCondition.sick,
      });
      // Malito es lo más urgente: la sugerencia y el botón lo mencionan.
      expect(find.textContaining('Miel'), findsWidgets);
      expect(find.text('Veterinario'), findsOneWidget);
      expect(find.text('Malito'), findsWidgets); // medidor de salud
      // Tocar el icono apagado no hace nada; el encendido abre el veterinario.
      await t.tap(find.byType(StatusBubbles));
      await idle(t);
    },
  );

  testWidgets('sano y descansado: ningún icono encendido', (t) async {
    await boot(t, backendWith((s) => s));
    expect(lit(t), isEmpty);
    expect(find.text('Sano'), findsOneWidget);
  });

  testWidgets('veterinario: tres pasos, pastilla y cura una sola vez', (
    t,
  ) async {
    final backend = backendWith(
      (s) => s.copyWith(sickSinceUtc: t0, lastSickUtc: t0, coins: 30),
    );
    await boot(t, backend);
    await tapText(t, 'Cuidados');
    expect(find.text('¡Malito!'), findsOneWidget);
    await tapText(t, 'Veterinario');
    expect(find.textContaining('está malito'), findsWidgets);
    // El orden es el del corazón, las patas y la pastilla.
    expect(find.text('Dar la pastilla'), findsNothing);
    await tapText(t, 'Usar fonendoscopio');
    await holdVet(t, 'chest');
    await tapText(t, 'Usar lupa');
    await holdVet(t, 'paws');
    expect(saved(backend).isSick, isTrue); // aún no se ha guardado nada
    await tapText(t, 'Coger pastilla');
    final scene = t.widget<SceneView>(find.byType(SceneView));
    final game = scene.game as VetGame;
    final mouth =
        t.getTopLeft(find.byType(SceneView)) + game.pet.landmarkScene('mouth');
    await t.tapAt(mouth);
    await idle(t);
    expect(game.activity.phase, VetPhase.pill);
    final start =
        t.getTopLeft(find.byType(SceneView)) +
        Offset(game.size.x * 0.82, game.size.y * 0.55);
    final gesture = await t.startGesture(start);
    await gesture.moveTo(mouth);
    await gesture.up();
    await frames(t, seconds: 2);
    await idle(t);
    expect(find.text('Malito → Sano'), findsOneWidget);
    final s = saved(backend);
    expect(s.isSick, isFalse);
    expect(s.lastSickUtc, t0);
    expect(s.needPoints(Need.mood), 80);
    expect(s.revision, 2);
    expect(s.coins, 0);
  });

  testWidgets('veterinario sano: revisión de dos pasos sin pastilla', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 30));
    await boot(t, backend);
    await tapText(t, 'Cuidados');
    await tapText(t, 'Veterinario');
    await tapText(t, 'Usar fonendoscopio');
    final scene = find.byType(SceneView);
    final touch = await t.startGesture(
      t.getTopLeft(scene) + const Offset(20, 80),
    );
    await frames(t, seconds: 3.2);
    await touch.up();
    expect(
      (t.widget<SceneView>(scene).game as VetGame).activity.phase,
      VetPhase.heart,
    );
    await holdVet(t, 'chest');
    await tapText(t, 'Usar lupa');
    await holdVet(t, 'paws');
    await idle(t);
    expect(find.text('Dar la pastilla'), findsNothing);
    expect(saved(backend).needPoints(Need.mood), 80);
    expect(saved(backend).isSick, isFalse);
  });

  testWidgets('dormir: cama, manta, luz y +60 de energía una sola vez', (
    t,
  ) async {
    final backend = backendWith(
      (s) => s.copyWith(needs100: {...s.needs100, Need.energy: 2000}),
    );
    await boot(t, backend);
    expect(lit(t), {PetCondition.tired});
    await tapText(t, 'Cuidados');
    await tapText(t, 'Dormir');
    final scene = t.widget<SceneView>(find.byType(SceneView));
    final sleep = scene.game as SleepGame;
    await tapText(t, 'Llevar a su cama');
    await frames(t, seconds: 1.8);
    expect(sleep.lightsOff(), isFalse);
    await tapText(t, 'Arropar');
    expect(sleep.canLightsOff, isFalse);
    await frames(t, seconds: 1.6);
    await tapText(t, 'Apagar la luz');
    await frames(t, seconds: 1);
    expect(saved(backend).needPoints(Need.energy), 20);
    await frames(t, seconds: 5);
    await idle(t);
    final s = saved(backend);
    expect(s.needPoints(Need.energy), 80);
    expect(s.needPoints(Need.mood), 85);
    expect(s.revision, 2);
    expect(find.text('DORMIR COMPLETADO'), findsOneWidget);
  });

  testWidgets('dormir: salir a medias no aplica nada', (t) async {
    final backend = backendWith(
      (s) => s.copyWith(needs100: {...s.needs100, Need.energy: 2000}),
    );
    await boot(t, backend);
    await tapText(t, 'Cuidados');
    await tapText(t, 'Dormir');
    await tapText(t, 'Llevar a su cama');
    await frames(t, seconds: 1.8);
    await tapIcon(t, Icons.close_rounded);
    await tapText(t, 'Salir');
    expect(saved(backend).needPoints(Need.energy), 20);
    expect(saved(backend).revision, 1);
  });

  testWidgets('armario: submenús de accesorios y compra de un lazo', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 30));
    await boot(t, backend);
    await tapText(t, 'Armario');
    await tapText(t, 'Accesorios');
    for (final sub in ['Cabeza', 'Ojos', 'Cuello', 'Patucos']) {
      expect(find.text(sub), findsWidgets, reason: sub);
    }
    await tapText(t, 'Lazo rosa');
    await tapText(t, 'Comprar y usar · 20');
    expect(find.text('Saldo restante'), findsOneWidget);
    await tapText(t, 'Confirmar');
    final s = saved(backend);
    expect([s.coins, s.appearance.head], [10, 'head.bow']);
    // Sin la versión completa, las zapatillas se prueban pero no se compran.
    await tapText(t, 'Patucos');
    await tapText(t, 'Zapatillas');
    expect(find.widgetWithText(AppButton, 'Versión completa'), findsOneWidget);
    expect(find.text('Faltan 24 · Jugar'), findsNothing);
  });

  testWidgets('armario con versión completa: lo que falta se gana jugando', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 16));
    await boot(t, backend, store: fullStore());
    await tapText(t, 'Armario');
    await tapText(t, 'Accesorios');
    await tapText(t, 'Patucos');
    await tapText(t, 'Zapatillas');
    expect(find.text('Faltan 24 · Jugar'), findsOneWidget);
  });

  testWidgets('armario: ropa por variedad y precios redondeados', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 50));
    await boot(t, backend, store: fullStore());
    await tapText(t, 'Armario');
    await tapText(t, 'Ropa');
    expect(find.text('Peto'), findsOneWidget);
    // Todos los colores de una prenda cuestan lo mismo; la prenda marca el precio.
    await scrollTo(t, find.text('Jersey'));

    await scrollTo(t, find.text('Mostaza'));
    await tapText(t, 'Mostaza');
    expect(find.text('Comprar y usar · 40'), findsOneWidget);
    await scrollTo(t, find.text('Impermeable'));

    await t.tap(find.text('Azul').hitTestable().last);
    await idle(t);
    expect(find.text('Comprar y usar · 50'), findsOneWidget);
    await scrollTo(t, find.text('Vestido'));
    expect(find.text('Vestido'), findsOneWidget);
  });

  testWidgets('girar al caniche recorre los cuatro ángulos', (t) async {
    await boot(t, backendWith((s) => s));
    expect(find.text('De frente'), findsOneWidget);
    final seen = <String>[];
    for (var i = 0; i < 4; i++) {
      await tapIcon(t, Icons.rotate_right_rounded);
      seen.add(
        [
          'De frente',
          'Lado derecho',
          'De espaldas',
          'Lado izquierdo',
        ].firstWhere((l) => find.text(l).evaluate().isNotEmpty),
      );
    }
    expect(seen, [
      'Lado derecho',
      'De espaldas',
      'Lado izquierdo',
      'De frente',
    ]);
    await tapIcon(t, Icons.rotate_left_rounded);
    expect(find.text('Lado izquierdo'), findsOneWidget);
  });

  testWidgets('al descansar el giro vuelve a «De frente»', (t) async {
    await boot(t, backendWith((s) => s));
    await tapIcon(t, Icons.rotate_right_rounded);
    await tapIcon(t, Icons.rotate_right_rounded);
    expect(find.text('De espaldas'), findsOneWidget);
    await tapText(t, 'Descansar en su cama');
    await idle(t);
    await tapText(t, 'Despertar');
    await idle(t);
    // Acostado mira de frente: el control no queda en el ángulo anterior.
    expect(find.text('De frente'), findsOneWidget);
    expect(find.text('De espaldas'), findsNothing);
  });

  testWidgets('los iconos solo laten si hay alguno encendido', (t) async {
    Widget bubbles(Set<PetCondition> active) => MaterialApp(
      home: Scaffold(
        body: StatusBubbles(active: active, onTap: (_) {}),
      ),
    );
    await t.pumpWidget(bubbles(const {}));
    expect(t.hasRunningAnimations, isFalse);
    await t.pumpWidget(bubbles(const {PetCondition.hungry}));
    await t.pump();
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpWidget(bubbles(const {}));
    await t.pump();
    expect(t.hasRunningAnimations, isFalse);
  });

  test('cada icono de medida apunta a su medida; malito no tiene', () {
    expect(
      {for (final c in PetCondition.values) c: c.need},
      {
        PetCondition.hungry: Need.satiety,
        PetCondition.dirty: Need.hygiene,
        PetCondition.sad: Need.mood,
        PetCondition.tired: Need.energy,
        PetCondition.thirsty: Need.hydration,
        PetCondition.sick: null,
      },
    );
  });
}
