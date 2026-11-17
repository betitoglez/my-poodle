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
import '../widgets/common.dart';
import '../widgets/scene_view.dart';
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
  Widget build(BuildContext context) => SceneView(
    game: _game!,
    semanticsLabel: 'Tu caniche celebra contento',
    onTap: (_) => _game!.pet.react(PetAnim.happy),
  );
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(kicker.toUpperCase(), style: AppText.kicker),
                    ),
                    if (c.demo) const DemoBadge(),
                    const SizedBox(width: 6),
                    CoinBalance(coins: c.pet.coins),
                  ],
                ),
              ),
              Expanded(child: _CelebrationScene(room: room)),
              Panel(
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: AppText.display.copyWith(fontSize: 26),
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
            ],
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
        Expanded(child: Text(Texts.needLabels[n]!, style: AppText.subtitle)),
        Text('$before → $after', style: AppText.number),
        const SizedBox(width: AppSpace.s),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: diff >= 0 ? AppColors.leafSoft : AppColors.plumSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
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
      const Expanded(child: Text('Salud', style: AppText.subtitle)),
      const Text('Malito → Sano', style: AppText.number),
      const SizedBox(width: AppSpace.s),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.leafSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
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
  late final String _message;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cured = widget.kind == CareKind.vet && widget.receipt.before.isSick;
    _message = Texts().pick(
      cured ? Texts.curedMessages : Texts.careDone[widget.kind]!,
      name: AppScope.read(context).pet.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final delta = AppScope.read(context).balance.care[widget.kind.name]!.delta;
    final room = switch (widget.kind) {
      CareKind.feed => RoomKind.kitchen,
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
          onPressed: () {
            AppScope.adsOf(context).onReturnHome();
            goToTab(context, ShellTab.home);
          },
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
  late final String _title;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _title = Texts().pick(
      Texts.gameDone,
      name: AppScope.read(context).pet.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    final def = GameCatalog.of(widget.game);
    final max = widget.game == GameId.fruit ? 12 : 3;
    return _ResultLayout(
      room: RoomKind.living,
      kicker: def.title,
      title: _title,
      body: Column(
        children: [
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
                child: Text(
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
                child: Text(
                  '+${r.coinsEarned} monedas',
                  style: AppText.subtitle,
                ),
              ),
              Text('Saldo ${r.after.coins}', style: AppText.number),
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
          onPressed: () {
            AppScope.adsOf(context).onReturnHome();
            goToTab(context, ShellTab.home);
          },
        ),
      ],
    );
  }
}
