import 'dart:async';
import 'dart:math' as math;

import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../domain/achievements.dart';
import '../theme.dart';
import 'celebrations.dart';

/// Icono y color de cada clave de pegatina del catálogo de logros.
(IconData, Color) stickerArt(String key) => switch (key) {
  'bowl' => (Icons.rice_bowl_rounded, AppColors.satiety),
  'bath' => (Icons.bathtub_rounded, AppColors.hygiene),
  'walk' => (Icons.pets_rounded, AppColors.energy),
  'vet' => (Icons.medical_services_rounded, AppColors.coral),
  'bed' => (Icons.bedtime_rounded, AppColors.focus),
  'heart' => (Icons.favorite_rounded, AppColors.mood),
  'calendar' => (Icons.calendar_month_rounded, AppColors.leaf),
  'fruit' || 'fruitStar' => (Icons.eco_rounded, const Color(0xFF5E9E3A)),
  'frisbee' || 'frisbeeStar' => (Icons.album_rounded, const Color(0xFFE08A2E)),
  'pairs' || 'pairsStar' => (Icons.style_rounded, AppColors.lavender),
  'memory' || 'memoryStar' => (Icons.psychology_rounded, AppColors.plum),
  'hanger' => (Icons.checkroom_rounded, const Color(0xFF3F8E8C)),
  'closet' => (Icons.door_sliding_rounded, const Color(0xFF9C6B3E)),
  'crown' => (Icons.workspace_premium_rounded, AppColors.coinDeep),
  'sofa' => (Icons.chair_rounded, const Color(0xFFB0567A)),
  'camera' => (Icons.photo_camera_rounded, const Color(0xFF4C6FA8)),
  'photos' => (Icons.photo_library_rounded, const Color(0xFF6A5BA8)),
  'trophy' => (Icons.emoji_events_rounded, const Color(0xFFC9932A)),
  'coins' => (Icons.savings_rounded, AppColors.coin),
  _ => (Icons.star_rounded, AppColors.coin),
};

/// Pegatina dibujada en código: borde ondulado, ribete blanco e icono. Las
/// pendientes se ven en silueta gris. Decorativa: la semántica la pone quien
/// la usa.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.sticker,
    required this.unlocked,
    this.size = 64,
  });
  final String sticker;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = stickerArt(sticker);
    final star = sticker.endsWith('Star');
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _StickerPainter(
            unlocked ? color : const Color(0xFFD8D1DA),
            unlocked,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: size * 0.48,
                color: unlocked ? Colors.white : const Color(0xFF9A90A0),
              ),
              if (star)
                Positioned(
                  right: size * 0.06,
                  bottom: size * 0.06,
                  child: Icon(
                    Icons.star_rounded,
                    size: size * 0.32,
                    color: unlocked
                        ? const Color(0xFFFFD45C)
                        : const Color(0xFFB9B0BE),
                  ),
                ),
              if (!unlocked)
                Positioned(
                  top: size * 0.04,
                  right: size * 0.04,
                  child: Icon(
                    Icons.lock_rounded,
                    size: size * 0.24,
                    color: const Color(0xFF8C8292),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.color, this.unlocked);
  final Color color;
  final bool unlocked;

  Path _scallop(Size size, double inset) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - inset;
    final path = Path();
    const steps = 96;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * 2 * math.pi;
      final rr = r * (0.93 + 0.05 * math.cos(12 * a));
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _scallop(size, 1);
    if (unlocked) {
      canvas.drawShadow(outer, const Color(0x6634283B), 3, false);
    }
    canvas.drawPath(outer, Paint()..color = Colors.white);
    canvas.drawPath(
      _scallop(size, size.shortestSide * 0.08),
      Paint()..color = color,
    );
    if (unlocked) {
      // Brillo de papel satinado.
      canvas.drawCircle(
        Offset(size.width * 0.36, size.height * 0.3),
        size.shortestSide * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_StickerPainter old) =>
      old.color != color || old.unlocked != unlocked;
}

/// Capa superior de la app: al confirmarse un logro muestra el aviso
/// «¡Nueva pegatina!» y un confeti breve (sin animación ni confeti con
/// movimiento reducido). No intercepta toques.
class StickerCelebrations extends StatefulWidget {
  const StickerCelebrations({
    super.key,
    required this.controller,
    required this.child,
  });
  final AppController controller;
  final Widget child;

  static const visible = Duration(milliseconds: 3200);

  @override
  State<StickerCelebrations> createState() => _StickerCelebrationsState();
}

class _StickerCelebrationsState extends State<StickerCelebrations> {
  List<String> _shown = const [];
  int _burst = 0;
  bool _confetti = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_check);
  }

  @override
  void didUpdateWidget(StickerCelebrations old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_check);
      widget.controller.addListener(_check);
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    widget.controller.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (widget.controller.newStickers.isEmpty) return;
    final ids = widget.controller.takeNewStickers();
    final reduced =
        widget.controller.reducedMotion ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    setState(() {
      _shown = ids;
      _burst++;
      _confetti = !reduced;
    });
    _hide?.cancel();
    _hide = Timer(StickerCelebrations.visible, () {
      if (mounted) setState(() => _shown = const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final first = _shown.isEmpty ? null : Achievements.byId(_shown.first);
    return Stack(
      children: [
        widget.child,
        if (_confetti)
          Positioned.fill(
            child: ConfettiBurst(
              key: ValueKey('sticker-confetti-$_burst'),
              reducedMotion: false,
              onDone: () {
                if (mounted) setState(() => _confetti = false);
              },
            ),
          ),
        if (first != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: _StickerToast(
                    achievement: first,
                    count: _shown.length,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StickerToast extends StatelessWidget {
  const _StickerToast({required this.achievement, required this.count});
  final Achievement achievement;
  final int count;

  @override
  Widget build(BuildContext context) {
    final headline = count > 1
        ? '¡$count pegatinas nuevas!'
        : '¡Nueva pegatina!';
    final label =
        '${localize(context, headline)} ${localize(context, achievement.title)}';
    return Semantics(
      liveRegion: true,
      container: true,
      label: label,
      excludeSemantics: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            key: const Key('sticker-toast'),
            color: AppColors.cream,
            elevation: 6,
            borderRadius: BorderRadius.circular(AppRadii.m),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.m),
              child: Row(
                children: [
                  Sticker(
                    sticker: achievement.sticker,
                    unlocked: true,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LText(headline, style: AppText.subtitle),
                        LText(
                          achievement.title,
                          style: AppText.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
