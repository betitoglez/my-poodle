import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:my_poodle/data/entitlement_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/needs_clock.dart';
import 'package:my_poodle/store/default_store.dart';
import 'package:my_poodle/store/iap_client.dart';
import 'package:my_poodle/store/iap_store.dart';
import 'package:my_poodle/store/store_controller.dart';
import 'package:my_poodle/store/store_provider.dart';

import '../support.dart';

const id = 'mypoodle.full_version';
final product = ProductDetails(
  id: id,
  title: 'Versión completa',
  description: '',
  price: r'$1.99',
  rawPrice: 1.99,
  currencyCode: 'USD',
);

PurchaseDetails purchase(
  PurchaseStatus status, {
  String productId = id,
  String? transaction = 'transaction-1',
  bool needsCompletion = true,
}) => PurchaseDetails(
  purchaseID: transaction,
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'private-receipt',
    serverVerificationData: 'private-token',
    source: 'test',
  ),
  transactionDate: '1794920000',
  status: status,
)..pendingCompletePurchase = needsCompletion;

class FakeClient implements IapClient {
  final updates = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  bool available = true;
  bool buyStarted = true;
  bool failQuery = false;
  bool failComplete = false;
  int restores = 0;
  int queries = 0;
  ProductDetails? bought;
  void Function()? onBuy;
  List<PurchaseDetails> restoreResult = [];
  List<GooglePlayPurchaseDetails> owned = [];
  IAPError? queryError;
  ProductDetailsResponse response = ProductDetailsResponse(
    productDetails: [product],
    notFoundIDs: [],
  );
  final List<PurchaseDetails> completed = [];
  void Function(PurchaseDetails)? onComplete;
  @override
  Stream<List<PurchaseDetails>> get purchases => updates.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> queryProduct(String id) async => response;
  @override
  Future<bool> buy(ProductDetails product) async {
    bought = product;
    onBuy?.call();
    return buyStarted;
  }

  @override
  Future<void> restore() async {
    restores++;
    updates.add(restoreResult);
  }

  @override
  Future<void> complete(PurchaseDetails p) async {
    if (failComplete) throw StateError('complete failed');
    onComplete?.call(p);
    completed.add(p);
  }

  @override
  Future<QueryPurchaseDetailsResponse> queryAndroidPurchases() async {
    queries++;
    if (failQuery) throw StateError('offline');
    return QueryPurchaseDetailsResponse(
      pastPurchases: owned,
      error: queryError,
    );
  }
}

class FlakyBackend extends MemoryBackend {
  bool failWrites = false;
  @override
  Future<void> write(String name, String text) async {
    if (failWrites) throw StateError('disk full');
    await super.write(name, text);
  }
}

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 25));

void main() {
  late FakeClient client;
  late IapStore store;
  late List<StoreEvent> events;
  setUp(() {
    client = FakeClient();
    store = IapStore(productId: id, android: false, client: client);
    events = [];
  });
  tearDown(() async {
    store.dispose();
    await client.updates.close();
  });

  test('selección nativa en móvil; NoStore en web y escritorio', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      final native = createDefaultStore(id, platform: platform, web: false);
      expect(native, isA<IapStore>());
      native.dispose();
      final web = createDefaultStore(id, platform: platform, web: true);
      expect(web, isA<NoStore>());
      web.dispose();
    }
    final desktop = createDefaultStore(
      id,
      platform: TargetPlatform.macOS,
      web: false,
    );
    expect(desktop, isA<NoStore>());
    desktop.dispose();
  });

  test('precio localizado, producto ausente y tienda no disponible', () async {
    expect((await store.loadProduct(id))!.price, r'$1.99');
    client.available = false;
    expect(await store.loadProduct(id), isNull);
    client.available = true;
    client.response = ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: [id],
    );
    expect(await store.loadProduct(id), isNull);
  });

  test('compra no consumible y rechazo al no iniciar la hoja', () async {
    await store.buy(id);
    expect(client.bought, same(product));
    client.buyStarted = false;
    await expectLater(store.buy(id), throwsStateError);
    await expectLater(store.buy('otro'), throwsStateError);
  });

  test(
    'suscripción temprana, pending → purchased, otros productos ignorados',
    () async {
      store.events.listen(events.add);
      client.updates.add([
        purchase(PurchaseStatus.pending),
        purchase(PurchaseStatus.purchased, productId: 'otro'),
      ]);
      client.updates.add([purchase(PurchaseStatus.purchased)]);
      await flush();
      expect(events.map((e) => e.kind), [
        StoreEventKind.pending,
        StoreEventKind.purchased,
      ]);
      expect(events.first.eventId, isNot(events.last.eventId));
      expect(events.last.eventId, matches(RegExp(r'^[0-9a-f]{64}$')));
      await store.complete(events.first.eventId);
      expect(client.completed, isEmpty);
      await store.complete(events.last.eventId);
      expect(client.completed, hasLength(1));
    },
  );

  test(
    'ID estable al reentregar; completar solo si lo pide el plugin',
    () async {
      store.events.listen(events.add);
      final p = purchase(PurchaseStatus.restored, needsCompletion: false);
      client.updates.add([p, p]);
      await flush();
      expect(events[0].eventId, events[1].eventId);
      await store.complete(events.first.eventId);
      expect(client.completed, isEmpty);
    },
  );

  test(
    'cancelación, error y fallo del stream se traducen sin desbloquear',
    () async {
      store.events.listen(events.add);
      client.updates.add([
        purchase(PurchaseStatus.canceled),
        purchase(PurchaseStatus.error),
      ]);
      client.updates.addError(StateError('native error'));
      await flush();
      expect(events.map((e) => e.kind), [
        StoreEventKind.canceled,
        StoreEventKind.error,
        StoreEventKind.error,
      ]);
    },
  );

  for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
    test(
      'Android: $status sin producto termina el flujo sin guardar ni confirmar',
      () async {
        final android = IapStore(productId: id, android: true, client: client);
        final backend = MemoryBackend();
        final controller = StoreController(
          provider: android,
          entitlements: EntitlementStore(backend, productId: id),
          clock: FakeClock(t0),
        );
        addTearDown(controller.dispose);
        addTearDown(android.dispose);
        await controller.start();
        await flush();
        client.onBuy = () => client.updates.add([
          purchase(status, productId: 'otro', needsCompletion: false),
        ]);
        await controller.buy();
        await flush();
        expect(controller.flow, PurchaseFlow.buying);
        client.updates.add([
          PurchaseDetails(
            purchaseID: '',
            productID: '',
            transactionDate: null,
            verificationData: PurchaseVerificationData(
              localVerificationData: '',
              serverVerificationData: '',
              source: 'google_play',
            ),
            status: status,
          ),
        ]);
        await flush();
        expect(controller.flow, PurchaseFlow.idle);
        expect(
          controller.notice,
          status == PurchaseStatus.canceled
              ? StoreNotice.canceled
              : StoreNotice.error,
        );
        expect(controller.full, isFalse);
        expect(backend.files, isEmpty);
        expect(client.completed, isEmpty);
      },
    );
  }

  test(
    'Android: fallos sin producto fuera de una compra no cambian una pendiente',
    () async {
      final android = IapStore(productId: id, android: true, client: client);
      final backend = MemoryBackend();
      final entitlements = EntitlementStore(backend, productId: id);
      await entitlements.write(
        const Entitlement(state: EntitlementState.pending, updatedUtc: 1),
      );
      final controller = StoreController(
        provider: android,
        entitlements: entitlements,
        clock: FakeClock(t0),
      );
      addTearDown(controller.dispose);
      addTearDown(android.dispose);
      final seen = <StoreEvent>[];
      android.events.listen(seen.add);
      // Consulta inconclusa: la pendiente se conserva al arrancar.
      client.queryError = IAPError(
        source: 'google_play',
        code: 'service_unavailable',
        message: 'sin servicio',
      );
      await controller.start();
      await flush();
      expect(controller.pending, isTrue);
      client.updates.add([
        PurchaseDetails(
          purchaseID: '',
          productID: '',
          transactionDate: null,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          status: PurchaseStatus.canceled,
        ),
      ]);
      client.updates.addError(StateError('native error'));
      await flush();
      expect(seen.map((e) => e.kind), [StoreEventKind.error]);
      expect(seen.single.productId, isNull);
      expect(controller.pending, isTrue);
      expect(
        (await EntitlementStore(backend, productId: id).load()).pending,
        isTrue,
      );
    },
  );

  test(
    'Android: restaurar una transacción pendiente no la desbloquea ni confirma',
    () async {
      final android = IapStore(productId: id, android: true, client: client);
      addTearDown(android.dispose);
      android.events.listen(events.add);
      final pending = GooglePlayPurchaseDetails.fromPurchase(
        PurchaseWrapper(
          orderId: '',
          packageName: 'com.betitoglez.mypoodle',
          purchaseTime: 1794920000,
          purchaseToken: 'pending-token',
          signature: '',
          products: [id],
          isAutoRenewing: false,
          originalJson: '{}',
          isAcknowledged: false,
          purchaseState: PurchaseStateWrapper.pending,
        ),
      ).single..status = PurchaseStatus.restored;
      client.restoreResult = [pending];
      await android.restore();
      await flush();
      expect(events.single.kind, StoreEventKind.pending);
      await android.complete(events.single.eventId);
      expect(client.completed, isEmpty);
      pending.status = PurchaseStatus.canceled;
      client.updates.add([pending]);
      await flush();
      expect(events.last.kind, StoreEventKind.canceled);
      await android.complete(events.last.eventId);
      expect(
        client.completed,
        isEmpty,
        reason: 'tampoco se confirma una pendiente cancelada',
      );
      client.updates.add([
        purchase(
          PurchaseStatus.purchased,
          productId: '',
          transaction: '',
          needsCompletion: false,
        ),
      ]);
      await flush();
      expect(
        events,
        hasLength(2),
        reason: 'una compra sin producto nunca entrega contenido',
      );
    },
  );

  test(
    'no consultar ni restaurar al arrancar iOS; restauración explícita',
    () async {
      store.events.listen(events.add);
      expect(store.silentOwnershipQuery, isFalse);
      expect(await store.queryOwnership(id), StoreOwnership.unknown);
      expect([client.queries, client.restores], [0, 0]);
      client.restoreResult = [purchase(PurchaseStatus.restored)];
      await store.restore();
      await flush();
      expect(events.single.kind, StoreEventKind.restored);
      client.available = false;
      await expectLater(store.restore(), throwsStateError);
    },
  );

  test(
    'Android: ausencia confirmada revoca; error o sin tienda es unknown',
    () async {
      final android = IapStore(productId: id, android: true, client: client);
      addTearDown(android.dispose);
      expect(await android.queryOwnership(id), StoreOwnership.notOwned);
      client.failQuery = true;
      expect(await android.queryOwnership(id), StoreOwnership.unknown);
      client.failQuery = false;
      client.queryError = IAPError(
        source: 'test',
        code: 'offline',
        message: '',
      );
      expect(await android.queryOwnership(id), StoreOwnership.unknown);
      client.queryError = null;
      client.available = false;
      expect(await android.queryOwnership(id), StoreOwnership.unknown);
    },
  );

  test(
    'Android: compra consultada se reentrega y pendiente no revoca',
    () async {
      final android = IapStore(productId: id, android: true, client: client);
      addTearDown(android.dispose);
      android.events.listen(events.add);
      GooglePlayPurchaseDetails from(PurchaseStateWrapper state) =>
          GooglePlayPurchaseDetails.fromPurchase(
            PurchaseWrapper(
              orderId: 'order-1',
              packageName: 'dev.mypoodle.my_poodle',
              purchaseTime: 1794920000,
              purchaseToken: 'token',
              signature: '',
              products: [id],
              isAutoRenewing: false,
              originalJson: '{}',
              isAcknowledged: false,
              purchaseState: state,
            ),
          ).single;
      client.owned = [from(PurchaseStateWrapper.pending)];
      expect(await android.queryOwnership(id), StoreOwnership.unknown);
      await flush();
      expect(events.single.kind, StoreEventKind.pending);
      client.owned = [from(PurchaseStateWrapper.purchased)];
      expect(await android.queryOwnership(id), StoreOwnership.owned);
      await flush();
      expect(events.last.kind, StoreEventKind.purchased);
      await android.complete(events.last.eventId);
      expect(client.completed, hasLength(1));
    },
  );

  test('StoreKit: revocationDate es revocación, no una compra nueva', () async {
    store.events.listen(events.add);
    client.updates.add([
      SK2PurchaseDetails(
        productID: id,
        purchaseID: '1',
        transactionDate: '1794920000',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'app_store',
        ),
        status: PurchaseStatus.purchased,
        sk2Transaction: SK2Transaction(
          id: '1',
          originalId: '1',
          productId: id,
          purchaseDate: '1794920000',
          appAccountToken: null,
          jsonRepresentation: '{"revocationDate":1794920100}',
        ),
      ),
    ]);
    await flush();
    expect(events.single.kind, StoreEventKind.revoked);
    await store.complete(events.single.eventId);
    expect(client.completed, hasLength(1));
  });

  test(
    'guarda antes de completar; fallo de disco y reentrega, sin datos privados',
    () async {
      final backend = FlakyBackend();
      final c = StoreController(
        provider: store,
        entitlements: EntitlementStore(
          backend,
          productId: id,
          acceptSimulated: false,
        ),
        clock: FakeClock(t0),
      );
      // dispose es idempotente: el controlador y tearDown comparten proveedor.
      await c.start();
      client.onComplete = (_) {
        expect(c.full, isTrue);
        expect(backend.files[EntitlementStore.primary], contains('purchased'));
      };
      final p = purchase(PurchaseStatus.purchased);
      backend.failWrites = true;
      client.updates.add([p]);
      await flush();
      expect(c.full, isFalse);
      expect(client.completed, isEmpty);
      backend.failWrites = false;
      client.failComplete = true;
      client.updates.add([p]);
      await flush();
      expect(c.full, isTrue);
      expect(client.completed, isEmpty);
      client.failComplete = false;
      client.updates.add([p]);
      await flush();
      expect(client.completed, hasLength(1));
      final text = backend.files.values.join();
      for (final private in [
        'transaction-1',
        'private-receipt',
        'private-token',
      ]) {
        expect(text, isNot(contains(private)));
      }
      c.dispose();
    },
  );
}
