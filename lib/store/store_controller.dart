import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/entitlement_store.dart';
import '../domain/entitlements.dart';
import '../domain/needs_clock.dart';
import 'store_provider.dart';

enum ProductStatus { loading, available, unavailable }

/// Paso del flujo de compra que ve el adulto en «Versión completa».
enum PurchaseFlow { idle, buying, restoring }

/// Último aviso del flujo, para mostrarlo una vez.
enum StoreNotice { none, thanks, pending, canceled, error, nothingToRestore }

/// Escucha la tienda, aplica las reglas del dominio, guarda el derecho y solo
/// entonces lo publica y cierra la transacción (docs/TECNICA.md). No toca la
/// partida, las monedas ni la propiedad.
class StoreController extends ChangeNotifier {
  StoreController({
    required this.provider,
    required this.entitlements,
    required this.clock,
    this.simulated = false,
  }) : rules = EntitlementRules(entitlements.productId);

  final StoreProvider provider;
  final EntitlementStore entitlements;
  final Clock clock;
  final EntitlementRules rules;

  /// Los derechos que nacen de esta tienda se marcan como simulados.
  final bool simulated;

  Entitlement _entitlement = Entitlement.none;
  Entitlement? _demo;
  StreamSubscription<StoreEvent>? _sub;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  int _queries = 0;

  bool get inDemo => _demo != null;

  StoreProduct? product;
  ProductStatus productStatus = ProductStatus.loading;
  PurchaseFlow flow = PurchaseFlow.idle;
  StoreNotice notice = StoreNotice.none;

  /// Derecho visible: el de la demostración si está activa.
  Entitlement get entitlement => _demo ?? _entitlement;

  /// Derecho guardado en el dispositivo (fuera de la demostración).
  Entitlement get confirmed => _entitlement;
  bool get full => entitlement.full;
  bool get pending => entitlement.pending;
  String get productId => rules.productId;
  bool canAccess(Tier tier) => rules.canAccess(tier, entitlement);

  /// Lee la caché y se suscribe a la tienda. Se espera antes de mostrar Casa;
  /// producto y consulta silenciosa siguen sin bloquear.
  Future<void> start() async {
    _entitlement = await entitlements.load();
    _sub ??= provider.events.listen(_onEvent);
    _notify();
    unawaited(loadProduct());
    if (provider.silentOwnershipQuery) unawaited(checkOwnership());
  }

  Future<void> loadProduct() async {
    productStatus = ProductStatus.loading;
    _notify();
    try {
      product = await provider.loadProduct(productId);
    } catch (_) {
      product = null;
    }
    productStatus = product == null
        ? ProductStatus.unavailable
        : ProductStatus.available;
    _notify();
  }

  /// Consulta de propiedad sin interacción. Solo una respuesta positiva de la
  /// tienda revoca; `unknown` conserva la caché.
  Future<void> checkOwnership() async {
    StoreOwnership o;
    try {
      o = await provider.queryOwnership(productId);
    } catch (_) {
      o = StoreOwnership.unknown;
    }
    final now = clock.nowUtcSeconds();
    _queries++;
    if (o == StoreOwnership.owned && !_entitlement.full) {
      await _apply(
        StoreEvent(
          StoreEventKind.restored,
          eventId: 'query-$now-$_queries',
          productId: productId,
        ),
        complete: false,
      );
    } else if (o == StoreOwnership.notOwned && _entitlement.full) {
      await _apply(
        StoreEvent(
          StoreEventKind.revoked,
          eventId: 'query-$now-$_queries',
          productId: productId,
        ),
        complete: false,
      );
    }
  }

  Future<void> buy() async {
    if (flow != PurchaseFlow.idle || full) return;
    if (_demo != null) {
      // Demostración: compra inmediata solo en memoria.
      _demo = Entitlement(
        state: EntitlementState.purchased,
        source: EntitlementSource.simulated,
        updatedUtc: clock.nowUtcSeconds(),
      );
      notice = StoreNotice.thanks;
      _notify();
      return;
    }
    flow = PurchaseFlow.buying;
    notice = StoreNotice.none;
    _notify();
    try {
      await provider.buy(productId);
    } catch (_) {
      flow = PurchaseFlow.idle;
      notice = StoreNotice.error;
      _notify();
    }
  }

  Future<void> restore() async {
    if (flow != PurchaseFlow.idle) return;
    if (_demo != null) {
      notice = full ? StoreNotice.thanks : StoreNotice.nothingToRestore;
      _notify();
      return;
    }
    flow = PurchaseFlow.restoring;
    notice = StoreNotice.none;
    _notify();
    try {
      await provider.restore();
      // Deja llegar y aplicar los eventos que entrega la restauración.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _tail;
      if (flow == PurchaseFlow.restoring) {
        flow = PurchaseFlow.idle;
        notice = StoreNotice.nothingToRestore;
        _notify();
      }
    } catch (_) {
      flow = PurchaseFlow.idle;
      notice = StoreNotice.error;
      _notify();
    }
  }

  void clearNotice() {
    if (notice == StoreNotice.none) return;
    notice = StoreNotice.none;
    _notify();
  }

  void _onEvent(StoreEvent ev) => unawaited(_apply(ev, complete: true));

  Future<void> _apply(StoreEvent ev, {required bool complete}) {
    final r = _tail.then((_) => _applyNow(ev, complete: complete));
    _tail = r.catchError((_) {});
    return r;
  }

  Future<void> _applyNow(StoreEvent ev, {required bool complete}) async {
    final change = rules.apply(
      _entitlement,
      ev,
      clock.nowUtcSeconds(),
      source: simulated ? EntitlementSource.simulated : EntitlementSource.store,
    );
    if (change.changed) {
      try {
        await entitlements.write(change.next);
      } catch (e) {
        // Sin guardar no se publica ni se cierra: la tienda la reenviará.
        debugPrint('Derecho no guardado: $e');
        flow = PurchaseFlow.idle;
        notice = StoreNotice.error;
        _notify();
        return;
      }
      _entitlement = change.next;
    }
    final interactive = flow != PurchaseFlow.idle;
    switch (ev.kind) {
      case StoreEventKind.purchased || StoreEventKind.restored:
        if (_entitlement.full && (interactive || change.changed)) {
          notice = StoreNotice.thanks;
        }
        flow = PurchaseFlow.idle;
      case StoreEventKind.pending:
        if (_entitlement.pending) notice = StoreNotice.pending;
        flow = PurchaseFlow.idle;
      case StoreEventKind.canceled:
        if (interactive || change.changed) notice = StoreNotice.canceled;
        flow = PurchaseFlow.idle;
      case StoreEventKind.error:
        if (interactive || change.changed) notice = StoreNotice.error;
        flow = PurchaseFlow.idle;
      case StoreEventKind.revoked:
        break;
    }
    _notify();
    if (complete && ev.kind != StoreEventKind.pending) {
      try {
        await provider.complete(ev.eventId);
      } catch (e) {
        debugPrint('Transacción no cerrada: $e');
      }
    }
  }

  // ------------------------------------------------------------ demostración

  /// Derecho en memoria del modo demostración; null lo retira. Nunca escribe
  /// el documento real.
  void setDemo(Entitlement? e) {
    _demo = e;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    provider.dispose();
    super.dispose();
  }
}
