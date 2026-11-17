import 'package:flutter/foundation.dart';

import 'iap_store.dart';
import 'store_provider.dart';

/// Misma selección en Debug/Profile/Release. La simulación solo se inyecta
/// expresamente en pruebas; la demostración de la app sigue siendo en memoria.
StoreProvider createDefaultStore(
  String productId, {
  TargetPlatform? platform,
  bool? web,
}) {
  if (web ?? kIsWeb) return NoStore();
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android => IapStore(productId: productId, android: true),
    TargetPlatform.iOS => IapStore(productId: productId, android: false),
    _ => NoStore(),
  };
}
