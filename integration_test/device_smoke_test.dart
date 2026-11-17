import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_controller.dart';
import 'package:my_poodle/app/app_root.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/platform/platform_backend_io.dart';
import 'package:my_poodle/store/iap_store.dart';
import 'package:my_poodle/ui/parental_gate.dart';
import 'package:my_poodle/ui/screens/home_screen.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/game/scenes/stage_game.dart';

/// Ejecutar con flutter drive --keep-app-running; ver docs/PRUEBAS.md.
/// Dos invocaciones separadas prueban persistencia entre procesos. Solo toca
/// `MyPoodle/qa/QA_RUN`, nunca la partida normal. No compra ni restaura.
const qaRun = String.fromEnvironment('QA_RUN');
const reopen = bool.fromEnvironment('QA_REOPEN');

Future<void> waitFor(
  WidgetTester t,
  bool Function() ready, {
  String reason = 'esperando interfaz',
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 40));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue, reason: reason);
}

Future<void> tap(WidgetTester t, Finder finder) async {
  await waitFor(t, () => finder.evaluate().isNotEmpty);
  await t.ensureVisible(finder.last);
  await t.pump(const Duration(milliseconds: 200));
  await t.tap(finder.hitTestable().last);
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'móvil · arranque, cuidados, tienda y persistencia entre procesos',
    (t) async {
      expect(Platform.isIOS || Platform.isAndroid, isTrue);
      // Profile no admite el client -1 de TestTextInput sin registrar.
      // La entrada de texto es del harness; teclado iOS real se revisa aparte.
      t.testTextInput.register();
      addTearDown(t.testTextInput.unregister);
      expect(
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(qaRun),
        isTrue,
        reason: 'Indicar --dart-define=QA_RUN=<id-unico>',
      );
      final nativePath = await storageChannel.invokeMethod<String>(
        'saveDirectory',
      );
      final base = Directory(nativePath!);
      final qa = Directory('${base.path}/qa/$qaRun');
      await qa.create(recursive: true);
      final backend = FileBackend(qa);
      final marker = File('${qa.path}/expected.json');
      expect(
        await backend.exists(SaveStore.primary),
        reopen,
        reason: 'Usar un QA_RUN nuevo en la primera ejecución y repetirlo al reabrir',
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      final bootWatch = Stopwatch()..start();
      await t.pumpWidget(MyPoodleApp(backend: backend));
      await waitFor(
        t,
        () =>
            find.byType(HomeScreen).evaluate().isNotEmpty ||
            find.text('Tu caniche toy').evaluate().isNotEmpty,
        reason: 'arranque nativo',
      );

      binding.reportData = {
        'bootToScreenMs': bootWatch.elapsedMilliseconds,
        'phase': reopen ? 'reopen' : 'first',
        'platform': Platform.operatingSystem,
      };
      debugPrint('QA_BOOT_TO_SCREEN_MS=${bootWatch.elapsedMilliseconds}');
      await waitFor(
        t,
        () =>
            find.byType(SceneView).evaluate().isNotEmpty &&
            (t.widget<SceneView>(find.byType(SceneView).first).game
                    as StageGame)
                .isLoaded,
        reason: 'ilustración Flame cargada',
      );
      bootWatch.stop();
      binding.reportData!['bootToSceneMs'] = bootWatch.elapsedMilliseconds;
      debugPrint('QA_SCENE_LOADED=true');

      if (reopen) {
        expect(find.text('Tu caniche toy'), findsNothing);
        final expected =
            jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
        final c = AppScope.read(t.element(find.byType(HomeScreen)));
        expect(c.pet.name, expected['name']);
        expect(c.pet.coins, expected['coins']);
        expect(
          c.pet.revision,
          greaterThanOrEqualTo(expected['revision'] as int),
        );
        expect(c.pet.needPoints(Need.satiety), greaterThanOrEqualTo(80));
        expect(c.purchases.provider, isA<IapStore>());
        expect(c.purchases.entitlements.acceptSimulated, isFalse);
        return;
      }

      expect(find.text('Tu caniche toy'), findsOneWidget);
      await tap(t, find.byType(TextField));
      await waitFor(
        t,
        () => find.byType(EditableText).evaluate().isNotEmpty,
        reason: 'campo editable de adopción listo',
      );
      await t.enterText(find.byType(EditableText).last, 'Nube QA');
      expect(
        t.widget<EditableText>(find.byType(EditableText).last).controller.text,
        'Nube QA',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump(const Duration(milliseconds: 500));
      await waitFor(t, () => find.byType(HomeScreen).evaluate().isNotEmpty);
      final c = AppScope.read(t.element(find.byType(HomeScreen)));
      expect(c.status, BootStatus.ready);
      expect(c.purchases.provider, isA<IapStore>());
      expect(c.purchases.entitlements.acceptSimulated, isFalse);
      expect(c.pet.coins, 0);
      await tap(t, find.text('Cuidados'));
      await tap(t, find.text('Comer'));
      for (var i = 0; i < 3; i++) {
        await waitFor(
          t,
          () => find.text('Dar un bocado').hitTestable().evaluate().isNotEmpty,
          reason: 'terminar masticación',
        );
        await tap(t, find.text('Dar un bocado'));
      }
      await waitFor(
        t,
        () => c.pet.needPoints(Need.satiety) == 85,
        reason: 'alimentación guardada una vez',
      );
      expect(c.pet.coins, 0);
      expect(await backend.exists(SaveStore.primary), isTrue);
      await tap(t, find.text('Casa'));
      await tap(t, find.byIcon(Icons.settings_rounded));
      await tap(t, find.text('Acceso para personas adultas'));
      await waitFor(
        t,
        () =>
            find.byKey(const Key('parental-gate-field')).evaluate().isNotEmpty,
      );
      final challenge = List.generate(79, (i) => i + 21).singleWhere(
        (n) => find
            .text('Escribe en cifras: ${ParentalGate.words(n)}')
            .evaluate()
            .isNotEmpty,
      );
      await t.enterText(
        find.byKey(const Key('parental-gate-field')),
        '$challenge',
      );
      await tap(t, find.text('Continuar'));
      await tap(t, find.text('Versión completa y restaurar compras'));
      await waitFor(
        t,
        () => c.purchases.productStatus.name != 'loading',
        reason: 'consulta real del producto sin bloquear cuidados',
      );
      // No se exige producto: no está configurado en las consolas. En ningún
      // caso se envía comprar/restaurar ni se simula un derecho.
      expect(c.purchases.full, isFalse);
      await marker.writeAsString(
        jsonEncode({
          'name': c.pet.name,
          'coins': c.pet.coins,
          'revision': c.pet.revision,
        }),
        flush: true,
      );
      expect(t.takeException(), isNull);
    },
  );
}
