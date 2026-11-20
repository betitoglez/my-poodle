import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/l10n/app_strings.dart';
import 'package:my_poodle/ui/widgets/sandbox_refund_button.dart';

Future<void> openButton(WidgetTester t) async {
  await t.pumpWidget(
    const MaterialApp(
      locale: Locale('es'),
      supportedLocales: [Locale('es')],
      localizationsDelegates: [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(body: SandboxRefundButton()),
    ),
  );
  for (var i = 0; i < 40; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 16));
    if (find.byKey(const Key('sandbox-refund')).evaluate().isNotEmpty) break;
  }
  await t.pumpAndSettle();
  expect(find.byKey(const Key('sandbox-refund')), findsOneWidget);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);
  tearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SandboxRefundButton.channel,
      null,
    ),
  );

  testWidgets(
    'una solicitud nativa, sin duplicar mientras la hoja está abierta',
    (t) async {
      final result = Completer<String>();
      var requests = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SandboxRefundButton.channel,
        (call) {
          expect(call.method, 'requestSandboxRefund');
          expect(call.arguments, isNull);
          requests++;
          return result.future;
        },
      );
      await openButton(t);
      await t.tap(find.byKey(const Key('sandbox-refund')));
      await t.pump();
      expect(
        t.widget<TextButton>(find.byKey(const Key('sandbox-refund'))).onPressed,
        isNull,
      );
      await t.tap(find.byKey(const Key('sandbox-refund')));
      expect(requests, 1);
      result.complete('submitted');
      await t.pumpAndSettle();
      expect(find.text('Solicitud enviada'), findsOneWidget);
      expect(
        find.text('¡Gracias! Ya tienes la versión completa'),
        findsNothing,
      );
    },
  );

  testWidgets('cancelar la hoja no anuncia un reembolso enviado', (t) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SandboxRefundButton.channel,
      (_) async => 'cancelled',
    );
    await openButton(t);
    await t.tap(find.byKey(const Key('sandbox-refund')));
    await t.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(
      t.widget<TextButton>(find.byKey(const Key('sandbox-refund'))).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'rechazo nativo muestra error genérico sin detalles de transacción',
    (t) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SandboxRefundButton.channel,
        (_) async => throw PlatformException(
          code: 'sandbox_only',
          message: 'private native detail',
        ),
      );
      await openButton(t);
      await t.tap(find.byKey(const Key('sandbox-refund')));
      await t.pumpAndSettle();
      expect(
        find.text('No se ha podido completar. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.textContaining('private native detail'), findsNothing);
    },
  );
}
