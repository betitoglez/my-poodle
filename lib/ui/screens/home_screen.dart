import 'dart:async';

import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/background_music.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../domain/tutorial.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/guide_card.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/pet_hearts.dart';
import '../widgets/scene_view.dart';
import '../widgets/status_bubbles.dart';
import '../widgets/turn_control.dart';
import 'care_activity_screens.dart';
import 'decor_screen.dart';
import 'main_shell.dart';
import 'settings_screens.dart';
import 'photo_screen.dart';

/// P03 · Casa: salón, caniche, nombre, saldo, iconos de estado tipo
/// tamagotchi, cuatro indicadores y salud, sugerencia de lo más urgente,
/// caricia (con corazones), reposos variados, guía de la primera partida,
/// descanso y giro para verlo desde los cuatro ángulos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeGame? _game;
  final _live = LivePoodleController();
  final _texts = Texts();
  String? _suggestion;
  Object? _suggestedFor;
  PetView _view = PetView.front;
  final _hearts = GlobalKey<PetHeartsState>();

  /// Reposos variados del sprite 2D: ciclo determinista de esperas y gestos.
  static const idleDelays = [11, 9, 13, 10, 14, 12];
  static const idleAnims = [PetAnim.lookUp, PetAnim.sniff, PetAnim.happy];
  Timer? _idleTimer;
  int _idleStep = 0;
  bool _idleAllowed = false;

  void _scheduleIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      Duration(seconds: idleDelays[_idleStep % idleDelays.length]),
      _idleReact,
    );
  }

  /// Solo con el sprite 2D a la vista, despierto, sin movimiento reducido y
  /// sin otra reacción en curso (la caricia manda).
  void _idleReact() {
    if (!mounted) return;
    final game = _game!;
    final onTop = ModalRoute.of(context)?.isCurrent ?? true;
    final shell = ShellScope.maybeOf(context);
    final visible = onTop && (shell == null || shell.tab == ShellTab.home);
    if (_idleAllowed && visible && !game.resting && !game.pet.reacting) {
      game.pet.react(idleAnims[_idleStep % idleAnims.length], seconds: 1.4);
    }
    _idleStep++;
    _scheduleIdle();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _idleTimer = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.of(context);
    _game ??= HomeGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      onPetTapped: () => AppScope.feedbackOf(context).play(Sfx.tap),
    );
    // Un único caniche que refleja el aspecto y la salud confirmados.
    _game!.setLook(c.look);
    // El salón muestra la decoración confirmada.
    _game!.setDecor(c.pet.decor);
    _game!.reducedMotion = c.reducedMotion;
    _game!.pet.fx = PetFx(sick: c.pet.isSick)
        .withHygiene(c.pet.needPoints(Need.hygiene));
    if (_idleTimer == null) _scheduleIdle();
  }

  void _turn(PetView v) {
    setState(() => _view = v);
    _game!.pet.setView(v);
  }

  /// Lleva a la actividad que resuelve cada estado: el veterinario y la cama
  /// tienen pantalla propia; el resto, la de su medida.
  Future<void> _openCare(CareKind kind, Widget screen) async {
    final c = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final blocked = c.careBlocked(kind);
    if (blocked != null) {
      showCareBlocked(context, kind, blocked);
      return;
    }
    if (c.pet.restingSinceUtc != null && !await _setResting(false)) return;
    if (mounted) pushScreen(context, screen, music: MusicTrack.activities);
  }

  /// Cada paso de la guía lleva a la misma ruta que su acción en Casa.
  void _guideAction(TutorialStep step) {
    switch (step) {
      case TutorialStep.feed:
        _openCare(CareKind.feed, const FeedScreen());
      case TutorialStep.play:
        ShellScope.maybeOf(context)?.go(ShellTab.games);
      case TutorialStep.dress:
        ShellScope.maybeOf(context)?.go(ShellTab.wardrobe);
    }
  }

  void _attend(PetCondition cond) {
    switch (cond) {
      case PetCondition.sick:
        _openCare(CareKind.vet, const VetScreen());
      case PetCondition.tired:
        _openCare(CareKind.sleep, const SleepScreen());
      case PetCondition.hungry ||
          PetCondition.dirty ||
          PetCondition.sad ||
          PetCondition.thirsty:
        _actNeed(cond.need!);
    }
  }

  void _actNeed(Need need) {
    switch (need) {
      case Need.satiety:
        _openCare(CareKind.feed, const FeedScreen());
      case Need.hygiene:
        _openCare(CareKind.bath, const BathScreen());
      case Need.mood:
        ShellScope.maybeOf(context)?.go(ShellTab.games);
      case Need.energy:
        _openCare(CareKind.sleep, const SleepScreen());
      case Need.hydration:
        _openCare(CareKind.drink, const DrinkScreen());
    }
  }

  /// Al acostarse mira de frente: el giro vuelve a ese ángulo para no
  /// quedar desfasado.
  Future<bool> _setResting(bool value) async {
    final c = AppScope.read(context);
    final saved = await saveOrRecover(context, () => c.setHomeResting(value));
    if (saved && value && mounted) setState(() => _view = PetView.front);
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final l = Layout.of(context);
    final lowest = c.rules.lowestNeed(pet);
    final conditions = c.rules.conditions(pet);
    final urgent = c.rules.mostUrgent(pet);
    final key = urgent ?? lowest;
    if (_suggestedFor != key) {
      _suggestedFor = key;
      _suggestion = urgent != null
          ? _texts.pick(Texts.conditionSuggestions[urgent]!, name: pet.name)
          : _texts.pick(Texts.suggestions[lowest]!, name: pet.name);
    }
    final resting = pet.restingSinceUtc != null;
    if (_game!.resting != resting) _game!.setResting(resting);
    final showModel =
        LivePoodleView.enabled &&
        !_live.failed &&
        LivePoodleView.supports(pet.appearance);
    final live =
        showModel && _live.ready && LivePoodleView.supports(pet.appearance);
    _game!.pet.showSprite = !showModel;
    _game!.useLiveBed = showModel;
    _idleAllowed = !showModel && !resting && !c.reducedMotion;
    final showHint = !pet.prefs.seenHints.contains('home.pet');
    // La guía releva a la pista de la caricia cuando esta ya se ha visto.
    final guide = pet.prefs.seenHints.contains(Tutorial.afterHint)
        ? Tutorial.next(pet, c.balance)
        : null;
    final actionNeed = urgent?.need ?? lowest;
    final actionLabel =
        Texts.conditionActions[urgent] ??
        (actionNeed == Need.energy
            ? (resting ? 'Despertar' : 'Descansar')
            : Texts.needActions[actionNeed]!);
    final actionIcon = urgent != null
        ? StatusBubbles.fallbackIcon(urgent)
        : (lowest == Need.energy ? Icons.bedtime_rounded : lowest.icon);
    final accent = urgent == PetCondition.sick ? AppColors.coral : lowest.color;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) => Column(
          children: [
            TabHeader(
              kicker: 'En casa',
              title: pet.name,
              literalTitle: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: localizeNullable(context, 'Decorar el salón'),
                    onPressed: () => pushScreen(context, const DecorScreen()),
                    icon: const Icon(
                      Icons.chair_rounded,
                      color: AppColors.plum,
                    ),
                  ),
                  IconButton(
                    tooltip: localizeNullable(context, 'Modo foto'),
                    onPressed: () => pushScreen(context, const PhotoScreen()),
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.plum,
                    ),
                  ),
                  IconButton(
                    tooltip: localizeNullable(context, 'Ajustes'),
                    onPressed: () =>
                        pushScreen(context, const SettingsScreen()),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.plum,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SceneView(
                game: _game!,
                semanticsLabel:
                    '${pet.name} en el salón, ${_view.label.toLowerCase()}. Toca para hacerle una caricia.',
                onTap: (p) async {
                  final tap = live
                      ? await _live.petAt(p)
                      : (_game!.pet.hits(p)
                            ? LivePetTap.touched
                            : LivePetTap.missed);
                  if (!context.mounted || tap == LivePetTap.missed) return;
                  if (resting && !await _setResting(false)) return;
                  if (!context.mounted) return;
                  setState(_game!.reactToPetTap);
                  _hearts.currentState?.burst(p);
                  if (tap == LivePetTap.greeted) {
                    _game!.playSound(Sfx.bark);
                    await saveOrRecover(context, c.rewardGreeting);
                  } else if (!live && !resting) {
                    _game!.playSound(Sfx.bark, minGap: 2);
                  }
                  if (context.mounted) {
                    await saveOrRecover(
                      context,
                      () => c.markHintSeen('home.pet'),
                    );
                  }
                },
                onDragUpdate: live
                    ? (_, _, delta) => _live.rotate(delta.dx)
                    : null,
                overlay: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (showModel)
                      Positioned.fill(
                        child: LivePoodleView(
                          controller: _live,
                          appearance: pet.appearance,
                          resting: resting,
                          passiveBed: true,
                          idle: true,
                          onPanting: _game!.setPanting,
                          roaming: true,
                          hygiene: pet.needPoints(Need.hygiene),
                          mood: pet.needPoints(Need.mood),
                          energy: pet.needPoints(Need.energy),
                          sick: pet.isSick,
                          reducedMotion: c.reducedMotion,
                          wardrobe: false,
                          onStatusChanged: () => setState(() {}),
                        ),
                      ),
                    // Por encima del visor 3D (vista nativa sobre Flame).
                    Positioned.fill(
                      child: PetHearts(
                        key: _hearts,
                        reducedMotion: c.reducedMotion,
                      ),
                    ),
                    Positioned(
                      left: AppSpace.s,
                      top: AppSpace.s,
                      bottom: AppSpace.s,
                      child: LayoutBuilder(
                        builder: (context, scene) {
                          final vertical = scene.maxHeight >= 224;
                          return Align(
                            alignment: Alignment.topLeft,
                            child: StatusBubbles(
                              active: conditions,
                              reducedMotion: c.reducedMotion,
                              onTap: _attend,
                              vertical: vertical,
                              itemExtent: vertical
                                  ? ((scene.maxHeight - 8) /
                                            StatusBubbles.order.length)
                                        .clamp(36.0, AppSizes.touch - 4)
                                  : AppSizes.touch - 4,
                            ),
                          );
                        },
                      ),
                    ),
                    if (showHint)
                      Positioned(
                        left: AppSpace.m,
                        right: AppSpace.m,
                        top: 64,
                        child: HintBubble(
                          icon: Icons.touch_app_rounded,
                          text: live
                              ? 'Toca a ${pet.name} para que se ponga a dos patas. Arrastra para girar.'
                              : 'Toca a ${pet.name} para hacerle una caricia.',
                          onClose: () => saveOrRecover(
                            context,
                            () => c.markHintSeen('home.pet'),
                          ),
                        ),
                      )
                    else if (guide != null)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, scene) {
                            // Junto a los iconos de estado, sin taparlos, y
                            // por encima de los controles de giro.
                            final vertical =
                                scene.maxHeight - 2 * AppSpace.s >= 224;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                vertical
                                    ? AppSpace.s * 2 + AppSizes.touch + 8
                                    : AppSpace.s,
                                vertical
                                    ? AppSpace.s
                                    : AppSpace.s * 2 + AppSizes.touch + 4,
                                AppSpace.s,
                                AppSizes.touch + AppSpace.m,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SceneTapShield(
                                  child: SingleChildScrollView(
                                    child: GuideCard(
                                      step: guide,
                                      petName: pet.name,
                                      onAction: () => _guideAction(guide),
                                      onSkip: () => saveOrRecover(
                                        context,
                                        () => c.markHintSeen(Tutorial.skipHint),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (live)
                      Positioned(
                        right: AppSpace.s,
                        bottom: AppSpace.s,
                        child: Row(
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
                              onPressed: () => _setResting(!resting),
                              child: LText(resting ? 'Levantarse' : 'Tumbarse'),
                            ),
                          ],
                        ),
                      )
                    else if (!resting)
                      Positioned(
                        right: AppSpace.s,
                        bottom: AppSpace.s,
                        child: TurnControl(
                          view: _view,
                          onTurn: _turn,
                          compact: l.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.51),
              child: Panel(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            resting ? Icons.bedtime_rounded : actionIcon,
                            color: accent,
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: LText(
                              resting
                                  ? '${pet.name} descansa en su cama. La energía sube con el tiempo en casa.'
                                  : _suggestion!,
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                          AppButton(
                            label: actionLabel,
                            icon: actionIcon,
                            onPressed: () => urgent != null
                                ? _attend(urgent)
                                : _actNeed(lowest),
                          ),
                        ],
                      ),
                      SizedBox(height: l.compact ? AppSpace.s : AppSpace.m),
                      GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: l.tablet ? 4 : 2,
                          mainAxisSpacing: AppSpace.s,
                          crossAxisSpacing: AppSpace.s,
                          // Altura según el tamaño de texto para no desbordar.
                          mainAxisExtent:
                              34 +
                              26 * MediaQuery.textScalerOf(context).scale(1),
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final n in Need.values.where(
                            (n) => n != Need.hydration,
                          ))
                            NeedMeter(
                              need: n,
                              onTap: () => _actNeed(n),
                              label: Texts.needLabels[n]!,
                              value: pet.needPoints(n),
                              highlight: urgent == null ? n == lowest : false,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s),
                      Row(
                        children: [
                          Expanded(
                            child: HealthMeter(
                              points: pet.healthPoints,
                              sick: pet.isSick,
                              onTap: () => _attend(PetCondition.sick),
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: NeedMeter(
                              need: Need.hydration,
                              onTap: () => _actNeed(Need.hydration),
                              label: Texts.needLabels[Need.hydration]!,
                              value: pet.needPoints(Need.hydration),
                              highlight:
                                  urgent == PetCondition.thirsty ||
                                  urgent == null && lowest == Need.hydration,
                            ),
                          ),
                        ],
                      ),
                      if (urgent == null && lowest != Need.energy) ...[
                        SizedBox(height: l.compact ? AppSpace.xs : AppSpace.s),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _setResting(!resting),
                            icon: Icon(
                              resting
                                  ? Icons.wb_sunny_rounded
                                  : Icons.bedtime_rounded,
                            ),
                            label: LText(
                              resting ? 'Despertar' : 'Descansar en su cama',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
