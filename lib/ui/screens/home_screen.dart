import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/scene_view.dart';
import '../widgets/status_bubbles.dart';
import '../widgets/turn_control.dart';
import 'care_activity_screens.dart';
import 'main_shell.dart';
import 'settings_screens.dart';

/// P03 · Casa: salón, caniche, nombre, saldo, iconos de estado tipo
/// tamagotchi, cuatro indicadores y salud, sugerencia de lo más urgente,
/// caricia, descanso y giro para verlo desde los cuatro ángulos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeGame? _game;
  final _texts = Texts();
  String? _suggestion;
  Object? _suggestedFor;
  PetView _view = PetView.front;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.of(context);
    _game ??= HomeGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
      onPetTapped: () {
        AppScope.feedbackOf(context).play(Sfx.tap);
        AppScope.read(context).markHintSeen('home.pet');
      },
    );
    // Un único caniche que refleja el aspecto y la salud confirmados.
    _game!.setLook(c.look);
    _game!.reducedMotion = c.reducedMotion;
    _game!.pet.fx = PetFx(sick: c.pet.isSick);
  }

  void _turn(PetView v) {
    setState(() => _view = v);
    _game!.pet.setView(v);
  }

  /// Lleva a la actividad que resuelve cada estado: el veterinario y la cama
  /// tienen pantalla propia; el resto, la de su medida.
  void _attend(PetCondition cond) {
    switch (cond) {
      case PetCondition.sick:
        pushScreen(context, const VetScreen());
      case PetCondition.tired:
        pushScreen(context, const SleepScreen());
      case PetCondition.hungry || PetCondition.dirty || PetCondition.sad:
        _actNeed(cond.need!);
    }
  }

  void _actNeed(Need need) {
    switch (need) {
      case Need.satiety:
        pushScreen(context, const FeedScreen());
      case Need.hygiene:
        pushScreen(context, const BathScreen());
      case Need.mood:
        ShellScope.maybeOf(context)?.go(ShellTab.games);
      case Need.energy:
        _setResting(!_game!.resting);
    }
  }

  /// Al acostarse mira de frente: el giro vuelve a ese ángulo para no
  /// quedar desfasado.
  void _setResting(bool value) {
    setState(() {
      _game!.setResting(value);
      if (value) _view = PetView.front;
    });
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
    final resting = _game!.resting;
    final showHint = !pet.prefs.seenHints.contains('home.pet');
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
              trailing: IconButton(
                tooltip: 'Ajustes',
                onPressed: () => pushScreen(context, const SettingsScreen()),
                icon: const Icon(Icons.settings_rounded, color: AppColors.plum),
              ),
            ),
            Expanded(
              child: SceneView(
                game: _game!,
                semanticsLabel:
                    '${pet.name} en el salón, ${_view.label.toLowerCase()}. Toca para hacerle una caricia.',
                onTap: (p) => setState(() => _game!.tapAt(p)),
                overlay: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: AppSpace.s,
                      top: AppSpace.s,
                      child: LayoutBuilder(
                        builder: (context, scene) => StatusBubbles(
                          active: conditions,
                          reducedMotion: c.reducedMotion,
                          onTap: _attend,
                          vertical: scene.maxHeight >= 260,
                        ),
                      ),
                    ),
                    if (showHint)
                      Positioned(
                        left: AppSpace.m,
                        right: AppSpace.m,
                        top: 64,
                        child: HintBubble(
                          icon: Icons.touch_app_rounded,
                          text: 'Toca a ${pet.name} para hacerle una caricia.',
                          onClose: () => c.markHintSeen('home.pet'),
                        ),
                      ),
                    if (!resting)
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
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.56),
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
                            child: Text(
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
                          for (final n in Need.values)
                            NeedMeter(
                              need: n,
                              label: Texts.needLabels[n]!,
                              value: pet.needPoints(n),
                              highlight: urgent == null ? n == lowest : false,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s),
                      HealthMeter(points: pet.healthPoints, sick: pet.isSick),
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
                            label: Text(
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
