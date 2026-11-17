import 'dart:ui';

import 'package:flame/components.dart';

import 'appearance_catalog.dart';
import 'pet_painter.dart';

/// Caniche en una escena Flame. El origen del componente está en los pies;
/// todas las capas comparten el mismo reloj de animación.
class PetComponent extends PositionComponent {
  PetComponent({
    required this.painter,
    required this.look,
    this.pose = PetPose.front,
    this.baseAnim = PetAnim.idle,
    this.petSize = 200,
    this.reducedMotion = false,
  });

  final PetPainter painter;
  PetLook look;

  /// Aspecto pedido mientras se cargan sus capas; sustituye a [look] al estar
  /// listo para no enseñar un fotograma a medias.
  PetLook? _pendingLook;
  PetPose pose;
  PetAnim baseAnim;
  double petSize;
  bool reducedMotion;
  PetFx fx = PetFx.none;
  double airborne = 0;
  bool facingLeft = false;

  double _t = 0;
  PetAnim? _reaction;
  double _reactionLeft = 0;

  PetAnim get anim => _reaction ?? baseAnim;

  /// Cambia el aspecto cargando antes sus capas (sin parpadeos).
  void setLook(PetLook next) {
    final ids = next.ids;
    // Mismo aspecto que el actual (o que el pedido): nada que hacer.
    if (ids != null && ids == (_pendingLook?.ids ?? look.ids)) return;
    if (ids == null || painter.sprites == null) {
      look = next;
      return;
    }
    _pendingLook = next;
    painter.warm(ids).then((_) {
      if (identical(_pendingLook, next)) {
        look = next;
        _pendingLook = null;
      }
    });
  }

  /// Mira desde uno de los cuatro ángulos.
  void setView(PetView v) {
    pose = v.pose;
    facingLeft = v.facingLeft;
  }

  bool get reacting => _reaction != null;

  /// Reacción breve que vuelve después a [baseAnim].
  void react(PetAnim a, {double seconds = 1.4}) {
    _reaction = a;
    _reactionLeft = seconds;
  }

  void clearReaction() {
    _reaction = null;
    _reactionLeft = 0;
  }

  double get clock => _t;

  /// Punto del cuerpo (ojos, boca, pecho, costados, patas…) en coordenadas
  /// de la escena, según la pose y el fotograma que se está dibujando.
  Offset landmarkScene(String name) {
    final u = painter.landmark(
      pose,
      name,
      anim: anim,
      t: _t,
      reducedMotion: reducedMotion,
      ids: look.ids,
    );
    return Offset(
      position.x + (facingLeft ? -u.dx : u.dx) * petSize,
      position.y + u.dy * petSize,
    );
  }

  /// Convierte un punto de la escena al espacio unitario del caniche.
  Offset toUnit(Offset scenePoint) {
    final dx = (scenePoint.dx - position.x) / petSize;
    return Offset(
      facingLeft ? -dx : dx,
      (scenePoint.dy - position.y) / petSize,
    );
  }

  /// ¿El punto toca el cuerpo del caniche? (caja aproximada por pose).
  bool hits(Offset scenePoint) {
    final u = toUnit(scenePoint);
    return pose == PetPose.side
        ? u.dx > -0.45 && u.dx < 0.6 && u.dy > -1.0 && u.dy < 0.05
        : u.dx.abs() < 0.3 && u.dy > -1.1 && u.dy < 0.05;
  }

  @override
  Future<void> onLoad() async {
    // Todas las poses del aspecto actual, para cambiar de pose sin parpadeo.
    final ids = look.ids;
    if (ids != null) await painter.warm(ids);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_reaction != null) {
      _reactionLeft -= dt;
      if (_reactionLeft <= 0) _reaction = null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (facingLeft) {
      canvas.save();
      canvas.scale(-1, 1);
    }
    painter.paint(
      canvas,
      look,
      pose: pose,
      anim: anim,
      t: _t,
      size: petSize,
      reducedMotion: reducedMotion,
      airborne: airborne,
      fx: fx,
    );
    if (facingLeft) canvas.restore();
  }
}
