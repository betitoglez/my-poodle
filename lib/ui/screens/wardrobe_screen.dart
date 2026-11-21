import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/appearance.dart';
import '../../domain/haircuts.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../game/pet/appearance_catalog.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/room_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/preview_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/luxury_badge.dart';
import '../widgets/scene_view.dart';
import '../widgets/turn_control.dart';
import 'main_shell.dart';

extension SlotUi on Slot {
  String get label => switch (this) {
    Slot.coat => 'Colores',
    Slot.hair => 'Peinados',
    Slot.outfit => 'Ropa',
    Slot.head => 'Cabeza',
    Slot.eyes => 'Ojos',
    Slot.collar => 'Cuello',
    Slot.neck => 'Cuello',
    Slot.paws => 'Patucos',
  };
  IconData get icon => switch (this) {
    Slot.coat => Icons.palette_rounded,
    Slot.hair => Icons.content_cut_rounded,
    Slot.outfit => Icons.checkroom_rounded,
    Slot.head => Icons.emoji_events_rounded,
    Slot.eyes => Icons.visibility_rounded,
    Slot.collar => Icons.loyalty_rounded,
    Slot.neck => Icons.diamond_rounded,
    Slot.paws => Icons.pets_rounded,
  };

  /// Las ranuras de accesorio cuelgan de la categoría «Accesorios».
  bool get isAccessory => switch (this) {
    Slot.head || Slot.eyes || Slot.collar || Slot.neck || Slot.paws => true,
    _ => false,
  };
}

/// Categorías principales del armario; «Accesorios» tiene submenús.
enum _Category {
  coat(Slot.coat),
  hair(Slot.hair),
  outfit(Slot.outfit),
  accessories(Slot.head);

  const _Category(this.firstSlot);
  final Slot firstSlot;

  /// Las de una sola ranura usan su nombre e icono; solo «Accesorios» es propia.
  String get label => this == accessories ? 'Accesorios' : firstSlot.label;
  IconData get icon =>
      this == accessories ? Icons.diamond_rounded : firstSlot.icon;

  static _Category of(Slot s) => s.isAccessory
      ? _Category.accessories
      : _Category.values.firstWhere((c) => c.firstSlot == s);
}

const _accessorySlots = [Slot.head, Slot.eyes, Slot.neck, Slot.paws];

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
  final _live = LivePoodleController();
  bool _resting3D = false;
  late Appearance _preview;
  late Slot _slot = widget.initialSlot == Slot.collar
      ? Slot.neck
      : widget.initialSlot;
  HairZone? _hairZone;
  PetView _view = PetView.front;
  bool _busy = false;
  ShellController? _shell;

  _Category get _category => _Category.of(_slot);

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
      _game!.pet.fx = PetFx(sick: c.pet.isSick)
          .withHygiene(c.pet.needPoints(Need.hygiene));
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

  void _turn(PetView v) {
    setState(() => _view = v);
    _game!.pet.setView(v);
  }

  bool get _sideHair =>
      _category == _Category.hair &&
      (_hairZone == HairZone.back || _hairZone == HairZone.tail);

  void _selectHairZone(HairZone? zone) {
    setState(() => _hairZone = zone);
    _turn(_sideHair ? PetView.right : PetView.front);
    _orientHairPreview();
  }

  void _orientHairPreview() {
    if (!_live.ready || _category != _Category.hair) return;
    _live.front();
    if (_sideHair) _live.rotate(-math.pi / (2 * .013));
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
    // Artículos de la versión completa: se prueban, pero no se compran.
    if (c.lockedIn(look).isNotEmpty) {
      await showAskAdult(context);
      return false;
    }
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
        for (final id in look.ids)
          if (!id.startsWith('hair.') &&
              !c.rules.ownsStyle(c.pet, id) &&
              c.itemCost(id) > 0)
            c.looks.label(id),
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
      final fx = AppScope.feedbackOf(context);
      if (r.cost > 0) {
        fx.play(Sfx.coins);
        ConfettiBurst.show(context, reducedMotion: c.reducedMotion);
      }
      if (r.receipt.before.appearance != r.receipt.after.appearance) {
        fx.play(Sfx.fabric, haptic: false);
      }
      _setPreview(r.receipt.after.appearance);
      _game!.pet.react(PetAnim.celebrate, seconds: 1.6);
      return true;
    }
    if (r is InsufficientCoins) {
      await showInsufficientDialog(context, missing: r.missing, price: r.cost);
    } else if (r is RequiresFull) {
      await showAskAdult(context);
    }
    return false;
  }

  /// Artículos agrupados por variedad; cada ficha muestra su precio vigente.
  List<_Section> _sections(AppController c, Slot slot) {
    if (slot == Slot.hair && _hairZone != null) {
      return [
        _Section(null, [
          for (final style in Haircuts.stylesFor(_hairZone!))
            StyleItem(
              id: Haircuts.id(_hairZone!, style),
              slot: Slot.hair,
              cost: Haircuts.cost(style),
              initial: Haircuts.cost(style) == 0,
              tier: Haircuts.tier(style),
            ),
        ]),
      ];
    }
    final out = <_Section>[];
    final byVariety = <String, _Section>{};
    final items = [
      ...c.balance.itemsFor(slot),
      if (slot == Slot.neck)
        ...c.balance.itemsFor(Slot.collar).where((item) => !item.initial),
    ];
    for (final it in items) {
      final v = c.looks.varietyOf(it.id);
      if (v == null) {
        if (out.isEmpty || out.last.variety != null) {
          out.add(_Section(null, []));
        }
        out.last.items.add(it);
      } else {
        final sec = byVariety.putIfAbsent(v, () {
          final created = _Section(v, []);
          out.add(created);
          return created;
        });
        sec.items.add(it);
      }
    }
    return out;
  }

  String _selected(Appearance appearance) =>
      _slot == Slot.hair && _hairZone != null
      ? appearance.cutId(_hairZone!)
      : _slot == Slot.hair && !appearance.uniformHair
      ? 'hair.custom'
      : _slot == Slot.neck &&
            appearance.neck == 'neck.none' &&
            appearance.collar != 'collar.none'
      ? appearance.collar
      : appearance.of(_slot);

  Appearance _selectItem(AppController c, StyleItem item) {
    var appearance = _preview;
    if (Haircuts.valid(item.id)) {
      return appearance.withCut(
        HairZone.values.byName(item.id.split('.')[1]),
        item.id.split('.').last,
      );
    }
    if (_slot == Slot.neck) {
      appearance = appearance
          .withSlot(Slot.neck, c.balance.baseFor(Slot.neck).id)
          .withSlot(Slot.collar, c.balance.baseFor(Slot.collar).id);
    }
    return appearance.withSlot(item.slot, item.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final l = Layout.of(context);
    final selectedId = _selected(_preview);
    final item =
        c.balance.item(selectedId) ??
        StyleItem(
          id: selectedId,
          slot: Slot.hair,
          cost: 0,
          initial:
              selectedId.endsWith('.natural') ||
              selectedId == 'cut.tail.standard',
        );
    final owned = c.rules.ownsStyle(pet, selectedId);
    final equipped = _selected(pet.appearance) == selectedId;
    final dirty = _preview != pet.appearance;
    final cost = c.lookCost(_preview);
    final locked = c.lockedIn(_preview).isNotEmpty;
    final zoom = ThumbZoom.of(_slot);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(_preview);
    final live = showModel && _live.ready;
    _game!.pet.showSprite = !showModel;

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
                      _slot == Slot.hair && _hairZone != null
                          ? _preview.withCut(_hairZone!, 'natural')
                          : _selectItem(c, c.balance.baseFor(_slot)),
                    ),
            )
          : const AppButton(
              label: 'Equipado',
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

    final sections = _sections(c, _slot);
    final columns = l.tablet ? 4 : 2;

    final content = Column(
      children: [
        if (!widget.standalone)
          const TabHeader(kicker: 'Vestuario', title: 'Armario'),
        Expanded(
          flex: l.compact ? 3 : 4,
          child: SceneView(
            game: _game!,
            semanticsLabel:
                'Vista previa de ${pet.name} con el aspecto elegido, ${_view.label.toLowerCase()}',
            onTap: (point) async {
              if (live) {
                if (await _live.petAt(point) == LivePetTap.greeted &&
                    context.mounted) {
                  _game!.playSound(Sfx.bark);
                  await saveOrRecover(context, c.rewardGreeting);
                }
              } else {
                _game!.pet.react(PetAnim.happy);
              }
            },
            onDragUpdate: live ? (_, _, delta) => _live.rotate(delta.dx) : null,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                if (showModel)
                  Positioned.fill(
                    child: LivePoodleView(
                      controller: _live,
                      appearance: _preview,
                      resting: _resting3D,
                      reducedMotion: c.reducedMotion,
                      wardrobe: true,
                      idle: true,
                      onPanting: _game!.setPanting,
                      hygiene: pet.needPoints(Need.hygiene),
                      mood: pet.needPoints(Need.mood),
                      energy: pet.needPoints(Need.energy),
                      sick: pet.isSick,
                      onStatusChanged: () {
                        if (mounted) {
                          setState(() {});
                          _orientHairPreview();
                        }
                      },
                    ),
                  ),
                if (dirty)
                  const Positioned(
                    right: AppSpace.s,
                    top: AppSpace.s,
                    child: PreviewBadge(),
                  ),
                Positioned(
                  right: AppSpace.s,
                  bottom: AppSpace.s,
                  child: live
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              tooltip: localizeNullable(
                                context,
                                'Volver de frente',
                              ),
                              onPressed: _live.front,
                              icon: const Icon(Icons.restart_alt_rounded),
                            ),
                            const SizedBox(width: 6),
                            FilledButton.tonal(
                              onPressed: () =>
                                  setState(() => _resting3D = !_resting3D),
                              child: LText(
                                _resting3D ? 'Levantarse' : 'Tumbarse',
                              ),
                            ),
                          ],
                        )
                      : TurnControl(
                          view: _view,
                          onTurn: _turn,
                          compact: l.compact,
                        ),
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
                    for (final cat in _Category.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _CategoryTab(
                            label: cat.label,
                            icon: cat.icon,
                            selected: cat == _category,
                            onTap: () => setState(() {
                              if (cat != _category) _slot = cat.firstSlot;
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_category == _Category.hair) ...[
                  const SizedBox(height: AppSpace.s),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final zone in <HairZone?>[
                          null,
                          ...HairZone.values,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpace.s),
                            child: ChoiceChip(
                              label: LText(zone?.label ?? 'Packs'),
                              selected: zone == _hairZone,
                              onSelected: (_) => _selectHairZone(zone),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_category == _Category.accessories) ...[
                  const SizedBox(height: AppSpace.s),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _accessorySlots)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpace.s),
                            child: ChoiceChip(
                              avatar: Icon(s.icon, size: 18),
                              label: LText(s.label),
                              selected: s == _slot,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _slot = s),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.s),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // Alto de ficha: la proporción habitual, pero nunca
                      // menos de lo que ocupan miniatura y textos (con letra
                      // grande y la línea «Te faltan N monedas»).
                      final scale = MediaQuery.textScalerOf(context);
                      final tileWidth =
                          (box.maxWidth - AppSpace.s * (columns - 1)) / columns;
                      final textHeight =
                          scale.scale(15) * 1.3 +
                          scale.scale(13) * 1.3 * 2 +
                          12;
                      final tileExtent = math.max(
                        tileWidth / (l.compact ? 1.35 : 1.1),
                        textHeight + 40,
                      );
                      return CustomScrollView(
                        slivers: [
                          for (final sec in sections) ...[
                            if (sec.variety != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    2,
                                    6,
                                    2,
                                    6,
                                  ),
                                  child: Row(
                                    children: [
                                      LText(
                                        c.looks.varietyLabel(sec.variety!),
                                        style: AppText.subtitle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: AppSpace.s,
                                    crossAxisSpacing: AppSpace.s,
                                    mainAxisExtent: tileExtent,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final it = sec.items[i];
                                final preview = _selectItem(c, it);
                                return _ItemTile(
                                  item: StyleItem(
                                    id: it.id,
                                    slot: it.slot,
                                    cost: c.itemCost(it.id),
                                    initial: it.initial,
                                    tier: it.tier,
                                  ),
                                  label: sec.variety != null
                                      ? (c.looks.colorLabel(it.id) ??
                                            c.looks.label(it.id))
                                      : c.looks.label(it.id),
                                  swatch: c.looks.swatch(it.id),
                                  zoom: zoom,
                                  pose: _sideHair
                                      ? PetPose.side
                                      : PetPose.front,
                                  useModelArtwork: showModel,
                                  look: c.looks.resolve(preview),
                                  selected: it.id == selectedId,
                                  owned: c.rules.ownsStyle(pet, it.id),
                                  locked: c.isLocked(it.id),
                                  coins: pet.coins,
                                  equipped: _selected(pet.appearance) == it.id,
                                  onTap: () => _setPreview(preview),
                                );
                              }, childCount: sec.items.length),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpace.s),
                            ),
                          ],
                        ],
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
                    child: LText(
                      locked
                          ? 'Probar es gratis. Para tenerlo, pide ayuda a un adulto.'
                          : 'Probar es gratis. Solo pagas al confirmar.',
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
          title: const LText('Armario'),
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

class _Section {
  _Section(this.variety, this.items);
  final String? variety;
  final List<StyleItem> items;
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
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
      onTap: onTap,
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

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.label,
    this.swatch,
    required this.look,
    required this.zoom,
    required this.useModelArtwork,
    this.pose = PetPose.front,
    required this.selected,
    required this.owned,
    required this.equipped,
    required this.onTap,
    this.locked = false,
    this.coins,
  });
  final StyleItem item;

  /// Saldo actual: si no alcanza el precio, la ficha dice cuánto falta.
  final int? coins;
  final String label;
  final Color? swatch;
  final ThumbZoom zoom;
  final bool useModelArtwork;
  final PetPose pose;
  final PetLook look;
  final bool selected;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  /// De la versión completa y no poseído: se prueba, no se compra.
  final bool locked;

  Widget _thumbnail() {
    final fallback = PetThumb(look: look, zoom: zoom, pose: pose);
    if (!useModelArtwork) return fallback;
    return Image.asset(
      'assets/images/wardrobe_thumbs/${item.id}.webp',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = equipped
        ? 'Equipado'
        : (owned
              ? 'En propiedad'
              : (locked ? 'Versión completa' : '${item.cost} monedas'));
    final buyable = !equipped && !owned && !locked;
    final balance = coins;
    final missing = buyable && balance != null && item.cost > balance
        ? item.cost - balance
        : null;
    final luxury = item.luxury;
    return LSemantics(
      button: true,
      selected: selected,
      label: tileSemantics(
        context,
        label,
        state,
        luxury: luxury,
        missing: missing,
      ),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.plumSoft
            : luxury
            ? LuxuryColors.goldSoft
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          side: BorderSide(
            color: selected
                ? AppColors.plum
                : luxury
                ? LuxuryColors.gold
                : const Color(0x22000000),
            width: selected || luxury ? 3 : 1,
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
                      _thumbnail(),
                      if (luxury)
                        const Positioned(top: 0, left: 0, child: LuxuryBadge()),
                      if (locked)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: LockBadge(compact: true),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (swatch != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x44000000)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: LText(
                        label,
                        style: AppText.subtitle.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                if (missing != null) MissingCoinsLine(missing: missing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zona del caniche que enseña una miniatura: el cuerpo entero o, para
/// accesorios, la parte donde se ven (cabeza, cuello, patas).
enum ThumbZoom {
  body(null),
  head(Rect.fromLTWH(-0.34, -1.05, 0.62, 0.5)),
  neck(Rect.fromLTWH(-0.37, -0.82, 0.74, 0.55)),
  paws(Rect.fromLTWH(-0.38, -0.34, 0.76, 0.38));

  const ThumbZoom(this.rect);

  /// Región en unidades del caniche (altura 1, origen en los pies).
  final Rect? rect;

  static ThumbZoom of(Slot s) => switch (s) {
    Slot.head || Slot.eyes => ThumbZoom.head,
    Slot.collar || Slot.neck => ThumbZoom.neck,
    Slot.paws => ThumbZoom.paws,
    _ => ThumbZoom.body,
  };
}

/// Miniatura estática del caniche con un aspecto concreto.
class PetThumb extends StatelessWidget {
  const PetThumb({
    super.key,
    required this.look,
    this.pose = PetPose.front,
    this.zoom = ThumbZoom.body,
  });
  final PetLook look;
  final PetPose pose;
  final ThumbZoom zoom;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ThumbPainter(PetPainterScope.of(context), look, pose, zoom),
    size: Size.infinite,
  );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.painter, this.look, this.pose, this.zoom)
    : super(repaint: painter);
  final PetPainter painter;
  final PetLook look;
  final PetPose pose;
  final ThumbZoom zoom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final r = zoom.rect;
    if (r == null) {
      final s = (size.height * 0.92)
          .clamp(0.0, size.width * (pose == PetPose.side ? 0.9 : 1.4))
          .toDouble();
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
    } else {
      // Encuadre cerrado: la región r llena la miniatura.
      final s = math.min(size.width / r.width, size.height / r.height);
      canvas.translate(
        size.width / 2 - r.center.dx * s,
        size.height / 2 - r.center.dy * s,
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
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.look != look || old.pose != pose || old.zoom != zoom;
}
