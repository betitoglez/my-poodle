import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/appearance.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../game/pet/appearance_catalog.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/room_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/scene_view.dart';
import 'main_shell.dart';

extension SlotUi on Slot {
  String get label => switch (this) {
    Slot.coat => 'Colores',
    Slot.hair => 'Peinados',
    Slot.outfit => 'Ropa',
    Slot.neck => 'Accesorios',
  };
  IconData get icon => switch (this) {
    Slot.coat => Icons.palette_rounded,
    Slot.hair => Icons.content_cut_rounded,
    Slot.outfit => Icons.checkroom_rounded,
    Slot.neck => Icons.diamond_rounded,
  };
}

/// P09 · Armario. La vista previa es una copia del aspecto: no modifica el
/// estado guardado ni descuenta monedas hasta confirmar.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({
    super.key,
    this.initialSlot = Slot.coat,
    this.standalone = false,
  });
  final Slot initialSlot;

  /// Abierto desde Peluquería o un resultado (ruta propia con Volver).
  final bool standalone;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  StageGame? _game;
  late Appearance _preview;
  late Slot _slot = widget.initialSlot;
  bool _busy = false;
  ShellController? _shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game == null) {
      final c = AppScope.read(context);
      _preview = c.pet.appearance;
      _game = StageGame(
        painter: PetPainterScope.of(context),
        look: c.look,
        room: RoomKind.wardrobe,
        reducedMotion: c.reducedMotion,
        petX: 0.42,
        petScale: 0.7,
        floorY: 0.76,
      );
      _shell = ShellScope.maybeOf(context);
      if (!widget.standalone) _shell?.leaveGuard = _confirmLeave;
    }
  }

  @override
  void dispose() {
    final shell = _shell;
    if (!widget.standalone &&
        shell != null &&
        shell.leaveGuard == _confirmLeave) {
      shell.leaveGuard = null;
    }
    super.dispose();
  }

  bool get _dirty => _preview != AppScope.read(context).pet.appearance;

  void _setPreview(Appearance a) {
    final c = AppScope.read(context);
    setState(() => _preview = a);
    _game!.setLook(c.looks.resolve(a));
    _game!.pet.react(PetAnim.happy, seconds: 1);
  }

  /// Salir con una prueba pendiente: aplicar (con compra) o descartar.
  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final c = AppScope.read(context);
    final choice = await showLeavePreviewDialog(
      context,
      cost: c.lookCost(_preview),
    );
    switch (choice) {
      case PreviewChoice.stay:
        return false;
      case PreviewChoice.discard:
        _setPreview(c.pet.appearance);
        return true;
      case PreviewChoice.apply:
        return _apply();
    }
  }

  Future<void> _goToGames() async {
    if (widget.standalone) {
      goToTab(context, ShellTab.games);
    } else {
      _setPreview(AppScope.read(context).pet.appearance);
      ShellScope.maybeOf(context)?.force(ShellTab.games);
    }
  }

  /// Compra y equipa la vista previa en una sola operación.
  Future<bool> _apply([Appearance? target]) async {
    final c = AppScope.read(context);
    final look = target ?? _preview;
    final cost = c.lookCost(look);
    if (cost > c.pet.coins) {
      final choice = await showInsufficientDialog(
        context,
        missing: cost - c.pet.coins,
        price: cost,
      );
      if (choice == InsufficientChoice.games && mounted) await _goToGames();
      return false;
    }
    if (cost > 0) {
      final items = [
        for (final s in Slot.values)
          if (!c.pet.owned.contains(look.of(s))) c.looks.label(look.of(s)),
      ];
      final ok = await showPurchaseDialog(
        context,
        items: items,
        price: cost,
        balance: c.pet.coins,
      );
      if (!ok || !mounted) return false;
    }
    setState(() => _busy = true);
    final r = await commitOrRecover<PurchaseOutcome>(
      context,
      () => c.applyLook(look),
    );
    if (!mounted) return false;
    setState(() => _busy = false);
    if (r is Purchased) {
      if (r.cost > 0) AppScope.feedbackOf(context).play(Sfx.coins);
      _setPreview(r.receipt.after.appearance);
      _game!.pet.react(PetAnim.celebrate, seconds: 1.6);
      return true;
    }
    if (r is InsufficientCoins) {
      await showInsufficientDialog(context, missing: r.missing, price: r.cost);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final l = Layout.of(context);
    final selectedId = _preview.of(_slot);
    final item = c.balance.item(selectedId)!;
    final owned = pet.owned.contains(selectedId);
    final equipped = pet.appearance.of(_slot) == selectedId;
    final dirty = _preview != pet.appearance;
    final cost = c.lookCost(_preview);

    // Acción contextual.
    late final Widget action;
    if (!dirty) {
      action = equipped && !item.initial
          ? AppButton(
              label: 'Quitar',
              icon: Icons.remove_circle_outline_rounded,
              secondary: true,
              expand: true,
              onPressed: _busy || c.saving
                  ? null
                  : () => _apply(
                      _preview.withSlot(_slot, c.balance.baseFor(_slot).id),
                    ),
            )
          : const AppButton(
              label: 'Equipado',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: null,
            );
    } else if (cost == 0) {
      action = AppButton(
        label: 'Usar',
        icon: Icons.check_rounded,
        expand: true,
        onPressed: _busy || c.saving ? null : _apply,
      );
    } else if (cost > pet.coins) {
      action = AppButton(
        label: 'Faltan ${cost - pet.coins} · Jugar',
        icon: Icons.sports_esports_rounded,
        expand: true,
        onPressed: () => _apply(),
      );
    } else {
      action = AppButton(
        label: 'Comprar y usar · $cost',
        icon: Icons.shopping_bag_rounded,
        expand: true,
        onPressed: _busy || c.saving ? null : _apply,
      );
    }

    final content = Column(
      children: [
        if (!widget.standalone)
          const TabHeader(kicker: 'Vestuario', title: 'Armario'),
        Expanded(
          flex: l.compact ? 4 : 5,
          child: SceneView(
            game: _game!,
            semanticsLabel:
                'Vista previa de ${pet.name} con el aspecto elegido',
            onTap: (_) => _game!.pet.react(PetAnim.happy),
            overlay: dirty
                ? Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s),
                      child: Chip(
                        avatar: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text('Probando'),
                        backgroundColor: AppColors.cream,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        Expanded(
          flex: l.compact ? 6 : 5,
          child: Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    for (final s in Slot.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _CategoryTab(
                            slot: s,
                            selected: s == _slot,
                            onTap: () => setState(() => _slot = s),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: l.tablet ? 4 : 2,
                    mainAxisSpacing: AppSpace.s,
                    crossAxisSpacing: AppSpace.s,
                    childAspectRatio: l.compact ? 1.5 : 1.15,
                    children: [
                      for (final it in c.balance.itemsFor(_slot))
                        _ItemTile(
                          item: it,
                          label: c.looks.label(it.id),
                          look: c.looks.resolve(
                            _preview.withSlot(_slot, it.id),
                          ),
                          selected: it.id == selectedId,
                          owned: pet.owned.contains(it.id),
                          equipped: pet.appearance.of(_slot) == it.id,
                          onTap: () =>
                              _setPreview(_preview.withSlot(_slot, it.id)),
                        ),
                    ],
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
                          onPressed: () => _setPreview(pet.appearance),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s),
                    ],
                    Expanded(flex: 3, child: action),
                  ],
                ),
                if (!owned && dirty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Probar es gratis. Solo pagas al confirmar.',
                      style: AppText.small,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.standalone) return SafeArea(bottom: false, child: content);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Armario'),
          actions: [
            if (c.demo) const DemoBadge(),
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 6),
              child: CoinBalance(coins: pet.coins),
            ),
          ],
        ),
        body: SafeArea(top: false, child: content),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  final Slot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: slot.label,
      excludeSemantics: true,
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
                  slot.icon,
                  size: 20,
                  color: selected ? AppColors.cream : AppColors.plum,
                ),
                Text(
                  slot.label,
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

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.label,
    required this.look,
    required this.selected,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });
  final StyleItem item;
  final String label;
  final PetLook look;
  final bool selected;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = equipped
        ? 'Equipado'
        : (owned ? 'En propiedad' : '${item.cost} monedas');
    return Semantics(
      button: true,
      selected: selected,
      label: '$label. $state',
      excludeSemantics: true,
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
                Expanded(child: PetThumb(look: look)),
                Text(
                  label,
                  style: AppText.subtitle.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (equipped)
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
                    else
                      const CoinIcon(size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        state,
                        style: AppText.small,
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

/// Miniatura estática del caniche con un aspecto concreto.
class PetThumb extends StatelessWidget {
  const PetThumb({super.key, required this.look, this.pose = PetPose.front});
  final PetLook look;
  final PetPose pose;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ThumbPainter(PetPainterScope.of(context), look, pose),
    size: Size.infinite,
  );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.painter, this.look, this.pose) : super(repaint: painter);
  final PetPainter painter;
  final PetLook look;
  final PetPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.height * 0.92)
        .clamp(0.0, size.width * (pose == PetPose.front ? 1.4 : 0.9))
        .toDouble();
    canvas.save();
    canvas.translate(
      size.width / 2 - (pose == PetPose.side ? s * 0.05 : 0),
      size.height * 0.97,
    );
    painter.paint(
      canvas,
      look,
      pose: pose,
      anim: PetAnim.idle,
      t: 1,
      size: s,
      reducedMotion: true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.look != look || old.pose != pose;
}
