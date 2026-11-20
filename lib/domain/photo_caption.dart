import 'package:characters/characters.dart';

import 'pet_name.dart';

/// Texto que el jugador escribe sobre una foto. Se valida como el nombre de
/// adopción (extremos recortados, NFC, sin controles ni saltos de línea) con
/// un límite de [maxGraphemes]. Nunca se guarda en la partida: solo queda
/// pintado, como texto plano, dentro del PNG local de la foto.
class PhotoCaption {
  static const int maxGraphemes = 24;

  /// Texto vacío: la foto va sin texto (no es un error para el editor, que
  /// simplemente no lo pinta).
  static NameResult validate(String raw) {
    final trimmed = raw.trim();
    if (_hasForbidden(trimmed)) {
      return const InvalidName(NameError.invalidCharacters);
    }
    final value = PetName.composeNfc(trimmed);
    final length = value.characters.length;
    if (length == 0) return const InvalidName(NameError.empty);
    if (length > maxGraphemes) return const InvalidName(NameError.tooLong);
    return ValidName(value);
  }

  static int graphemeCount(String raw) =>
      PetName.composeNfc(raw.trim()).characters.length;

  /// Controles C0/C1, separadores de línea y párrafo y marcas de dirección
  /// que podrían reordenar o esconder el texto pintado.
  static bool _hasForbidden(String s) {
    for (final r in s.runes) {
      if (r < 0x20 || r == 0x7f || (r >= 0x80 && r < 0xa0)) return true;
      if (r == 0x2028 || r == 0x2029) return true;
      if ((r >= 0x202a && r <= 0x202e) || (r >= 0x2066 && r <= 0x2069)) {
        return true;
      }
    }
    return false;
  }
}
