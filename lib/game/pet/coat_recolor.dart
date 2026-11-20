import 'dart:typed_data';
import 'dart:math' as math;

/// Remapeo del pelaje en un isolate. Conserva facciones, alfa y microtextura.
Uint8List recolorFur(Map<String, Object> args) {
  final pixels = args['pixels']! as Uint8List;
  final palette = args['palette']! as List<int>;
  final out = Uint8List.fromList(pixels);
  final width = args['width'] as int? ?? 1;
  final pattern = args['pattern'] as String? ?? '';
  double smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  for (var i = 0; i < out.length; i += 4) {
    if (out[i + 3] == 0) {
      out[i] = out[i + 1] = out[i + 2] = 0;
      continue;
    }
    final r = pixels[i].toDouble(),
        g = pixels[i + 1].toDouble(),
        b = pixels[i + 2].toDouble();
    final lum = r * 0.25 + g * 0.6 + b * 0.15;
    final fur =
        smooth(30, 85, lum) *
        (1 - smooth(18, 65, b - g)) *
        (1 - smooth(35, 90, r - g * 1.65));
    final t = ((lum - 40) / 205).clamp(0.0, 1.0);
    final index = t < 0.58 ? 0 : 1;
    final blend = index == 0 ? t / 0.58 : (t - 0.58) / 0.42;
    for (var c = 0; c < 3; c++) {
      final shift = 16 - c * 8;
      final low = (palette[index] >> shift) & 255;
      final high = (palette[index + 1] >> shift) & 255;
      var target = low + (high - low) * blend;
      final x = (i ~/ 4) % width / width, y = (i ~/ 4) ~/ width / width;
      final stripe = math.sin(y * 105 + x * 32 + 2 * math.sin(x * 50)) > 0;
      int? patterned;
      if (pattern == 'zebra') patterned = stripe ? 0xF3EEE7 : 0x25272D;
      if (pattern == 'tiger') patterned = stripe ? 0xE79C49 : 0x2E2520;
      if (pattern == 'redwhite') {
        patterned = math.sin(y * 115) > 0 ? 0xF5EFE8 : 0xC12A3E;
      }
      if (pattern == 'dalmatian') {
        final dx = (x * 17) % 1 - .5, dy = (y * 17) % 1 - .5;
        final cell = (x * 17).floor() * 13 + (y * 17).floor() * 7;
        patterned = dx * dx + dy * dy < .09 && cell % 3 != 0
            ? 0x25272D
            : 0xF3EEE7;
      }
      if (patterned != null) {
        target = ((patterned >> shift) & 255) * (.48 + .52 * t);
      }

      final feature = lum < 95
          ? pixels[i + c] * 0.55
          : pixels[i + c].toDouble();
      out[i + c] = ((feature * (1 - fur) + target * fur) * out[i + 3] / 255)
          .round()
          .clamp(0, 255);
    }
  }
  return out;
}
