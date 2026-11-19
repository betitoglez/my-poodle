import 'package:material_ui/material_ui.dart';

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

Future<T?> pushScreen<T>(
  BuildContext context,
  Widget screen, {
  MusicTrack music = MusicTrack.home,
}) => Navigator.of(context).push<T>(
  MaterialPageRoute(
    settings: RouteSettings(arguments: music),
    builder: (_) => screen,
  ),
);

Future<T?> replaceScreen<T>(
  BuildContext context,
  Widget screen, {
  MusicTrack music = MusicTrack.home,
}) => Navigator.of(context).pushReplacement<T, void>(
  MaterialPageRoute(
    settings: RouteSettings(arguments: music),
    builder: (_) => screen,
  ),
);
