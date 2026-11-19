import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../domain/appearance.dart';
import 'appearance_catalog.dart';
import 'pet_sprites.dart';
import 'pet_accessories.dart';
import 'integrated_accessories.dart';
import 'fitted_accessories.dart';

/// Reacciones y bucles compartidos por todas las capas (reloj común).
enum PetAnim {
  idle,
  happy,
  eat,
  bath,
  brush,
  trot,
  sniff,
  run,
  jump,
  catchDisc,
  celebrate,
  sleep,
  lookUp,
}

/// Los cuatro ángulos desde los que se puede ver al caniche. Izquierda es
/// el perfil derecho reflejado.
enum PetView {
  front,
  right,
  back,
  left;

  PetPose get pose => switch (this) {
    PetView.front => PetPose.front,
    PetView.back => PetPose.back,
    _ => PetPose.side,
  };

  bool get facingLeft => this == PetView.left;

  /// Siguiente ángulo al girar: frente → derecha → espalda → izquierda.
  PetView get next => PetView.values[(index + 1) % PetView.values.length];
  PetView get previous =>
      PetView.values[(index + PetView.values.length - 1) %
          PetView.values.length];

  String get label => switch (this) {
    PetView.front => 'De frente',
    PetView.right => 'Lado derecho',
    PetView.back => 'De espaldas',
    PetView.left => 'Lado izquierdo',
  };
}

/// Efectos de escena dibujados sobre el personaje (espuma, mechones, agua).
class PetFx {
  const PetFx({
    this.wet = false,
    this.hygiene = 100,
    this.foam = const [0, 0, 0],
    this.messy = const [0, 0, 0],
    this.sick = false,
  });

  final bool wet;
  final int hygiene;

  /// 65 limpio; 64..52, 51..39, 38..26, 25..13, 12..0.
  int get dirtStage =>
      hygiene >= 65 ? 0 : (((65 - hygiene.clamp(0, 65)) * 6 + 64) ~/ 65);
  PetFx withHygiene(int value) =>
      PetFx(wet: wet, foam: foam, messy: messy, sick: sick, hygiene: value);

  /// Malito: tono apagado y temblor.
  final bool sick;

  /// Espuma por zona: lomo, patas, pecho (0..1).
  final List<double> foam;

  /// Mechones sin cepillar: flequillo, orejas, lomo (1 = despeinado).
  final List<double> messy;

  static const none = PetFx();

  /// Mismos efectos con otro estado de salud.
  PetFx withSick(bool value) =>
      PetFx(wet: wet, foam: foam, messy: messy, sick: value, hygiene: hygiene);
}

enum _Eyes { open, blink, happy, closed }

/// Caniche vectorial provisional por capas. Unidad: altura ≈ 1, origen en el
/// punto medio entre las patas sobre el suelo, Y hacia abajo (canvas).
/// Las capas siguen el orden de appearance-v1.json; el color del pelaje solo
/// tiñe pelo y piel, nunca ojos, nariz, ropa ni accesorios.
class PetPainter extends ChangeNotifier {
  PetPainter(this.catalog);
  final AppearanceCatalog catalog;
  final IntegratedAccessories integratedAccessories = IntegratedAccessories();

  /// Comparativa visual reproducible de los tres artículos del piloto.
  bool integratedPilot = true;

  PetSprites? _sprites;

  /// Atlas ilustrado por capas. Mientras no esté cargado (o si falta una
  /// pieza) se dibuja el caniche vectorial provisional.
  PetSprites? get sprites => _sprites;
  set sprites(PetSprites? value) {
    _sprites?.onImageLoaded = null;
    _sprites = value;
    value?.onImageLoaded = notifyListeners;
    notifyListeners();
  }

  /// Centros de zonas interactivas en pose frontal (unidades).
  static const Map<String, Offset> frontZones = {
    'back': Offset(0, -0.6),
    'paws': Offset(0, -0.05),
    'chest': Offset(0, -0.46),
    'forelock': Offset(0, -0.95),
    'ears': Offset(0.18, -0.72),
    'body': Offset(0, -0.5),
    'head': Offset(0, -0.82),
  };

  void paint(
    Canvas canvas,
    PetLook look, {
    required PetPose pose,
    required PetAnim anim,
    required double t,
    required double size,
    bool reducedMotion = false,
    double airborne = 0,
    PetFx fx = PetFx.none,
  }) {
    // El dibujo vectorial no tiene espalda: usa el frente.
    final vectorPose = pose == PetPose.back ? PetPose.front : pose;
    final s = _Ctx(
      canvas,
      look,
      vectorPose,
      anim,
      t,
      reducedMotion ? 0.15 : 1.0,
      airborne,
      fx,
    );
    canvas.save();
    canvas.scale(size);
    canvas.translate(0, s.bodyDy);
    if (s.bodyRot != 0) {
      canvas.translate(0, -0.45);
      canvas.rotate(s.bodyRot);
      canvas.translate(0, 0.45);
    }
    if (_paintSprites(s, pose)) {
      canvas.restore();
      return;
    }
    final meta = catalog.poses[vectorPose]!;
    for (final layer in meta.drawOrder) {
      switch (layer) {
        case 'shadow':
          _shadow(s);
        case 'tail':
          _tail(s);
        case 'legsBack':
          _legs(s, back: true);
        case 'body':
          _body(s);
        case 'legsFront':
          _legs(s, back: false);
        case 'outfit':
          _outfit(s);
        case 'ears':
          _withHead(s, () => _ears(s));
        case 'head':
          _withHead(s, () => _head(s));
        case 'hair':
          _withHead(s, () => _hair(s));
        case 'face':
          _withHead(s, () => _face(s));
        case 'neck':
          _neck(s, meta.anchors['neck']!);
      }
    }
    _fx(s);
    _dirt(s, _vectorLandmarks[vectorPose] ?? const {});
    canvas.restore();
  }

  // ---------------------------------------------------------------- sprites

  /// Referencias del dibujo vectorial (respaldo si no hay atlas).
  static const Map<PetPose, Map<String, Offset>> _vectorLandmarks = {
    PetPose.front: {
      'eyes': Offset(0, -0.82),
      'mouth': Offset(0, -0.72),
      'neck': Offset(0, -0.64),
      'chest': Offset(0, -0.47),
      'flankRight': Offset(0.18, -0.5),
      'flankLeft': Offset(-0.18, -0.5),
      'paws': Offset(0, -0.04),
      'headTop': Offset(0, -0.97),
      'earRight': Offset(0.19, -0.72),
      'earLeft': Offset(-0.19, -0.72),
      'shoulderLeft': Offset(-0.2, -0.55),
      'shoulderRight': Offset(0.2, -0.55),
    },
    PetPose.side: {
      'mouth': Offset(0.47, -0.66),
      'neck': Offset(0.2, -0.6),
      'paws': Offset(0, -0.04),
      'headTop': Offset(0.29, -0.9),
    },
  };

  /// Pose del atlas que corresponde a una pose lógica y una reacción en el
  /// instante [t]: comer y dormir tienen pose propia, la espalda también y
  /// el galope recorre sus fotogramas.
  String spritePoseName(
    PetPose pose,
    PetAnim anim,
    double t, {
    bool reducedMotion = false,
  }) {
    final sp = _sprites;
    bool has(String p) => sp != null && sp.hasPose(p);
    if (pose == PetPose.back) return 'back';
    if (pose == PetPose.front) {
      if (anim == PetAnim.eat && has('eat')) return 'eat';
      if (anim == PetAnim.sleep && has('sleep')) return 'sleep';
      return 'front';
    }
    if (anim == PetAnim.jump || anim == PetAnim.catchDisc) return 'jump';
    final frames = has('run_a') && has('run_b');
    if (anim == PetAnim.run && !reducedMotion) {
      const gallop = ['run_b', 'run_a', 'jump'];
      return frames
          ? gallop[(t * 9).floor() % 3]
          : ((t * 11).floor().isOdd ? 'jump' : 'side');
    }
    if (anim == PetAnim.trot && !reducedMotion && frames) {
      const trot = ['side', 'run_b', 'side', 'run_a'];
      return trot[(t * 5).floor() % 4];
    }
    return 'side';
  }

  /// Si falta algo en una pose se prueba con la siguiente de la cadena. Un
  /// artículo sin capa en una pose «de reposo» (comer, dormir) simplemente
  /// no se dibuja; en las demás obliga a cambiar de pose.
  static const Map<String, List<String>> _poseChains = {
    'front': ['front'],
    'back': ['back', 'front'],
    'side': ['side', 'front'],
    'jump': ['jump', 'side'],
    'run_a': ['run_a', 'side'],
    'run_b': ['run_b', 'side'],
    'eat': ['eat', 'front'],
    'sleep': ['sleep', 'front'],
  };
  static const Set<String> _dropItemsIn = {'eat', 'sleep'};

  /// Pose que realmente se dibuja y artículos visibles en ella (orden de
  /// capas: prenda, patucos, collar, cuello, ojos, cabeza). Null si el
  /// atlas no puede dibujar este aspecto.
  ({String pose, List<String> items})? resolve(String desired, Appearance ids) {
    final sp = _sprites;
    if (sp == null || !sp.hasCoat(ids.coat)) return null;
    final equipped = [
      ids.outfit,
      ids.paws,
      ids.collar,
      ids.neck,
      ids.eyes,
      ids.head,
    ].where((id) => !id.endsWith('.none')).toList();
    for (final cand in _poseChains[desired] ?? [desired]) {
      if (!sp.hasPose(cand) ||
          (!sp.hasHair(ids.hair, cand) &&
              !(cand == 'eat' && sp.hasHair('hair.natural', 'eat')))) {
        continue;
      }

      return (
        pose: cand,
        items: _dropItemsIn.contains(cand)
            ? const []
            : equipped
                  .where((id) => cand != 'back' || !id.startsWith('eyes.'))
                  .toList(),
      );
    }
    return null;
  }

  /// Carga de antemano lo que hace falta para dibujar un aspecto sin
  /// parpadeos en estas poses.
  Future<void> warm(
    Appearance ids, {
    Iterable<String> poses = const [
      'front',
      'side',
      'back',
      'sleep',
      'eat',
      'jump',
      'run_a',
      'run_b',
    ],
  }) async {
    final sp = _sprites;
    if (sp == null) return;
    final names = <String>{};
    for (final p in poses) {
      final r = resolve(p, ids);
      if (r != null) names.add(r.pose);
    }
    if (integratedPilot) await integratedAccessories.warm(ids);
    await sp.preload(hair: ids.hair, poseNames: names);
    final coat = catalog.resolve(ids).coat;
    final palette = [
      coat.shade.toARGB32(),
      coat.base.toARGB32(),
      coat.light.toARGB32(),
    ];
    for (final p in names) {
      for (final layer in [
        sp.hairLayer(ids.hair, p),
        sp.stateLayer('messy', ids.hair, p),
        sp.expressionLayer('blink', p),
        sp.expressionLayer('happy', p),
        if (p == 'eat' && !sp.hasHair(ids.hair, p))
          sp.hairLayer(ids.hair, 'front'),
      ]) {
        if (layer != null) await sp.prepareCoat(layer, ids.coat, palette);
      }
    }
  }

  /// Punto del cuerpo en unidades (origen en los pies) para colocar efectos,
  /// marcas o el disco: del atlas si está cargado, si no del vectorial.
  Offset landmark(
    PetPose pose,
    String name, {
    PetAnim anim = PetAnim.idle,
    double t = 0,
    bool reducedMotion = false,
    Appearance? ids,
  }) {
    final sp = _sprites;
    if (sp != null) {
      var poseName = spritePoseName(
        pose,
        anim,
        t,
        reducedMotion: reducedMotion,
      );
      if (ids != null) poseName = resolve(poseName, ids)?.pose ?? poseName;
      final v = sp.poses[poseName]?.landmarks[name];
      if (v != null) return v;
    }
    return _vectorLandmarks[pose == PetPose.back
            ? PetPose.front
            : pose]?[name] ??
        Offset.zero;
  }

  /// Malito: menos color y un tinte verdoso pálido, bien visible sobre
  /// cualquier pelaje.
  static const List<double> _sickMatrix = [
    0.62, 0.34, 0.06, 0, -6, //
    0.17, 0.78, 0.07, 0, 6,
    0.15, 0.32, 0.50, 0, -2,
    0, 0, 0, 1, 0,
  ];

  /// Pinta el caniche ilustrado: base del peinado teñida con la matriz del
  /// pelaje, estado (despeinado), expresión y capas de artículos en orden.
  /// Devuelve false si el atlas aún no puede dibujar este aspecto (se usa
  /// el dibujo vectorial).
  bool _paintSprites(_Ctx s, PetPose requested) {
    final sp = _sprites;
    final ids = s.look.ids;
    if (sp == null || ids == null) return false;
    final desired = spritePoseName(
      requested,
      s.anim,
      s.t,
      reducedMotion: s.m < 0.5,
    );
    final r = resolve(desired, ids);
    if (r == null) return false;
    final poseName = r.pose;
    final coat = s.look.coat;
    final palette = [
      coat.shade.toARGB32(),
      coat.base.toARGB32(),
      coat.light.toARGB32(),
    ];
    final base = sp.coatedLayer(
      sp.hairLayer(ids.hair, poseName),
      ids.coat,
      palette,
    );
    final meta = sp.poses[poseName];
    if (base == null || meta == null) return false;

    final c = s.c;
    final k = 1 / sp.unitHeightPx;
    _spriteShadow(c, poseName);
    final canvasRect = Rect.fromLTWH(
      -meta.anchor.dx * k,
      -meta.anchor.dy * k,
      meta.size.width * k,
      meta.size.height * k,
    );
    Rect rectOf(Rect? box) => box == null
        ? canvasRect
        : Rect.fromLTWH(
            canvasRect.left + box.left * k,
            canvasRect.top + box.top * k,
            box.width * k,
            box.height * k,
          );
    Rect fullSrc(Image i) =>
        Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());

    // Movimiento por transformaciones del lienzo, con un reloj común.
    c.save();
    final breath = math.sin(s.t * 2 * math.pi / 2.6) * 0.012 * s.m;
    var tilt = 0.0;
    var squash = 1.0 + breath;
    var dy = 0.0;
    switch (s.anim) {
      case PetAnim.sniff:
        tilt = 0.06 + math.sin(s.t * 9) * 0.01 * s.m;
      case PetAnim.brush || PetAnim.happy:
        tilt = math.sin(s.t * 2.4) * 0.035 * s.m;
      case PetAnim.eat:
        // Masticar: la cabeza baja y sube un poco sobre el cuenco.
        dy = (math.sin(s.t * 11) * 0.5 + 0.5) * 0.012 * math.max(s.m, 0.4);
      case PetAnim.sleep:
        squash =
            1 + math.sin(s.t * 2 * math.pi / 3.4) * 0.018 * math.max(s.m, 0.4);
      default:
        break;
    }
    if (s.fx.sick) {
      // Malito: tiembla un poco y se encoge.
      tilt += math.sin(s.t * 19) * 0.012 * math.max(s.m, 0.3);
      squash *= 0.985;
    }
    if (tilt != 0) c.rotate(tilt);
    if (dy != 0) c.translate(0, dy);
    c.scale(1, squash);

    final coatPaint = Paint()..filterQuality = FilterQuality.medium;
    List<double>? matrix;
    if (s.fx.sick) matrix = PetSprites.chain(matrix, _sickMatrix);
    if (s.fx.wet) matrix = PetSprites.chain(matrix, _darken(0.82));
    if (matrix != null) coatPaint.colorFilter = ColorFilter.matrix(matrix);
    final articulate =
        poseName == 'side' &&
        (s.anim == PetAnim.run || s.anim == PetAnim.trot) &&
        s.m > 0.5;
    if (articulate) {
      final dst = rectOf(base.box);
      // El torso se conserva; las patas giran desde sus caderas/hombros.
      c.save();
      c.clipRect(Rect.fromLTRB(dst.left, dst.top, dst.right, -0.29));
      c.drawImageRect(base.image, fullSrc(base.image), dst, coatPaint);
      c.restore();
      for (var leg = 0; leg < 2; leg++) {
        final left = leg == 0 ? dst.left : 0.04;
        final right = leg == 0 ? 0.04 : dst.right;
        final pivot = Offset(leg == 0 ? -0.22 : 0.22, -0.32);
        final angle = math.sin(s.t * 2 * math.pi * 3.8 + leg * math.pi) * 0.42;
        c.save();
        c.translate(pivot.dx, pivot.dy);
        c.rotate(angle);
        c.translate(-pivot.dx, -pivot.dy);
        c.clipRect(Rect.fromLTRB(left, -0.33, right, dst.bottom));
        c.drawImageRect(base.image, fullSrc(base.image), dst, coatPaint);
        c.restore();
      }
    } else {
      c.drawImageRect(
        base.image,
        fullSrc(base.image),
        rectOf(base.box),
        coatPaint,
      );
    }

    // Los cortes sin pose de comida reutilizan el cuerpo inclinado y
    // conservan su cabeza y orejas; la boca sigue el anclaje del cuenco.
    if (poseName == 'eat' && !sp.hasHair(ids.hair, 'eat')) {
      final head = sp.coatedLayer(
        sp.hairLayer(ids.hair, 'front'),
        ids.coat,
        palette,
      );
      final front = sp.poses['front'];
      if (head != null && front != null) {
        final dst = Rect.fromLTWH(
          -front.anchor.dx * k,
          -front.anchor.dy * k,
          front.size.width * k,
          front.size.height * k,
        );
        c.save();
        c.translate(0, 0.5);
        c.clipRect(Rect.fromLTRB(dst.left, dst.top, dst.right, -0.53));
        c.drawImageRect(head.image, fullSrc(head.image), dst, coatPaint);
        c.restore();
      }
    }

    // Despeinado: la variante se ve solo alrededor de cada mechón pendiente
    // y se desvanece al cepillar.
    final messy = sp.coatedLayer(
      sp.stateLayer('messy', ids.hair, poseName),
      ids.coat,
      palette,
    );
    if (messy != null && s.fx.messy.any((m) => m > 0.01)) {
      final spots = <(Offset, double)>[];
      const names = [
        ['headTop'],
        ['earLeft', 'earRight'],
        ['shoulderLeft', 'shoulderRight'],
      ];
      for (var i = 0; i < 3; i++) {
        final m = s.fx.messy[i];
        if (m <= 0.01) continue;
        for (final n in names[i]) {
          final p = meta.landmarks[n];
          if (p != null) spots.add((p, m));
        }
      }
      c.saveLayer(canvasRect, Paint());
      c.drawImageRect(
        messy.image,
        fullSrc(messy.image),
        rectOf(messy.box),
        coatPaint,
      );
      c.saveLayer(canvasRect, Paint()..blendMode = BlendMode.dstIn);
      for (final (p, m) in spots) {
        final a = m.clamp(0, 1).toDouble();
        c.drawCircle(
          p,
          0.16,
          Paint()
            ..shader = Gradient.radial(
              p,
              0.16,
              [
                const Color(0xFFFFFFFF).withValues(alpha: a),
                const Color(0xFFFFFFFF).withValues(alpha: a),
                const Color(0x00FFFFFF),
              ],
              [0, 0.55, 1],
            ),
        );
      }
      c.restore();
      c.restore();
    }

    if (poseName == 'front') {
      final expr = switch (s.eyes) {
        _Eyes.blink || _Eyes.closed => 'blink',
        _Eyes.happy => 'happy',
        _ => s.tongue ? 'happy' : null,
      };
      final img = expr == null
          ? null
          : sp.coatedLayer(
              sp.expressionLayer(expr, poseName),
              ids.coat,
              palette,
            );
      if (img != null) {
        c.drawImageRect(
          img.image,
          fullSrc(img.image),
          rectOf(img.box),
          coatPaint,
        );
      }
    }
    final pilot =
        integratedPilot &&
        IntegratedAccessories.supportsPose(poseName) &&
        integratedAccessories.readyFor(ids);
    if (pilot) {
      integratedAccessories.paintTailoredOutfit(
        c,
        catalog,
        ids,
        poseName,
        meta.landmarks,
        base,
        rectOf(base.box),
        coatPaint,
      );
      integratedAccessories.paintSweater(
        c,
        catalog,
        ids,
        poseName,
        meta.landmarks,
        base,
        rectOf(base.box),
        coatPaint,
      );
    }
    PetAccessories.paint(
      c,
      catalog,
      ids,
      poseName,
      meta.landmarks,
      s.t,
      skipPilot: pilot,
    );
    if (pilot) {
      integratedAccessories.paintTailoredNeck(
        c,
        ids,
        poseName,
        meta.landmarks['headTop']!,
        base,
        rectOf(base.box),
        coatPaint,
      );
      integratedAccessories.paintBandana(
        c,
        ids,
        poseName,
        meta.landmarks,
        base,
        rectOf(base.box),
        coatPaint,
      );
      integratedAccessories.paintBeanie(
        c,
        ids,
        poseName,
        meta.landmarks,
        base,
        rectOf(base.box),
        coatPaint,
      );
      FittedAccessories.paint(c, ids, poseName, meta.landmarks['headTop']!, (
        mask,
      ) {
        c.save();
        c.clipPath(mask);
        c.drawImageRect(
          base.image,
          fullSrc(base.image),
          rectOf(base.box),
          coatPaint,
        );
        c.restore();
      });
    }
    _dirt(s, meta.landmarks);
    c.restore();
    _foamAtLandmarks(s, meta.landmarks);
    _sickMarks(s, meta.landmarks);
    return true;
  }

  void _dirt(_Ctx s, Map<String, Offset> lm) {
    final stage = s.fx.dirtStage;
    if (stage == 0) return;
    final centers = [
      lm['chest'],
      lm['paws'],
      lm['flankLeft'],
      lm['flankRight'],
      lm['earLeft'],
      lm['earRight'],
    ].whereType<Offset>().toList();
    if (centers.isEmpty) centers.add(const Offset(0, -0.4));
    final mud = Paint()
      ..color = Color.fromRGBO(100, 73, 46, 0.12 + stage * 0.075);
    final frizz = Paint()
      ..color = s.look.coat.shade
      ..strokeWidth = 0.004
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < stage * 5; i++) {
      final p =
          centers[i % centers.length] +
          Offset((_rand(i * 17) - 0.5) * 0.09, (_rand(i * 23) - 0.5) * 0.08);
      s.c.drawOval(
        Rect.fromCenter(
          center: p,
          width: 0.018 + _rand(i) * stage * 0.014,
          height: 0.015 + stage * 0.006,
        ),
        mud,
      );
      s.c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            p.dx + 0.015,
            p.dy - 0.03,
            p.dx + 0.025,
            p.dy - 0.012 - stage * 0.009,
          ),
        frizz,
      );
    }
  }

  /// Gotas de sudor y un hilo de nubecilla sobre la cabeza cuando está malito.
  void _sickMarks(_Ctx s, Map<String, Offset> lm) {
    if (!s.fx.sick) return;
    final top = lm['headTop'];
    if (top == null) return;
    final c = s.c;
    final drop = Paint()
      ..color = const Color(0xFF7FB6E8).withValues(alpha: 0.95);
    final edge = Paint()
      ..color = const Color(0xFF3F78B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.006;
    for (var i = 0; i < 2; i++) {
      final ph = (s.t * 0.7 + i * 0.5) % 1.0;
      final x = top.dx + (i == 0 ? -0.16 : 0.17);
      final y = top.dy + 0.07 + ph * 0.08;
      final w = 0.04;
      final path = Path()
        ..moveTo(x, y - 0.08)
        ..quadraticBezierTo(x + w * 1.4, y - 0.01, x, y + 0.02)
        ..quadraticBezierTo(x - w * 1.4, y - 0.01, x, y - 0.08);
      c.drawPath(path, drop);
      c.drawPath(path, edge);
    }
  }

  void _spriteShadow(Canvas c, String pose) {
    final w = switch (pose) {
      'sleep' => 0.8,
      'side' || 'run_a' || 'run_b' || 'jump' => 0.7,
      'eat' => 0.55,
      _ => 0.5,
    };
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.01), width: w, height: 0.07),
      Paint()..color = catalog.fixed['shadow']!.withValues(alpha: 0.18),
    );
  }

  /// Espuma vectorial de respaldo colocada en las referencias del atlas.
  /// (El baño estampa su espuma ilustrada y entonces pasa foam a cero.)
  void _foamAtLandmarks(_Ctx s, Map<String, Offset> lm) {
    if (!s.fx.foam.any((f) => f > 0)) return;
    final bubble = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92);
    final ring = Paint()
      ..color = const Color(0xFFB9A6D6)
      ..strokeWidth = 0.005
      ..style = PaintingStyle.stroke;
    final zones = [
      [lm['flankLeft'], lm['flankRight']],
      [lm['paws']],
      [lm['chest']],
      [lm['headTop']],
    ];
    for (var z = 0; z < math.min(zones.length, s.fx.foam.length); z++) {
      final f = s.fx.foam[z];
      if (f <= 0) continue;
      for (final p in zones[z].whereType<Offset>()) {
        for (var i = 0; i < (8 * f).round(); i++) {
          final o =
              p +
              Offset(
                (_rand(z * 97 + i) - 0.5) * 0.12,
                (_rand(i * 13 + z) - 0.5) * 0.07,
              );
          final r = 0.02 + _rand(i * 7 + z * 3) * 0.02;
          s.c.drawCircle(o, r, bubble);
          s.c.drawCircle(o, r, ring);
        }
      }
    }
  }

  static List<double> _darken(double k) => [
    k, 0, 0, 0, 0, //
    0, k, 0, 0, 0,
    0, 0, k, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // ---------------------------------------------------------------- capas

  void _shadow(_Ctx s) {
    final lift = s.pose == PetPose.side
        ? (s.airborne.abs() * 0.15).clamp(0, 0.5)
        : 0.0;
    s.c.drawOval(
      Rect.fromCenter(
        center: Offset(0, 0.01 - s.bodyDy),
        width: (s.pose == PetPose.side ? 0.72 : 0.6) * (1 - lift),
        height: 0.07 * (1 - lift),
      ),
      Paint()..color = catalog.fixed['shadow']!.withValues(alpha: 0.18),
    );
  }

  void _tail(_Ctx s) {
    final wag =
        math.sin(s.t * (s.excited ? 14 : 4)) * (s.excited ? 0.05 : 0.02) * s.m;
    if (s.pose == PetPose.front) {
      _curly(
        s,
        Offset(0.19 + wag, -0.67),
        0.07,
        0.075,
        s.look.coat.base,
        seed: 11,
      );
    } else {
      final stem = Paint()
        ..color = s.look.hair == HairStyle.pom
            ? s.look.coat.skin
            : s.look.coat.base
        ..strokeWidth = 0.035
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final tip = Offset(-0.36 + wag, -0.66 - wag.abs());
      s.c.drawLine(const Offset(-0.25, -0.5), tip, stem);
      _curly(s, tip, 0.075, 0.08, s.look.coat.base, seed: 12);
    }
  }

  void _legs(_Ctx s, {required bool back}) {
    final coat = s.look.coat;
    final pom = s.look.hair == HairStyle.pom;
    if (s.pose == PetPose.front) {
      final xs = back ? const [-0.155, 0.155] : const [-0.075, 0.075];
      final top = back ? -0.36 : -0.38;
      for (final x in xs) {
        final color = back
            ? Color.lerp(coat.base, coat.shade, 0.35)!
            : coat.base;
        _legColumn(
          s,
          Offset(x, top),
          Offset(x, -0.02),
          back ? 0.08 : 0.09,
          color,
          pom,
          seed: (x * 100).round(),
        );
      }
      return;
    }
    // Perfil: dos patas por par, con balanceo del reloj común.
    final pivots = back ? const [-0.2, -0.13] : const [0.12, 0.19];
    for (var i = 0; i < 2; i++) {
      final far = i == 0;
      final angle = s.legAngle(back: back, far: far);
      final pivot = Offset(pivots[i], -0.36);
      final len = 0.35;
      final foot = pivot + Offset(math.sin(angle) * len, math.cos(angle) * len);
      final color = far ? Color.lerp(coat.base, coat.shade, 0.45)! : coat.base;
      _legColumn(s, pivot, foot, 0.075, color, pom, seed: i + (back ? 20 : 30));
    }
  }

  void _legColumn(
    _Ctx s,
    Offset top,
    Offset foot,
    double width,
    Color color,
    bool pom, {
    required int seed,
  }) {
    final coat = s.look.coat;
    final p = Paint()
      ..color = pom ? coat.skin : color
      ..strokeWidth = pom ? width * 0.7 : width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    s.c.drawLine(top, foot, p);
    if (pom) {
      _curly(
        s,
        foot + const Offset(0, -0.045),
        0.065,
        0.055,
        color,
        seed: seed + 3,
      );
    } else {
      // Rizos a lo largo de la pata.
      for (var k = 0; k <= 4; k++) {
        final q = Offset.lerp(top, foot, k / 4)!;
        _curl(
          s,
          q + Offset((k.isEven ? 1 : -1) * width * 0.15, 0),
          width * 0.26,
          Color.lerp(color, coat.shade, 0.45)!,
        );
      }
    }
    // Pata: almohadilla clara, color fijo de uñas.
    s.c.drawOval(
      Rect.fromCenter(
        center: foot + const Offset(0.01, -0.005),
        width: width * 1.15,
        height: 0.04,
      ),
      Paint()..color = Color.lerp(color, coat.light, 0.3)!,
    );
    final toe = Paint()
      ..color = catalog.fixed['paw']!.withValues(alpha: 0.45)
      ..strokeWidth = 0.006
      ..style = PaintingStyle.stroke;
    s.c.drawLine(
      foot + Offset(-width * 0.18, -0.012),
      foot + Offset(-width * 0.18, 0.01),
      toe,
    );
    s.c.drawLine(
      foot + Offset(width * 0.18, -0.012),
      foot + Offset(width * 0.18, 0.01),
      toe,
    );
  }

  void _body(_Ctx s) {
    final coat = s.look.coat;
    final breath = math.sin(s.t * 2 * math.pi / 2.6) * 0.006 * s.m;
    if (s.pose == PetPose.front) {
      if (s.look.hair == HairStyle.pom) {
        _curly(s, Offset(0, -0.5 - breath), 0.215, 0.2, coat.base, seed: 40);
      } else {
        _curly(
          s,
          Offset(0, -0.47 - breath),
          0.22,
          0.17 + breath,
          coat.base,
          seed: 41,
        );
      }
      return;
    }
    if (s.look.hair == HairStyle.pom) {
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(-0.1, -0.44),
          width: 0.36,
          height: 0.21,
        ),
        Paint()..color = coat.skin,
      );
      _curly(s, const Offset(-0.22, -0.47), 0.07, 0.07, coat.base, seed: 42);
      _curly(s, Offset(0.08, -0.47 - breath), 0.18, 0.16, coat.base, seed: 43);
    } else {
      _curly(s, Offset(-0.02, -0.45 - breath), 0.28, 0.14, coat.base, seed: 44);
    }
  }

  void _outfit(_Ctx s) {
    if (s.look.outfitStyle != OutfitStyle.overalls) return;
    final g = s.look.outfit!;
    final fill = Paint()..color = g.color;
    final seam = Paint()
      ..color = g.shade
      ..strokeWidth = 0.008
      ..style = PaintingStyle.stroke;
    final trim = Paint()..color = g.trim;
    if (s.pose == PetPose.front) {
      // Perneras sobre la parte alta de las patas delanteras.
      for (final x in const [-0.075, 0.075]) {
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, -0.31), width: 0.115, height: 0.12),
          const Radius.circular(0.03),
        );
        s.c.drawRRect(r, fill);
        s.c.drawLine(Offset(x - 0.05, -0.255), Offset(x + 0.05, -0.255), seam);
      }
      final bib = RRect.fromRectAndRadius(
        Rect.fromLTRB(-0.135, -0.56, 0.135, -0.36),
        const Radius.circular(0.05),
      );
      s.c.drawRRect(bib, fill);
      // Pana: líneas verticales.
      for (var x = -0.1; x <= 0.1; x += 0.04) {
        s.c.drawLine(
          Offset(x, -0.54),
          Offset(x, -0.38),
          seam..color = g.shade.withValues(alpha: 0.6),
        );
      }
      final strap = Paint()
        ..color = g.color
        ..strokeWidth = 0.035
        ..strokeCap = StrokeCap.round;
      s.c.drawLine(
        const Offset(-0.1, -0.55),
        const Offset(-0.07, -0.64),
        strap,
      );
      s.c.drawLine(const Offset(0.1, -0.55), const Offset(0.07, -0.64), strap);
      s.c.drawCircle(const Offset(-0.1, -0.545), 0.02, trim);
      s.c.drawCircle(const Offset(0.1, -0.545), 0.02, trim);
      s.c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-0.055, -0.5, 0.055, -0.43),
          const Radius.circular(0.015),
        ),
        seam..color = g.shade,
      );
    } else {
      s.c.save();
      s.c.clipPath(
        Path()..addOval(
          Rect.fromCenter(
            center: const Offset(-0.02, -0.45),
            width: 0.6,
            height: 0.32,
          ),
        ),
      );
      s.c.drawRect(const Rect.fromLTRB(-0.16, -0.62, 0.22, -0.28), fill);
      for (var x = -0.13; x <= 0.2; x += 0.045) {
        s.c.drawLine(
          Offset(x, -0.6),
          Offset(x, -0.3),
          seam..color = g.shade.withValues(alpha: 0.6),
        );
      }
      s.c.restore();
      final strap = Paint()
        ..color = g.color
        ..strokeWidth = 0.03
        ..strokeCap = StrokeCap.round;
      s.c.drawLine(const Offset(0.16, -0.58), const Offset(0.2, -0.63), strap);
      s.c.drawCircle(const Offset(0.16, -0.565), 0.018, trim);
    }
  }

  void _ears(_Ctx s) {
    final coat = s.look.coat;
    final lift = s.excited ? 0.05 * s.m : 0.0;
    final flutter =
        (s.anim == PetAnim.run ||
            s.anim == PetAnim.jump ||
            s.anim == PetAnim.catchDisc)
        ? math.sin(s.t * 12) * 0.03 * s.m
        : 0.0;
    if (s.pose == PetPose.front) {
      for (final side in const [-1.0, 1.0]) {
        _curly(
          s,
          Offset(side * (0.19 + lift * 0.4), -0.71 - lift),
          0.08,
          0.15,
          Color.lerp(coat.base, coat.shade, 0.12)!,
          seed: side > 0 ? 50 : 51,
        );
      }
    } else {
      _curly(
        s,
        Offset(0.24 - flutter, -0.66 - flutter.abs()),
        0.065,
        0.13,
        Color.lerp(coat.base, coat.shade, 0.15)!,
        seed: 52,
      );
    }
  }

  void _head(_Ctx s) {
    final coat = s.look.coat;
    if (s.pose == PetPose.front) {
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -0.8),
          width: 0.36,
          height: 0.33,
        ),
        Paint()..color = coat.base,
      );
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -0.742),
          width: 0.17,
          height: 0.13,
        ),
        Paint()..color = coat.light,
      );
      // Mejillas.
      final blush = Paint()..color = const Color(0x33E77A86);
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(-0.1, -0.76),
          width: 0.06,
          height: 0.035,
        ),
        blush,
      );
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(0.1, -0.76),
          width: 0.06,
          height: 0.035,
        ),
        blush,
      );
    } else {
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(0.3, -0.72),
          width: 0.26,
          height: 0.26,
        ),
        Paint()..color = coat.base,
      );
      s.c.drawOval(
        Rect.fromCenter(
          center: const Offset(0.43, -0.69),
          width: 0.19,
          height: 0.1,
        ),
        Paint()..color = coat.light,
      );
    }
  }

  void _hair(_Ctx s) {
    final coat = s.look.coat;
    final pom = s.look.hair == HairStyle.pom;
    if (s.pose == PetPose.front) {
      if (pom) {
        _curly(s, const Offset(0, -0.99), 0.165, 0.125, coat.base, seed: 60);
      } else {
        _curly(s, const Offset(0, -0.94), 0.16, 0.08, coat.base, seed: 61);
      }
    } else {
      if (pom) {
        _curly(s, const Offset(0.28, -0.88), 0.125, 0.11, coat.base, seed: 62);
      } else {
        _curly(s, const Offset(0.28, -0.84), 0.125, 0.07, coat.base, seed: 63);
      }
    }
  }

  void _face(_Ctx s) {
    final eye = Paint()..color = catalog.fixed['eye']!;
    final hi = Paint()..color = const Color(0xFFFFFFFF);
    final line = Paint()
      ..color = catalog.fixed['eye']!
      ..strokeWidth = 0.012
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nose = Paint()..color = catalog.fixed['nose']!;
    final tongue = Paint()..color = catalog.fixed['tongue']!;
    final front = s.pose == PetPose.front;
    final eyes = front
        ? const [Offset(-0.07, -0.818), Offset(0.07, -0.818)]
        : const [Offset(0.35, -0.755)];
    final look = s.anim == PetAnim.lookUp
        ? const Offset(0, -0.006)
        : Offset.zero;
    for (final e in eyes) {
      switch (s.eyes) {
        case _Eyes.open:
          s.c.drawOval(
            Rect.fromCenter(center: e, width: 0.058, height: 0.07),
            eye,
          );
          s.c.drawCircle(e + const Offset(-0.012, -0.018) + look, 0.013, hi);
          s.c.drawCircle(e + const Offset(0.012, 0.014), 0.006, hi);
        case _Eyes.blink:
          s.c.drawLine(
            e + const Offset(-0.024, 0),
            e + const Offset(0.024, 0),
            line,
          );
        case _Eyes.happy:
          s.c.drawArc(
            Rect.fromCenter(
              center: e + const Offset(0, 0.01),
              width: 0.05,
              height: 0.045,
            ),
            math.pi,
            math.pi,
            false,
            line,
          );
        case _Eyes.closed:
          s.c.drawArc(
            Rect.fromCenter(
              center: e - const Offset(0, 0.008),
              width: 0.05,
              height: 0.03,
            ),
            0,
            math.pi,
            false,
            line,
          );
      }
    }
    final chew = s.anim == PetAnim.eat
        ? (math.sin(s.t * 11) * 0.5 + 0.5) * 0.012 * math.max(s.m, 0.5)
        : 0.0;
    if (front) {
      final n = Path()
        ..moveTo(-0.032, -0.775)
        ..quadraticBezierTo(0, -0.79, 0.032, -0.775)
        ..quadraticBezierTo(0.02, -0.748, 0, -0.745)
        ..quadraticBezierTo(-0.02, -0.748, -0.032, -0.775)
        ..close();
      s.c.drawPath(n, nose);
      s.c.drawCircle(const Offset(-0.01, -0.772), 0.006, hi);
      final mouth = Path()
        ..moveTo(-0.04, -0.722 + chew)
        ..quadraticBezierTo(-0.02, -0.708 + chew, 0, -0.72)
        ..quadraticBezierTo(0.02, -0.708 + chew, 0.04, -0.722 + chew);
      s.c.drawPath(mouth, line..strokeWidth = 0.008);
      if (s.tongue) {
        s.c.drawOval(
          Rect.fromCenter(
            center: const Offset(0, -0.7),
            width: 0.045,
            height: 0.05,
          ),
          tongue,
        );
      }
    } else {
      s.c.drawCircle(const Offset(0.515, -0.705), 0.024, nose);
      s.c.drawCircle(const Offset(0.508, -0.712), 0.006, hi);
      s.c.drawLine(
        Offset(0.45, -0.665 + chew),
        const Offset(0.5, -0.67),
        line..strokeWidth = 0.008,
      );
      if (s.tongue) {
        s.c.drawOval(
          Rect.fromCenter(
            center: const Offset(0.47, -0.65),
            width: 0.05,
            height: 0.035,
          ),
          tongue,
        );
      }
    }
  }

  void _neck(_Ctx s, Offset anchor) {
    if (s.look.neckStyle != NeckStyle.scarf) return;
    final g = s.look.neck!;
    final fill = Paint()..color = g.color;
    final shade = Paint()..color = g.shade;
    if (s.pose == PetPose.front) {
      final band = RRect.fromRectAndRadius(
        Rect.fromCenter(center: anchor, width: 0.24, height: 0.045),
        const Radius.circular(0.02),
      );
      s.c.drawRRect(band, fill);
      final tri = Path()
        ..moveTo(anchor.dx - 0.1, anchor.dy)
        ..lineTo(anchor.dx + 0.1, anchor.dy)
        ..lineTo(anchor.dx, anchor.dy + 0.14)
        ..close();
      s.c.drawPath(tri, fill);
      s.c.drawPath(
        Path()
          ..moveTo(anchor.dx, anchor.dy + 0.02)
          ..lineTo(anchor.dx + 0.06, anchor.dy + 0.02)
          ..lineTo(anchor.dx, anchor.dy + 0.13)
          ..close(),
        shade,
      );
      // Nudo y puntas.
      final tails = Path()
        ..moveTo(anchor.dx + 0.08, anchor.dy)
        ..lineTo(anchor.dx + 0.17, anchor.dy + 0.05)
        ..lineTo(anchor.dx + 0.13, anchor.dy + 0.08)
        ..close();
      s.c.drawPath(tails, shade);
      s.c.drawCircle(anchor + const Offset(0.08, 0), 0.025, fill);
    } else {
      final tri = Path()
        ..moveTo(anchor.dx - 0.05, anchor.dy - 0.03)
        ..lineTo(anchor.dx + 0.07, anchor.dy - 0.01)
        ..lineTo(anchor.dx + 0.03, anchor.dy + 0.11)
        ..close();
      s.c.drawPath(tri, fill);
      s.c.drawLine(
        Offset(anchor.dx - 0.05, anchor.dy - 0.03),
        Offset(anchor.dx + 0.07, anchor.dy - 0.01),
        Paint()
          ..color = g.shade
          ..strokeWidth = 0.03
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _fx(_Ctx s) {
    if (s.pose != PetPose.front) return;
    final fx = s.fx;
    if (fx.wet) {
      final drop = Paint()
        ..color = const Color(0xFF8FC7E8).withValues(alpha: 0.8);
      for (var i = 0; i < 7; i++) {
        final x = -0.22 + i * 0.075;
        final y = -0.9 + ((s.t * 0.6 + i * 0.37) % 1) * 0.6;
        s.c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 0.018, height: 0.03),
          drop,
        );
      }
    }
    final zones = [
      const Offset(0, -0.56),
      const Offset(0, -0.04),
      const Offset(0, -0.47),
    ];
    final spread = [0.06, 0.16, 0.1];
    final bubble = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92);
    final ring = Paint()
      ..color = const Color(0xFFB9A6D6)
      ..strokeWidth = 0.005
      ..style = PaintingStyle.stroke;
    for (var z = 0; z < 3; z++) {
      final f = fx.foam[z];
      if (f <= 0) continue;
      final n = (14 * f).round();
      for (var i = 0; i < n; i++) {
        final r = _rand(z * 97 + i);
        // El lomo se ve por ambos flancos: dos grupos simétricos.
        final side = z == 0 ? (i.isEven ? 1.0 : -1.0) : 0.0;
        final o =
            zones[z] +
            Offset(side * 0.17, 0) +
            Offset((r - 0.5) * 2 * spread[z], (_rand(i * 13 + z) - 0.5) * 0.08);
        final rad = 0.02 + _rand(i * 7 + z * 3) * 0.025;
        s.c.drawCircle(o, rad, bubble);
        s.c.drawCircle(o, rad, ring);
      }
    }
    // Mechones despeinados: flequillo, orejas, lomo.
    final frizz = Paint()
      ..color = s.look.coat.shade
      ..strokeWidth = 0.014
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final spots = [
      [
        const Offset(-0.05, -1.0),
        const Offset(0.0, -1.03),
        const Offset(0.05, -1.0),
      ],
      [
        const Offset(-0.23, -0.65),
        const Offset(0.23, -0.65),
        const Offset(0.21, -0.6),
      ],
      [
        const Offset(-0.2, -0.55),
        const Offset(0.2, -0.55),
        const Offset(0.0, -0.64),
      ],
    ];
    for (var k = 0; k < 3; k++) {
      final m = fx.messy[k];
      if (m <= 0.01) continue;
      for (final p in spots[k]) {
        final dir = p.dx == 0 ? const Offset(0, -1) : Offset(p.dx.sign, -0.6);
        final path = Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            p.dx + dir.dx * 0.03 * m + 0.02,
            p.dy + dir.dy * 0.03 * m,
            p.dx + dir.dx * 0.06 * m,
            p.dy + dir.dy * 0.06 * m,
          );
        s.c.drawPath(path, frizz);
      }
    }
  }

  // ---------------------------------------------------------------- utilidades

  void _withHead(_Ctx s, void Function() draw) {
    if (s.headOffset == Offset.zero && s.headRot == 0) {
      draw();
      return;
    }
    final pivot = s.pose == PetPose.front
        ? const Offset(0, -0.66)
        : const Offset(0.2, -0.62);
    s.c.save();
    s.c.translate(pivot.dx + s.headOffset.dx, pivot.dy + s.headOffset.dy);
    s.c.rotate(s.headRot);
    s.c.translate(-pivot.dx, -pivot.dy);
    draw();
    s.c.restore();
  }

  static double _rand(int seed) {
    final x = math.sin(seed * 12.9898 + 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  static final Map<int, List<(Offset, double)>> _curlCache = {};

  /// Masa rizada: borde festoneado y textura de rizos con sombreado.
  void _curly(
    _Ctx s,
    Offset center,
    double rx,
    double ry,
    Color base, {
    required int seed,
  }) {
    final coat = s.look.coat;
    final wet = s.fx.wet;
    final color = wet ? Color.lerp(base, coat.shade, 0.35)! : base;
    final fill = Paint()..color = color;
    final r = math.min(rx, ry) * 0.36;
    final perimeter = math.pi * (rx + ry);
    final bumps = (perimeter / (r * 1.25)).clamp(6, 40).round();
    for (var i = 0; i < bumps; i++) {
      final a = i / bumps * 2 * math.pi + seed;
      s.c.drawCircle(
        center +
            Offset(
              math.cos(a) * (rx - r * 0.55),
              math.sin(a) * (ry - r * 0.55),
            ),
        r,
        fill,
      );
    }
    s.c.drawOval(
      Rect.fromCenter(center: center, width: rx * 2 - r, height: ry * 2 - r),
      fill,
    );
    final key = seed * 1000 + (rx * 100).round() * 10 + (ry * 100).round();
    final pts = _curlCache.putIfAbsent(key, () {
      final out = <(Offset, double)>[];
      final n = ((rx * ry) / 0.0026).clamp(3, 30).round();
      for (var i = 0; i < n; i++) {
        final a = _rand(seed * 31 + i) * 2 * math.pi;
        final d = math.sqrt(_rand(seed * 17 + i * 3));
        out.add((
          Offset(math.cos(a) * rx * 0.85 * d, math.sin(a) * ry * 0.85 * d),
          _rand(i + seed) * math.pi * 2,
        ));
      }
      return out;
    });
    for (final (o, rot) in pts) {
      _curl(
        s,
        center + o,
        r * 0.34,
        wet ? coat.shade : Color.lerp(color, coat.shade, 0.42)!,
        rot: rot,
      );
    }
  }

  void _curl(_Ctx s, Offset c, double r, Color color, {double rot = 0}) {
    final p = Paint()
      ..color = color
      ..strokeWidth = r * 0.38
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    s.c.drawArc(
      Rect.fromCircle(center: c, radius: r),
      rot,
      math.pi * 1.1,
      false,
      p,
    );
    s.c.drawCircle(
      c + Offset(-r * 0.3, -r * 0.4),
      r * 0.28,
      Paint()
        ..color = s.look.coat.light.withValues(alpha: s.fx.wet ? 0.2 : 0.55),
    );
  }
}

class _Ctx {
  _Ctx(
    this.c,
    this.look,
    this.pose,
    this.anim,
    this.t,
    this.m,
    this.airborne,
    this.fx,
  ) {
    final hop = switch (anim) {
      PetAnim.happy => -(math.sin(t * 2 * math.pi * 1.4).abs()) * 0.03 * m,
      PetAnim.celebrate => -(math.sin(t * 2 * math.pi * 1.6).abs()) * 0.07 * m,
      PetAnim.trot => -(math.sin(t * 2 * math.pi * 3.2).abs()) * 0.012 * m,
      PetAnim.run => -(math.sin(t * 2 * math.pi * 5).abs()) * 0.02 * m,
      PetAnim.sleep => 0.04,
      _ => 0.0,
    };
    bodyDy = hop;
    bodyRot = switch (anim) {
      PetAnim.jump || PetAnim.catchDisc when pose == PetPose.side =>
        (-airborne * 0.05).clamp(-0.35, 0.35).toDouble(),
      PetAnim.bath => math.sin(t * 9) * 0.03 * m,
      _ => 0,
    };
    headOffset = switch (anim) {
      PetAnim.eat => Offset(0, 0.06 + math.sin(t * 11) * 0.006 * m),
      PetAnim.sniff => Offset(0.02, 0.1 + math.sin(t * 9) * 0.01 * m),
      PetAnim.lookUp => const Offset(0, -0.01),
      PetAnim.sleep => const Offset(0, 0.05),
      PetAnim.catchDisc => const Offset(0, -0.02),
      _ => Offset.zero,
    };
    headRot = switch (anim) {
      PetAnim.brush => math.sin(t * 2.2) * 0.09 * m,
      PetAnim.happy => math.sin(t * 3) * 0.06 * m,
      PetAnim.sniff => 0.35,
      PetAnim.idle => math.sin(t * 0.9) * 0.025 * m,
      _ => 0.0,
    };
    excited =
        anim == PetAnim.happy ||
        anim == PetAnim.celebrate ||
        anim == PetAnim.catchDisc ||
        anim == PetAnim.run ||
        anim == PetAnim.trot;
    tongue =
        anim == PetAnim.happy ||
        anim == PetAnim.celebrate ||
        anim == PetAnim.run ||
        anim == PetAnim.catchDisc ||
        anim == PetAnim.trot;
    final blinking = (t % 3.7) < 0.13;
    eyes = switch (anim) {
      PetAnim.sleep => _Eyes.closed,
      PetAnim.happy || PetAnim.celebrate => _Eyes.happy,
      PetAnim.bath when (t % 2.4) < 0.9 => _Eyes.happy,
      _ when blinking => _Eyes.blink,
      _ => _Eyes.open,
    };
  }

  final Canvas c;
  final PetLook look;
  final PetPose pose;
  final PetAnim anim;
  final double t;
  final double m;
  final double airborne;
  final PetFx fx;
  late final double bodyDy;
  late final double bodyRot;
  late final Offset headOffset;
  late final double headRot;
  late final bool excited;
  late final bool tongue;
  late final _Eyes eyes;

  double legAngle({required bool back, required bool far}) {
    final phase = far ? math.pi : 0.0;
    switch (anim) {
      case PetAnim.trot:
        return math.sin(
              t * 2 * math.pi * 3.2 + phase + (back ? math.pi / 2 : 0),
            ) *
            0.45 *
            m;
      case PetAnim.run:
        return math.sin(t * 2 * math.pi * 5 + phase + (back ? math.pi : 0)) *
            0.6 *
            math.max(m, 0.4);
      case PetAnim.jump:
      case PetAnim.catchDisc:
        return back ? -0.85 - (far ? 0.1 : 0) : 0.95 + (far ? 0.1 : 0);
      case PetAnim.sniff:
        return back ? 0.05 : -0.05;
      default:
        return 0;
    }
  }
}
