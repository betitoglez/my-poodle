import 'package:characters/characters.dart';

/// Resultado de validar un nombre de mascota.
sealed class NameResult {
  const NameResult();
}

class ValidName extends NameResult {
  const ValidName(this.value);
  final String value;
}

enum NameError { empty, tooLong, invalidCharacters }

class InvalidName extends NameResult {
  const InvalidName(this.error);
  final NameError error;
}

class PetName {
  static const int maxGraphemes = 16;
  static const List<String> suggestions = ['Nube', 'Miel', 'Coco'];

  /// Recorta extremos, compone a NFC (caracteres latinos habituales), rechaza
  /// controles y saltos de línea y cuenta de 1 a 16 grafemas.
  static NameResult validate(String raw) {
    if (_hasControl(raw.trim())) {
      return const InvalidName(NameError.invalidCharacters);
    }
    final value = composeNfc(raw.trim());
    final length = value.characters.length;
    if (length == 0) return const InvalidName(NameError.empty);
    if (length > maxGraphemes) return const InvalidName(NameError.tooLong);
    return ValidName(value);
  }

  static int graphemeCount(String raw) =>
      composeNfc(raw.trim()).characters.length;

  static bool _hasControl(String s) {
    for (final r in s.runes) {
      if (r < 0x20 || r == 0x7f || (r >= 0x80 && r < 0xa0)) return true;
      if (r == 0x2028 || r == 0x2029) return true;
    }
    return false;
  }

  /// Composición NFC para letras latinas con diacríticos combinantes
  /// frecuentes en nombres (agudo, grave, circunflejo, tilde, diéresis,
  /// cedilla). Dart no incluye normalización Unicode completa; el resto de
  /// secuencias se conserva tal cual y se cuenta por grafemas.
  static String composeNfc(String s) {
    final out = StringBuffer();
    final runes = s.runes.toList();
    for (var i = 0; i < runes.length; i++) {
      final base = runes[i];
      if (i + 1 < runes.length) {
        final composed = _table[runes[i + 1]]?[base];
        if (composed != null) {
          out.writeCharCode(composed);
          i++;
          continue;
        }
      }
      out.writeCharCode(base);
    }
    return out.toString();
  }

  static Map<int, int> _build(String bases, String composed) {
    final b = bases.runes.toList();
    final c = composed.runes.toList();
    return {for (var i = 0; i < b.length; i++) b[i]: c[i]};
  }

  static final Map<int, Map<int, int>> _table = {
    0x0301: _build('AEIOUYaeiouyNnCc', 'ÁÉÍÓÚÝáéíóúýŃńĆć'),
    0x0300: _build('AEIOUaeiou', 'ÀÈÌÒÙàèìòù'),
    0x0302: _build('AEIOUaeiou', 'ÂÊÎÔÛâêîôû'),
    0x0303: _build('ANOano', 'ÃÑÕãñõ'),
    0x0308: _build('AEIOUaeiouy', 'ÄËÏÖÜäëïöüÿ'),
    0x0327: _build('Cc', 'Çç'),
  };
}
