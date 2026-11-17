/// Publicidad aislada. El prototipo usa [NoAds]: no hay SDK ni red.
/// Punto de integración posterior: [AdsController.onReturnHome] tras un
/// resultado ya guardado. Ningún anuncio puede tapar controles ni premios.
abstract class AdsProvider {
  bool get available;
  String get name;
}

class NoAds implements AdsProvider {
  const NoAds();
  @override
  bool get available => false;
  @override
  String get name => 'Sin publicidad (NoAds)';
}

class AdsController {
  AdsController({this.provider = const NoAds()});
  final AdsProvider provider;
  int interstitialsThisSession = 0;

  /// Llamado al volver a Casa tras una actividad con resultado guardado.
  /// Con NoAds no hace nada; la navegación y los premios no dependen de ello.
  void onReturnHome() {}
}
