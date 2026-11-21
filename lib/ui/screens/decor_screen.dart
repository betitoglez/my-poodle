import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/decor_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/preview_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/scene_view.dart';
import '../widgets/live_poodle_view.dart';

extension DecorSlotUi on DecorSlot {
  String get label => switch (this) {
    DecorSlot.rug => 'Alfombra',
    DecorSlot.wall => 'Pared',
    DecorSlot.plant => 'Planta',
  };
  IconData get icon => switch (this) {
    DecorSlot.rug => Icons.crop_square_rounded,
    DecorSlot.wall => Icons.wallpaper_rounded,
    DecorSlot.plant => Icons.local_florist_rounded,
  };
}

/// Nombre visible (clave de traducción) de cada artículo de decoración.
String decorLabel(String id) => switch (id) {
  'rug.none' => 'Sin alfombra',
  'rug.round' => 'Alfombra redonda',
  'rug.stripes' => 'Alfombra de rayas',
  'rug.bone' => 'Alfombra hueso',
  'wall.none' => 'Pared libre',
  'wall.frame' => 'Cuadro de huella',
  'wall.garland' => 'Guirnalda de banderines',
  'wall.stars' => 'Estrellas luminosas',
  'plant.none' => 'Sin planta',
  'plant.fern' => 'Helecho',
  'plant.flowers' => 'Maceta de flores',
  'plant.cactus' => 'Cactus sonriente',
  _ => id,
};

/// Decorar el salón: tocar una ficha solo previsualiza (gratis); el botón
/// principal compra y coloca el artículo del hueco elegido en una operación.
/// Salir descarta la vista previa sin coste.
class DecorScreen extends StatefulWidget {
  const DecorScreen({super.key});

  @override
  State<DecorScreen> createState() => _DecorScreenState();
}

class _DecorScreenState extends State<DecorScreen> {
  HomeGame? _game;
  final _live = LivePoodleController();
  DecorSlot _slot = DecorSlot.rug;
  late Map<DecorSlot, String> _preview;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.read(context);
    if (_game == null) {
      _preview = _placed(c);
      _game = HomeGame(
        painter: PetPainterScope.of(context),
        look: c.look,
        reducedMotion: c.reducedMotion,
      )..setDecor(_preview);
      _game!.pet.fx = PetFx(sick: c.pet.isSick)
          .withHygiene(c.pet.needPoints(Need.hygiene));
    }
    _game!.reducedMotion = c.reducedMotion;
  }

  /// Decoración guardada, con el artículo vacío en los huecos sin dato.
  Map<DecorSlot, String> _placed(AppController c) => {
    ...c.balance.initialDecor,
    ...c.pet.decor,
  };

  void _setPreview(Map<DecorSlot, String> next, {bool react = true}) {
    setState(() => _preview = Map.of(next));
    _game!.setDecor(_preview);
    if (react) _game!.pet.react(PetAnim.happy, seconds: 1);
  }

  /// Cambiar de hueco descarta la prueba del anterior: solo se prueba uno.
  void _selectSlot(DecorSlot slot) {
    if (slot == _slot) return;
    final placed = _placed(AppScope.read(context));
    setState(() => _slot = slot);
    _setPreview(placed, react: false);
  }

  bool _locked(AppController c, DecorItem item) =>
      !item.initial &&
      !c.pet.owned.contains(item.id) &&
      !c.canAccess(item.tier);

  bool _owned(AppController c, DecorItem item) =>
      item.initial || c.pet.owned.contains(item.id);

  Future<void> _apply() async {
    final c = AppScope.read(context);
    final item = c.balance.decorItem(_preview[_slot]!)!;
    if (_locked(c, item)) {
      await showAskAdult(context);
      return;
    }
    final cost = _owned(c, item) ? 0 : item.cost;
    if (cost > c.pet.coins) {
      await _insufficient(cost - c.pet.coins, cost);
      return;
    }
    if (cost > 0) {
      final ok = await showPurchaseDialog(
        context,
        title: 'Comprar y colocar',
        items: [decorLabel(item.id)],
        price: cost,
        balance: c.pet.coins,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    final r = await commitOrRecover<PurchaseOutcome>(
      context,
      () => c.applyDecor(item.id),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Purchased(:final receipt, cost: final paid):
        if (paid > 0) {
          AppScope.feedbackOf(context).play(Sfx.coins);
          ConfettiBurst.show(context, reducedMotion: c.reducedMotion);
        }
        _setPreview({..._placed(c), ...receipt.after.decor}, react: false);
        _game!.pet.react(PetAnim.celebrate, seconds: 1.6);
      case InsufficientCoins(:final missing, cost: final price):
        await _insufficient(missing, price);
      case RequiresFull():
        await showAskAdult(context);
      case null:
        break;
    }
  }

  Future<void> _insufficient(int missing, int price) async {
    final choice = await showInsufficientDialog(
      context,
      missing: missing,
      price: price,
    );
    if (choice == InsufficientChoice.games && mounted) {
      goToTab(context, ShellTab.games);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final l = Layout.of(context);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(pet.appearance);
    _game!.pet.showSprite = !showModel;
    _game!.useLiveBed = showModel;
    final placed = _placed(c);
    final selectedId = _preview[_slot]!;
    final item = c.balance.decorItem(selectedId)!;
    final dirty = selectedId != placed[_slot];
    final owned = _owned(c, item);
    final locked = _locked(c, item);
    final cost = owned ? 0 : item.cost;
    final blocked = _busy || c.saving;

    late final Widget action;
    if (!dirty) {
      action = const AppButton(
        label: 'Puesto',
        icon: Icons.check_rounded,
        expand: true,
        onPressed: null,
      );
    } else if (locked) {
      action = AppButton(
        label: 'Versión completa',
        icon: Icons.lock_rounded,
        secondary: true,
        expand: true,
        onPressed: () => showAskAdult(context),
      );
    } else if (cost == 0) {
      action = AppButton(
        label: 'Colocar',
        icon: Icons.check_rounded,
        expand: true,
        onPressed: blocked ? null : _apply,
      );
    } else if (cost > pet.coins) {
      action = AppButton(
        label: 'Faltan ${cost - pet.coins} · Jugar',
        icon: Icons.sports_esports_rounded,
        expand: true,
        onPressed: () => _insufficient(cost - pet.coins, cost),
      );
    } else {
      action = AppButton(
        label: 'Comprar y colocar · $cost',
        icon: Icons.shopping_bag_rounded,
        expand: true,
        onPressed: blocked ? null : _apply,
      );
    }

    final textScale = MediaQuery.textScalerOf(context);
    final tileExtent =
        (l.compact ? 54.0 : 70.0) +
        textScale.scale(15) * 1.3 +
        textScale.scale(13) * 1.3 +
        18;
    final items = c.balance.decorFor(_slot);

    return Scaffold(
      appBar: AppBar(
        title: const LText(
          'Decorar el salón',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (c.demo) const DemoBadge(),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 6),
            child: CoinBalance(coins: pet.coins),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              flex: l.compact ? 3 : 4,
              child: SceneView(
                game: _game!,
                semanticsLabel: 'Vista previa del salón de ${pet.name}',
                onDragUpdate: showModel
                    ? (_, _, delta) => _live.rotate(delta.dx)
                    : null,
                onTap: (_) {
                  if (showModel) {
                    _live.pet();
                  } else {
                    _game!.pet.react(PetAnim.happy);
                  }
                },
                overlay: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showModel)
                      IgnorePointer(
                        child: LivePoodleView(
                          controller: _live,
                          appearance: pet.appearance,
                          resting: false,
                          reducedMotion: c.reducedMotion,
                          wardrobe: false,
                          idle: true,
                          hygiene: pet.needPoints(Need.hygiene),
                          mood: pet.needPoints(Need.mood),
                          energy: pet.needPoints(Need.energy),
                          sick: pet.isSick,
                          onStatusChanged: () {
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    if (dirty)
                      const Positioned(
                        right: AppSpace.s,
                        top: AppSpace.s,
                        child: PreviewBadge(),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: l.compact ? 7 : 6,
              child: Panel(
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final slot in DecorSlot.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _SlotTab(
                                label: slot.label,
                                icon: slot.icon,
                                selected: slot == _slot,
                                onTap: () => _selectSlot(slot),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: l.tablet ? 4 : 2,
                          mainAxisSpacing: AppSpace.s,
                          crossAxisSpacing: AppSpace.s,
                          mainAxisExtent: tileExtent,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final it = items[i];
                          final isOwned = _owned(c, it);
                          final isPlaced = placed[_slot] == it.id;
                          final isLocked = _locked(c, it);
                          return _DecorTile(
                            id: it.id,
                            label: decorLabel(it.id),
                            state: isPlaced
                                ? 'Puesto'
                                : it.initial
                                ? 'Gratis'
                                : isOwned
                                ? 'En propiedad'
                                : isLocked
                                ? 'Versión completa'
                                : '${it.cost} monedas',
                            cost: isOwned || isLocked ? null : it.cost,
                            placed: isPlaced,
                            owned: isOwned,
                            locked: isLocked,
                            selected: it.id == selectedId,
                            onTap: () =>
                                _setPreview({..._preview, _slot: it.id}),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpace.s),
                    Row(
                      children: [
                        if (dirty) ...[
                          Expanded(
                            flex: 2,
                            child: AppButton(
                              label: 'Descartar',
                              icon: Icons.undo_rounded,
                              secondary: true,
                              expand: true,
                              onPressed: () => _setPreview(placed),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                        ],
                        Expanded(flex: 3, child: action),
                      ],
                    ),
                    if (dirty && !owned)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LText(
                          locked
                              ? 'Probar es gratis. Para tenerlo, pide ayuda a un adulto.'
                              : 'Probar es gratis. Solo pagas al confirmar.',
                          style: AppText.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LSemantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.plum : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.s),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.s),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch + 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.cream : AppColors.plum,
                ),
                LText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.cream : AppColors.ink,
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

class _DecorTile extends StatelessWidget {
  const _DecorTile({
    required this.id,
    required this.label,
    required this.state,
    required this.cost,
    required this.placed,
    required this.owned,
    required this.locked,
    required this.selected,
    required this.onTap,
  });
  final String id;
  final String label;

  /// «Puesto», «Gratis», «En propiedad», «Versión completa» o el precio.
  final String state;

  /// Precio visible (null: no se paga).
  final int? cost;
  final bool placed;
  final bool owned;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LSemantics(
      button: true,
      selected: selected,
      label: label,
      value: state,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.plumSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          side: BorderSide(
            color: selected ? AppColors.plum : const Color(0x22000000),
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.creamDeep,
                          borderRadius: BorderRadius.circular(AppRadii.s),
                        ),
                        child: DecorPainter.isEmpty(id)
                            ? const Icon(
                                Icons.do_not_disturb_alt_rounded,
                                color: AppColors.inkSoft,
                              )
                            : CustomPaint(painter: _ThumbPainter(id)),
                      ),
                      if (locked)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: LockBadge(compact: true),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                LText(
                  label,
                  style: AppText.subtitle.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (placed)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.leaf,
                      )
                    else if (owned)
                      const Icon(
                        Icons.inventory_2_rounded,
                        size: 16,
                        color: AppColors.inkSoft,
                      )
                    else if (locked)
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AppColors.plum,
                      )
                    else
                      const CoinIcon(size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: LText(
                        state,
                        style: AppText.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) =>
      DecorPainter.paintThumb(canvas, size, id);

  @override
  bool shouldRepaint(_ThumbPainter old) => old.id != id;
}
