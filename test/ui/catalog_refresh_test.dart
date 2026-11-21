import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/ui/screens/care_activity_screens.dart';
import 'package:my_poodle/ui/screens/games_screen.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/screens/wardrobe_screen.dart';

import 'decor_test.dart' show openDecor, previewGame;
import 'care_composition_review_test.dart' show waitScene;

import '../support.dart';
import 'app_flow_test.dart' show boot, fullStore, saved, scrollTo, tapText;
import 'features_test.dart' show backendWith;

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('REFRESH_CAPTURE')) return;
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/review/refresh/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(rootBundle.clear);
  setUpAll(() async {
    if (!const bool.fromEnvironment('REFRESH_CAPTURE')) return;
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'Ahem': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File(
        '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/${entry.value}',
      );
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  for (final full in [false, true]) {
    testWidgets(
      'selector de juegos: cuota solo gratuita y contador vivo, completa=$full',
      (t) async {
        final clock = FakeClock(t0);
        final backend = backendWith(
          (s) => s.copyWith(gameStartedUtc: [t0 - 20, t0 - 10, t0]),
        );
        await boot(t, backend, clock: clock, store: full ? fullStore() : null);
        await tapText(t, 'Juegos');
        if (!full) {
          expect(find.text('04:40'), findsWidgets);
          clock.advance(1);
          await t.pump(const Duration(seconds: 1));
          expect(find.text('04:39'), findsWidgets);
          await tapText(t, '04:39');
          expect(
            find.textContaining('La versión completa permite jugar'),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(SnackBarAction, 'Versión completa'),
            findsOneWidget,
          );
          await capture(t, 'games-quota-free');
        } else {
          expect(find.text('04:40'), findsNothing);
          await scrollTo(t, find.text('Juego de parejas'));
          await capture(t, 'games-covers');
          await scrollTo(t, find.text('Memory de caniches'));
          await capture(t, 'games-memory-cover');
          await tapText(t, 'Memory de caniches');
          expect(find.byType(InstructionsScreen), findsOneWidget);
        }
        expect(t.takeException(), isNull);
      },
    );
  }

  for (final full in [false, true]) {
    testWidgets(
      'comer: saldo, plazo por ración y otra opción disponible, completa=$full',
      (t) async {
        final clock = FakeClock(t0);
        await boot(
          t,
          backendWith(
            (s) => s.copyWith(
              coins: 100,
              careCompletedUtc: {'feed': t0, 'feed.basic': t0},
            ),
          ),
          clock: clock,
          store: full ? fullStore() : null,
        );
        await tapText(t, 'Cuidados');
        await tapText(t, 'Comer');
        expect(find.byType(FeedScreen), findsOneWidget);
        expect(find.byType(CoinBalance), findsOneWidget);
        expect(find.text('Disponible en 15:00'), findsOneWidget);
        clock.advance(1);
        await t.pump(const Duration(seconds: 1));
        expect(find.text('Disponible en 14:59'), findsOneWidget);
        await tapText(t, 'Pienso diario · Gratis');
        expect(
          find.textContaining('Podrás repetir este cuidado'),
          findsOneWidget,
        );
        await tapText(t, 'Comida premium');
        expect(
          t
              .widget<AppButton>(
                find.widgetWithText(AppButton, 'Dar un bocado'),
              )
              .onPressed,
          isNotNull,
        );
        await capture(t, 'care-options-${full ? 'full' : 'free'}');
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('decoración: artículos realistas en escena y catálogo', (
    t,
  ) async {
    await boot(
      t,
      backendWith((s) => s.copyWith(coins: 1000)),
      store: fullStore(),
    );
    await openDecor(t);
    await waitScene(t, previewGame(t));
    await tapText(t, 'Alfombra redonda');
    await capture(t, 'decor-rug');
    await tapText(t, 'Pared');
    await tapText(t, 'Estrellas luminosas');
    await capture(t, 'decor-stars');
    await tapText(t, 'Planta');
    await tapText(t, 'Helecho');
    await capture(t, 'decor-plants');
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'armario: compra solo cabeza y completa pack por 150; menú granular en 320 px',
    (t) async {
      final backend = backendWith((s) => s.copyWith(coins: 1000));
      await boot(t, backend, size: const Size(320, 568), store: fullStore());
      await tapText(t, 'Armario');
      await tapText(t, 'Peinados');
      await tapText(t, 'Cabeza');
      await tapText(t, 'Corte osito · Cabeza');
      await tapText(t, 'Comprar y usar · 50');
      await tapText(t, 'Confirmar');
      expect(saved(backend).appearance.cuts[HairZone.head], 'teddy');
      expect(saved(backend).appearance.cuts[HairZone.legs], 'natural');
      expect(saved(backend).coins, 950);
      await capture(t, 'wardrobe-head-320');
      await tapText(t, 'Packs');
      await scrollTo(t, find.text('Corte osito'));
      await tapText(t, 'Corte osito');
      expect(find.text('Comprar y usar · 150'), findsOneWidget);
      await tapText(t, 'Comprar y usar · 150');
      await tapText(t, 'Confirmar');
      expect(saved(backend).coins, 800);
      expect(saved(backend).appearance.cuts.values.toSet(), {'teddy'});
      expect(t.takeException(), isNull);
      final controller = AppScope.read(t.element(find.byType(WardrobeScreen)));
      expect(controller.lookCost(saved(backend).appearance), 0);
    },
  );
}
