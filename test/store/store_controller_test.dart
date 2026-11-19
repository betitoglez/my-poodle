import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/entitlement_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/store/store_controller.dart';
import 'package:my_poodle/store/store_provider.dart';

import '../support.dart';

const id = 'mypoodle.full_version';

/// Almacenamiento que puede fallar al escribir.
class FlakyBackend extends MemoryBackend {
  bool failWrites = false;
  @override
  Future<void> write(String name, String text) async {
    if (failWrites) throw StateError('disco lleno');
    return super.write(name, text);
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

class DeferredOwnershipStore extends SimulatedStore {
  DeferredOwnershipStore()
    : super(delay: Duration.zero, silentOwnershipQuery: false);
  final result = Completer<StoreOwnership>();
  @override
  Future<StoreOwnership> queryOwnership(String id) => result.future;
}

void main() {
  late FlakyBackend backend;
  late SimulatedStore store;

  StoreController make() => StoreController(
    provider: store,
    entitlements: EntitlementStore(backend, productId: id),
    clock: FakeClock(t0),
    simulated: true,
  );

  setUp(() {
    backend = FlakyBackend();
    store = SimulatedStore(delay: Duration.zero);
  });

  test('compra: guarda, publica y después cierra la transacción', () async {
    final c = make();
    await c.start();
    await settle();
    expect(c.productStatus, ProductStatus.available);
    expect(c.product!.price, '1,99 €');
    await c.buy();
    await settle();
    expect(c.full, isTrue);
    expect(c.notice, StoreNotice.thanks);
    expect(backend.files.containsKey(EntitlementStore.primary), isTrue);
    expect(store.completed, hasLength(1));
  });

  test('cancelada, error y pendiente no desbloquean; aprobada sí', () async {
    final c = make();
    await c.start();
    store.next = SimulatedOutcome.cancel;
    await c.buy();
    await settle();
    expect([c.full, c.notice], [false, StoreNotice.canceled]);
    store.next = SimulatedOutcome.error;
    await c.buy();
    await settle();
    expect([c.full, c.notice], [false, StoreNotice.error]);
    store.next = SimulatedOutcome.pending;
    await c.buy();
    await settle();
    expect([c.full, c.pending, c.notice], [false, true, StoreNotice.pending]);
    store.approvePending();
    await settle();
    expect(c.full, isTrue);
  });

  test('pendiente rechazada vuelve a gratis', () async {
    final c = make();
    await c.start();
    store.next = SimulatedOutcome.pending;
    await c.buy();
    await settle();
    store.declinePending();
    await settle();
    expect([c.full, c.pending], [false, false]);
  });

  test('sin red: producto no disponible y la compra no cambia nada', () async {
    store.online = false;
    final c = make();
    await c.start();
    await settle();
    expect(c.productStatus, ProductStatus.unavailable);
    await c.buy();
    await settle();
    expect([c.full, c.notice], [false, StoreNotice.error]);
  });

  test(
    'E15 · si no se guarda, no se cierra; al reentregar se aplica',
    () async {
      final c = make();
      await c.start();
      backend.failWrites = true;
      store.emit(
        const StoreEvent(
          StoreEventKind.purchased,
          eventId: 'b1',
          productId: id,
        ),
      );
      await settle();
      expect(c.full, isFalse);
      expect(store.completed, isEmpty);
      backend.failWrites = false;
      store.emit(
        const StoreEvent(
          StoreEventKind.purchased,
          eventId: 'b1',
          productId: id,
        ),
      );
      await settle();
      expect(c.full, isTrue);
      expect(store.completed, ['b1']);
    },
  );

  test('E15 · sin red con caché completa sigue completa', () async {
    await EntitlementStore(backend, productId: id).write(
      const Entitlement(state: EntitlementState.purchased, updatedUtc: t0),
    );
    store
      ..online = false
      ..owned = false;
    final c = make();
    await c.start();
    await settle();
    expect(c.full, isTrue);
  });

  test(
    'E15 · consulta notOwned revoca; owned restaura; duplicados ignorados',
    () async {
      await EntitlementStore(backend, productId: id).write(
        const Entitlement(state: EntitlementState.purchased, updatedUtc: t0),
      );
      final c = make();
      await c.start();
      await settle();
      expect(c.full, isFalse, reason: 'la tienda confirma que no lo posee');
      store.owned = true;
      await c.checkOwnership();
      expect(c.full, isTrue);
      store.refund();
      await settle();
      expect(c.full, isFalse);
      store.emit(
        const StoreEvent(
          StoreEventKind.purchased,
          eventId: 'z',
          productId: 'otro',
        ),
      );
      await settle();
      expect(c.full, isFalse);
    },
  );

  test(
    'pendiente desaparecida se cancela solo ante ausencia confirmada',
    () async {
      final c = make();
      addTearDown(c.dispose);
      await c.start();
      await settle();
      store.next = SimulatedOutcome.pending;
      await c.buy();
      await settle();
      expect(c.pending, isTrue);
      store.online = false;
      await c.checkOwnership();
      expect(c.pending, isTrue);
      store.online = true;
      await c.checkOwnership();
      expect(c.pending, isFalse);
      expect(c.full, isFalse);
      expect(c.notice, StoreNotice.canceled);
    },
  );

  test('restaurar sin compras avisa; con compra desbloquea', () async {
    final c = make();
    await c.start();
    await c.restore();
    expect(c.notice, StoreNotice.nothingToRestore);
    store.owned = true;
    await c.restore();
    await settle();
    expect(c.full, isTrue);
  });

  test('demostración: derecho en memoria, nunca escribe', () async {
    final c = make();
    await c.start();
    await settle();
    c.setDemo(Entitlement.none);
    await c.buy();
    expect(c.full, isTrue);
    expect(backend.files.containsKey(EntitlementStore.primary), isFalse);
    c.setDemo(null);
    expect(c.full, isFalse);
  });

  test('una consulta antigua no revoca una compra recién recibida', () async {
    final provider = DeferredOwnershipStore();
    final c = StoreController(
      provider: provider,
      entitlements: EntitlementStore(backend, productId: id),
      clock: FakeClock(t0),
    );
    addTearDown(c.dispose);
    await c.start();
    final query = c.checkOwnership();
    provider.emit(
      const StoreEvent(
        StoreEventKind.purchased,
        eventId: 'new-buy',
        productId: id,
      ),
    );
    await settle();
    expect(c.full, isTrue);
    provider.result.complete(StoreOwnership.notOwned);
    await query;
    expect(c.full, isTrue);
  });

  test('un evento de otro producto no interrumpe la compra activa', () async {
    store.next = SimulatedOutcome.pending;
    final c = make();
    await c.start();
    await c.buy();
    await settle();
    expect(c.pending, isTrue);
    store.emit(
      const StoreEvent(
        StoreEventKind.error,
        eventId: 'other-error',
        productId: 'otro',
      ),
    );
    await settle();
    expect(c.notice, StoreNotice.pending);
    expect(c.pending, isTrue);
    c.dispose();
  });

  test('NoStore: sin producto y sin cambios', () async {
    final c = StoreController(
      provider: NoStore(),
      entitlements: EntitlementStore(backend, productId: id),
      clock: FakeClock(t0),
    );
    await c.start();
    await settle();
    expect(c.productStatus, ProductStatus.unavailable);
    expect(c.full, isFalse);
  });
}
