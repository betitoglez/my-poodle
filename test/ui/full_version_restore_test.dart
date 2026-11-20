import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/ui/parental_gate.dart';

import 'app_flow_test.dart'
    show boot, adopt, openAdultZone, scrollTo, tapText, idle;

class _RestoreStore extends SimulatedStore {
  _RestoreStore() : super(owned: true, delay: Duration.zero);

  int restoreCalls = 0;
  Completer<void>? waitForRestore;
  bool failRestore = false;
  bool nothingFound = false;

  @override
  Future<void> restore() async {
    restoreCalls++;
    if (waitForRestore != null) await waitForRestore!.future;
    if (failRestore) throw StateError('offline');
    if (nothingFound) return;
    await super.restore();
  }
}

void main() {
  setUp(() {
    rootBundle.clear();
    ParentalGate.nextNumber = () => 47;
  });
  tearDown(ParentalGate.reset);

  testWidgets('restaurar sigue accesible con compra y conserva la partida', (
    t,
  ) async {
    final backend = MemoryBackend();
    final store = _RestoreStore();
    await boot(t, backend, store: store, size: const Size(320, 568));
    await adopt(t, 'Nube');
    final before = backend.files[SaveStore.primary];
    await openAdultZone(t);
    await scrollTo(t, find.text('Ver versión completa y restaurar compras'));
    await tapText(t, 'Ver versión completa y restaurar compras');
    await scrollTo(t, find.text('¡Gracias! Ya tienes la versión completa'));
    expect(
      find.text('¡Gracias! Ya tienes la versión completa'),
      findsOneWidget,
    );
    await scrollTo(t, find.text('Restaurar compras'));

    store.waitForRestore = Completer<void>();
    await t.tap(find.text('Restaurar compras'));
    await t.pump();
    expect(find.text('Restaurando compras…'), findsOneWidget);
    expect(
      t.widget<TextButton>(find.byKey(const Key('restore'))).onPressed,
      isNull,
    );
    store.waitForRestore!.complete();
    await idle(t);
    expect(store.restoreCalls, 1);
    expect(
      find.text('¡Gracias! Ya tienes la versión completa'),
      findsOneWidget,
    );
    expect(backend.files[SaveStore.primary], before);

    store.waitForRestore = null;
    store.failRestore = true;
    await scrollTo(t, find.text('Restaurar compras'));
    await tapText(t, 'Restaurar compras');
    expect(
      find.text('No se ha podido completar. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(
      find.text('¡Gracias! Ya tienes la versión completa'),
      findsOneWidget,
    );
    expect(backend.files[SaveStore.primary], before);
    expect(store.restoreCalls, 2);

    store.failRestore = false;
    store.nothingFound = true;
    await scrollTo(t, find.text('Restaurar compras'));
    await tapText(t, 'Restaurar compras');
    expect(
      find.text(
        'No hay compras nuevas que restaurar. Tu versión completa sigue activa.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('¡Gracias! Ya tienes la versión completa'),
      findsOneWidget,
    );
    expect(backend.files[SaveStore.primary], before);
    expect(store.restoreCalls, 3);
    expect(t.takeException(), isNull);
  });
}
