import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_controller.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/domain/achievements.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/ui/screens/album_screen.dart';
import 'package:my_poodle/ui/screens/main_shell.dart';
import 'package:my_poodle/ui/widgets/celebrations.dart';

import '../support.dart';
import 'app_flow_test.dart' show boot, idle, saved, scrollTo, tapText;
import 'features_test.dart' show backendWith;

AppController controllerOf(WidgetTester t) =>
    AppScope.of(t.element(find.byType(MainShell)));

Future<void> openAlbum(WidgetTester t) async {
  await tapText(t, 'Juegos');
  await t.tap(find.byKey(const Key('album-button')));
  await idle(t);
  expect(find.byType(AlbumScreen), findsOneWidget);
}

/// Toca la ficha de [page] en el selector (puede estar desplazada).
Future<void> showPage(WidgetTester t, AlbumPage page) async {
  final chip = find.byKey(Key('album-chip-${page.name}'));
  await t.ensureVisible(chip);
  await t.pump();
  await t.tap(chip);
  await idle(t);
}

PetState Function(PetState) withPhotosPage = (s) => s.copyWith(
  photosTaken: 10,
  achievements: {
    for (final a in Achievements.onPage(AlbumPage.photos)) a.id: t0,
  },
);

void main() {
  setUp(rootBundle.clear);

  testWidgets('el álbum se abre desde Juegos con pegatinas pendientes', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await boot(t, backendWith((s) => s));
    await openAlbum(t);
    expect(find.text('Cuidados'), findsWidgets);
    expect(find.text('0 de 7 pegatinas'), findsOneWidget);
    expect(find.text('Completa la página para ganar 40 monedas.'), findsOne);
    expect(
      find.bySemanticsLabel(
        'Primera comida. Pendiente. Dale de comer a tu caniche.',
      ),
      findsOneWidget,
    );
    // Selector de páginas accesible y con acción de toque.
    final chip = find.bySemanticsLabel('Fotos. 0 de 2 pegatinas');
    expect(chip, findsOneWidget);
    expect(t.getSemantics(chip), isSemantics(hasTapAction: true));
    await t.ensureVisible(chip);
    await t.pump();
    await t.tap(chip);
    await idle(t);
    expect(find.text('Completa la página para ganar 30 monedas.'), findsOne);
    handle.dispose();
  });

  testWidgets('Recoger cobra el bono de la página una sola vez', (t) async {
    final backend = backendWith((s) => withPhotosPage(s).copyWith(coins: 5));
    await boot(t, backend);
    // La cabecera avisa del bono pendiente.
    expect(find.byType(Badge), findsNothing);
    await tapText(t, 'Juegos');
    expect(t.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
    await t.tap(find.byKey(const Key('album-button')));
    await idle(t);
    await showPage(t, AlbumPage.photos);
    expect(find.text('Recoger 30 monedas'), findsOneWidget);
    await t.tap(find.byKey(const Key('album-collect-photos')));
    await idle(t);
    expect(saved(backend).coins, 35);
    expect(saved(backend).albumCollected, {'photos'});
    expect(find.text('Recoger 30 monedas'), findsNothing);
    expect(find.text('Bono recogido: 30 monedas.'), findsOneWidget);
    expect(find.text('¡Has recogido 30 monedas!'), findsOneWidget);
  });

  testWidgets('una partida antigua obtiene al abrir lo que ya cumple, sin '
      'aviso ni monedas', (t) async {
    final backend = backendWith(
      (s) => s.copyWith(coins: 7, careCompletedUtc: {'feed': t0 - 100}),
    );
    await boot(t, backend);
    final s = saved(backend);
    expect(s.achievements.keys, contains('ach.care.feed'));
    expect(s.coins, 7);
    expect(find.byKey(const Key('sticker-toast')), findsNothing);
    await openAlbum(t);
    expect(find.text('1 de 7 pegatinas'), findsOneWidget);
    expect(find.textContaining('Conseguida el'), findsOneWidget);
  });

  testWidgets('una pegatina nueva se celebra con aviso y confeti', (t) async {
    final backend = backendWith((s) => s);
    await boot(t, backend);
    await controllerOf(t).recordPhotoTaken();
    await t.pump();
    expect(find.text('¡Nueva pegatina!'), findsOneWidget);
    expect(find.text('Primera foto'), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsOneWidget);
    expect(saved(backend).achievements.keys, ['ach.photo.first']);
    await t.pump(const Duration(seconds: 4));
    await idle(t);
    expect(find.byKey(const Key('sticker-toast')), findsNothing);
  });

  testWidgets('con movimiento reducido el aviso aparece sin confeti', (
    t,
  ) async {
    await boot(
      t,
      backendWith(
        (s) => s.copyWith(prefs: s.prefs.copyWith(reducedMotion: true)),
      ),
    );
    await controllerOf(t).recordPhotoTaken();
    await t.pump();
    expect(find.text('¡Nueva pegatina!'), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsNothing);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('320×568 con texto ×1,6 sin desbordes en todas las páginas', (
    t,
  ) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await boot(t, backendWith(withPhotosPage), size: const Size(320, 568));
    await openAlbum(t);
    expect(t.takeException(), isNull);
    for (final page in AlbumPage.values) {
      await showPage(t, page);
      expect(t.takeException(), isNull, reason: page.name);
      final last = Achievements.onPage(page).last.id;
      await scrollTo(t, find.byKey(Key('sticker-$last')));
      expect(t.takeException(), isNull, reason: '${page.name} final');
    }
  });
}
