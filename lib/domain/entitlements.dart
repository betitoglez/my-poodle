/// Versión gratuita y versión completa (docs/FUNCIONAL.md). Dart puro: sin
/// Flutter, Flame ni plugin de tienda. Las reglas deciden qué contenido se
/// puede usar y cómo cambia el derecho ante un evento de la tienda; nunca
/// tocan monedas, propiedad ni partida.
library;

/// Versión a la que pertenece un artículo o un juego del catálogo.
enum Tier { free, full }

/// Estado del derecho a la versión completa.
enum EntitlementState { none, pending, purchased, revoked }

/// Fuente del derecho guardado: la tienda real o la simulada (desarrollo).
enum EntitlementSource { store, simulated }

/// Eventos que entrega la tienda (ya traducidos desde el plugin).
enum StoreEventKind { pending, purchased, restored, canceled, error, revoked }

class StoreEvent {
  const StoreEvent(
    this.kind, {
    required this.eventId,
    this.productId,
    this.code,
  });

  final StoreEventKind kind;

  /// Identificador estable del evento (resumen del ID de transacción).
  final String eventId;

  /// Producto al que se refiere; null en cancelaciones y errores genéricos.
  final String? productId;

  /// Código de error de la tienda, solo informativo.
  final String? code;
}

/// Derecho confirmado. Inmutable.
class Entitlement {
  const Entitlement({
    this.state = EntitlementState.none,
    this.source = EntitlementSource.store,
    this.updatedUtc = 0,
    this.lastEventIds = const [],
  });

  static const none = Entitlement();

  final EntitlementState state;
  final EntitlementSource source;
  final int updatedUtc;

  /// Últimos eventos aplicados, para ignorar duplicados.
  final List<String> lastEventIds;

  /// Solo una compra confirmada desbloquea; pendiente no.
  bool get full => state == EntitlementState.purchased;
  bool get pending => state == EntitlementState.pending;

  Entitlement copyWith({
    EntitlementState? state,
    EntitlementSource? source,
    int? updatedUtc,
    List<String>? lastEventIds,
  }) => Entitlement(
    state: state ?? this.state,
    source: source ?? this.source,
    updatedUtc: updatedUtc ?? this.updatedUtc,
    lastEventIds: lastEventIds ?? this.lastEventIds,
  );

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.state == state &&
      other.source == source &&
      other.updatedUtc == updatedUtc &&
      _sameList(other.lastEventIds, lastEventIds);

  @override
  int get hashCode =>
      Object.hash(state, source, updatedUtc, Object.hashAll(lastEventIds));
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Resultado de aplicar un evento: el derecho siguiente y si ha cambiado.
class EntitlementChange {
  const EntitlementChange(this.next, {required this.changed});
  final Entitlement next;
  final bool changed;
}

class EntitlementRules {
  const EntitlementRules(this.productId);

  /// Producto «Versión completa» del catálogo.
  final String productId;

  /// Cuántos IDs de evento se recuerdan para la idempotencia.
  static const memory = 20;

  bool canAccess(Tier tier, Entitlement e) => tier == Tier.free || e.full;

  /// Aplica un evento de la tienda. Duplicados, otros productos,
  /// cancelaciones y errores no cambian el derecho.
  EntitlementChange apply(
    Entitlement e,
    StoreEvent ev,
    int nowUtc, {
    EntitlementSource source = EntitlementSource.store,
  }) {
    if (e.lastEventIds.contains(ev.eventId)) {
      return EntitlementChange(e, changed: false);
    }
    final EntitlementState? target = switch (ev.kind) {
      StoreEventKind.purchased ||
      StoreEventKind.restored => EntitlementState.purchased,
      // Una compra pendiente nunca rebaja un derecho ya confirmado.
      StoreEventKind.pending => e.full ? null : EntitlementState.pending,
      StoreEventKind.revoked => EntitlementState.revoked,
      // Una compra pendiente que se cancela o falla vuelve a «sin compra».
      StoreEventKind.canceled ||
      StoreEventKind.error => e.pending ? EntitlementState.none : null,
    };
    final generic =
        ev.kind == StoreEventKind.canceled || ev.kind == StoreEventKind.error;
    final mine = ev.productId == productId || (generic && ev.productId == null);
    if (target == null || !mine) return EntitlementChange(e, changed: false);
    final ids = [...e.lastEventIds, ev.eventId];
    final next = e.copyWith(
      state: target,
      source: source,
      updatedUtc: nowUtc,
      lastEventIds: ids.length > memory
          ? ids.sublist(ids.length - memory)
          : ids,
    );
    return EntitlementChange(next, changed: true);
  }
}
