import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/appearance.dart';
import '../../domain/games/orchard_sim.dart';

enum LivePetTap { missed, touched, greeted }

class LivePoodleController {
  MethodChannel? _channel;
  Rect? _bowlBounds;
  Size _viewport = Size.zero;
  bool ready = false;
  bool failed = false;

  /// Desplazamiento horizontal en píxeles lógicos, como el gesto de arrastre.
  void rotate(double deltaPixels) => _send('rotate', deltaPixels);
  void pet() => _send('pet');

  /// La cabeza del modelo mira hacia [point] (píxeles lógicos de la vista);
  /// null la devuelve al frente.
  void look(Offset? point) {
    if (point == null || _viewport.isEmpty) {
      _send('look', const <double>[]);
      return;
    }
    _send('look', [
      (point.dx / _viewport.width).clamp(0.0, 1.0),
      (point.dy / _viewport.height).clamp(0.0, 1.0),
    ]);
  }

  Future<LivePetTap> petAt(Offset point) async {
    if (_viewport.isEmpty) return LivePetTap.missed;
    final result = await _channel?.invokeMethod<int>('petAt', [
      point.dx / _viewport.width,
      point.dy / _viewport.height,
    ]);
    return switch (result) {
      2 => LivePetTap.greeted,
      1 => LivePetTap.touched,
      _ => LivePetTap.missed,
    };
  }

  Future<Uint8List?> snapshot() async {
    if (!ready || failed) return null;
    final encoded = await _channel?.invokeMethod<String>('snapshot');
    const prefix = 'data:image/png;base64,';
    if (encoded == null || !encoded.startsWith(prefix)) return null;
    return base64Decode(encoded.substring(prefix.length));
  }

  void front() => _send('front');
  void feed(double progress, double fill) => _send('feed', [progress, fill]);
  void bath(List<double> state) => _send('bath', state);
  void vet(List<num> state) => _send('vet', state);
  void groom(List<num> state) => _send('groom', state);
  void sleep(List<double> state) => _send('sleep', state);
  void walk(List<double> state) => _send('walk', state);
  void orchard(List<num> state) => _send('orchard', state);
  void frisbee(List<num> state) => _send('frisbee', state);

  bool hitBowl(Offset point) {
    final bounds = _bowlBounds;
    if (bounds == null || _viewport.isEmpty) return false;
    return Rect.fromLTRB(
      bounds.left * _viewport.width,
      bounds.top * _viewport.height,
      bounds.right * _viewport.width,
      bounds.bottom * _viewport.height,
    ).inflate(10).contains(point);
  }

  void _send(String method, [Object? data]) {
    _channel?.invokeMethod<void>(method, data);
  }
}

class LivePoodleView extends StatefulWidget {
  const LivePoodleView({
    super.key,
    required this.controller,
    required this.appearance,
    required this.onStatusChanged,
    required this.resting,
    required this.reducedMotion,
    required this.wardrobe,
    this.feeding = false,
    this.drinking = false,
    this.drinkColor,
    this.bathing = false,
    this.spaBath = false,
    this.onBathTargets,
    this.veterinary = false,
    this.onVetTargets,
    this.grooming = false,
    this.onGroomTargets,
    this.sleeping = false,
    this.onSleepBounds,
    this.walking = false,
    this.orchardLevel,
    this.frisbee = false,
    this.idle = false,
    this.onPanting,
    this.roaming = false,
    this.hygiene = 100,
    this.mood = 100,
    this.energy = 100,
    this.sick = false,
    this.passiveBed = false,
  });

  final LivePoodleController controller;
  final Appearance appearance;
  final VoidCallback onStatusChanged;
  final bool resting;
  final bool reducedMotion;
  final bool wardrobe;
  final bool feeding;
  final bool drinking;
  final Color? drinkColor;
  final bool bathing;
  final bool spaBath;
  final ValueChanged<List<Offset>>? onBathTargets;
  final bool veterinary;
  final ValueChanged<List<Offset>>? onVetTargets;
  final bool grooming;
  final ValueChanged<List<Offset>>? onGroomTargets;
  final bool sleeping;
  final ValueChanged<Rect>? onSleepBounds;
  final bool walking;
  final ValueChanged<bool>? onPanting;
  final OrchardLevel? orchardLevel;
  final bool frisbee, idle, roaming, sick, passiveBed;
  final int hygiene, mood, energy;

  static bool get enabled =>
      const bool.fromEnvironment('POODLE_LIVE_3D') &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const supportedItems = {
    'outfit.teal',
    'outfit.overalls_red',
    'outfit.overalls_yellow',
    'outfit.sweater_red',
    'outfit.sweater_blue',
    'outfit.sweater_mustard',
    'outfit.dress_pink',
    'outfit.dress_lilac',
    'outfit.dress_turquoise',
    'outfit.raincoat_blue',
    'outfit.raincoat_yellow',
    'outfit.raincoat_pink',
    'outfit.overalls_denim',
    'outfit.overalls_pink',
    'outfit.sweater_green',
    'outfit.sweater_purple',
    'outfit.raincoat_red',
    'outfit.raincoat_green',
    'outfit.dress_yellow',
    'outfit.dress_coral',
    'head.crown_jewels',
    'collar.pearls_gold',
    'neck.coral',
    'neck.bowtie',
    'neck.knit',
    'head.bow',
    'head.beanie',
    'head.crown',
    'eyes.round',
    'eyes.sun',
    'eyes.heart',
    'collar.tag',
    'collar.bell',
    'collar.pearls',
    'paws.rain',
    'paws.booties',
    'paws.sneakers',
  };

  static bool supports(Appearance appearance) =>
      const {
        'hair.natural',
        'hair.teddy',
        'hair.pom',
        'hair.puppy',
        'hair.show',
      }.contains(appearance.hair) &&
      _clothes(appearance).every(supportedItems.contains);

  static Iterable<String> _clothes(Appearance appearance) => [
    appearance.outfit,
    appearance.neck,
    appearance.head,
    appearance.eyes,
    appearance.paws,
    appearance.collar,
  ].where((id) => !id.endsWith('.none'));

  @override
  State<LivePoodleView> createState() => _LivePoodleState();
}

class _LivePoodleState extends State<LivePoodleView> {
  MethodChannel? _channel;
  Size _size = Size.zero;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    _loadTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || widget.controller.ready) return;
      widget.controller.failed = true;
      widget.onStatusChanged();
    });
  }

  void _configure() {
    if (_size.isEmpty) return;
    // Same cover crop and feet landmarks as StageGame/RoomArt.
    final imageWidth = widget.spaBath ? 1200.0 : 672.0;
    final imageHeight = widget.spaBath
        ? 675.0
        : widget.wardrobe
        ? 697.0
        : 900.0;
    final scale = math.max(
      _size.width / imageWidth,
      _size.height / imageHeight,
    );
    final artWidth = imageWidth * scale;
    final artHeight = imageHeight * scale;
    final floor =
        _size.height -
        artHeight *
            (widget.wardrobe
                ? 0.14
                : widget.bathing
                ? 0.22
                : widget.veterinary
                ? 0.24
                : widget.grooming
                ? 0.14
                : widget.sleeping
                ? 0.19
                : widget.roaming
                ? 0.17
                : 0.20);
    final height = math
        .min(
          math.min(
            artHeight * (widget.wardrobe || widget.grooming ? 0.54 : 0.42),
            floor * 0.92,
          ),
          _size.width *
              (widget.sleeping
                  ? 0.59
                  : widget.feeding || widget.bathing || widget.veterinary
                  ? 0.68
                  : 0.80),
        )
        .clamp(
          0.0,
          widget.roaming || widget.wardrobe
              ? _size.height * 0.55
              : double.infinity,
        );
    final appearance = widget.appearance;
    final orchard = widget.orchardLevel;
    _channel?.invokeMethod<void>('configure', {
      'x': widget.walking || orchard != null
          ? 0.0
          : widget.feeding
          ? 0.40
          : widget.sleeping
          ? 0.57
          : (_size.width / 2 - (widget.wardrobe ? artWidth * 0.05 : 0)) /
                _size.width,
      'y': widget.frisbee
          ? 1.0
          : orchard != null
          ? 0.80
          : widget.walking
          ? 0.79
          : floor / _size.height,
      'size': widget.frisbee
          ? 0.18
          : orchard != null
          ? math.min(_size.width / 4.8, _size.height / 3.4) / _size.height
          : widget.walking
          ? _size.width / (2.6 * _size.height)
          : height / _size.height,
      'resting': widget.resting,
      'feeding': widget.feeding,
      'drinking': widget.drinking,
      'drinkColor': widget.drinkColor == null
          ? null
          : widget.drinkColor!.toARGB32() & 0xffffff,
      'bathing': widget.bathing,
      'veterinary': widget.veterinary,
      'grooming': widget.grooming,
      'sleeping': widget.sleeping,
      'walking': widget.walking,
      'frisbee': widget.frisbee,
      'idle': widget.idle,
      'roaming': widget.roaming,
      'hygiene': widget.hygiene,
      'mood': widget.mood,
      'energy': widget.energy,
      'sick': widget.sick,
      'passiveBed': widget.passiveBed,
      'orchardLevel': orchard == null
          ? null
          : {
              'platforms': [
                for (final p in orchard.platforms) [p.x0, p.x1, p.top],
              ],
              'fruit': [
                for (final f in orchard.apples) [f.x, f.y, f.kind.index],
              ],
              'barriers': [
                for (final b in orchard.barriers)
                  [b.x, b.ground, b.width, b.height, b.kind.index],
              ],
              'goal': orchard.goalX,
              'start': orchard.startX,
            },
      'reduced': widget.reducedMotion,
      'visible': LivePoodleView.supports(appearance),
      'pom': appearance.hair == 'hair.pom',
      'puppy': appearance.hair == 'hair.puppy',
      'teddy': appearance.hair == 'hair.teddy',
      'showCut': appearance.hair == 'hair.show',
      'coat': appearance.coat.split('.').last,
      'wear': LivePoodleView._clothes(appearance).toList(),
    });
  }

  void _created(int id) {
    if (!mounted) return;
    final channel = _channel = MethodChannel('my_poodle/3d/$id');
    widget.controller._channel = channel;
    channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'ready' || call.method == 'failed') {
        _loadTimer?.cancel();
        widget.controller.ready = call.method == 'ready';
        widget.controller.failed = call.method == 'failed';
        if (widget.controller.failed) widget.onPanting?.call(false);
        widget.onStatusChanged();
      } else if (call.method == 'motionSound') {
        final event = call.arguments;
        if (event == 0 || event == 1) {
          widget.onPanting?.call(event == 1);
        }
      } else if (call.method == 'bowlBounds' || call.method == 'sleepBounds') {
        final values = (call.arguments as List).cast<double>();
        final bounds = Rect.fromLTRB(
          values[0],
          values[1],
          values[2],
          values[3],
        );
        if (call.method == 'sleepBounds') {
          widget.onSleepBounds?.call(bounds);
        } else if (widget.feeding) {
          widget.controller._bowlBounds = bounds;
        }
      } else if (call.method == 'bathTargets' ||
          call.method == 'vetTargets' ||
          call.method == 'groomTargets') {
        final values = (call.arguments as List).cast<double>();
        final callback = switch (call.method) {
          'bathTargets' => widget.onBathTargets,
          'vetTargets' => widget.onVetTargets,
          _ => widget.onGroomTargets,
        };
        callback?.call([
          for (var i = 0; i < values.length; i += 2)
            Offset(values[i], values[i + 1]),
        ]);
      }
    });
    _configure();
  }

  @override
  void didUpdateWidget(covariant LivePoodleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appearance != widget.appearance ||
        oldWidget.resting != widget.resting ||
        oldWidget.feeding != widget.feeding ||
        oldWidget.drinking != widget.drinking ||
        oldWidget.drinkColor != widget.drinkColor ||
        oldWidget.bathing != widget.bathing ||
        oldWidget.spaBath != widget.spaBath ||
        oldWidget.veterinary != widget.veterinary ||
        oldWidget.grooming != widget.grooming ||
        oldWidget.sleeping != widget.sleeping ||
        oldWidget.walking != widget.walking ||
        oldWidget.orchardLevel != widget.orchardLevel ||
        oldWidget.frisbee != widget.frisbee ||
        oldWidget.idle != widget.idle ||
        oldWidget.roaming != widget.roaming ||
        oldWidget.hygiene != widget.hygiene ||
        oldWidget.mood != widget.mood ||
        oldWidget.energy != widget.energy ||
        oldWidget.sick != widget.sick ||
        oldWidget.passiveBed != widget.passiveBed ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _configure();
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _channel?.setMethodCallHandler(null);
    if (widget.controller._channel == _channel) {
      widget.controller._channel = null;
      widget.controller._bowlBounds = null;
      widget.controller.ready = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (_size != constraints.biggest) {
        _size = constraints.biggest;
        widget.controller._viewport = _size;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _configure();
        });
      }
      return IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (defaultTargetPlatform == TargetPlatform.iOS)
              UiKitView(
                viewType: 'my_poodle/poodle_3d',
                onPlatformViewCreated: _created,
              )
            else
              AndroidView(
                viewType: 'my_poodle/poodle_3d',
                onPlatformViewCreated: _created,
              ),
            if (!widget.controller.ready && !widget.controller.failed)
              const ColoredBox(
                color: Color(0xFFFFF8E9),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
          ],
        ),
      );
    },
  );
}
