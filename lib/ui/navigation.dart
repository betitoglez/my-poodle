import 'package:material_ui/material_ui.dart';

import '../app/app_scope.dart';
import '../app/background_music.dart';

/// Cuatro destinos principales.
enum ShellTab { home, care, games, wardrobe }

/// Controla la pestaña activa y la guarda de salida (prueba de aspecto).
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.home;
  Future<bool> Function()? leaveGuard;

  ShellTab get tab => _tab;

  Future<void> go(ShellTab t) async {
    if (t == _tab) return;
    final guard = leaveGuard;
    if (guard != null && !await guard()) return;
    leaveGuard = null;
    _tab = t;
    notifyListeners();
  }

  /// Fuerza la pestaña sin preguntar (tras una salida ya resuelta).
  void force(ShellTab t) {
    leaveGuard = null;
    _tab = t;
    notifyListeners();
  }
}

class ShellScope extends InheritedNotifier<ShellController> {
  const ShellScope({
    super.key,
    required ShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShellController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>()?.notifier;
}

/// Vuelve a la raíz y abre una pestaña (resultados, monedas insuficientes).
void goToTab(BuildContext context, ShellTab tab) {
  final shell = ShellScope.maybeOf(context);
  Navigator.of(context).popUntil((r) => r.isFirst);
  shell?.force(tab);
}

/// Movimiento reducido al navegar: la preferencia del juego (Ajustes) o la
/// del sistema (`MediaQuery.disableAnimations`). Basta con una de las dos: la
/// preferencia es la elección explícita del jugador dentro de la app y la del
/// sistema cubre a quien ya lo pidió en la accesibilidad del dispositivo.
bool navigationReducedMotion(BuildContext context) {
  final app = context.getInheritedWidgetOfExactType<AppScope>()?.notifier;
  return (app?.reducedMotion ?? false) ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}

/// Página con fundido y un leve ascenso (~260 ms) en lugar de la transición
/// de plataforma. Sigue siendo una [MaterialPageRoute]: conserva
/// `RouteSettings.arguments` (pista de música, ver `MusicRouteObserver`) y el
/// resto del comportamiento de página. Con movimiento reducido no se anima.
class SoftPageRoute<T> extends MaterialPageRoute<T> {
  SoftPageRoute({
    required super.builder,
    required super.settings,
    this.reducedMotion = false,
  });

  final bool reducedMotion;

  static const duration = Duration(milliseconds: 260);
  static const reverseDuration = Duration(milliseconds: 200);

  @override
  Duration get transitionDuration => reducedMotion
      ? Duration.zero
      : (_isIOS ? super.transitionDuration : duration);

  bool get _isIOS =>
      navigator?.context != null &&
      Theme.of(navigator!.context).platform == TargetPlatform.iOS;

  @override
  Duration get reverseTransitionDuration => reducedMotion
      ? Duration.zero
      : (_isIOS ? super.reverseTransitionDuration : reverseDuration);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion) return child;
    // En iOS se conserva la transición del sistema: incluye el gesto de
    // volver deslizando desde el borde.
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

Future<T?> pushScreen<T>(
  BuildContext context,
  Widget screen, {
  MusicTrack music = MusicTrack.home,
}) => Navigator.of(context).push<T>(
  SoftPageRoute(
    settings: RouteSettings(arguments: music),
    reducedMotion: navigationReducedMotion(context),
    builder: (_) => screen,
  ),
);

Future<T?> replaceScreen<T>(
  BuildContext context,
  Widget screen, {
  MusicTrack music = MusicTrack.home,
}) => Navigator.of(context).pushReplacement<T, void>(
  SoftPageRoute(
    settings: RouteSettings(arguments: music),
    reducedMotion: navigationReducedMotion(context),
    builder: (_) => screen,
  ),
);
