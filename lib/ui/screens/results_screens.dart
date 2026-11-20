import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/texts.dart';
import '../../domain/appearance.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../game/game_registry.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/room_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/coin_count.dart';
import '../widgets/common.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/scene_view.dart';
import '../widgets/star_reveal.dart';
import 'games_screen.dart';
import 'wardrobe_screen.dart';

/// Escena de celebración compartida por ambos resultados.
class _CelebrationScene extends StatefulWidget {
  const _CelebrationScene({required this.room});
  final RoomKind room;
  @override
  State<_CelebrationScene> createState() => _CelebrationSceneState();
}

class _CelebrationSceneState extends State<_CelebrationScene> {
  StageGame? _game;
  final _live = LivePoodleController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.read(context);
    _game ??= StageGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      room: widget.room,
      reducedMotion: c.reducedMotion,
      anim: PetAnim.celebrate,
      petScale: 0.62,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final hasModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(c.pet.appearance);
    _game!.pet.showSprite = !hasModel;
    return SceneView(
      game: _game!,
      semanticsLabel: 'Tu caniche celebra contento',
      onTap: (_) => hasModel ? _live.pet() : _game!.pet.react(PetAnim.happy),
      overlay: hasModel
          ? LivePoodleView(
              controller: _live,
              appearance: c.pet.appearance,
              resting: false,
              wardrobe: false,
              reducedMotion: c.reducedMotion,
              idle: true,
              hygiene: c.pet.needPoints(Need.hygiene),
              mood: c.pet.needPoints(Need.mood),
              energy: c.pet.needPoints(Need.energy),
              sick: c.pet.isSick,
              onStatusChanged: () => setState(() {}),
            )
          : null,
    );
  }
}

class _ResultLayout extends StatelessWidget {
  const _ResultLayout({
    required this.room,
    required this.kicker,
    required this.title,
    required this.body,
    required this.actions,
  });
  final RoomKind room;
  final String kicker;
  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: LText(
                          kicker.toUpperCase(),
                          style: AppText.kicker,
                        ),
                      ),
                      if (c.demo) const DemoBadge(),
                      const SizedBox(width: 6),
                      CoinBalance(coins: c.pet.coins),
                    ],
                  ),
                ),
                Expanded(child: _CelebrationScene(room: room)),
                // El panel nunca tapa del todo la escena: en pantallas bajas o
                // con texto grande se desplaza en lugar de desbordar.
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * 0.72),
                  child: Panel(
                    child: SingleChildScrollView(
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LSemantics(
                              header: true,
                              child: LText(
                                title,
                                style: AppText.display.copyWith(fontSize: 26),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s),
                            body,
                            const SizedBox(height: AppSpace.l),
                            Wrap(
                              spacing: AppSpace.s,
                              runSpacing: AppSpace.s,
                              alignment: WrapAlignment.end,
                              children: actions,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _needChange(Receipt r, Need n) {
  final before = r.before.needPoints(n), after = r.after.needPoints(n);
  final diff = after - before;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(n.icon, color: n.color),
        const SizedBox(width: AppSpace.s),
        Expanded(child: LText(Texts.needLabels[n]!, style: AppText.subtitle)),
        // Con texto grande la cifra se reduce en lugar de desbordar.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: LText('$before → $after', style: AppText.number),
          ),
        ),
        const SizedBox(width: AppSpace.s),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: diff >= 0 ? AppColors.leafSoft : AppColors.plumSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: LText(
            diff >= 0 ? '+$diff' : '$diff',
            style: AppText.number.copyWith(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

/// Salud antes y después según el recibo (la diferencia sale del dominio).
Widget _healthChange(Receipt r) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    children: [
      const Icon(Icons.favorite_rounded, color: AppColors.leaf),
      const SizedBox(width: AppSpace.s),
      const Expanded(child: LText('Salud', style: AppText.subtitle)),
      const LText('Malito → Sano', style: AppText.number),
      const SizedBox(width: AppSpace.s),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.leafSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: LText(
          '+${r.after.healthPoints - r.before.healthPoints}',
          style: AppText.number.copyWith(fontSize: 14),
        ),
      ),
    ],
  ),
);

/// P14 · Resultado del cuidado.
class CareResultScreen extends StatefulWidget {
  const CareResultScreen({
    super.key,
    required this.kind,
    required this.receipt,
  });
  final CareKind kind;
  final Receipt receipt;
  @override
  State<CareResultScreen> createState() => _CareResultScreenState();
}

class _CareResultScreenState extends State<CareResultScreen> {
  late final String _message = Texts().pick(
    widget.kind == CareKind.vet && widget.receipt.before.isSick
        ? Texts.curedMessages
        : Texts.careDone[widget.kind]!,
    name: widget.receipt.after.name,
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final delta = AppScope.read(context).balance.care[widget.kind.name]!.delta;
    final room = switch (widget.kind) {
      CareKind.feed || CareKind.drink => RoomKind.kitchen,
      CareKind.bath => RoomKind.bath,
      CareKind.groom => RoomKind.salon,
      CareKind.vet => RoomKind.vet,
      _ => RoomKind.living,
    };
    return _ResultLayout(
      room: room,
      kicker: '${Texts.careTitles[widget.kind]} completado',
      title: _message,
      body: Column(
        children: [
          if (r.before.isSick && !r.after.isSick) _healthChange(r),
          for (final n in delta.keys) _needChange(r, n),
        ],
      ),
      actions: [
        if (widget.kind == CareKind.groom)
          AppButton(
            label: 'Ver cortes',
            icon: Icons.content_cut_rounded,
            secondary: true,
            onPressed: () => replaceScreen(
              context,
              const WardrobeScreen(initialSlot: Slot.hair, standalone: true),
            ),
          ),
        AppButton(
          label: 'Cuidados',
          icon: Icons.volunteer_activism_rounded,
          secondary: true,
          onPressed: () => goToTab(context, ShellTab.care),
        ),
        AppButton(
          label: 'Casa',
          icon: Icons.home_rounded,
          onPressed: () => goToTab(context, ShellTab.home),
        ),
      ],
    );
  }
}

/// P15 · Resultado del juego: puntuación, monedas obtenidas y saldo final.
class GameResultScreen extends StatefulWidget {
  const GameResultScreen({
    super.key,
    required this.game,
    required this.receipt,
  });
  final GameId game;
  final Receipt receipt;
  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  late final String _title = Texts().pick(
    Texts.gameDone,
    name: widget.receipt.after.name,
  );

  @override
  void initState() {
    super.initState();
    // Nueva mejor marca de estrellas: confeti (destello estático si el
    // movimiento está reducido) tras el primer fotograma.
    if (widget.receipt.newBestStars) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ConfettiBurst.show(
          context,
          reducedMotion: AppScope.read(context).reducedMotion,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final reduced = AppScope.of(context).reducedMotion;
    final balance = AppScope.read(context).balance;
    final def = GameCatalog.of(widget.game, balance);
    final max = widget.game == GameId.fruit
        ? balance.fruit.maxScore
        : balance.frisbee.targetsField.length;
    return _ResultLayout(
      room: RoomKind.living,
      kicker: def.title,
      title: _title,
      body: Column(
        children: [
          StarReveal(stars: r.stars, reducedMotion: reduced),
          if (r.newBestStars)
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.xs),
              child: LText(
                '¡Nueva mejor marca de estrellas!',
                textAlign: TextAlign.center,
                style: AppText.subtitle,
              ),
            ),
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              Icon(
                widget.game == GameId.fruit
                    ? Icons.apple_rounded
                    : Icons.album_rounded,
                color: AppColors.coral,
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: LText(
                  '${r.score} de $max ${def.scoreLabel}${r.newBest ? ' · ¡nuevo récord!' : ''}',
                  style: AppText.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              const CoinIcon(size: 22),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: CountUpText(
                  from: 0,
                  to: r.coinsEarned,
                  format: (v) => '+$v monedas',
                  reducedMotion: reduced,
                  style: AppText.subtitle,
                ),
              ),
              CountUpText(
                from: r.before.coins,
                to: r.after.coins,
                format: (v) => 'Saldo $v',
                reducedMotion: reduced,
                style: AppText.number,
              ),
            ],
          ),
          const Divider(height: AppSpace.l),
          _needChange(r, Need.mood),
          _needChange(r, Need.energy),
        ],
      ),
      actions: [
        AppButton(
          label: 'Repetir',
          icon: Icons.replay_rounded,
          secondary: true,
          onPressed: () =>
              replaceScreen(context, InstructionsScreen(game: widget.game)),
        ),
        AppButton(
          label: 'Otro juego',
          icon: Icons.sports_esports_rounded,
          secondary: true,
          onPressed: () => goToTab(context, ShellTab.games),
        ),
        AppButton(
          label: 'Casa',
          icon: Icons.home_rounded,
          onPressed: () => goToTab(context, ShellTab.home),
        ),
      ],
    );
  }
}
