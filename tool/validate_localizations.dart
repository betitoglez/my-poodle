import 'dart:convert';
import 'dart:io';

void main() {
  const tags = [
    'en',
    'es',
    'fr',
    'de',
    'pt-BR',
    'it',
    'ru',
    'ko',
    'ja',
    'zh-Hans',
    'zh-Hant',
  ];
  final token = RegExp(r'\{(?:p\d+|name)\}');
  Map<String, dynamic> read(String tag) =>
      jsonDecode(File('assets/l10n/$tag.json').readAsStringSync())
          as Map<String, dynamic>;
  final reference = read('es');
  if (reference.length < 500) throw StateError('Incomplete source catalog');
  for (final tag in tags) {
    final catalog = read(tag);
    if (catalog.length != reference.length ||
        !catalog.keys.toSet().containsAll(reference.keys)) {
      throw StateError('Incomplete locale: $tag');
    }
    for (final key in reference.keys) {
      final value = catalog[key];
      if (value is! String || value.trim().isEmpty || value.contains('ZX')) {
        throw StateError('Invalid message: $tag: $key');
      }
      final source = token.allMatches(key).map((m) => m[0]).toList()..sort();
      final translated = token.allMatches(value).map((m) => m[0]).toList()
        ..sort();
      if (source.join('|') != translated.join('|')) {
        throw StateError('Invalid parameters: $tag: $key');
      }
    }
  }
  stdout.writeln(
    'Verified ${tags.length} languages × ${reference.length} messages and template parameters.',
  );
}
