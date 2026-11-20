import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:flame/game.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../game/scenes/stage_game.dart';

/// Aloja una escena Flame creada fuera de build. Captura el primer puntero
/// y entrega toque o arrastre en coordenadas de la escena; un segundo dedo
/// se ignora. Los controles Flutter quedan fuera de esta área.
class SceneView extends StatefulWidget {
  const SceneView({
    super.key,
    required this.game,
    this.onTap,
    this.onPress,
    this.onRelease,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.semanticsLabel,
    this.overlay,
  });

  final Game game;
  final void Function(Offset p)? onTap;

  /// Inmediato al tocar (p. ej. saltar), sin esperar a soltar.
  final void Function(Offset p)? onPress;
  final VoidCallback? onRelease;
  final void Function(Offset start, Offset p, Offset delta)? onDragUpdate;
  final void Function(Offset start, Offset end)? onDragEnd;
  final VoidCallback? onDragCancel;
  final String? semanticsLabel;
  final Widget? overlay;

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> with RouteAware {
  int? _pointer;
  Offset? _start;
  Offset? _last;
  bool _dragging = false;
  FeedbackService? _feedback;
  ModalRoute<dynamic>? _route;

  StageGame? get _stage =>
      widget.game is StageGame ? widget.game as StageGame : null;

  void _soundVisible(bool visible) =>
      _stage?.bindSound(_feedback, visible: visible);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feedback = context
        .getInheritedWidgetOfExactType<AppScope>()
        ?.feedback;
    final route = ModalRoute.of(context);
    if (_feedback != feedback || _route != route) {
      _feedback?.routes.unsubscribe(this);
      _feedback = feedback;
      _route = route;
      if (route != null) feedback?.routes.subscribe(this, route);
    }
    _soundVisible(route?.isCurrent ?? true);
  }

  @override
  void didUpdateWidget(SceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      final old = oldWidget.game;
      if (old is StageGame) old.bindSound(null, visible: false);
      _soundVisible(_route?.isCurrent ?? true);
    }
  }

  @override
  void didPushNext() => _soundVisible(false);

  @override
  void didPopNext() => _soundVisible(true);

  @override
  void didPop() => _soundVisible(false);

  @override
  void dispose() {
    _feedback?.routes.unsubscribe(this);
    _stage?.bindSound(null, visible: false);
    super.dispose();
  }

  void _reset() {
    _pointer = null;
    _start = null;
    _last = null;
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return LSemantics(
      label: widget.semanticsLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (_pointer != null) return; // un solo dueño por gesto
          _pointer = e.pointer;
          _start = e.localPosition;
          _last = e.localPosition;
          widget.onPress?.call(e.localPosition);
        },
        onPointerMove: (e) {
          if (e.pointer != _pointer) return;
          final delta = e.localPosition - _last!;
          _last = e.localPosition;
          if (!_dragging && (e.localPosition - _start!).distance > 8) {
            _dragging = true;
          }
          if (_dragging) {
            widget.onDragUpdate?.call(_start!, e.localPosition, delta);
          }
        },
        onPointerUp: (e) {
          if (e.pointer != _pointer) return;
          if (_dragging) {
            widget.onDragEnd?.call(_start!, e.localPosition);
          } else {
            widget.onTap?.call(e.localPosition);
          }
          widget.onRelease?.call();
          _reset();
        },
        onPointerCancel: (e) {
          if (e.pointer != _pointer) return;
          widget.onDragCancel?.call();
          widget.onRelease?.call();
          _reset();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: GameWidget(game: widget.game)),
            ?widget.overlay,
          ],
        ),
      ),
    );
  }
}

/// Programa un setState tras el fotograma actual. Las escenas Flame avisan
/// desde su update, que puede coincidir con la fase de build.
mixin FrameSafeRefresh<T extends StatefulWidget> on State<T> {
  bool _refreshScheduled = false;

  void refreshAfterFrame([VoidCallback? then]) {
    // Fuera de build/layout (p. ej. al pulsar un botón) se refresca ya.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (!mounted) return;
      setState(() {});
      then?.call();
      return;
    }
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      setState(() {});
      then?.call();
    });
  }
}
