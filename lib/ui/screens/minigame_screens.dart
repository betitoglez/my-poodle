import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/games/frisbee_sim.dart';
import '../../domain/games/orchard_sim.dart';
import '../../domain/rules.dart';
import '../../domain/balance.dart';
import '../../game/frisbee_game.dart';
import '../../game/game_registry.dart';
import '../../game/orchard_game.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/activity_frame.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/scene_view.dart';
import 'games_screen.dart';
import 'results_screens.dart';

/// Cierre común de partida: una sola finalización por sesión.
mixin _GameSession<W extends StatefulWidget> on State<W> {
  late final String session;
  bool finishing = false;
  GameId get gameId;

  /// Un juego de la versión completa sin derecho no crea sesión: vuelve atrás
  /// y abre «Pide ayuda a un adulto» (la tarjeta ya lo evita; esto es la
  /// segunda comprobación de las reglas).
  Future<bool> beginSession() async {
    final c = AppScope.read(context);
    final s = await c.beginGame(gameId);
    if (!mounted) return false;
    session = s ?? '';
    if (s == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        nav.pop();
        if (!c.canPlay(gameId)) {
          showAskAdult(nav.context);
        } else {
          AppScope.feedbackOf(nav.context).play(Sfx.blocked);
          ScaffoldMessenger.of(nav.context).showSnackBar(
            SnackBar(
              content: Text(
                c.gameBlocked ?? 'No se pudo guardar el inicio de la partida.',
              ),
            ),
          );
        }
      });
    }
    return s != null;
  }

  Future<void> complete(int score) async {
    if (finishing) return;
    finishing = true;
    final c = AppScope.read(context);
    final receipt = await commitOrRecover<Receipt>(
      context,
      () => c.finishGame(session, gameId, score),
    );
    if (!mounted) return;
    if (receipt != null) {
      final fx = AppScope.feedbackOf(context);
      fx.play(Sfx.coins);
      replaceScreen(context, GameResultScreen(game: gameId, receipt: receipt));
    } else {
      Navigator.pop(context);
    }
  }

  void cancel() => AppScope.read(context).cancelActivity(session);
}

// ======================================================================
// P12 · Huerto saltarín
// ======================================================================

class OrchardScreen extends StatefulWidget {
  const OrchardScreen({super.key});
  @override
  State<OrchardScreen> createState() => _OrchardScreenState();
}

class _OrchardScreenState extends State<OrchardScreen>
    with _GameSession, FrameSafeRefresh {
  OrchardGame? _game;
  final _frame = GlobalKey<ActivityFrameState>();
  final _live = LivePoodleController();
  final _effectsFrame = ValueNotifier<int>(0);
  bool _render3d = false;
  Timer? _loadTimeout;
  List<num>? _lastVisualFrame;

  void _syncOrchard() {
    if (!_render3d || !_live.ready || !mounted) return;
    final state = _game!.liveFrame;
    if (listEquals(state, _lastVisualFrame)) return;
    _lastVisualFrame = state;
    _live.orchard(state);
    _effectsFrame.value++;
  }

  void _fallback() {
    if (!mounted) return;
    _loadTimeout?.cancel();
    setState(() {
      _render3d = false;
      _game!
        ..useLiveModel = false
        ..start();
    });
  }

  void _onViewerStatus() {
    if (_live.failed) {
      _fallback();
    } else if (_render3d && _live.ready) {
      _loadTimeout?.cancel();
      _game!.useLiveModel = true;
      _syncOrchard();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _effectsFrame.dispose();
    super.dispose();
  }

  @override
  GameId get gameId => GameId.fruit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_starting) return;
    _starting = true;
    _start();
  }

  bool _starting = false;
  Future<void> _start() async {
    if (!await beginSession() || !mounted) return;
    final c = AppScope.read(context);
    final fx = AppScope.feedbackOf(context);
    _render3d =
        LivePoodleView.enabled && LivePoodleView.supports(c.pet.appearance);
    _game = OrchardGame(
      sim: OrchardSim(timeLimit: c.balance.fruit.seconds.toDouble()),
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      onFinished: (score) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) complete(score);
      }),
      onHud: refreshAfterFrame,
      waitForStart: _render3d,
      onVisualFrame: _syncOrchard,
      onEvent: (e) => fx.play(e, haptic: e != Sfx.countdown && e != Sfx.land),
    );
    _game!.pet.hygiene = c.pet.needPoints(Need.hygiene);
    _game!.pet.showSprite = !_render3d;
    if (_render3d) _loadTimeout = Timer(const Duration(seconds: 10), _fallback);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sim = _game!.sim;
    final c = AppScope.of(context);
    final live = _render3d && _live.ready;
    final waiting = _game!.waitForStart;
    final def = GameCatalog.fruit(c.balance.fruit);
    return ActivityFrame(
      key: _frame,
      title: def.title,
      activityName: 'la partida',
      isGame: true,
      showPauseButton: true,
      game: _game!,
      hasPendingProgress: () => !sim.finished,
      onExit: cancel,
      scene: SceneView(
        game: _game!,
        semanticsLabel: 'Huerto lateral. Toca para saltar.',
        onPress: (_) => _game!.jump(),
        overlay: _render3d
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: c.pet.appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    wardrobe: false,
                    orchardLevel: sim.level,
                    onStatusChanged: _onViewerStatus,
                  ),
                  if (live)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _OrchardEffects(_game!, _effectsFrame),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hud: GameHud(
        items: [
          (Icons.timer_rounded, 'Tiempo', '${sim.remaining.ceil()} s'),
          (
            Icons.apple_rounded,
            'Frutas',
            '${sim.score} / ${sim.level.apples.length}',
          ),
        ],
      ),
      controls: Row(
        children: [
          Expanded(
            child: Text(
              _game!.showPenalty
                  ? _game!.lastPenaltyWasFall
                        ? 'Caída −${OrchardSim.fallPenaltySeconds} s. Vuelves al último apoyo.'
                        : 'Choque −${OrchardSim.fallPenaltySeconds} s.'
                  : waiting
                  ? 'Salta los bancales y recoge las frutas.'
                  : def.gesture,
              style: AppText.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpace.s),
          // Botón grande Saltar: misma intención que tocar el campo.
          SizedBox(
            width: 140,
            child: Listener(
              onPointerDown: (_) => _game!.jump(),
              child: AppButton(
                label: waiting ? (live ? 'Empezar' : 'Cargando…') : 'Saltar',
                icon: waiting
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_upward_rounded,
                big: true,
                expand: true,
                onPressed: waiting
                    ? (live ? () => setState(_game!.start) : null)
                    : () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrchardEffects extends CustomPainter {
  _OrchardEffects(this.game, Listenable repaint) : super(repaint: repaint);

  final OrchardGame game;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    game.paintEffects(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrchardEffects oldDelegate) => oldDelegate.game != game;
}

// ======================================================================
// P13 · Frisbee en el prado
// ======================================================================

class FrisbeeScreen extends StatefulWidget {
  const FrisbeeScreen({super.key});
  @override
  State<FrisbeeScreen> createState() => _FrisbeeScreenState();
}

class _FrisbeeScreenState extends State<FrisbeeScreen>
    with _GameSession, FrameSafeRefresh {
  FrisbeeGame? _game;
  final _texts = Texts();
  String? _missText;
  Size _area = Size.zero;
  final _live = LivePoodleController();
  final _visual = ValueNotifier<int>(0);
  bool _showModel = false;
  List<num>? _lastFrame;

  void _syncFrisbee() {
    if (!mounted || !_showModel || !_live.ready) return;
    final frame = _game!.liveFrame;
    if (frame.isNotEmpty && !listEquals(frame, _lastFrame)) {
      _lastFrame = frame;
      _live.frisbee(frame);
    }
    _visual.value++;
  }

  void _viewerStatus() {
    if (!mounted) return;
    if (_live.failed) {
      _showModel = false;
      _game!.start();
    }
    _game!.useLiveModel = _showModel && _live.ready;
    _game!.pet.showSprite = !_showModel;
    _syncFrisbee();
    setState(() {});
  }

  @override
  void dispose() {
    _visual.dispose();
    super.dispose();
  }

  @override
  GameId get gameId => GameId.frisbee;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_starting) return;
    _starting = true;
    _start();
  }

  bool _starting = false;
  Future<void> _start() async {
    if (!await beginSession() || !mounted) return;
    final c = AppScope.read(context);
    final fx = AppScope.feedbackOf(context);
    final rule = c.balance.frisbee;
    _showModel =
        LivePoodleView.enabled && LivePoodleView.supports(c.pet.appearance);
    _game =
        FrisbeeGame(
            painter: PetPainterScope.of(context),
            look: c.look,
            reducedMotion: c.reducedMotion,
            sim: FrisbeeSim(
              targets: rule.targetsField,
              flightSeconds: rule.flightSeconds,
              catchRadius: rule.catchRadius,
            ),
            onFinished: (score) =>
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) complete(score);
                }),
            onHud: refreshAfterFrame,
            onVisualFrame: _syncFrisbee,
            onEvent: (e) {
              fx.play(e, haptic: e != Sfx.countdown);
              switch (e) {
                case Sfx.catchDisc:
                  _missText = null;
                case Sfx.miss:
                  _missText = _texts.pick(Texts.missFeedback);
                default:
                  break;
              }
            },
          )
          ..waitForStart = _showModel
          ..pet.showSprite = !_showModel;
    _game!.pet.hygiene = c.pet.needPoints(Need.hygiene);
    setState(() {});
  }

  FieldPoint? _aim(Offset start, Offset p) {
    if (_area.isEmpty) return null;
    return FrisbeeSim.aimFromDrag(
      (p.dx - start.dx) / _area.width,
      (start.dy - p.dy) / _area.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sim = _game!.sim;
    final c = AppScope.of(context);
    final waiting = _game!.waitForStart;
    final def = GameCatalog.frisbee;
    final status = waiting
        ? 'Apunta al aro y atrapa el disco en 20 segundos.'
        : switch (sim.phase) {
            FrisbeePhase.aim => _missText ?? 'Arrastra hacia arriba y suelta. La línea muestra dónde caerá.',
            FrisbeePhase.flight => '¡El disco vuela!',
            FrisbeePhase.catchAnim =>
              sim.lastCaught == true ? '¡Atrapado!' : (_missText ?? '¡Casi!'),
            FrisbeePhase.returning => 'Tu caniche vuelve con el disco…',
            FrisbeePhase.finished => '¡Partida terminada!',
          };
    return ActivityFrame(
      title: def.title,
      activityName: 'la partida',
      isGame: true,
      showPauseButton: true,
      game: _game!,
      hasPendingProgress: () => !sim.finished,
      onExit: cancel,
      scene: LayoutBuilder(
        builder: (context, box) {
          _area = box.biggest;
          return SceneView(
            game: _game!,
            semanticsLabel:
                'Prado con el aro objetivo. Arrastra hacia arriba para lanzar.',
            onDragUpdate: (start, p, _) {
              if (waiting || !sim.canThrow || _game!.paused) return;
              final aim = _aim(start, p);
              _game!.setAim(aim, tooShort: aim == null);
            },
            onDragEnd: (start, end) {
              final aim = _aim(start, end);
              _game!.setAim(null);
              // Gesto demasiado corto: vuelve a apuntar sin gastar intento.
              if (aim != null) _game!.launch(aim);
            },
            onDragCancel: () => _game!.setAim(null),
            overlay: _showModel
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      LivePoodleView(
                        controller: _live,
                        appearance: c.pet.appearance,
                        onStatusChanged: _viewerStatus,
                        resting: false,
                        reducedMotion: c.reducedMotion,
                        wardrobe: false,
                        frisbee: true,
                      ),
                      if (_live.ready)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _FrisbeeGuide(_game!, _visual),
                          ),
                        ),
                    ],
                  )
                : null,
          );
        },
      ),
      hud: GameHud(
        items: [
          (Icons.timer_rounded, 'Tiempo', '${sim.remaining.ceil()} s'),
          (
            Icons.album_rounded,
            'Lanzamiento',
            '${(sim.attempts + (sim.finished ? 0 : 1)).clamp(1, sim.targets.length)} / ${sim.targets.length}',
          ),
          (Icons.check_circle_rounded, 'Aciertos', '${sim.catches}'),
        ],
      ),
      controls: Row(
        children: [
          Expanded(
            child: Text(
              status,
              style: AppText.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpace.s),
          SizedBox(
            width: 150,
            child: AppButton(
              label: waiting
                  ? (_live.ready ? 'Empezar' : 'Cargando…')
                  : 'Lanzar al aro',
              icon: Icons.gps_fixed_rounded,
              semanticsHint: 'Lanzamiento asistido hacia el centro del aro',
              big: true,
              expand: true,
              onPressed: waiting
                  ? (_live.ready ? () => setState(_game!.start) : null)
                  : sim.canThrow
                  ? () => _game!.launchAssisted()
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrisbeeGuide extends CustomPainter {
  _FrisbeeGuide(this.game, Listenable repaint) : super(repaint: repaint);
  final FrisbeeGame game;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    game.paintGuide(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrisbeeGuide previous) => previous.game != game;
}
