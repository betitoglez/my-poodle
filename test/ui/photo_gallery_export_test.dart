import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/data/photo_album.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/l10n/app_strings.dart';
import 'package:my_poodle/platform/photo_gallery.dart';
import 'package:my_poodle/ui/parental_gate.dart';
import 'package:my_poodle/ui/screens/photo_screen.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGP43+DwH4QZHBr+/wdhAGBOCvmXKY6pAAAAAElFTkSuQmCC',
);

Future<void> settle(WidgetTester t, bool Function() ready) async {
  for (var i = 0; i < 50 && !ready(); i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 16));
  }
  await t.pumpAndSettle();
}

Future<AlbumPhoto> openDetail(WidgetTester t) async {
  final album = PhotoAlbum(MemoryBackend());
  final photo = await album.save(png, now: DateTime.utc(2026, 11, 20));
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: PhotoDetailScreen(album: album, photo: photo),
    ),
  );
  final button = find.byKey(const Key('photo-export'));
  await settle(
    t,
    () =>
        button.evaluate().isNotEmpty &&
        find
            .descendant(
              of: button,
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .evaluate()
            .any((e) => (e.widget as ButtonStyleButton).onPressed != null),
  );
  expect(button, findsOneWidget);
  return photo;
}

Future<void> passGate(WidgetTester t, {bool pass = true}) async {
  await t.tap(find.byKey(const Key('photo-export')));
  await t.pumpAndSettle();
  expect(find.byType(TextField), findsOneWidget);
  if (pass) {
    await t.enterText(find.byType(TextField), '21');
    await t.pump();
    await t.tap(find.text('Continuar'));
  } else {
    await t.tap(find.text('Cancelar'));
  }
  await settle(t, () => find.byType(SnackBar).evaluate().isNotEmpty);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    rootBundle.clear();
    ParentalGate.reset();
    ParentalGate.nextNumber = () => 21;
  });
  tearDown(() {
    ParentalGate.reset();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoGallery.channel,
      null,
    );
  });

  void answer(Object? Function(MethodCall call) reply, List<MethodCall> log) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoGallery.channel,
      (call) async {
        log.add(call);
        return reply(call);
      },
    );
  }

  testWidgets(
    'la puerta adulta protege el carrete: cancelar no llama al canal',
    (t) async {
      final calls = <MethodCall>[];
      answer((_) => 'saved', calls);
      await openDetail(t);
      await passGate(t, pass: false);
      expect(calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('tras la puerta envía el PNG del álbum y confirma el guardado', (
    t,
  ) async {
    final calls = <MethodCall>[];
    answer((_) => 'saved', calls);
    final photo = await openDetail(t);
    await passGate(t);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'saveToGallery');
    final args = calls.single.arguments as Map;
    expect(args['bytes'], png);
    expect(args['name'], 'MyPoodle-${photo.id}');
    expect(find.text('Foto guardada en el carrete del móvil.'), findsOneWidget);
  });

  testWidgets('sin permiso del sistema explica cómo activarlo', (t) async {
    answer((_) => 'denied', []);
    await openDetail(t);
    await passGate(t);
    expect(
      find.text(
        'Sin permiso para guardar en el carrete. Actívalo en los ajustes del móvil.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un fallo nativo no rompe la pantalla y permite reintentar', (
    t,
  ) async {
    final calls = <MethodCall>[];
    answer((_) => throw PlatformException(code: 'failed'), calls);
    await openDetail(t);
    await passGate(t);
    expect(
      find.text(
        'No se ha podido guardar la foto en el carrete. Inténtalo de nuevo.',
      ),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    final button = t.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(const Key('photo-export')),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(button.onPressed, isNotNull);
    expect(calls, hasLength(1));
  });

  test('traduce respuestas y errores del canal', () async {
    final replies = <Object? Function()>[
      () => 'saved',
      () => 'denied',
      () => 'raro',
      () => throw PlatformException(code: 'denied'),
      () => throw PlatformException(code: 'failed'),
    ];
    final results = <GalleryExportResult>[];
    for (final reply in replies) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PhotoGallery.channel,
        (_) async => reply(),
      );
      results.add(await PhotoGallery.save(png, name: 'x'));
    }
    expect(results, [
      GalleryExportResult.saved,
      GalleryExportResult.denied,
      GalleryExportResult.failed,
      GalleryExportResult.denied,
      GalleryExportResult.failed,
    ]);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PhotoGallery.channel,
      null,
    );
    expect(await PhotoGallery.save(png, name: 'x'), GalleryExportResult.failed);
  });
}
