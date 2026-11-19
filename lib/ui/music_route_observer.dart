import 'package:flutter/widgets.dart';

import '../app/background_music.dart';

/// Los diálogos mantienen la pista de la página que los abrió. Las páginas
/// sin asignación explícita usan la música de Casa y menús.
class MusicRouteObserver extends NavigatorObserver {
  MusicRouteObserver(this.music);
  final BackgroundMusic music;
  final _routes = <Route<dynamic>>[];

  void _sync() {
    final page = _routes.whereType<PageRoute<dynamic>>().lastOrNull;
    final track = page?.settings.arguments;
    music.setTrack(track is MusicTrack ? track : MusicTrack.home);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _sync();
  }
}
