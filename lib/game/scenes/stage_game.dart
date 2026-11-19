import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../pet/appearance_catalog.dart';
import '../pet/pet_component.dart';
import '../pet/pet_painter.dart';
import 'room_painter.dart';

/// Componente que delega el dibujo en una función (capas de escena).
class Painted extends Component {
  Painted(this.painter, {super.priority});
  final void Function(Canvas canvas) painter;
  @override
  void render(Canvas canvas) => painter(canvas);
}

/// Escena 2D con sala y caniche. Base de Casa, Armario, cuidados y
/// resultados. La entrada llega desde widgets ([tapAt]/[dragAt]) en
/// coordenadas de la escena, con un solo dueño por gesto.
class StageGame extends FlameGame {
  StageGame({
    required this.painter,
    required PetLook look,
    required this.room,
    bool reducedMotion = false,
    this.floorY = 0.74,
    this.petX = 0.5,
    this.petScale = 0.6,
    PetAnim anim = PetAnim.idle,
    PetPose pose = PetPose.front,
    this.onChanged,
  }) : pet = PetComponent(
         painter: painter,
         look: look,
         reducedMotion: reducedMotion,
         baseAnim: anim,
         pose: pose,
       )..priority = 10;

  final PetPainter painter;
  final RoomKind? room;
  final double floorY;
  double petX;
  final double petScale;
  final PetComponent pet;
  void Function()? onChanged;
  double time = 0;

  bool get reducedMotion => pet.reducedMotion;
  set reducedMotion(bool v) => pet.reducedMotion = v;

  @override
  Color backgroundColor() => const Color(0xFFFFF8E9);

  /// Ilustración de la sala (null: dibujo vectorial provisional).
  Image? roomImage;
  RoomArt? roomArt;

  @override
  Future<void> onLoad() async {
    final art = room == null ? null : RoomArt.of[room!];
    if (art != null) {
      try {
        roomImage = await images.load(art.asset);
        roomArt = art;
      } catch (_) {
        roomImage = null; // Fallback visible: sala vectorial.
      }
    }
    if (room != null) {
      add(
        Painted((c) {
          final img = roomImage;
          if (img != null) {
            final r = imageRect;
            c.drawImageRect(
              img,
              Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
              r,
              Paint()..filterQuality = FilterQuality.medium,
            );
          } else {
            RoomPainter.paint(c, size.toSize(), room!, floorY: floorY, t: time);
          }
        }, priority: 0),
      );
    }
    add(pet);
    layoutPet();
  }

  /// La ilustración cubre la escena anclada al suelo (se recorta arriba).
  Rect get imageRect {
    final img = roomImage!;
    final s = math.max(size.x / img.width, size.y / img.height);
    final w = img.width * s, h = img.height * s;
    return Rect.fromLTWH((size.x - w) / 2, size.y - h, w, h);
  }

  /// Rectángulo de la ilustración (fracciones) en coordenadas de escena.
  Rect? imageFraction(Rect f) {
    if (roomImage == null) return null;
    final r = imageRect;
    return Rect.fromLTRB(
      r.left + f.left * r.width,
      r.top + f.top * r.height,
      r.left + f.right * r.width,
      r.top + f.bottom * r.height,
    );
  }

  /// Pies del caniche y tamaño según el área disponible.
  void layoutPet() {
    if (!isLoaded && size.x == 0) return;
    final art = roomArt;
    if (art != null && roomImage != null) {
      final r = imageRect;
      final feetY = r.top + art.feet.dy * r.height;
      // Altura según la ilustración, sin salirse por arriba.
      pet.petSize = math.min(
        math.min(art.petHeight * r.height, feetY * 0.92),
        size.x * 0.8,
      );
      pet.position = Vector2(r.left + art.feet.dx * r.width, feetY);
      return;
    }
    pet.petSize = math.min(size.y * petScale, size.x * 0.8);
    pet.position = Vector2(
      size.x * petX,
      size.y * (floorY + (1 - floorY) * 0.5),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layoutPet();
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
  }

  void setLook(PetLook look) => pet.setLook(look);

  void tapAt(Offset p) {}
  void dragAt(Offset p, Offset delta) {}
  void notify() => onChanged?.call();
}

/// Cama del caniche (imagen de atrezo). El caniche duerme sobre ella: el
/// fondo y la cara posterior se pintan detrás y el borde delantero delante.
class BedProp {
  Image? image;

  Future<void> load(StageGame g) async {
    try {
      image = await g.images.load('props/bed.webp');
    } catch (_) {
      image = null; // Respaldo vectorial.
    }
  }

  /// Cama bajo los pies del caniche tumbado: su barriga queda al 62 % de la altura.
  Rect rect(Offset feet, double petSize) {
    final w = petSize * 1.5;
    final img = image;
    final h = img == null ? w * 0.4 : w * img.height / img.width;
    return Rect.fromLTWH(feet.dx - w / 2, feet.dy - h * 0.62, w, h);
  }

  static const double frontRim = 0.5;

  void paintBack(Canvas c, Rect r) {
    final img = image;
    if (img == null) {
      c.drawOval(r, Paint()..color = const Color(0xFF8E3B55));
      c.drawOval(
        r.deflate(r.width * 0.08),
        Paint()..color = const Color(0xFFA9506C),
      );
      return;
    }
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      r,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void paintFront(Canvas c, Rect r) {
    final img = image;
    if (img == null) return;
    c.save();
    c.clipRect(
      Rect.fromLTRB(r.left, r.top + r.height * frontRim, r.right, r.bottom),
    );
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      r,
      Paint()..filterQuality = FilterQuality.medium,
    );
    c.restore();
  }
}

/// Casa: caricia al tocar al caniche y descanso en el cojín.
class HomeGame extends StageGame {
  HomeGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    this.onPetTapped,
  }) : super(room: RoomKind.living);

  final void Function()? onPetTapped;
  bool resting = false;
  bool useLiveBed = false;

  final bed = BedProp();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // La cama llega sin bloquear la escena; mientras, cojín vectorial.
    bed.load(this);
    add(Painted(_bedBack, priority: 5));
    add(Painted(_bedFront, priority: 15));
    add(Painted(_zzz, priority: 20));
  }

  void setResting(bool value) {
    resting = value;
    pet.baseAnim = value ? PetAnim.sleep : PetAnim.idle;
    if (value) pet.setView(PetView.front);
    pet.clearReaction();
  }

  Rect get _bedRect => bed.rect(pet.position.toOffset(), pet.petSize);

  void _bedBack(Canvas c) {
    if (resting && !useLiveBed) bed.paintBack(c, _bedRect);
  }

  void _bedFront(Canvas c) {
    if (resting && !useLiveBed) bed.paintFront(c, _bedRect);
  }

  void _zzz(Canvas c) {
    if (!resting || useLiveBed) return;
    final head = pet.landmarkScene('headTop') + Offset(pet.petSize * .09, 0);
    for (var i = 0; i < 3; i++) {
      final k = ((time * 0.5 + i / 3) % 1);
      final tp = _text('z', 14 + i * 5.0, const Color(0xFF5C354E));
      tp.paint(c, head + Offset(k * 30 + i * 6, -k * 40 - i * 10));
    }
  }

  @override
  void tapAt(Offset p) {
    if (pet.hits(p)) reactToPetTap();
  }

  void reactToPetTap() {
    if (resting) setResting(false);
    pet.react(PetAnim.happy, seconds: 1.6);
    onPetTapped?.call();
  }
}

TextPainter _text(String s, double size, Color color) => TextPainter(
  text: TextSpan(
    text: s,
    style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w900),
  ),
  textDirection: TextDirection.ltr,
)..layout();

TextPainter sceneText(String s, double size, Color color) =>
    _text(s, size, color);
