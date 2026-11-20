import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Corazones que brotan del punto acariciado, suben y se desvanecen en
/// ~1 s. Es solo decoración: sin toques ni semántica. Con movimiento
/// reducido sale un único corazón que aparece y se apaga sin moverse.
///
/// Se dispara con [PetHeartsState.burst] (a través de una `GlobalKey`).
class PetHearts extends StatefulWidget {
  const PetHearts({super.key, this.reducedMotion = false});

  final bool reducedMotion;

  static const duration = Duration(milliseconds: 1000);

  @override
  State<PetHearts> createState() => PetHeartsState();
}

class PetHeartsState extends State<PetHearts> {
  final _bursts = <_BurstData>[];
  int _serial = 0;

  /// Lanza una tanda desde [origin] (coordenadas locales de este widget).
  void burst(Offset origin) {
    if (!mounted) return;
    final n = _serial++;
    setState(() {
      // 3, 4 o 5 corazones según la tanda: variado pero determinista.
      _bursts.add(
        _BurstData(
          id: n,
          origin: origin,
          count: widget.reducedMotion ? 1 : 3 + n % 3,
        ),
      );
    });
  }

  void _done(_BurstData b) {
    if (mounted) setState(() => _bursts.remove(b));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            for (final b in _bursts)
              _Burst(
                key: ValueKey(b.id),
                data: b,
                reducedMotion: widget.reducedMotion,
                onDone: () => _done(b),
              ),
          ],
        ),
      ),
    );
  }
}

class _BurstData {
  const _BurstData({
    required this.id,
    required this.origin,
    required this.count,
  });
  final int id;
  final Offset origin;
  final int count;
}

class _Burst extends StatefulWidget {
  const _Burst({
    super.key,
    required this.data,
    required this.reducedMotion,
    required this.onDone,
  });
  final _BurstData data;
  final bool reducedMotion;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: PetHearts.duration,
  );

  // Desplazamiento lateral y tamaño de cada corazón (se reparten en abanico).
  static const _spread = [0.0, -26.0, 24.0, -12.0, 14.0];
  static const _sizes = [26.0, 20.0, 22.0, 18.0, 19.0];
  static const _rise = [78.0, 64.0, 70.0, 88.0, 84.0];

  @override
  void initState() {
    super.initState();
    _c.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [for (var i = 0; i < d.count; i++) _heart(i, d.count)],
      ),
    );
  }

  Widget _heart(int i, int count) {
    final size = _sizes[i % _sizes.length];
    final double opacity;
    var offset = Offset.zero;
    var scale = 1.0;
    if (widget.reducedMotion) {
      // Aparece y se apaga en su sitio.
      final v = _c.value;
      opacity = v < 0.3 ? v / 0.3 : (1 - v) / 0.7;
    } else {
      // Cada corazón sale un poco después que el anterior.
      final delay = i * 0.08;
      final v = ((_c.value - delay) / (1 - delay)).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(v);
      offset = Offset(_spread[i % _spread.length] * eased, -_rise[i] * eased);
      scale = 0.6 + 0.4 * Curves.easeOutBack.transform(v);
      opacity = v == 0 ? 0 : (v < 0.6 ? 1 : (1 - v) / 0.4);
    }
    final p = widget.data.origin + offset;
    return Positioned(
      left: p.dx - size / 2,
      top: p.dy - size / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Icon(
            Icons.favorite_rounded,
            size: size,
            color: i.isEven ? AppColors.coral : const Color(0xFFE88AA8),
            shadows: const [Shadow(color: Color(0x5534283B), blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}
