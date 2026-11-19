import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/activities.dart';
import '../../domain/appearance.dart';
import '../../domain/care_options.dart';
import '../../domain/food.dart';
import '../../domain/balance.dart';
import '../ask_adult_view.dart';
import '../../domain/rules.dart';
import '../../game/care/care_games.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/activity_frame.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/scene_view.dart';
import 'results_screens.dart';
import 'wardrobe_screen.dart';

/// Sesión común: abre una sesión al entrar, la cancela al salir y envía un
/// único Finish al completar. Los pasos no se guardan hasta confirmar.
abstract class CareActivityState<W extends StatefulWidget, G extends StageGame>
    extends State<W>
    with FrameSafeRefresh<W> {
  late final String session;
  G? game;
  bool finishing = false;
  final hintKey = GlobalKey();

  CareKind get kind;
  CareOption? get option => null;
  bool confirming = false;
  String? get groomingHair => null;
  StepActivity get activity;
  G createGame(AppController c);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (game == null) {
      final c = AppScope.read(context);
      session = c.beginActivity(kind.name);
      if (session.isEmpty) {
        final reason =
            c.careBlocked(kind) ?? 'Espera a que termine el guardado.';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showCareBlocked(context, kind, reason);
          Navigator.pop(context);
        });
      }
      game = createGame(c)..onChanged = _changed;
      // Malito se le ve en todas las escenas, no solo en Casa.
      final pet = game!.pet;
      pet.hygiene = c.pet.needPoints(Need.hygiene);
      pet.fx = pet.fx
          .withSick(c.pet.isSick)
          .withHygiene(c.pet.needPoints(Need.hygiene));
    }
  }

  void _changed() {
    if (!mounted) return;
    refreshAfterFrame(() {
      if (autoFinish && isDone) finish();
    });
  }

  bool get autoFinish => true;

  /// Cuándo se da por terminada (por defecto, al completar los pasos).
  bool get isDone => activity.completed;

  Future<void> finish() async {
    if (finishing) return;
    finishing = true;
    final c = AppScope.read(context);
    final receipt = await commitOrRecover<Receipt>(
      context,
      () => c.finishCare(
        session,
        kind,
        option: option,
        groomingHair: groomingHair,
      ),
    );
    if (!mounted) return;
    if (receipt != null) {
      final fx = AppScope.feedbackOf(context);
      fx.play(Sfx.celebrate);
      if (receipt.after.coins < receipt.before.coins) {
        fx.play(Sfx.coins, haptic: false);
      }
      replaceScreen(context, CareResultScreen(kind: kind, receipt: receipt));
    } else {
      finishing = false;
      final reason = c.careBlocked(kind, option: option);
      if (reason != null) {
        showCareBlocked(context, kind, reason);
        Navigator.pop(context);
      } else {
        setState(() {});
      }
    }
  }

  Future<bool> confirmOption(
    CareOption selection, {
    required String title,
    required String note,
  }) async {
    if (confirming || finishing) return false;
    final c = AppScope.read(context);
    final reason = c.careBlocked(kind, option: selection);
    if (reason != null) {
      showCareBlocked(context, kind, reason);
      return false;
    }
    if (selection.cost == 0) return true;
    setState(() => confirming = true);
    final accepted = await showPurchaseDialog(
      context,
      items: [selection.label],
      price: selection.cost,
      balance: c.pet.coins,
      title: title,
      confirmLabel: 'Aceptar',
      note: note,
    );
    if (!mounted) return false;
    setState(() => confirming = false);
    return accepted;
  }

  void onExit() => AppScope.read(context).cancelActivity(session);

  bool hasPending() => activity.done > 0 && !finishing;

  String get hintId => 'care.${kind.name}';

  Widget? hint(String text, IconData icon) {
    final c = AppScope.of(context);
    if (c.prefs.seenHints.contains(hintId) || activity.done > 0) return null;
    return HintBubble(
      text: text,
      icon: icon,
      onClose: () => saveOrRecover(context, () => c.markHintSeen(hintId)),
    );
  }

  Widget frame({
    required String title,
    required Widget controls,
    required Widget scene,
    Widget? hintWidget,
  }) => ActivityFrame(
    title: title,
    activityName: Texts.careTitles[kind]!.toLowerCase(),
    game: game!,
    scene: scene,
    controls: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StepMarks(done: activity.done, total: activity.total),
        const SizedBox(height: AppSpace.s),
        controls,
      ],
    ),
    hasPendingProgress: hasPending,
    onExit: onExit,
    hint: hintWidget,
  );
}

Widget _instruction(String text, {IconData icon = Icons.touch_app_rounded}) =>
    Row(
      children: [
        Icon(icon, color: AppColors.leaf),
        const SizedBox(width: AppSpace.s),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

// ======================================================================
// P05 · Cocina
// ======================================================================

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends CareActivityState<FeedScreen, FeedGame> {
  final _activity = FeedActivity();
  final _live = LivePoodleController();
  Food? _selected;
  @override
  Food get option => _selected ?? Food.basic;
  @override
  CareKind get kind => CareKind.feed;
  @override
  StepActivity get activity => _activity;
  @override
  FeedGame createGame(AppController c) => FeedGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
  )..onChewFrame = _syncFeedingPose;

  void _syncFeedingPose() {
    final feedingGame = game;
    if (_live.ready && feedingGame != null) {
      _live.feed(feedingGame.biteProgress, feedingGame.liveBowlFill);
    }
  }

  Future<void> _bite() async {
    final selection = _selected;
    if (selection == null || confirming || finishing || !_activity.canBite) {
      return;
    }
    if (_activity.done > 0) {
      game!.bite();
      return;
    }
    if (await confirmOption(
          selection,
          title: 'Confirmar la ración',
          note:
              'El cobro y los efectos se aplican al terminar los tres bocados.',
        ) &&
        mounted) {
      game!.bite();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final name = c.pet.name;
    final appearance = c.pet.appearance;
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final feedingGame = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final eating = _activity.done > 0;
    final text = _activity.chewing
        ? '$name está masticando…'
        : _activity.completed
        ? '¡Cuenco vacío!'
        : 'Toca el cuenco o el botón para darle un bocado.';
    return frame(
      title: 'Hora de comer',
      scene: SceneView(
        game: feedingGame,
        semanticsLabel: 'Cocina con el cuenco de comida',
        onTap: !eating
            ? null
            : (point) {
                if (live) {
                  if (_live.hitBowl(point)) feedingGame.bite();
                } else {
                  feedingGame.tapAt(point);
                }
              },
        overlay: showModel
            ? LivePoodleView(
                controller: _live,
                appearance: appearance,
                resting: false,
                reducedMotion: c.reducedMotion,
                hygiene: c.pet.needPoints(Need.hygiene),
                mood: c.pet.needPoints(Need.mood),
                energy: c.pet.needPoints(Need.energy),
                sick: c.pet.isSick,
                wardrobe: false,
                feeding: true,
                onStatusChanged: () {
                  setState(() {});
                  _syncFeedingPose();
                },
              )
            : null,
      ),
      hintWidget: hint(
        'Elige una comida y pulsa Dar un bocado para empezar.',
        Icons.restaurant_rounded,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!eating)
            _CareOptions<Food>(
              options: Food.values,
              selected: _selected,
              artwork: (choice) => 'assets/images/food/${choice.name}.webp',
              icon: Icons.restaurant_rounded,
              onSelected: confirming
                  ? null
                  : (choice) => setState(() => _selected = choice),
            )
          else
            _instruction(
              '${option.label}. $text',
              icon: Icons.restaurant_rounded,
            ),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: _activity.chewing ? 'Masticando…' : 'Dar un bocado',
            icon: Icons.restaurant_rounded,
            big: true,
            expand: true,
            onPressed:
                _selected != null &&
                    _activity.canBite &&
                    !finishing &&
                    !confirming
                ? _bite
                : null,
          ),
        ],
      ),
    );
  }
}

class _CareOptions<T extends CareOption> extends StatelessWidget {
  const _CareOptions({
    required this.options,
    required this.selected,
    required this.artwork,
    required this.icon,
    required this.onSelected,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) artwork;
  final IconData icon;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return SizedBox(
      height: (MediaQuery.sizeOf(context).height * .27).clamp(146.0, 230.0),
      child: ListView(
        children: [
          for (final choice in options)
            _CareOptionTile(
              choice: choice,
              artwork: artwork(choice),
              icon: icon,
              selected: selected == choice,
              locked: !c.canAccess(choice.tier),
              onTap: onSelected == null
                  ? null
                  : () {
                      if (!c.canAccess(choice.tier)) {
                        showAskAdult(context);
                        return;
                      }
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onSelected!(choice);
                    },
            ),
        ],
      ),
    );
  }
}

class _CareOptionTile extends StatelessWidget {
  const _CareOptionTile({
    required this.choice,
    required this.artwork,
    required this.icon,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final CareOption choice;
  final String artwork;
  final IconData icon;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.plum : AppColors.plum.withAlpha(38),
        width: selected ? 2 : 1,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          shape: shape,
          color: selected ? AppColors.leafSoft : Colors.white,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Image.asset(
                    artwork,
                    width: 58,
                    height: 55,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) =>
                        Icon(icon, size: 32, color: AppColors.leaf),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choice.cost == 0
                              ? '${choice.label} · Gratis'
                              : choice.label,
                          style: AppText.subtitle,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 3,
                          children: [
                            for (final effect in choice.delta.entries)
                              Semantics(
                                label:
                                    '${Texts.needLabels[effect.key]} '
                                    '${effect.value >= 0 ? '+' : ''}${effect.value}',
                                excludeSemantics: true,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      effect.key.icon,
                                      size: 16,
                                      color: effect.key.color,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${effect.value >= 0 ? '+' : ''}${effect.value}',
                                      style: AppText.number.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (choice.cost > 0)
                    Semantics(
                      label: '${choice.cost} monedas',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          const CoinIcon(size: 16),
                          const SizedBox(width: 4),
                          Text('${choice.cost}', style: AppText.number),
                        ],
                      ),
                    ),
                  if (locked)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 15,
                        semanticLabel: 'Versión completa',
                      ),
                    ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.leaf,
                        size: 19,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrinkScreen extends StatefulWidget {
  const DrinkScreen({super.key});
  @override
  State<DrinkScreen> createState() => _DrinkScreenState();
}

class _DrinkScreenState extends CareActivityState<DrinkScreen, FeedGame> {
  final _activity = FeedActivity();
  final _live = LivePoodleController();
  Drink? _selected;
  @override
  Drink get option => _selected ?? Drink.water;

  Color get _drinkColor => switch (option) {
    Drink.water => const Color(0xFF88BDD8),
    Drink.bottled => const Color(0xFF8DD3EF),
    Drink.vitamins => const Color(0xFF92D0B7),
    Drink.juice => const Color(0xFFF3AA65),
  };

  @override
  CareKind get kind => CareKind.drink;
  @override
  StepActivity get activity => _activity;

  void _syncWater() {
    if (!_live.ready || game == null) return;
    _live.feed(game!.biteProgress, game!.liveBowlFill);
  }

  @override
  FeedGame createGame(AppController c) => FeedGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
    drinking: true,
  )..onChewFrame = _syncWater;

  Future<void> _fill() async {
    final selection = _selected;
    if (selection == null || game!.hasWater) return;
    if (await confirmOption(
          selection,
          title: 'Confirmar la bebida',
          note:
              'El cobro y los efectos se aplican al terminar los tres sorbos.',
        ) &&
        mounted) {
      game!
        ..waterColor = _drinkColor
        ..fillWater();
    }
  }

  @override
  bool hasPending() => game!.hasWater && !finishing;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(pet.appearance);
    final live = showModel && _live.ready;
    final g = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final label = !g.hasWater
        ? 'Llenar el cuenco'
        : g.pouring
        ? 'Llenando…'
        : _activity.chewing
        ? 'Bebiendo…'
        : 'Dar un sorbo';
    return frame(
      title: 'Hora de beber',
      scene: SceneView(
        game: g,
        semanticsLabel: 'Cuenco de agua de ${pet.name}',
        onTap: g.hasWater && !finishing
            ? (p) {
                if (live) {
                  if (_live.hitBowl(p)) g.bite();
                } else {
                  g.tapAt(p);
                }
              }
            : null,
        overlay: showModel
            ? LivePoodleView(
                controller: _live,
                appearance: pet.appearance,
                resting: false,
                reducedMotion: c.reducedMotion,
                wardrobe: false,
                feeding: true,
                drinking: true,
                drinkColor: _drinkColor,
                hygiene: pet.needPoints(Need.hygiene),
                mood: pet.needPoints(Need.mood),
                energy: pet.needPoints(Need.energy),
                sick: pet.isSick,
                onStatusChanged: () {
                  setState(() {});
                  _syncWater();
                },
              )
            : null,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!g.hasWater)
            _CareOptions<Drink>(
              options: Drink.values,
              selected: _selected,
              artwork: (choice) =>
                  'assets/images/food/drink_${choice.name}.webp',
              icon: Need.hydration.icon,
              onSelected: confirming
                  ? null
                  : (choice) => setState(() => _selected = choice),
            )
          else
            _instruction(
              '${option.label}. Toca el cuenco para darle los tres sorbos.',
              icon: Need.hydration.icon,
            ),
          const SizedBox(height: AppSpace.s),
          AppButton(
            label: label,
            icon: Need.hydration.icon,
            big: true,
            expand: true,
            onPressed:
                _selected == null ||
                    confirming ||
                    g.pouring ||
                    !_activity.canBite ||
                    finishing
                ? null
                : g.hasWater
                ? g.bite
                : _fill,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// P06 · Baño
// ======================================================================

class BathScreen extends StatefulWidget {
  const BathScreen({super.key});
  @override
  State<BathScreen> createState() => _BathScreenState();
}

class _BathScreenState extends CareActivityState<BathScreen, BathGame> {
  final _activity = BathActivity();
  final _live = LivePoodleController();
  List<double>? _lastBathFrame;
  BathPlan? _selected;
  bool _started = false;
  @override
  BathPlan get option => _selected ?? BathPlan.standard;

  Future<void> _startBath() async {
    final selection = _selected;
    if (selection == null || _started) return;
    if (await confirmOption(
          selection,
          title: 'Confirmar el baño',
          note: 'El cobro y los efectos se aplican al completar el baño.',
        ) &&
        mounted) {
      setState(() {
        _started = true;
        _activity.select(selection);
      });
      if (selection == BathPlan.massage) game!.setSpa();
      _syncBath();
    }
  }

  @override
  bool hasPending() => _started && !finishing;

  @override
  CareKind get kind => CareKind.bath;
  @override
  StepActivity get activity => _activity;
  @override
  BathGame createGame(AppController c) => BathGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
  )..onBathFrame = _syncBath;

  void _syncBath() {
    if (!_live.ready) {
      _lastBathFrame = null;
      return;
    }
    final frame = <double>[
      _activity.phase.index.toDouble(),
      (_activity.toolProgress * 32).round() / 32,
      for (final zone in BathZone.values)
        (_activity.visibleFoam(zone) * 32).round() / 32,
      for (final zone in BathZone.values)
        (_activity.wetness(zone) * 32).round() / 32,
      (_activity.curlProgress * 32).round() / 32,
      option == BathPlan.massage && _started ? 1 : 0,
      (_activity.extraProgress * 32).round() / 32,
    ];
    if (listEquals(frame, _lastBathFrame)) return;
    _lastBathFrame = frame;
    _live.bath(frame);
  }

  static const _zoneNames = {
    BathZone.head: 'Cabeza',
    BathZone.back: 'Lomo',
    BathZone.paws: 'Patas',
    BathZone.chest: 'Pecho',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final equipped = c.pet.appearance;
    final appearance = c.balance.initialAppearance
        .withSlot(Slot.coat, equipped.coat)
        .withSlot(Slot.hair, equipped.hair);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final bathGame = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final phase = _activity.phase;
    final text = switch (phase) {
      BathPhase.wet => 'Pasa la ducha por el pelaje o mantén pulsado el botón.',
      BathPhase.soap => 'Frota cabeza, lomo, pecho y patas con la esponja.',
      BathPhase.rinse => 'Pasa la ducha por la espuma para aclararla.',
      BathPhase.dry => 'Pasa el secador por el pelo mojado para secarlo.',
      BathPhase.salts =>
        'Mantén el bote sobre el agua o mantén pulsado el botón.',
      BathPhase.massage => 'Masajea despacio el lomo, el pecho y la cabeza.',
      BathPhase.nails =>
        'Mantén el cortauñas sobre cada una de las cuatro patas.',
      BathPhase.curl =>
        'Pasa el rizador por la cabeza y el lomo para definir los rizos.',
      BathPhase.done => '¡Limpio y seco!',
    };
    final (toolLabel, toolIcon) = switch (phase) {
      BathPhase.dry => ('Mantén: secador', Icons.air_rounded),
      BathPhase.salts => ('Añadir sales de baño relajantes', Icons.spa_rounded),
      BathPhase.massage => ('Masaje perruno', Icons.back_hand_rounded),
      BathPhase.nails => ('Cortador de uñas de perro', Icons.pets_rounded),
      BathPhase.curl => ('Rizado Extra', Icons.waves_rounded),
      _ => ('Mantén: ducha', Icons.shower_rounded),
    };
    final action = phase == BathPhase.soap
        ? Wrap(
            spacing: 8,
            children: [
              for (final z in BathZone.values)
                SizedBox(
                  width: 76,
                  child: _ZoneButton(
                    label: _zoneNames[z]!,
                    progress: _activity.foam(z),
                    done: _activity.zoneDone(z),
                    onPressed: () => game!.soap(z),
                  ),
                ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _activity.extraTargets > 0
                    ? _activity.extraProgress
                    : _activity.toolProgress,
              ),
              const SizedBox(height: 8),
              Listener(
                onPointerDown: (_) => game!.holdTool(),
                onPointerUp: (_) => game!.releaseTool(),
                onPointerCancel: (_) => game!.releaseTool(),
                child: AppButton(
                  label: toolLabel,
                  icon: toolIcon,
                  big: true,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          );
    return frame(
      title: _started ? option.label : 'Un baño de espuma',
      scene: SceneView(
        game: bathGame,
        semanticsLabel: 'Bañera lavanda con el caniche',
        onTap: _started ? bathGame.tapAt : null,
        onPress: _started ? bathGame.pressAt : null,
        onRelease: _started ? bathGame.releaseTool : null,
        onDragUpdate: _started ? (_, p, d) => bathGame.dragAt(p, d) : null,
        overlay: showModel
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    hygiene: c.pet.needPoints(Need.hygiene),
                    mood: c.pet.needPoints(Need.mood),
                    energy: c.pet.needPoints(Need.energy),
                    sick: c.pet.isSick,
                    wardrobe: false,
                    bathing: true,
                    spaBath: bathGame.spaRoom,
                    onBathTargets: bathGame.setLiveTargets,
                    onStatusChanged: () {
                      setState(() {});
                      _syncBath();
                    },
                  ),
                  if (live)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LiveCareOverlay(bathGame.paintLiveOverlay),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hintWidget: !_started || option == BathPlan.massage
          ? null
          : hint('Mantén la ducha sobre el perrito.', Icons.shower_rounded),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_started) ...[
            _instruction(text, icon: toolIcon),
            const SizedBox(height: AppSpace.m),
            action,
          ] else ...[
            _CareOptions<BathPlan>(
              options: BathPlan.values,
              selected: _selected,
              artwork: (choice) => switch (choice) {
                BathPlan.standard => 'assets/images/cards/bath.jpg',
                BathPlan.premium => 'assets/images/food/bath_premium.webp',
                BathPlan.massage => 'assets/images/food/bath_massage.webp',
              },
              icon: Icons.bathtub_rounded,
              onSelected: confirming
                  ? null
                  : (choice) => setState(() => _selected = choice),
            ),
            const SizedBox(height: AppSpace.m),
            AppButton(
              label: 'Empezar el baño',
              icon: Icons.bathtub_rounded,
              big: true,
              expand: true,
              onPressed: _selected == null || confirming ? null : _startBath,
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveCareOverlay extends CustomPainter {
  _LiveCareOverlay(this.paintOverlay, {super.repaint});

  final void Function(Canvas) paintOverlay;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    paintOverlay(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveCareOverlay oldDelegate) => true;
}

class _ZoneButton extends StatelessWidget {
  const _ZoneButton({
    required this.label,
    required this.progress,
    required this.done,
    required this.onPressed,
  });
  final String label;
  final double progress;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label${done ? ', enjabonado' : ''}',
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: done ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.bigButton),
          backgroundColor: done ? AppColors.leafSoft : null,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.bubble_chart_outlined,
              color: done ? AppColors.leaf : AppColors.plum,
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (!done && progress > 0)
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  value: progress,
                  color: AppColors.lavender,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// P07 · Paseo
// ======================================================================

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});
  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends CareActivityState<WalkScreen, WalkGame> {
  final _activity = WalkActivity();
  final _live = LivePoodleController();
  final _overlayFrame = ValueNotifier<int>(0);
  List<double>? _lastWalkFrame;
  @override
  CareKind get kind => CareKind.walk;
  @override
  StepActivity get activity => _activity;
  @override
  WalkGame createGame(AppController c) => WalkGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
  )..onWalkFrame = _syncWalk;

  void _syncWalk() {
    if (!_live.ready) {
      _lastWalkFrame = null;
      return;
    }
    final state = game!.liveWalkFrame;
    if (listEquals(state, _lastWalkFrame)) return;
    _lastWalkFrame = state;
    _live.walk(state);
    _overlayFrame.value++;
  }

  @override
  void dispose() {
    game?.onWalkFrame = null;
    _overlayFrame.dispose();
    super.dispose();
  }

  static const _go = ['Ir a las flores', 'Ir al banco', 'Ir a la fuente'];

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final name = c.pet.name;
    final appearance = c.pet.appearance;
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final g = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final stop = _activity.enabledStop;
    final atStop = _activity.phase == WalkPhase.atStop;
    final text = switch (_activity.phase) {
      _ when _activity.completed => '¡Paseo completo!',
      _ when stop != null => 'Toca la huella de la parada ${stop + 1}.',
      WalkPhase.moving => '$name va de camino…',
      WalkPhase.atStop => 'Toca la huella para que $name olfatee.',
      _ => '$name está olfateando…',
    };
    return frame(
      title: 'El sendero',
      scene: SceneView(
        game: g,
        semanticsLabel: 'Sendero con tres paradas',
        onTap: g.tapAt,
        overlay: showModel
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    hygiene: c.pet.needPoints(Need.hygiene),
                    mood: c.pet.needPoints(Need.mood),
                    energy: c.pet.needPoints(Need.energy),
                    sick: c.pet.isSick,
                    wardrobe: false,
                    walking: true,
                    onStatusChanged: () {
                      setState(() {});
                      _syncWalk();
                    },
                  ),
                  if (live)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LiveCareOverlay(
                          g.paintMarkers,
                          repaint: _overlayFrame,
                        ),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hintWidget: hint(
        'Toca la huella brillante para avanzar.',
        Icons.pets_rounded,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(text, icon: Icons.pets_rounded),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: atStop
                ? 'Olfatear'
                : stop != null
                ? _go[stop]
                : switch (_activity.phase) {
                    WalkPhase.moving => 'De camino…',
                    WalkPhase.sniffing => 'Olfateando…',
                    _ => '¡Paseo completo!',
                  },
            icon: atStop ? Icons.pets_rounded : Icons.directions_walk_rounded,
            big: true,
            expand: true,
            onPressed: atStop
                ? g.sniff
                : stop != null
                ? () => g.goTo(stop)
                : null,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// P08 · Peluquería
// ======================================================================

class GroomScreen extends StatefulWidget {
  const GroomScreen({super.key});
  @override
  State<GroomScreen> createState() => _GroomScreenState();
}

class _GroomScreenState extends CareActivityState<GroomScreen, GroomGame> {
  final _activity = GroomActivity();
  final _live = LivePoodleController();
  String? _targetHair;
  List<num>? _lastGroomFrame;
  @override
  CareKind get kind => CareKind.groom;
  @override
  String? get groomingHair => _live.ready ? _targetHair : null;
  @override
  StepActivity get activity => _activity;
  @override
  bool get autoFinish => false;
  @override
  GroomGame createGame(AppController c) => GroomGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
  )..onGroomFrame = _syncGroom;

  void _syncGroom() {
    if (!_live.ready || !mounted) {
      _lastGroomFrame = null;
      return;
    }
    final current = AppScope.read(context).pet.appearance.hair;
    final target = _targetHair ?? current;
    final state = [
      if (target == 'hair.pom') 1 else 0,
      if (target == 'hair.puppy') 1 else 0,
      for (final tool in GroomTool.values)
        for (final strand in Strand.values)
          (_activity.strandProgress(tool, strand) * 48).round() / 48,
      target == 'hair.teddy' ? 1 : 0,
      target == 'hair.show' ? 1 : 0,
    ];
    if (listEquals(state, _lastGroomFrame)) return;
    _lastGroomFrame = state;
    _live.groom(state);
  }

  static const _names = {
    Strand.forelock: 'Flequillo',
    Strand.ears: 'Orejas',
    Strand.back: 'Lomo',
  };

  Future<void> _tryCuts() async {
    game!.pauseEngine();
    await pushScreen(
      context,
      const WardrobeScreen(initialSlot: Slot.hair, standalone: true),
    );
    if (!mounted) return;
    game!
      ..setLook(AppScope.read(context).look)
      ..resumeEngine();
  }

  Future<void> _chooseCut() async {
    final c = AppScope.read(context);
    final selected = _targetHair ?? c.pet.appearance.hair;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elegir corte'),
        children: [
          for (final item in c.balance.itemsFor(Slot.hair))
            ListTile(
              title: Text(c.looks.labels[item.id]!),
              subtitle: Text(
                c.pet.owned.contains(item.id)
                    ? 'Se puede guardar'
                    : 'Vista previa · Disponible en el armario',
              ),
              trailing: item.id == selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, item.id),
            ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => _targetHair = choice);
    _syncGroom();
  }

  @override
  Widget build(BuildContext context) {
    final done = _activity.completed;
    final c = AppScope.of(context);
    final equipped = c.pet.appearance;
    final appearance = c.balance.initialAppearance
        .withSlot(Slot.coat, equipped.coat)
        .withSlot(Slot.hair, equipped.hair);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final g = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final target = _targetHair ?? equipped.hair;
    final preview = live && !c.pet.owned.contains(target);
    return frame(
      title: 'Entre rizos',
      scene: SceneView(
        game: g,
        semanticsLabel: 'Peluquería con espejo y tres mechones por cepillar',
        onTap: g.tapAt,
        onPress: g.pressAt,
        onRelease: g.releaseTool,
        onDragUpdate: (_, p, d) => g.dragAt(p, d),
        overlay: showModel
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    hygiene: c.pet.needPoints(Need.hygiene),
                    mood: c.pet.needPoints(Need.mood),
                    energy: c.pet.needPoints(Need.energy),
                    sick: c.pet.isSick,
                    wardrobe: false,
                    grooming: true,
                    onGroomTargets: g.setLiveTargets,
                    onStatusChanged: () {
                      setState(() {});
                      _syncGroom();
                    },
                  ),
                  if (live)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LiveCareOverlay(g.paintTools),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hintWidget: hint(
        'Frota o toca cada círculo para cepillar.',
        Icons.brush_rounded,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(
            done
                ? !live
                      ? 'Rizos listos. Termina el cepillado.'
                      : preview
                      ? 'Vista previa lista. Se conservará el corte que llevaba.'
                      : 'Rizos listos. Termina para guardar el corte.'
                : switch (_activity.tool) {
                    GroomTool.comb => 'Peine: frota los tres mechones.',
                    GroomTool.scissors => 'Tijeras: repasa los tres mechones.',
                    GroomTool.dryer => 'Secador: pasa por los tres mechones.',
                  },
            icon: switch (_activity.tool) {
              GroomTool.comb => Icons.brush_rounded,
              GroomTool.scissors => Icons.content_cut_rounded,
              GroomTool.dryer => Icons.air_rounded,
            },
          ),
          if (live) ...[
            const SizedBox(height: 4),
            Text(
              '${c.looks.labels[target]}${preview ? ' · Vista previa' : ''}',
              style: AppText.small,
            ),
          ],
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              for (final s in Strand.values) ...[
                Expanded(
                  child: _ZoneButton(
                    label: _names[s]!,
                    progress: _activity.brushed(s),
                    done: _activity.strandDone(s),
                    onPressed: () => game!.brush(s),
                  ),
                ),
                if (s != Strand.values.last) const SizedBox(width: AppSpace.s),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: live ? 'Elegir corte' : 'Probar cortes',
                  icon: Icons.content_cut_rounded,
                  secondary: true,
                  expand: true,
                  onPressed: live
                      ? (_activity.tool == GroomTool.comb ? _chooseCut : null)
                      : _tryCuts,
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: AppButton(
                  label: 'Terminar cepillado',
                  icon: Icons.check_rounded,
                  expand: true,
                  onPressed: done && !finishing ? finish : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Dormir
// ======================================================================

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});
  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends CareActivityState<SleepScreen, SleepGame> {
  final _activity = SleepActivity();
  final _live = LivePoodleController();
  List<double>? _lastSleepFrame;
  @override
  CareKind get kind => CareKind.sleep;
  @override
  StepActivity get activity => _activity;
  @override
  SleepGame createGame(AppController c) => SleepGame(
    painter: PetPainterScope.of(context),
    look: c.look,
    reducedMotion: c.reducedMotion,
    activity: _activity,
  )..onSleepFrame = _syncSleep;

  void _syncSleep() {
    if (!_live.ready) {
      _lastSleepFrame = null;
      return;
    }
    final state = [
      for (final value in game!.liveSleepFrame) (value * 48).round() / 48,
    ];
    if (listEquals(state, _lastSleepFrame)) return;
    _lastSleepFrame = state;
    _live.sleep(state);
  }

  @override
  void dispose() {
    game?.onSleepFrame = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final name = c.pet.name;
    final equipped = c.pet.appearance;
    final appearance = c.balance.initialAppearance
        .withSlot(Slot.coat, equipped.coat)
        .withSlot(Slot.hair, equipped.hair);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final g = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final (text, label, icon, action) = switch (_activity.phase) {
      SleepPhase.toBed => (
        'Toca su cama para que $name se acueste.',
        'Llevar a su cama',
        Icons.hotel_rounded,
        g.goToBed,
      ),
      SleepPhase.blanket => (
        g.atBed ? 'Arropa a $name con su manta.' : '$name va hacia su cama…',
        'Arropar',
        Icons.dry_cleaning_rounded,
        g.atBed ? g.tuckIn : null,
      ),
      SleepPhase.lights => (
        'Apaga la luz para que $name duerma.',
        'Apagar la luz',
        Icons.lightbulb_outline_rounded,
        g.canLightsOff ? g.lightsOff : null,
      ),
      _ => (
        '$name duerme plácidamente… Zzz.',
        'Durmiendo…',
        Icons.bedtime_rounded,
        null,
      ),
    };
    return frame(
      title: 'A dormir',
      scene: SceneView(
        game: g,
        semanticsLabel: 'Salón con la cama de ${AppScope.of(context).pet.name}',
        onTap: g.tapAt,
        overlay: showModel
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    hygiene: c.pet.needPoints(Need.hygiene),
                    mood: c.pet.needPoints(Need.mood),
                    energy: c.pet.needPoints(Need.energy),
                    sick: c.pet.isSick,
                    wardrobe: false,
                    sleeping: true,
                    onSleepBounds: g.setLiveBedBounds,
                    onStatusChanged: () {
                      setState(() {});
                      _syncSleep();
                    },
                  ),
                  if (live && _activity.phase == SleepPhase.lights)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Material(
                        shape: const CircleBorder(),
                        color: AppColors.cream,
                        child: IconButton(
                          tooltip: 'Interruptor de la sala',
                          icon: const Icon(Icons.lightbulb_rounded),
                          color: AppColors.plum,
                          onPressed: g.canLightsOff ? g.lightsOff : null,
                        ),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hintWidget: hint('Toca la cama para acostarlo.', Icons.hotel_rounded),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(text, icon: Icons.bedtime_rounded),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: label,
            icon: icon,
            big: true,
            expand: true,
            onPressed: action == null ? null : () => action(),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Veterinario
// ======================================================================

class VetScreen extends StatefulWidget {
  const VetScreen({super.key});
  @override
  State<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends CareActivityState<VetScreen, VetGame> {
  late final VetActivity _activity;
  final _live = LivePoodleController();
  final _overlayFrame = ValueNotifier<int>(0);
  List<num>? _lastVetFrame;
  @override
  CareKind get kind => CareKind.vet;
  @override
  StepActivity get activity => _activity;
  @override
  bool get isDone => _activity.completed && !(game?.busy ?? false);
  @override
  VetGame createGame(AppController c) {
    _activity = VetActivity(sick: c.pet.isSick);
    return VetGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      activity: _activity,
    )..onVetFrame = _syncVet;
  }

  void _syncVet() {
    if (!_live.ready) {
      _lastVetFrame = null;
      return;
    }
    final state = game!.liveVetFrame;
    if (listEquals(state, _lastVetFrame)) return;
    _lastVetFrame = state;
    _live.vet(state);
    _overlayFrame.value++;
  }

  @override
  void dispose() {
    game?.onVetFrame = null;
    _overlayFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final name = c.pet.name;
    final equipped = c.pet.appearance;
    final appearance = c.balance.initialAppearance
        .withSlot(Slot.coat, equipped.coat)
        .withSlot(Slot.hair, equipped.hair);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(appearance);
    final live = showModel && _live.ready;
    final g = game!
      ..useLiveModel = live
      ..pet.showSprite = !showModel;
    final busy = g.busy;
    final sick = _activity.sick;
    final (text, label, icon, action) = switch (_activity.phase) {
      VetPhase.heart => (
        sick
            ? '$name está malito. Mantén el fonendo sobre su pecho 3 segundos.'
            : 'Fonendo: mantén sobre el pecho de $name durante 3 segundos.',
        'Usar fonendoscopio',
        Icons.favorite_rounded,
        g.listen,
      ),
      VetPhase.paws => (
        'Lupa: mantén sobre sus patitas durante 3 segundos.',
        'Usar lupa',
        Icons.pets_rounded,
        g.checkPaws,
      ),
      VetPhase.pill => (
        'Arrastra la pastilla hasta su boca para curarle.',
        'Coger pastilla',
        Icons.medication_rounded,
        g.givePill,
      ),
      VetPhase.done => (
        sick ? '¡Ya está sanito!' : '¡Todo en orden!',
        'Hecho',
        Icons.check_rounded,
        null,
      ),
    };
    return frame(
      title: 'El veterinario',
      scene: SceneView(
        game: g,
        semanticsLabel: 'Consulta del veterinario con $name',
        onTap: live ? null : g.tapAt,
        onPress: g.pressAt,
        onRelease: g.releaseTool,
        onDragUpdate: (_, p, d) => g.dragAt(p, d),
        overlay: showModel
            ? Stack(
                fit: StackFit.expand,
                children: [
                  LivePoodleView(
                    controller: _live,
                    appearance: appearance,
                    resting: false,
                    reducedMotion: c.reducedMotion,
                    hygiene: c.pet.needPoints(Need.hygiene),
                    mood: c.pet.needPoints(Need.mood),
                    energy: c.pet.needPoints(Need.energy),
                    sick: c.pet.isSick,
                    wardrobe: false,
                    veterinary: true,
                    onVetTargets: g.setLiveTargets,
                    onStatusChanged: () {
                      setState(() {});
                      _syncVet();
                    },
                  ),
                  if (live)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LiveCareOverlay(
                          g.paintLiveOverlay,
                          repaint: _overlayFrame,
                        ),
                      ),
                    ),
                ],
              )
            : null,
      ),
      hintWidget: hint(
        'Arrastra el instrumento hasta el círculo.',
        Icons.touch_app_rounded,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(text, icon: Icons.medical_services_rounded),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: label,
            icon: icon,
            big: true,
            expand: true,
            onPressed: action == null || busy || finishing
                ? null
                : g.selectTool,
          ),
        ],
      ),
    );
  }
}
