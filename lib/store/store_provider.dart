import 'dart:async';

import '../domain/entitlements.dart';

/// Producto tal como lo describe la tienda. El precio es el texto localizado
/// que entrega la tienda: la app nunca escribe un importe propio.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
  });
  final String id;
  final String title;
  final String price;
}

/// Respuesta de una consulta de propiedad. [unknown] (sin red, error o
/// plataforma que no permite consultar en silencio) nunca revoca.
enum StoreOwnership { owned, notOwned, unknown }

/// Frontera con la tienda (docs/TECNICA.md). Implementaciones: la tienda
/// real (`in_app_purchase`, F07.5), [SimulatedStore] y [NoStore].
abstract class StoreProvider {
  /// Eventos de compra: se escuchan desde el arranque, antes de Casa.
  Stream<StoreEvent> get events;

  /// La plataforma tiene tienda (Android/iOS con plugin).
  bool get supported;

  /// Se puede consultar la propiedad sin interacción (Android sí; iOS no:
  /// restaurar puede pedir iniciar sesión).
  bool get silentOwnershipQuery;

  String get name;

  Future<StoreProduct?> loadProduct(String productId);

  /// Inicia la compra; el resultado llega por [events].
  Future<void> buy(String productId);

  /// Pide a la tienda las compras anteriores; llegan como `restored`.
  Future<void> restore();

  Future<StoreOwnership> queryOwnership(String productId);

  /// Cierra la transacción tras guardar el derecho. Si no se llama, la
  /// tienda vuelve a entregarla en el siguiente arranque.
  Future<void> complete(String eventId);

  void dispose();
}

/// Sin tienda: web, escritorio y pruebas que no la necesitan.
class NoStore implements StoreProvider {
  NoStore();
  final _events = StreamController<StoreEvent>.broadcast();

  @override
  Stream<StoreEvent> get events => _events.stream;
  @override
  bool get supported => false;
  @override
  bool get silentOwnershipQuery => false;
  @override
  String get name => 'Sin tienda';
  @override
  Future<StoreProduct?> loadProduct(String productId) async => null;
  @override
  Future<void> buy(String productId) async {}
  @override
  Future<void> restore() async {}
  @override
  Future<StoreOwnership> queryOwnership(String productId) async =>
      StoreOwnership.unknown;
  @override
  Future<void> complete(String eventId) async {}
  @override
  void dispose() => _events.close();
}
