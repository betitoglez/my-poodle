import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../domain/entitlements.dart';
import 'iap_client.dart';
import 'store_provider.dart';

/// Un producto no consumible. La suscripción nativa empieza cuando el
/// StoreController escucha events, antes de consultar el producto o Casa.
class IapStore implements StoreProvider {
  IapStore({
    required this.productId,
    required this.android,
    IapClient? client,
    this.queryTimeout = const Duration(seconds: 15),
  }) : _client = client ?? NativeIapClient() {
    _events = StreamController<StoreEvent>.broadcast(onListen: _listen);
  }

  final String productId;
  final bool android;
  final Duration queryTimeout;
  final IapClient _client;
  late final StreamController<StoreEvent> _events;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, PurchaseDetails> _unfinished = {};
  ProductDetails? _product;
  bool _disposed = false;
  int _sequence = 0;

  /// Hay una hoja de compra abierta por [buy]. Solo entonces se aceptan los
  /// fallos genéricos de Android sin producto.
  bool _buying = false;

  @override
  Stream<StoreEvent> get events => _events.stream;
  @override
  bool get supported => true;
  @override
  bool get silentOwnershipQuery => android;
  @override
  String get name => android ? 'Google Play' : 'App Store';

  void _listen() {
    if (_subscription != null || _disposed) return;
    try {
      _subscription = _client.purchases.listen(
        _receive,
        onError: (Object _) => _error('purchase_stream'),
      );
    } catch (_) {
      _error('purchase_stream');
    }
  }

  void _error(String code) {
    if (_disposed) return;
    _events.add(
      StoreEvent(
        StoreEventKind.error,
        eventId: 'iap-error-${++_sequence}',
        // Error del adaptador, no de una transacción: no cambia el derecho.
        code: code,
      ),
    );
  }

  void _receive(List<PurchaseDetails> purchases) {
    if (_disposed) return;
    for (final p in purchases) {
      // Android emite cancelación/error sin producto cuando se cierra la hoja
      // antes de crear una transacción. Nunca admitir éxitos sin producto.
      final genericFailure =
          android &&
          _buying &&
          p.productID.isEmpty &&
          (p.status == PurchaseStatus.canceled ||
              p.status == PurchaseStatus.error);
      if (p.productID != productId && !genericFailure) continue;
      // La respuesta a la hoja abierta (no una reentrega de la consulta).
      if (p.status != PurchaseStatus.restored) _buying = false;
      var kind = switch (p.status) {
        PurchaseStatus.pending => StoreEventKind.pending,
        PurchaseStatus.purchased => StoreEventKind.purchased,
        PurchaseStatus.restored => StoreEventKind.restored,
        PurchaseStatus.canceled => StoreEventKind.canceled,
        PurchaseStatus.error => StoreEventKind.error,
      };
      // restorePurchases del plugin Android marca también las pendientes
      // como restored: para entregar contenido manda el estado nativo.
      if (android &&
          p is GooglePlayPurchaseDetails &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored)) {
        final state = p.billingClientPurchase.purchaseState;
        if (state == PurchaseStateWrapper.pending) {
          kind = StoreEventKind.pending;
        } else if (state != PurchaseStateWrapper.purchased) {
          _error('invalid_android_purchase_state');
          continue;
        }
      }
      // StoreKit 2 entrega también reembolsos como purchased. Solo se lee
      // el JSON de la transacción verificada que expone el plugin, en memoria.
      if (p is SK2PurchaseDetails &&
          p.sk2Transaction?.jsonRepresentation != null) {
        try {
          final transaction = jsonDecode(p.sk2Transaction!.jsonRepresentation!);
          if (transaction is Map && transaction['revocationDate'] != null) {
            kind = StoreEventKind.revoked;
          }
        } on FormatException {
          _error('invalid_storekit_transaction');
          continue;
        }
      }
      // Incluir el estado evita que pending oculte la posterior aprobación.
      // SHA-256 estable entre arranques; jamás persistir IDs ni recibos.
      final identity =
          (p.purchaseID?.isNotEmpty == true ? p.purchaseID : null) ??
          (p.verificationData.serverVerificationData.isNotEmpty
              ? p.verificationData.serverVerificationData
              : p.transactionDate);
      if ((kind == StoreEventKind.purchased ||
              kind == StoreEventKind.restored) &&
          (identity == null || identity.isEmpty)) {
        _error('missing_transaction_identity');
        continue;
      }
      final eventId = sha256
          .convert(
            utf8.encode(
              jsonEncode([
                productId,
                kind.name,
                identity ?? 'transient-${++_sequence}',
              ]),
            ),
          )
          .toString();
      final nativePending =
          android &&
          p is GooglePlayPurchaseDetails &&
          p.billingClientPurchase.purchaseState == PurchaseStateWrapper.pending;
      if (!genericFailure &&
          !nativePending &&
          p.pendingCompletePurchase &&
          kind != StoreEventKind.pending) {
        _unfinished[eventId] = p;
      }
      _events.add(
        StoreEvent(
          kind,
          eventId: eventId,
          productId: genericFailure ? null : productId,
          code: p.error?.code,
        ),
      );
    }
  }

  Future<bool> _available() => _client.isAvailable().timeout(queryTimeout);

  @override
  Future<StoreProduct?> loadProduct(String id) async {
    _product = null;
    if (id != productId || !await _available()) return null;
    final response = await _client.queryProduct(id).timeout(queryTimeout);
    if (response.error != null || response.notFoundIDs.contains(id)) {
      return null;
    }
    for (final product in response.productDetails) {
      if (product.id == id) {
        _product = product;
        return StoreProduct(id: id, title: product.title, price: product.price);
      }
    }
    return null;
  }

  @override
  Future<void> buy(String id) async {
    if (id != productId) throw StateError('Otro producto');
    if (_product == null) await loadProduct(id);
    final product = _product;
    if (product == null) throw StateError('Producto no disponible');
    // No limitar la duración de la hoja nativa: puede pedir aprobación adulta.
    _buying = true;
    try {
      if (!await _client.buy(product)) {
        throw StateError('La tienda no ha iniciado la compra');
      }
    } catch (_) {
      _buying = false;
      rethrow;
    }
  }

  @override
  Future<void> restore() async {
    if (!await _available()) throw StateError('Tienda no disponible');
    // Solo desde una intención del adulto; nunca se restaura al arrancar iOS.
    await _client.restore();
  }

  @override
  Future<StoreOwnership> queryOwnership(String id) async {
    if (!android || id != productId) return StoreOwnership.unknown;
    try {
      if (!await _available()) return StoreOwnership.unknown;
      final response = await _client.queryAndroidPurchases().timeout(
        queryTimeout,
      );
      if (response.error != null) return StoreOwnership.unknown;
      final mine = response.pastPurchases
          .where((p) => p.productID == id)
          .toList();
      // Reentregar para guardar y confirmar compras aún sin acknowledgement.
      _receive(mine);
      if (mine.any(
        (p) =>
            p.billingClientPurchase.purchaseState ==
            PurchaseStateWrapper.purchased,
      )) {
        return StoreOwnership.owned;
      }
      // Una pendiente no demuestra ausencia de propiedad.
      return mine.isEmpty ? StoreOwnership.notOwned : StoreOwnership.unknown;
    } catch (_) {
      return StoreOwnership.unknown;
    }
  }

  @override
  Future<void> complete(String eventId) async {
    final purchase = _unfinished[eventId];
    if (purchase == null) return;
    await _client.complete(purchase);
    // Conservarla si el plugin falla; no cerrar antes del guardado confirmado.
    if (identical(_unfinished[eventId], purchase)) _unfinished.remove(eventId);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    _unfinished.clear();
    unawaited(_events.close());
  }
}
