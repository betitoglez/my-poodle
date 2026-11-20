import 'dart:async';

import '../domain/entitlements.dart';
import 'store_provider.dart';

/// Resultado que dará la próxima compra simulada.
enum SimulatedOutcome { purchase, cancel, error, pending }

/// Tienda simulada para pruebas, vista previa web y desarrollo. Reproduce
/// producto disponible o ausente, sin red, demora, cancelación, error,
/// compra pendiente que se aprueba o rechaza, reembolso y eventos repetidos.
/// Nunca se usa en una build Release de tienda.
class SimulatedStore implements StoreProvider {
  SimulatedStore({
    this.productId = 'mypoodle.full_version',
    this.price = '1,99 €',
    this.owned = false,
    this.online = true,
    this.hasProduct = true,
    this.delay = const Duration(milliseconds: 300),
    this.silentOwnershipQuery = true,
  });

  final String productId;
  String price;
  bool owned;
  bool online;
  bool hasProduct;
  Duration delay;
  SimulatedOutcome next = SimulatedOutcome.purchase;

  @override
  final bool silentOwnershipQuery;

  /// Eventos cerrados con [complete], en orden.
  final List<String> completed = [];

  final _events = StreamController<StoreEvent>.broadcast();
  var _n = 0;
  String? _pendingId;

  @override
  Stream<StoreEvent> get events => _events.stream;
  @override
  bool get supported => true;
  @override
  String get name => 'Tienda simulada';

  String _id(String kind) => 'sim-$kind-${++_n}';

  Future<void> _wait() =>
      delay == Duration.zero ? Future.value() : Future.delayed(delay);

  /// Entrega un evento tal cual (para probar duplicados o eventos tardíos).
  void emit(StoreEvent e) => _events.add(e);

  @override
  Future<StoreProduct?> loadProduct(String id) async {
    await _wait();
    if (!online || !hasProduct || id != productId) return null;
    return StoreProduct(id: productId, title: 'Versión completa', price: price);
  }

  @override
  Future<void> buy(String id) async {
    await _wait();
    if (!online) {
      emit(
        StoreEvent(StoreEventKind.error, eventId: _id('err'), code: 'offline'),
      );
      return;
    }
    switch (next) {
      case SimulatedOutcome.purchase:
        owned = true;
        emit(
          StoreEvent(
            StoreEventKind.purchased,
            eventId: _id('buy'),
            productId: id,
          ),
        );
      case SimulatedOutcome.cancel:
        emit(
          StoreEvent(
            StoreEventKind.canceled,
            eventId: _id('cancel'),
            productId: id,
          ),
        );
      case SimulatedOutcome.error:
        emit(
          StoreEvent(
            StoreEventKind.error,
            eventId: _id('err'),
            productId: id,
            code: 'simulated',
          ),
        );
      case SimulatedOutcome.pending:
        _pendingId = _id('pending');
        emit(
          StoreEvent(
            StoreEventKind.pending,
            eventId: _pendingId!,
            productId: id,
          ),
        );
    }
  }

  /// El adulto aprueba la compra pendiente (fuera de la app).
  void approvePending() {
    if (_pendingId == null) return;
    _pendingId = null;
    owned = true;
    emit(
      StoreEvent(
        StoreEventKind.purchased,
        eventId: _id('buy'),
        productId: productId,
      ),
    );
  }

  /// El adulto rechaza la compra pendiente.
  void declinePending() {
    if (_pendingId == null) return;
    _pendingId = null;
    emit(
      StoreEvent(
        StoreEventKind.canceled,
        eventId: _id('cancel'),
        productId: productId,
      ),
    );
  }

  /// Reembolso confirmado por la tienda.
  void refund() {
    owned = false;
    emit(
      StoreEvent(
        StoreEventKind.revoked,
        eventId: _id('refund'),
        productId: productId,
      ),
    );
  }

  @override
  Future<void> restore() async {
    await _wait();
    if (!online) {
      emit(
        StoreEvent(StoreEventKind.error, eventId: _id('err'), code: 'offline'),
      );
      return;
    }
    if (owned) {
      emit(
        StoreEvent(
          StoreEventKind.restored,
          eventId: _id('restore'),
          productId: productId,
        ),
      );
    }
  }

  @override
  Future<StoreOwnership> queryOwnership(String id) async {
    await _wait();
    if (!online) return StoreOwnership.unknown;
    // Como Google Play: la compra pendiente sigue en la lista, sin propiedad.
    if (_pendingId != null) return StoreOwnership.unknown;
    return owned ? StoreOwnership.owned : StoreOwnership.notOwned;
  }

  @override
  Future<void> complete(String eventId) async => completed.add(eventId);

  @override
  void dispose() => _events.close();
}
