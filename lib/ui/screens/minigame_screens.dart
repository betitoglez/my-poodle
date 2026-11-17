import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/games/frisbee_sim.dart';
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
    AppScope.feedbackOf(context).play(Sfx.coins);
    final receipt = await commitOrRecover<Receipt>(
      context,
      () => c.finishGame(session, gameId, score),
    );
    if (!mounted) return;
    if (receipt != null) {
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
    _game = OrchardGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      onFinished: (score) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) complete(score);
      }),
      onHud: refreshAfterFrame,
      onEvent: (e) => fx.play(switch (e) {
        'apple' => Sfx.apple,
        'fall' => Sfx.fall,
        _ => Sfx.jump,
      }),
    );
    _game!.pet.hygiene = c.pet.needPoints(Need.hygiene);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sim = _game!.sim;
    final def = GameCatalog.fruit;
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
      ),
      hud: GameHud(
        items: [
          (Icons.timer_rounded, 'Tiempo', '${sim.remaining.ceil()} s'),
          (Icons.apple_rounded, 'Frutas', '${sim.score} / 12'),
        ],
      ),
      controls: Row(
        children: [
          Expanded(
            child: Text(
              sim.respawning
                  ? 'Caída: −5 s. Seguimos desde el último bancal.'
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
                label: 'Saltar',
                icon: Icons.arrow_upward_rounded,
                big: true,
                expand: true,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    _game = FrisbeeGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      sim: FrisbeeSim(
        targets: rule.targetsField,
        flightSeconds: rule.flightSeconds,
        catchRadius: rule.catchRadius,
      ),
      onFinished: (score) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) complete(score);
      }),
      onHud: refreshAfterFrame,
      onEvent: (e) {
        switch (e) {
          case 'catch':
            fx.play(Sfx.catchDisc);
            _missText = null;
          case 'miss':
            fx.play(Sfx.miss);
            _missText = _texts.pick(Texts.missFeedback);
          default:
            fx.play(Sfx.throwDisc);
        }
      },
    );
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
    final def = GameCatalog.frisbee;
    final status = switch (sim.phase) {
      FrisbeePhase.aim =>
        _missText ??
            'Arrastra hacia arriba y suelta. La línea muestra dónde caerá.',
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
              if (!sim.canThrow || _game!.paused) return;
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
          );
        },
      ),
      hud: GameHud(
        items: [
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
              label: 'Lanzar al aro',
              icon: Icons.gps_fixed_rounded,
              semanticsHint: 'Lanzamiento asistido hacia el centro del aro',
              big: true,
              expand: true,
              onPressed: sim.canThrow ? () => _game!.launchAssisted() : null,
            ),
          ),
        ],
      ),
    );
  }
}
