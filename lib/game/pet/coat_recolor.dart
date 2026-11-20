import 'dart:typed_data';

/// Remapeo del pelaje en un isolate. Conserva facciones, alfa y microtextura.
Uint8List recolorFur(Map<String, Object> args) {
  final pixels = args['pixels']! as Uint8List;
  final palette = args['palette']! as List<int>;
  final out = Uint8List.fromList(pixels);
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
      final target = low + (high - low) * blend;
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
