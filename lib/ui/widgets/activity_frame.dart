import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'dialogs.dart';

/// Marco de actividad: prioriza sus controles y ofrece salida clara.
/// Pausa la escena al perder el foco y exige pulsar Continuar.
class ActivityFrame extends StatefulWidget {
  const ActivityFrame({
    super.key,
    required this.title,
    required this.activityName,
    required this.scene,
    required this.controls,
    required this.game,
    required this.hasPendingProgress,
    required this.onExit,
    this.status,
    this.isGame = false,
    this.showPauseButton = false,
    this.hud,
    this.hint,
  });

  final String title;
  final String activityName;
  final Widget scene;
  final Widget controls;
  final Game game;
  final bool Function() hasPendingProgress;

  /// Se llama al abandonar (cancelar sesión) antes de cerrar la ruta.
  final VoidCallback onExit;
  final Widget? status;
  final bool isGame;
  final bool showPauseButton;
  final Widget? hud;
  final Widget? hint;

  @override
  State<ActivityFrame> createState() => ActivityFrameState();
}

class ActivityFrameState extends State<ActivityFrame>
    with WidgetsBindingObserver {
  bool _pauseOpen = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppScope.read(context).onResumed();
      return;
    }
    // Inactiva, oculta o en segundo plano: congelar hasta Continuar.
    if (!widget.game.paused) pause();
  }

  Future<void> pause() async {
    if (_pauseOpen || _leaving) return;
    _pauseOpen = true;
    widget.game.pauseEngine();
    final resume = await showPauseDialog(context, game: widget.isGame);
    _pauseOpen = false;
    if (!mounted) return;
    if (resume) {
      widget.game.resumeEngine();
    } else {
      _leave();
    }
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    widget.onExit();
    Navigator.of(context).pop();
  }

  Future<void> requestExit() async {
    if (!widget.hasPendingProgress()) {
      _leave();
      return;
    }
    widget.game.pauseEngine();
    final exit = await showExitActivityDialog(
      context,
      activity: widget.activityName,
      game: widget.isGame,
    );
    if (!mounted) return;
    if (exit) {
      _leave();
    } else {
      widget.game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    final controller = AppScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  l.gutter - 4,
                  AppSpace.xs,
                  l.gutter - 4,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Salir de ${widget.activityName}',
                      onPressed: requestExit,
                      icon: const Icon(Icons.close_rounded, size: 28),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (controller.demo)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: DemoBadge(),
                      ),
                    ?widget.status,
                    if (widget.showPauseButton)
                      IconButton(
                        tooltip: 'Pausa',
                        onPressed: pause,
                        icon: const Icon(
                          Icons.pause_circle_rounded,
                          size: 32,
                          color: AppColors.plum,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.scene,
                    if (widget.hud != null)
                      Positioned(
                        left: l.gutter,
                        right: l.gutter,
                        top: AppSpace.s,
                        child: widget.hud!,
                      ),
                    if (widget.hint != null)
                      Positioned(
                        left: l.gutter,
                        right: l.gutter,
                        top: AppSpace.s,
                        child: Center(child: widget.hint!),
                      ),
                  ],
                ),
              ),
              Panel(child: SafeArea(top: false, child: widget.controls)),
            ],
          ),
        ),
      ),
    );
  }
}
