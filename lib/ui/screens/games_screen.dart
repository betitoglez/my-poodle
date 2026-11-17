import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../domain/rules.dart';
import '../../game/game_registry.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'minigame_screens.dart';

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
            child: const Text(
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
                for (final def in GameCatalog.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.m),
                    child: _GameCard(
                      def: def,
                      best: def.id == GameId.fruit
                          ? c.pet.bestFruit
                          : c.pet.bestFrisbee,
                      locked: !c.canPlay(def.id),
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
    this.locked = false,
  });
  final GameDefinition def;
  final int best;
  final VoidCallback onOpen;

  /// Juego de la versión completa sin derecho: candado, no abre el juego.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    return Semantics(
      button: true,
      label: locked
          ? '${def.title}. Versión completa. Pide ayuda a un adulto.'
          : '${def.title}. ${def.tagline}. Récord $best ${def.scoreLabel}.',
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(def.title, style: AppText.title),
                          Text(def.tagline, style: AppText.body),
                          const SizedBox(height: 4),
                          Text(
                            '${def.limitLabel} · Récord: $best ${def.scoreLabel}',
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    AppButton(
                      label: locked ? 'Ver' : 'Jugar',
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
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key, required this.game});
  final GameId game;

  @override
  Widget build(BuildContext context) {
    final def = GameCatalog.of(game);
    final l = Layout.of(context);
    final reduced = AppScope.of(context).reducedMotion;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(def.title),
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
                  icon: game == GameId.fruit
                      ? Icons.touch_app_rounded
                      : Icons.swipe_up_rounded,
                  text: def.gesture,
                ),
                _Line(icon: Icons.flag_rounded, text: def.objective),
                _Line(
                  icon: Icons.timer_rounded,
                  text: 'Duración: ${def.limitLabel}.',
                ),
                _Line(
                  icon: Icons.savings_rounded,
                  text:
                      'Premio: ${def.rewardLabel}. Si sales antes de terminar, no hay premio.',
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
                        onPressed: () => replaceScreen(
                          context,
                          game == GameId.fruit
                              ? const OrchardScreen()
                              : const FrisbeeScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.leaf),
        const SizedBox(width: AppSpace.m),
        Expanded(child: Text(text, style: AppText.body)),
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
                  child: Text(
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
  const GameHud({super.key, required this.items});
  final List<(IconData, String, String)> items;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s,
      runSpacing: AppSpace.s,
      alignment: WrapAlignment.center,
      children: [
        for (final (icon, label, value) in items)
          Semantics(
            label: '$label $value',
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
                  Text(value, style: AppText.number),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
