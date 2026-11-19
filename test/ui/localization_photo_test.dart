import 'package:my_poodle/ui/widgets/dialogs.dart';
import 'package:my_poodle/ui/screens/main_shell.dart';

import 'dart:convert';

import 'package:my_poodle/data/save_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/data/photo_album.dart';
import 'package:my_poodle/l10n/app_strings.dart';
import 'package:my_poodle/ui/screens/games_screen.dart';
import 'package:my_poodle/ui/screens/photo_screen.dart';
import 'package:my_poodle/ui/parental_gate.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import 'app_flow_test.dart' show boot, idle, tapIcon, saved;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);
  for (final language in AppLanguage.all) {
    testWidgets(
      '${language.tag}: name, narrow photo screen, games and adult gate',
      (t) async {
        final backend = backendWith(
          (s) => s.copyWith(prefs: s.prefs.copyWith(language: language.tag)),
        );
        final fixture = jsonDecode(
          backend.files[SaveStore.primary]!,
        ) as Map<String, dynamic>;
        fixture['name'] = 'Casa';
        backend.files[SaveStore.primary] = jsonEncode(fixture);
        await boot(t, backend, size: const Size(320, 568));
        expect(
          find.descendant(
            of: find.byType(TabHeader),
            matching: find.text('Casa'),
          ),
          findsOneWidget,
        );
        var context = t.element(find.byType(StatusBubbles));
        expect(AppStrings.of(context).language.tag, language.tag);
        await tapIcon(t, Icons.camera_alt_rounded);
        expect(find.byType(PhotoScreen), findsOneWidget);
        expect(
          t.takeException(),
          isNull,
          reason: 'Photo layout: ${language.tag}',
        );
        final before = saved(backend);
        await tapIcon(t, Icons.photo_library_rounded);
        expect(find.byType(PhotoAlbumScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        expect((await PhotoAlbum(backend).load()), isEmpty);
        await t.tap(find.byType(BackButton));
        await idle(t);
        await t.tap(find.byType(BackButton));
        await idle(t);
        expect(saved(backend).appearance.toJson(), before.appearance.toJson());
        expect(saved(backend).coins, before.coins);
        context = t.element(find.byType(StatusBubbles));
        await t.tap(find.text(AppStrings.of(context).text('Juegos')).last);
        await idle(t);
        expect(find.byType(GamesScreen), findsOneWidget);
        expect(
          t.takeException(),
          isNull,
          reason: 'Games layout: ${language.tag}',
        );
        context = t.element(find.byType(GamesScreen));
        ParentalGate.reset();
        ParentalGate.nextNumber = () => 21;
        final result = ParentalGate.show(context);
        await idle(t);
        expect(
          find.textContaining(AppStrings.of(context).numberWords(21)),
          findsWidgets,
        );
        expect(
          t.takeException(),
          isNull,
          reason: 'Adult gate layout: ${language.tag}',
        );
        await t.enterText(find.byType(TextField), '21');
        await t.pump();
        await t.tap(find.text(AppStrings.of(context).text('Continuar')).last);
        await idle(t);
        expect(await result, isTrue);
        ParentalGate.reset();
        final controller = AppScope.read(context);
        expect(controller.prefs.language, language.tag);
      },
    );
  }
  testWidgets('purchase confirmation translates each selected wardrobe item', (
    t,
  ) async {
    await boot(
      t,
      backendWith((s) => s.copyWith(prefs: s.prefs.copyWith(language: 'en'))),
    );
    final context = t.element(find.byType(StatusBubbles));
    final strings = AppStrings.of(context);
    final result = showPurchaseDialog(
      context,
      items: ['Corte osito', 'Lazo rosa'],
      price: 20,
      balance: 42,
    );
    await idle(t);
    expect(
      find.text(
        '${strings.text('Corte osito')} · ${strings.text('Lazo rosa')}',
      ),
      findsOneWidget,
    );
    expect(find.text('Corte osito · Lazo rosa'), findsNothing);
    await t.tap(find.text(strings.text('Cancelar')));
    await idle(t);
    expect(await result, isFalse);
  });
  testWidgets('unsupported persisted language falls back safely in Settings', (
    t,
  ) async {
    await boot(
      t,
      backendWith(
        (s) => s.copyWith(prefs: s.prefs.copyWith(language: 'future-language')),
      ),
    );
    await tapIcon(t, Icons.settings_rounded);
    expect(t.takeException(), isNull);
    expect(
      t
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      'en',
    );
  });
}
