import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/ui/parental_gate.dart';

import 'app_flow_test.dart'
    show boot, adopt, openAdultZone, scrollTo, tapText, idle;

class _AskToBuyStore extends SimulatedStore {
  _AskToBuyStore({required super.silentOwnershipQuery})
    : super(delay: Duration.zero);

  int buyCalls = 0;

  @override
  Future<void> buy(String id) async {
    buyCalls++;
    await super.buy(id);
  }
}

void main() {
  setUp(() {
    rootBundle.clear();
    ParentalGate.nextNumber = () => 47;
  });
  tearDown(ParentalGate.reset);

  testWidgets('iOS: rechazo sin evento permite otra solicitud y aprobación', (
    t,
  ) async {
    final store = _AskToBuyStore(silentOwnershipQuery: false)
      ..next = SimulatedOutcome.pending;
    await boot(t, MemoryBackend(), store: store, size: const Size(320, 568));
    await adopt(t, 'Nube');
    await openAdultZone(t);
    await scrollTo(t, find.text('Versión completa y restaurar compras'));
    await tapText(t, 'Versión completa y restaurar compras');
    await scrollTo(t, find.text('Desbloquear por 1,99 €'));
    await tapText(t, 'Desbloquear por 1,99 €');
    expect(store.buyCalls, 1);
    expect(find.text('¡Gracias! Ya tienes la versión completa'), findsNothing);

    // StoreKit no entrega un evento cuando se rechaza Ask to Buy. No emitir
    // canceled: la app debe seguir ofreciendo otra solicitud sin ese evento.
    await idle(t);
    await scrollTo(t, find.text('Desbloquear por 1,99 €'));
    await tapText(t, 'Desbloquear por 1,99 €');
    expect(store.buyCalls, 2);
    expect(find.text('¡Gracias! Ya tienes la versión completa'), findsNothing);

    store.approvePending();
    await idle(t);
    await scrollTo(t, find.text('¡Gracias! Ya tienes la versión completa'));
    expect(
      find.text('¡Gracias! Ya tienes la versión completa'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('tienda con consulta de pendientes conserva la espera', (
    t,
  ) async {
    final store = _AskToBuyStore(silentOwnershipQuery: true)
      ..next = SimulatedOutcome.pending;
    await boot(t, MemoryBackend(), store: store, size: const Size(320, 568));
    await adopt(t, 'Nube');
    await openAdultZone(t);
    await scrollTo(t, find.text('Versión completa y restaurar compras'));
    await tapText(t, 'Versión completa y restaurar compras');
    await scrollTo(t, find.text('Desbloquear por 1,99 €'));
    await tapText(t, 'Desbloquear por 1,99 €');
    expect(store.buyCalls, 1);
    expect(find.text('Desbloquear por 1,99 €'), findsNothing);
    expect(
      find.text(
        'Esperando la aprobación. Se desbloqueará cuando la tienda confirme el pago.',
      ),
      findsOneWidget,
    );
    expect(find.text('¡Gracias! Ya tienes la versión completa'), findsNothing);
  });
}
