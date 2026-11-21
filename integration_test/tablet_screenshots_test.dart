import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_root.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/games/puzzle_deals.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/tutorial.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/ui/screens/home_screen.dart';
import 'package:my_poodle/ui/widgets/activity_frame.dart';
import 'package:my_poodle/ui/widgets/live_poodle_view.dart';

/// Recorrido de tablet real en simulador. Partida de muestra solo en memoria;
/// no usa archivos personales ni la tienda Apple. No cambia el tamaño del visor.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('iPad Pro 13: pared, zonas y los cuatro juegos a igual ancho', (
    t,
  ) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    expect(LivePoodleView.enabled, isTrue);
    final balance = Balance.fromJson(
      jsonDecode(await rootBundle.loadString('assets/data/balance-v1.json'))
          as Map<String, dynamic>,
    );
    final codec = SaveCodec(balance), reports = <Map<String, Object?>>[];
    MemoryBackend? current;
    Future<void> wait(bool Function() predicate, String reason) async {
      final deadline = DateTime.now().add(const Duration(seconds: 55));
      while (!predicate() && DateTime.now().isBefore(deadline)) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(predicate(), isTrue, reason: reason);
    }

    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        final scroll = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axis == Axis.vertical,
        );
        if (scroll.evaluate().isNotEmpty) {
          await t.scrollUntilVisible(
            finder,
            300,
            scrollable: scroll.last,
            maxScrolls: 20,
          );
        }
      }
      await wait(
        () => finder.evaluate().isNotEmpty,
        'control construido: $finder',
      );
      await t.ensureVisible(finder.first);
      await t.pump(const Duration(milliseconds: 150));
      await t.tap(finder.hitTestable().first);
      await t.pump(const Duration(milliseconds: 350));
    }

    Future<void> text(String label) => tap(find.text(label));
    Future<void> nativeReady() async {
      await wait(
        () => t
            .widgetList<LivePoodleView>(find.byType(LivePoodleView))
            .every((w) => w.controller.ready || w.controller.failed),
        'primer frame 3D',
      );
      for (final view in t.widgetList<LivePoodleView>(
        find.byType(LivePoodleView),
      )) {
        expect(
          view.controller.failed,
          isFalse,
          reason: 'visor WebGL disponible en tablet',
        );
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    Future<void> boot(String wall) async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(milliseconds: 250));
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final base = PetState.adopt(
        validName: 'Nube',
        nowUtc: now,
        balance: balance,
      );
      final pet = base.copyWith(
        coins: 1250,
        owned: {
          ...base.owned,
          for (final item in balance.styles) item.id,
          'rug.round',
          'wall.garland',
          'wall.stars',
          'plant.fern',
        },
        decor: {
          DecorSlot.wall: wall,
          DecorSlot.rug: 'rug.round',
          DecorSlot.plant: 'plant.fern',
        },
        prefs: base.prefs.copyWith(
          language: 'es',
          music: false,
          effects: false,
          reducedMotion: true,
          seenHints: {Tutorial.afterHint, Tutorial.skipHint},
        ),
      );
      current = MemoryBackend()..files[SaveStore.primary] = codec.encode(pet);
      await t.pumpWidget(
        MyPoodleApp(
          key: UniqueKey(),
          backend: current,
          storeProvider: SimulatedStore(owned: true, delay: Duration.zero),
        ),
      );
      await wait(
        () => find.byType(HomeScreen).evaluate().isNotEmpty,
        'casa cargada',
      );
      await nativeReady();
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      expect(
        view.physicalSize.width / view.devicePixelRatio,
        greaterThanOrEqualTo(1000),
      );
    }

    Future<void> capture(String name) async {
      await nativeReady();
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final metric = {
        'name': name,
        'widthPx': view.physicalSize.width,
        'heightPx': view.physicalSize.height,
        'devicePixelRatio': view.devicePixelRatio,
        'native3DViews': find.byType(LivePoodleView).evaluate().length,
      };
      reports.add(metric);
      binding.reportData = {'captures': reports};
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:18476/capture?name=$name'),
        );
        final response = await request.close();
        final message = await utf8.decoder.bind(response).join();
        expect(response.statusCode, 200, reason: message);
      } finally {
        client.close(force: true);
      }
      expect(
        t.takeException(),
        isNull,
        reason: 'pantalla sin excepciones/desbordes: $name',
      );
    }

    Future<void> game(String title) async {
      await boot('wall.stars');
      await text('Juegos');
      await text(title);
      await text('Jugar');
      await wait(
        () => find.byType(ActivityFrame).evaluate().isNotEmpty,
        'partida iniciada',
      );
      await nativeReady();
      if (find.text('Empezar').hitTestable().evaluate().isNotEmpty) {
        await text('Empezar');
      }
      await t.pump(const Duration(milliseconds: 500));
    }

    await boot('wall.garland');
    await capture('01-casa-guirnalda');
    await boot('wall.stars');
    await capture('02-casa-estrellas');
    await tap(find.byIcon(Icons.chair_rounded));
    await text('Pared');
    await text('Guirnalda de banderines');
    await capture('03-decoracion-probando-visible');
    await text('Probando');
    await text('Estrellas luminosas');
    await capture('04-decoracion-estrellas-colocadas');

    await boot('wall.garland');
    await text('Armario');
    await text('Peinados');
    await text('Cola');
    await text('Corte estándar · Cola');
    await capture('05-armario-cola-probando');
    await text('Probando');
    await capture('06-armario-cola-ojo');

    await boot('wall.stars');
    await text('Cuidados');
    await capture('07-cuidados');
    await text('Comer');
    await capture('08-comer');

    await boot('wall.stars');
    await tap(find.byIcon(Icons.camera_alt_rounded));
    await capture('09-modo-foto');

    await boot('wall.garland');
    await text('Juegos');
    await capture('10-catalogo-juegos');
    await text('Juego de parejas');
    await capture('11-instrucciones-parejas');
    await text('8 parejas');
    await text('Jugar');
    await wait(
      () => find.byKey(const ValueKey('pair-card-0')).evaluate().isNotEmpty,
      'cartas listas',
    );
    final saved = codec.decode(current!.files[SaveStore.primary]!);
    final cards = PuzzleDeals.decode(saved.puzzleDeals['pairs-8']!.last);
    await tap(find.byKey(const ValueKey('pair-card-0')));
    await tap(
      find.byKey(ValueKey('pair-card-${cards.indexOf(cards.first, 1)}')),
    );
    await capture('12-juego-parejas-8');

    await game('Memory de caniches');
    await wait(
      () => find.text('Tu turno: 0 / 3').evaluate().isNotEmpty,
      'turno Memory',
    );
    await capture('13-juego-memory');
    await game('Huerto saltarín');
    await capture('14-juego-huerto');
    await game('Frisbee en el prado');
    await capture('15-juego-frisbee');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
