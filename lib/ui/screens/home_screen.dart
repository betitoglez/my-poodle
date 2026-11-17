import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/balance.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/scene_view.dart';
import 'care_activity_screens.dart';
import 'main_shell.dart';
import 'settings_screens.dart';

/// P03 · Casa: salón, caniche, nombre, saldo, cuatro indicadores,
/// sugerencia de la necesidad más baja, caricia y descanso.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeGame? _game;
  final _texts = Texts();
  String? _suggestion;
  Need? _suggestedFor;

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
    // Un único caniche que refleja el aspecto confirmado.
    _game!.setLook(c.look);
    _game!.reducedMotion = c.reducedMotion;
  }

  void _act(Need need) {
    switch (need) {
      case Need.satiety:
        pushScreen(context, const FeedScreen());
      case Need.hygiene:
        pushScreen(context, const BathScreen());
      case Need.mood:
        ShellScope.maybeOf(context)?.go(ShellTab.games);
      case Need.energy:
        setState(() => _game!.setResting(!_game!.resting));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pet = c.pet;
    final l = Layout.of(context);
    final lowest = c.rules.lowestNeed(pet);
    if (_suggestedFor != lowest) {
      _suggestedFor = lowest;
      _suggestion = _texts.pick(Texts.suggestions[lowest]!, name: pet.name);
    }
    final resting = _game!.resting;
    final showHint = !pet.prefs.seenHints.contains('home.pet');
    final actionLabel = switch (lowest) {
      Need.satiety => 'Comer',
      Need.hygiene => 'Bañar',
      Need.mood => 'Jugar',
      Need.energy => resting ? 'Despertar' : 'Descansar',
    };

    return SafeArea(
      bottom: false,
      child: Column(
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
                  '${pet.name} en el salón. Toca para hacerle una caricia.',
              onTap: (p) => setState(() => _game!.tapAt(p)),
              overlay: showHint
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.m),
                        child: HintBubble(
                          icon: Icons.touch_app_rounded,
                          text: 'Toca a ${pet.name} para hacerle una caricia.',
                          onClose: () => c.markHintSeen('home.pet'),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      resting ? Icons.bedtime_rounded : lowest.icon,
                      color: lowest.color,
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: Text(
                        resting
                            ? '${pet.name} descansa en su cojín. La energía sube con el tiempo en casa.'
                            : _suggestion!,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    AppButton(
                      label: actionLabel,
                      icon: lowest == Need.energy
                          ? Icons.bedtime_rounded
                          : lowest.icon,
                      onPressed: () => _act(lowest),
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
                        34 + 26 * MediaQuery.textScalerOf(context).scale(1),
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final n in Need.values)
                      NeedMeter(
                        need: n,
                        label: Texts.needLabels[n]!,
                        value: pet.needPoints(n),
                        highlight: n == lowest,
                      ),
                  ],
                ),
                if (lowest != Need.energy) ...[
                  SizedBox(height: l.compact ? AppSpace.xs : AppSpace.s),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _game!.setResting(!resting)),
                      icon: Icon(
                        resting
                            ? Icons.wb_sunny_rounded
                            : Icons.bedtime_rounded,
                      ),
                      label: Text(
                        resting ? 'Despertar' : 'Descansar en el cojín',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
