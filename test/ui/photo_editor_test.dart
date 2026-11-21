import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/data/photo_album.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/ui/ask_adult_view.dart';
import 'package:my_poodle/ui/screens/photo_editor_screen.dart';
import 'package:my_poodle/ui/screens/photo_screen.dart';

import 'app_flow_test.dart' show boot, idle, saved, tapIcon, tapText;
import 'features_test.dart' show backendWith;

/// Espera real (E/S y decodificación de imágenes) hasta que se cumpla [ready].
Future<void> waitFor(WidgetTester t, bool Function() ready) async {
  for (var i = 0; i < 80 && !ready(); i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await t.pump(const Duration(milliseconds: 16));
  }
  expect(ready(), isTrue);
}

bool _photoReady() =>
    find.byType(RawImage).evaluate().isNotEmpty &&
    (find.byType(RawImage).evaluate().first.widget as RawImage).image != null;

/// Abre el modo foto, hace la foto y espera al editor con la imagen.
Future<void> openEditor(
  WidgetTester t,
  MemoryBackend backend, {
  Size size = const Size(390, 844),
}) async {
  await boot(t, backend, size: size);
  await tapIcon(t, Icons.camera_alt_rounded);
  expect(find.byType(PhotoScreen), findsOneWidget);
  await t.tap(find.text('Hacer foto'));
  await waitFor(t, () => find.byType(PhotoEditorScreen).evaluate().isNotEmpty);
  await idle(t);
  await waitFor(t, _photoReady);
}

Future<void> tapPiece(WidgetTester t, String id) async {
  final piece = find.byKey(Key('photo-piece-$id'));
  await t.ensureVisible(piece);
  await t.pump();
  await t.tap(piece);
  await idle(t);
}

Future<void> tapTool(WidgetTester t, String tooltip) async {
  final tool = find.byTooltip(tooltip);
  await t.ensureVisible(tool);
  await t.pump();
  await t.tap(tool);
  await t.pump();
}

Future<int> albumCount(MemoryBackend backend) async =>
    (await PhotoAlbum(backend).load()).length;

void main() {
  setUp(rootBundle.clear);

  testWidgets('tras hacer la foto se abre «Decorar foto» sin cobrar', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 30));
    await openEditor(t, backend);
    expect(find.text('Decorar foto'), findsOneWidget);
    expect(find.text('Pegatinas'), findsOneWidget);
    expect(find.text('Marcos'), findsOneWidget);
    expect(find.text('Texto'), findsOneWidget);
    expect(await t.runAsync(() => albumCount(backend)), 0);
    expect(saved(backend).coins, 30);
  });

  testWidgets('colocar una pegatina gratis y manejarla con botones', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 0));
    await openEditor(t, backend);
    await tapPiece(t, 'sticker.heart');
    expect(find.byKey(const ValueKey('placed-sticker-0')), findsOneWidget);
    expect(find.text('Pegatina: Corazón'), findsOneWidget);
    final before = t.getSize(find.byKey(const ValueKey('placed-sticker-0')));
    await tapTool(t, 'Más grande');
    final after = t.getSize(find.byKey(const ValueKey('placed-sticker-0')));
    expect(after.width, greaterThan(before.width));
    final topLeft = t.getTopLeft(find.byKey(const ValueKey('placed-sticker-0')));
    await tapTool(t, 'Mover a la derecha');
    expect(
      t.getTopLeft(find.byKey(const ValueKey('placed-sticker-0'))).dx,
      greaterThan(topLeft.dx),
    );
    // Arrastrar con un dedo la mueve.
    final moved = t.getTopLeft(find.byKey(const ValueKey('placed-sticker-0')));
    await t.drag(
      find.byKey(const ValueKey('placed-sticker-0')),
      const Offset(-40, 30),
    );
    await t.pump();
    final dragged = t.getTopLeft(
      find.byKey(const ValueKey('placed-sticker-0')),
    );
    expect(dragged.dy, greaterThan(moved.dy));
    // Etiqueta y acciones accesibles en la pegatina colocada.
    final semantics = t.ensureSemantics();
    final node = t.getSemantics(find.byKey(const ValueKey('placed-sticker-0')));
    expect(node.label, contains('Corazón'));
    semantics.dispose();
    await tapTool(t, 'Borrar pegatina');
    expect(find.byKey(const ValueKey('placed-sticker-0')), findsNothing);
    expect(saved(backend).coins, 0);
  });

  testWidgets('comprar un pack cobra una vez y permite usar sus piezas', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 70));
    await openEditor(t, backend);
    await tapPiece(t, 'sticker.balloon');
    expect(find.text('Desbloquear pack'), findsOneWidget);
    expect(find.text('Fiesta'), findsWidgets);
    await tapText(t, 'Desbloquear');
    expect(saved(backend).coins, 10);
    expect(saved(backend).owned, contains('photo.party'));
    expect(find.byKey(const ValueKey('placed-sticker-0')), findsOneWidget);
    // Otra pieza del mismo pack ya no pide confirmación ni cobra.
    await tapPiece(t, 'sticker.cake');
    expect(find.text('Desbloquear pack'), findsNothing);
    expect(find.byKey(const ValueKey('placed-sticker-1')), findsOneWidget);
    expect(saved(backend).coins, 10);
  });

  testWidgets('pack de la versión completa: candado y «Pide ayuda»', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 500));
    await openEditor(t, backend);
    await tapText(t, 'Marcos');
    await tapPiece(t, 'frame.gold');
    expect(find.byType(AskAdultScreen), findsOneWidget);
    await tapText(t, 'Volver');
    expect(find.byType(PhotoEditorScreen), findsOneWidget);
    expect(saved(backend).coins, 500);
    expect(saved(backend).owned, isNot(contains('photo.frames_luxury')));
  });

  testWidgets('saldo insuficiente muestra lo que falta y no cobra', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 45));
    await openEditor(t, backend);
    await tapText(t, 'Marcos');
    await tapPiece(t, 'frame.pink');
    expect(find.text('Faltan 5 monedas'), findsOneWidget);
    await tapText(t, 'Ahora no');
    expect(find.byType(PhotoEditorScreen), findsOneWidget);
    expect(saved(backend).coins, 45);
  });

  testWidgets('guardar añade una foto decorada al álbum', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 0));
    await openEditor(t, backend);
    await tapPiece(t, 'sticker.star');
    await tapText(t, 'Marcos');
    await tapPiece(t, 'frame.white');
    await tapText(t, 'Texto');
    await t.enterText(
      find.byKey(const Key('photo-editor-text')),
      '¡Feliz día!',
    );
    await t.pump();
    await t.tap(find.byKey(const Key('photo-editor-save')));
    await waitFor(t, () => find.byType(PhotoEditorScreen).evaluate().isEmpty);
    await idle(t);
    expect(find.byType(PhotoScreen), findsOneWidget);
    expect(find.text('Foto guardada en tu álbum.'), findsOneWidget);
    expect(await t.runAsync(() => albumCount(backend)), 1);
    expect(saved(backend).coins, 0);
    // El texto no se guarda en la partida.
    expect(backend.files.values.join(), isNot(contains('Feliz')));
  });

  testWidgets('descartar vuelve sin guardar ni cobrar', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 70));
    await openEditor(t, backend);
    final before = saved(backend);
    await tapPiece(t, 'sticker.heart');
    await t.tap(find.byKey(const Key('photo-editor-discard')));
    await idle(t);
    expect(find.byType(PhotoEditorScreen), findsNothing);
    expect(find.byType(PhotoScreen), findsOneWidget);
    expect(await t.runAsync(() => albumCount(backend)), 0);
    expect(saved(backend).coins, before.coins);
    expect(saved(backend).revision, before.revision);
  });

  testWidgets('cabe a 320×568 con texto ×1,6', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 70));
    t.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await openEditor(t, backend, size: const Size(320, 568));
    expect(t.takeException(), isNull);
    await tapPiece(t, 'sticker.heart');
    expect(t.takeException(), isNull);
    for (final tab in ['Marcos', 'Texto', 'Pegatinas']) {
      await tapText(t, tab);
      expect(t.takeException(), isNull, reason: tab);
    }
  });
}
