import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/background_music.dart';
import '../../domain/rules.dart';
import '../../game/game_registry.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'minigame_screens.dart';
import 'puzzle_screens.dart';

/// P10 · Selección de juegos: tarjetas leídas de [GameCatalog].
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const TabHeader(kicker: 'En el parque', title: 'A jugar'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: l.gutter),
            child: const LText(
              'Elige dónde ganar monedas con tu caniche.',
              style: AppText.body,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                l.gutter,
                AppSpace.m,
                l.gutter,
                AppSpace.l,
              ),
              children: [
                for (final def in GameCatalog.all(c.balance))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.m),
                    child: _GameCard(
                      def: def,
                      best: c.rules.gameBest(c.pet, def.id),
                      bestStars: c.pet.bestStars[def.id.name] ?? 0,
                      locked: !c.canPlay(def.id),
                      trial: c.isGameTrial(def.id),
                      trialLabel: c.trialLabel(def.id),
                      onOpen: () => c.canPlay(def.id)
                          ? pushScreen(
                              context,
                              InstructionsScreen(game: def.id),
                            )
                          : showAskAdult(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.def,
    required this.best,
    required this.onOpen,
    this.bestStars = 0,
    this.locked = false,
    this.trial = false,
    this.trialLabel,
  });
  final GameDefinition def;
  final int best;
  final VoidCallback onOpen;

  /// Mejor marca de estrellas guardada (0..3).
  final int bestStars;

  /// Juego de la versión completa sin derecho: candado, no abre el juego.
  final bool locked;
  final bool trial;
  final String? trialLabel;

  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    // Cada parte se localiza con su propia plantilla y se unen después.
    final label = locked
        ? localize(
            context,
            '${def.title}. Versión completa. Pide ayuda a un adulto.',
          )
        : '${localize(context, '${def.title}. ${def.tagline}. Récord $best ${def.scoreLabel}.')} '
              '${localize(context, 'Mejor marca: $bestStars de 3 estrellas.')}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.m),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: l.compact ? 120 : 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(def.thumbnail, fit: BoxFit.cover),
                    if (locked) ...[
                      Container(color: const Color(0x5534283B)),
                      const Positioned(top: 10, right: 10, child: LockBadge()),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LText(def.title, style: AppText.title),
                        LText(def.tagline, style: AppText.body),
                        if (trial && !locked)
                          const LText('Versión completa', style: AppText.small),
                        if (trialLabel != null)
                          LText(trialLabel!, style: AppText.small),
                        const SizedBox(height: 4),
                        LText(
                          '${def.limitLabel} · Récord: $best ${def.scoreLabel}',
                          style: AppText.small,
                        ),
                        const SizedBox(height: 2),
                        StarRow(stars: bestStars, size: 20),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s),
                    AppButton(
                      expand: true,
                      label: locked
                          ? 'Ver'
                          : trial
                          ? 'Probar gratis'
                          : 'Jugar',
                      icon: locked
                          ? Icons.lock_rounded
                          : Icons.play_arrow_rounded,
                      secondary: locked,
                      onPressed: onOpen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// P11 · Instrucciones: demostración del gesto, objetivo, límite, Jugar/Volver.
class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key, required this.game});
  final GameId game;
  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  int _pairs = 4;
  GameId get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final def = GameCatalog.of(game, c.balance);
    final l = Layout.of(context);
    final reduced = c.reducedMotion;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: localizeNullable(context, 'Volver'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: LText(def.title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: l.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.all(l.gutter),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  child: SizedBox(
                    height: l.compact ? 170 : 230,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(def.thumbnail, fit: BoxFit.cover),
                        Container(color: const Color(0x3334283B)),
                        if (game == GameId.fruit || game == GameId.frisbee)
                          _GestureDemo(
                            drag: game == GameId.frisbee,
                            reducedMotion: reduced,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.l),
                _Line(
                  icon: game == GameId.frisbee
                      ? Icons.swipe_up_rounded
                      : Icons.touch_app_rounded,
                  text: def.gesture,
                ),
                _Line(icon: Icons.flag_rounded, text: def.objective),
                if (c.isGameTrial(game))
                  const _Line(
                    icon: Icons.schedule_rounded,
                    text: 'Una partida gratis cada 24 horas. La prueba se usa al comenzar, aunque salgas antes de terminar.',
                  ),
                _Line(
                  icon: Icons.timer_rounded,
                  text: 'Duración: ${def.limitLabel}.',
                ),
                _Line(
                  icon: Icons.savings_rounded,
                  text:
                      'Premio: ${def.rewardLabel}. Si sales antes de terminar, no hay premio.',
                ),
                if (game == GameId.pairs) ...[
                  const SizedBox(height: AppSpace.m),
                  const LText('Elige un nivel', style: AppText.subtitle),
                  const SizedBox(height: AppSpace.s),
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      for (final count in [4, 6, 8])
                        AppButton(
                          label: '$count parejas',
                          icon: _pairs == count
                              ? Icons.check_circle_rounded
                              : Icons.grid_view_rounded,
                          secondary: _pairs != count,
                          onPressed: () => setState(() => _pairs = count),
                        ),
                    ],
                  ),
                ],
                if (game == GameId.memory)
                  const _Line(
                    icon: Icons.lock_rounded,
                    text: 'Solo disponible en la versión completa.',
                  ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Volver',
                        icon: Icons.arrow_back_rounded,
                        secondary: true,
                        expand: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: AppButton(
                        label: 'Jugar',
                        icon: Icons.play_arrow_rounded,
                        big: true,
                        expand: true,
                        onPressed: () => replaceScreen(context, switch (game) {
                          GameId.fruit => const OrchardScreen(),
                          GameId.frisbee => const FrisbeeScreen(),
                          GameId.pairs => PairsScreen(pairs: _pairs),
                          GameId.memory => const MemoryScreen(),
                        }, music: MusicTrack.games),
                      ),
                    ),
                  ],
                ),
                // Retos después de Jugar: el botón principal sigue a la vista.
                const SizedBox(height: AppSpace.xl),
                _Challenges(game: game),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Retos de estrellas y variedad de la partida, con números del balance.
/// Las estrellas no cambian el premio en monedas.
class _Challenges extends StatelessWidget {
  const _Challenges({required this.game});
  final GameId game;

  @override
  Widget build(BuildContext context) {
    final b = AppScope.of(context).balance;
    final lines = switch (game) {
      GameId.pairs => [
        'Estrella 1: 4 parejas',
        'Estrella 2: 6 parejas',
        'Estrella 3: 8 parejas',
      ],
      GameId.memory => [
        'Estrella 1: 3 pasos',
        'Estrella 2: 6 pasos',
        'Estrella 3: 10 pasos',
      ],
      GameId.frisbee => [
        'Estrella 1: ${b.frisbee.starCatches[0]} capturas',
        'Estrella 2: ${b.frisbee.starCatches[1]} capturas',
        'Estrella 3: ${b.frisbee.starCatches[2]} capturas',
      ],
      GameId.fruit => [
        'Estrella 1: ${b.fruit.starFruits[0]} frutas',
        'Estrella 2: ${b.fruit.starFruits[1]} frutas',
        'Estrella 3: ${b.fruit.starFruits[1]} frutas y las ${b.fruit.starGolden} doradas',
      ],
    };
    final variety = switch (game) {
      GameId.pairs || GameId.memory => 'Los objetivos cambian en cada partida.',
      GameId.frisbee => 'Los objetivos cambian en cada partida.',
      GameId.fruit =>
        'Cada partida esconde ${b.fruit.starGolden} frutas doradas.',
    };
    final best = AppScope.of(context).pet.bestStars[game.name] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.s,
          runSpacing: AppSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const LSemantics(
              header: true,
              child: LText('Retos de estrellas', style: AppText.title),
            ),
            StarRow(stars: best, size: 20),
          ],
        ),
        for (var i = 0; i < lines.length; i++)
          _Line(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFB9861F),
            text: lines[i],
          ),
        _Line(icon: Icons.shuffle_rounded, text: variety),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.iconColor});
  final IconData icon;
  final String text;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? AppColors.leaf),
        const SizedBox(width: AppSpace.m),
        Expanded(child: LText(text, style: AppText.body)),
      ],
    ),
  );
}

/// Mano animada que demuestra un toque o un arrastre hacia arriba.
class _GestureDemo extends StatefulWidget {
  const _GestureDemo({required this.drag, required this.reducedMotion});
  final bool drag;
  final bool reducedMotion;
  @override
  State<_GestureDemo> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<_GestureDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = widget.reducedMotion ? 0.5 : _c.value;
          final dy = widget.drag ? -60 * math.min(1, t * 1.4) : 0.0;
          final press = !widget.drag && t > 0.3 && t < 0.5;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.drag)
                Positioned(
                  bottom: 30,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 70,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              if (press || widget.reducedMotion && !widget.drag)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              Transform.translate(
                offset: Offset(18, 30 + dy + (press ? 6 : 0)),
                child: const Icon(
                  Icons.pan_tool_alt_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: LText(
                    widget.drag ? 'Arrastra y suelta' : 'Toca para saltar',
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Indicador superior de partida (tiempo, contador, intentos).
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.items, this.live = const {}});
  final List<(IconData, String, String)> items;

  /// Etiquetas cuyo cambio se anuncia (puntuación, aciertos, doradas). El
  /// tiempo cambia cada segundo y no se anuncia: saturaría el lector.
  final Set<String> live;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s,
      runSpacing: AppSpace.s,
      alignment: WrapAlignment.center,
      children: [
        for (final (icon, label, value) in items)
          LSemantics(
            label: '$label $value',
            liveRegion: live.contains(label),
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cream.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: const [
                  BoxShadow(color: Color(0x2234283B), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: AppColors.plum),
                  const SizedBox(width: 6),
                  LText(value, style: AppText.number),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
