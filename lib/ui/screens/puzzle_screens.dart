import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/games/pairs_sim.dart';
import '../../domain/games/memory_sim.dart';
import '../../domain/games/puzzle_deals.dart';
import '../../domain/rules.dart';
import '../../game/game_registry.dart';
import '../../game/puzzle_game.dart';
import '../../l10n/localized_widgets.dart';
import '../theme.dart';
import '../widgets/activity_frame.dart';
import '../widgets/scene_view.dart';
import 'games_screen.dart';
import 'game_session.dart';

// ======================================================================
// Parejas y Memory
// ======================================================================

class PairsScreen extends StatefulWidget {
  const PairsScreen({super.key, this.pairs = 4})
    : assert(pairs == 4 || pairs == 6 || pairs == 8);
  final int pairs;
  @override
  State<PairsScreen> createState() => _PairsScreenState();
}

class _PairsScreenState extends State<PairsScreen>
    with GameSession, FrameSafeRefresh {
  PairsSim? _sim;
  PuzzleGame? _game;
  bool _starting = false;
  @override
  GameId get gameId => GameId.pairs;
  @override
  int get pairsCount => widget.pairs;
  @override
  int get resultMaxScore => widget.pairs;
  @override
  String get resultMessage => _sim!.won
      ? '¡Todas las parejas!'
      : _sim!.remaining == 0
      ? 'Se acabó el tiempo'
      : 'Se acabaron los intentos';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_starting) return;
    _starting = true;
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      for (final dog in PuzzleDeals.poodles)
        precacheImage(
          ResizeImage(AssetImage('assets/images/poodles/$dog.png'), width: 320),
          context,
        ),
    ]);
    if (!mounted || !await beginSession() || !mounted) return;
    final c = AppScope.read(context);
    final deal = c.pet.puzzleDeals[PuzzleDeals.pairsKey(widget.pairs)]!.last;
    final sim = _sim = PairsSim(PuzzleDeals.decode(deal));
    _game = PuzzleGame(
      tick: sim.update,
      onChanged: () => refreshAfterFrame(() {
        if (sim.finished) complete(sim.score);
      }),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sim = _sim, game = _game;
    if (sim == null || game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ActivityFrame(
      title: GameCatalog.pairs.title,
      activityName: 'la partida',
      isGame: true,
      showPauseButton: true,
      game: game,
      hasPendingProgress: () => !sim.finished,
      onExit: cancel,
      scene: SceneView(
        game: game,
        overlay: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.s),
              child: GameHud(
                items: [
                  (Icons.timer_rounded, 'Tiempo', '${sim.remaining.ceil()} s'),
                  (Icons.favorite_rounded, 'Intentos', '${sim.attempts} / 5'),
                  (
                    Icons.check_circle_rounded,
                    'Parejas',
                    '${sim.found} / ${sim.pairCount}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _PuzzleGrid(
                count: sim.cards.length,
                columns:
                    MediaQuery.sizeOf(context).width >
                        MediaQuery.sizeOf(context).height
                    ? widget.pairs
                    : 4,
                builder: (index) {
                  final visible = sim.visible(index);
                  final matched = sim.matched.contains(index);
                  final dog = PuzzleDeals.poodles[sim.cards[index]];
                  return LSemantics(
                    label: visible
                        ? matched
                              ? 'Carta ${index + 1}: ${_poodleNames[sim.cards[index]]}, pareja encontrada'
                              : 'Carta ${index + 1}: ${_poodleNames[sim.cards[index]]}'
                        : 'Carta ${index + 1}, boca abajo',
                    button: true,
                    excludeSemantics: true,
                    child: Material(
                      color: matched ? AppColors.leafSoft : AppColors.plum,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('pair-card-$index'),
                        onTap:
                            game.paused ||
                                sim.finished ||
                                visible ||
                                sim.second != null
                            ? null
                            : () {
                                if (!sim.flip(index)) return;
                                AppScope.feedbackOf(context).play(Sfx.tap);
                                setState(() {});
                              },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (visible)
                              Padding(
                                padding: EdgeInsets.all(matched ? 4 : 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/poodles/$dog.png',
                                    fit: BoxFit.cover,
                                    cacheWidth: 320,
                                  ),
                                ),
                              )
                            else ...[
                              const Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.cream,
                                  size: 30,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 7,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (matched)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.leaf,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LText(
            'Encuentra los caniches iguales.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: AppSpace.xs),
          LText(
            'Premio al completar: ${AppScope.read(context).rules.pairsCoins(widget.pairs)} monedas',
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}

const _poodleNames = [
  'Caniche blanco',
  'Caniche negro',
  'Caniche albaricoque',
  'Caniche plateado',
  'Caniche chocolate',
  'Caniche rojo',
  'Caniche blanco y negro',
  'Caniche crema',
];
const _memoryColors = [
  Color(0xFFB8324A),
  Color(0xFF2258A6),
  Color(0xFF20744B),
  Color(0xFFF1C84C),
];
const _memoryNames = ['Rojo', 'Azul', 'Verde', 'Amarillo'];
const _memoryNotes = ['Do', 'Mi', 'Sol', 'Do agudo'];
const _memoryDogs = ['white', 'black', 'apricot', 'chocolate'];
const _memorySounds = [
  Sfx.memoryRed,
  Sfx.memoryBlue,
  Sfx.memoryGreen,
  Sfx.memoryYellow,
];
const _memoryShapes = [
  Icons.favorite_rounded,
  Icons.water_drop_rounded,
  Icons.eco_rounded,
  Icons.star_rounded,
];

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});
  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen>
    with GameSession, FrameSafeRefresh {
  MemorySim? _sim;
  PuzzleGame? _game;
  bool _starting = false;
  @override
  GameId get gameId => GameId.memory;
  @override
  int get resultMaxScore => 10;
  @override
  String get resultMessage => _sim!.won
      ? '¡Secuencia de 10 completada!'
      : _sim!.remaining == 0
      ? 'Se acabó el tiempo'
      : 'Fin de la secuencia';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_starting) return;
    _starting = true;
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      for (final dog in _memoryDogs)
        precacheImage(
          ResizeImage(AssetImage('assets/images/poodles/$dog.png'), width: 400),
          context,
        ),
    ]);
    if (!mounted || !await beginSession() || !mounted) return;
    final c = AppScope.read(context);
    final sim = _sim = MemorySim(
      PuzzleDeals.decode(c.pet.puzzleDeals['memory']!.last),
    );
    final fx = AppScope.feedbackOf(context);
    _game = PuzzleGame(
      tick: (dt) => sim.update(
        dt,
        onSignal: (signal) => fx.play(_memorySounds[signal], haptic: false),
      ),
      onChanged: () => refreshAfterFrame(() {
        if (sim.finished) complete(sim.completed);
      }),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sim = _sim, game = _game;
    if (sim == null || game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final responding = sim.phase == MemoryPhase.input;
    final status = switch (sim.phase) {
      MemoryPhase.showing => 'Mira y escucha',
      MemoryPhase.input => 'Tu turno: ${sim.inputIndex} / ${sim.length}',
      MemoryPhase.feedback => '¡Muy bien! Siguiente ronda…',
      MemoryPhase.finished => '¡Partida terminada!',
    };
    return ActivityFrame(
      title: GameCatalog.memory.title,
      activityName: 'la partida',
      isGame: true,
      showPauseButton: true,
      game: game,
      hasPendingProgress: () => !sim.finished,
      onExit: cancel,
      scene: SceneView(
        game: game,
        overlay: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.s),
              child: GameHud(
                items: [
                  (
                    Icons.timer_rounded,
                    'Tiempo',
                    responding ? '${sim.remaining.ceil()} s' : '— s',
                  ),
                  (Icons.repeat_rounded, 'Pasos', '${sim.length} / 10'),
                  (Icons.savings_rounded, 'Premio', '${sim.coins}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.m,
                vertical: AppSpace.s,
              ),
              child: LText(
                status,
                style: AppText.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: _PuzzleGrid(
                count: 4,
                columns:
                    MediaQuery.sizeOf(context).width >
                        MediaQuery.sizeOf(context).height
                    ? 4
                    : 2,
                builder: (index) {
                  final lit = sim.lit == index;
                  return LSemantics(
                    label: '${_memoryNames[index]}, ${_memoryNotes[index]}',
                    button: true,
                    excludeSemantics: true,
                    child: AnimatedContainer(
                      duration: Duration(
                        milliseconds: AppScope.read(context).reducedMotion
                            ? 0
                            : 90,
                      ),
                      padding: EdgeInsets.all(lit ? 3 : 9),
                      decoration: BoxDecoration(
                        color: lit ? Colors.white : _memoryColors[index],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _memoryColors[index],
                          width: 3,
                        ),
                        boxShadow: lit
                            ? [
                                BoxShadow(
                                  color: _memoryColors[index].withValues(
                                    alpha: .7,
                                  ),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: _memoryColors[index],
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('memory-pad-$index'),
                          onTap: !responding || game.paused || finishing
                              ? null
                              : () {
                                  if (!sim.press(index)) return;
                                  AppScope.feedbackOf(context)
                                      .play(_memorySounds[index]);
                                  setState(() {});
                                },
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/images/poodles/${_memoryDogs[index]}.png',
                                      fit: BoxFit.cover,
                                      cacheWidth: 400,
                                    ),
                                    if (!lit)
                                      ColoredBox(
                                        color: _memoryColors[index].withValues(
                                          alpha: .2,
                                        ),
                                      ),
                                    if (lit)
                                      const Align(
                                        alignment: Alignment.topRight,
                                        child: Icon(
                                          Icons.volume_up_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _memoryShapes[index],
                                      size: 18,
                                      color: index == 3
                                          ? AppColors.ink
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: LText(
                                        _memoryNames[index],
                                        style: TextStyle(
                                          color: index == 3
                                              ? AppColors.ink
                                              : Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LText(
            '10 segundos para repetir la secuencia.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: AppSpace.xs),
          LText('Premio alcanzado: ${sim.coins} monedas', style: AppText.body),
        ],
      ),
    );
  }
}

/// Cartas cuadradas y centradas; permite desplazamiento con texto ampliado.
class _PuzzleGrid extends StatelessWidget {
  const _PuzzleGrid({
    required this.count,
    required this.columns,
    required this.builder,
  });
  final int count;
  final int columns;
  final Widget Function(int) builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 8.0;
      final rows = (count / columns).ceil();
      final width = (box.maxWidth - 32 - gap * (columns - 1)) / columns;
      final availableHeight = (box.maxHeight - 24 - gap * (rows - 1)) / rows;
      final height = math
          .min(width, availableHeight)
          .clamp(48.0, double.infinity);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Center(
          child: SizedBox(
            height: rows * height + gap * (rows - 1),
            child: GridView.builder(
              physics: availableHeight < 48
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: count,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                childAspectRatio: width / height,
              ),
              itemBuilder: (context, index) => builder(index),
            ),
          ),
        ),
      );
    },
  );
}
