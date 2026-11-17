import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../app/texts.dart';
import '../../domain/activities.dart';
import '../../domain/appearance.dart';
import '../../domain/rules.dart';
import '../../game/care/care_games.dart';
import '../../game/scenes/stage_game.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/activity_frame.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
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
  StepActivity get activity;
  G createGame(AppController c);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (game == null) {
      final c = AppScope.read(context);
      session = c.beginActivity(kind.name);
      game = createGame(c)..onChanged = _changed;
      // Malito se le ve en todas las escenas, no solo en Casa.
      final pet = game!.pet;
      pet.fx = pet.fx.withSick(c.pet.isSick);
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
    AppScope.feedbackOf(context).play(Sfx.celebrate);
    final receipt = await commitOrRecover<Receipt>(
      context,
      () => c.finishCare(session, kind),
    );
    if (!mounted) return;
    if (receipt != null) {
      replaceScreen(context, CareResultScreen(kind: kind, receipt: receipt));
    } else {
      finishing = false;
      setState(() {});
    }
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
      onClose: () => c.markHintSeen(hintId),
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
  )..onBite = () => AppScope.feedbackOf(context).play(Sfx.bite);

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).pet.name;
    final text = _activity.chewing
        ? '$name está masticando…'
        : _activity.completed
        ? '¡Cuenco vacío!'
        : 'Toca el cuenco o el botón para darle un bocado.';
    return frame(
      title: 'Hora de comer',
      scene: SceneView(
        game: game!,
        semanticsLabel: 'Cocina con el cuenco de comida',
        onTap: game!.tapAt,
      ),
      hintWidget: hint(
        'Toca el cuenco para darle un bocado.',
        Icons.restaurant_rounded,
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(text, icon: Icons.restaurant_rounded),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: _activity.chewing ? 'Masticando…' : 'Dar un bocado',
            icon: Icons.restaurant_rounded,
            big: true,
            expand: true,
            onPressed: _activity.canBite && !finishing
                ? () => game!.bite()
                : null,
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
  )..onSoap = (_) => AppScope.feedbackOf(context).play(Sfx.bubble);

  static const _zoneNames = {
    BathZone.back: 'Lomo',
    BathZone.paws: 'Patas',
    BathZone.chest: 'Pecho',
  };

  @override
  Widget build(BuildContext context) {
    final phase = _activity.phase;
    final text = switch (phase) {
      BathPhase.wet => 'Primero, moja el pelo: toca al caniche o pulsa Mojar.',
      BathPhase.soap => 'Enjabona las tres zonas: toca o frota cada círculo.',
      BathPhase.rinse => '¡Mucha espuma! Ahora aclara.',
      BathPhase.done => '¡Limpio!',
    };
    Widget action;
    switch (phase) {
      case BathPhase.wet:
        action = AppButton(
          label: 'Mojar',
          icon: Icons.shower_rounded,
          big: true,
          expand: true,
          onPressed: () {
            if (game!.wet()) AppScope.feedbackOf(context).play(Sfx.splash);
          },
        );
      case BathPhase.soap:
        action = Row(
          children: [
            for (final z in BathZone.values) ...[
              Expanded(
                child: _ZoneButton(
                  label: _zoneNames[z]!,
                  progress: _activity.foam(z),
                  done: _activity.zoneDone(z),
                  onPressed: () => game!.soap(z),
                ),
              ),
              if (z != BathZone.values.last) const SizedBox(width: AppSpace.s),
            ],
          ],
        );
      case BathPhase.rinse:
      case BathPhase.done:
        action = AppButton(
          label: 'Aclarar',
          icon: Icons.water_drop_rounded,
          big: true,
          expand: true,
          onPressed: phase == BathPhase.rinse
              ? () {
                  if (game!.rinse()) {
                    AppScope.feedbackOf(context).play(Sfx.splash);
                  }
                }
              : null,
        );
    }
    return frame(
      title: 'Un baño de espuma',
      scene: SceneView(
        game: game!,
        semanticsLabel: 'Bañera lavanda con el caniche',
        onTap: game!.tapAt,
        onDragUpdate: (_, p, d) => game!.dragAt(p, d),
      ),
      hintWidget: hint('Toca al caniche para mojarlo.', Icons.shower_rounded),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _instruction(text, icon: Icons.bubble_chart_rounded),
          const SizedBox(height: AppSpace.m),
          action,
        ],
      ),
    );
  }
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
  )..onArrive = (_) => AppScope.feedbackOf(context).play(Sfx.sniff);

  static const _go = ['Ir a las flores', 'Ir al banco', 'Ir a la fuente'];

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).pet.name;
    final stop = _activity.enabledStop;
    final text = switch (_activity.phase) {
      _ when _activity.completed => '¡Paseo completo!',
      _ when stop != null => 'Toca la huella de la parada ${stop + 1}.',
      _ when _activity.phase.name == 'moving' => '$name va de camino…',
      _ => '$name está olfateando…',
    };
    return frame(
      title: 'El sendero',
      scene: SceneView(
        game: game!,
        semanticsLabel: 'Sendero con tres paradas',
        onTap: game!.tapAt,
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
            label: stop != null
                ? _go[stop]
                : (_activity.completed ? '¡Llegamos!' : 'Esperando…'),
            icon: Icons.directions_walk_rounded,
            big: true,
            expand: true,
            onPressed: stop != null
                ? () {
                    if (game!.goTo(stop)) {
                      AppScope.feedbackOf(context).play(Sfx.step);
                    }
                  }
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
  @override
  CareKind get kind => CareKind.groom;
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
  )..onBrushed = (_) => AppScope.feedbackOf(context).play(Sfx.brush);

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

  @override
  Widget build(BuildContext context) {
    final done = _activity.completed;
    return frame(
      title: 'Entre rizos',
      scene: SceneView(
        game: game!,
        semanticsLabel: 'Peluquería con espejo y tres mechones por cepillar',
        onTap: game!.tapAt,
        onDragUpdate: (_, p, d) => game!.dragAt(p, d),
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
                ? 'Rizos listos. Termina el cepillado.'
                : 'Cepilla los tres mechones antes de elegir un corte.',
            icon: Icons.brush_rounded,
          ),
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
                  label: 'Probar cortes',
                  icon: Icons.content_cut_rounded,
                  secondary: true,
                  expand: true,
                  onPressed: _tryCuts,
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
  );

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).pet.name;
    final g = game!;
    final (text, label, icon, action) = switch (_activity.phase) {
      SleepPhase.toBed => (
        'Toca su cama para que $name se acueste.',
        'Llevar a su cama',
        Icons.hotel_rounded,
        () {
          g.goToBed();
          AppScope.feedbackOf(context).play(Sfx.step);
        },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).pet.name;
    final g = game!;
    final busy = g.busy;
    final sick = _activity.sick;
    final (text, label, icon, action) = switch (_activity.phase) {
      VetPhase.heart => (
        sick
            ? '$name está malito. Empieza escuchando su corazón.'
            : 'Una revisión: escucha el corazón de $name.',
        'Escuchar el corazón',
        Icons.favorite_rounded,
        g.listen,
      ),
      VetPhase.paws => (
        'Ahora revisa sus patitas.',
        'Revisar las patas',
        Icons.pets_rounded,
        g.checkPaws,
      ),
      VetPhase.pill => (
        'Dale la pastilla para que se ponga bueno.',
        'Dar la pastilla',
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
        onTap: g.tapAt,
      ),
      hintWidget: hint(
        'Toca el círculo para empezar.',
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
                : () {
                    action();
                    AppScope.feedbackOf(context).play(Sfx.tap);
                  },
          ),
        ],
      ),
    );
  }
}
