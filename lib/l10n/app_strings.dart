import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'number_words.dart';

class AppLanguage {
  const AppLanguage(this.tag, this.locale, this.nativeName, this.appName);
  final String tag;
  final Locale locale;
  final String nativeName;
  final String appName;
  static const all = [
    AppLanguage('en', Locale('en'), 'English', 'My Poodle'),
    AppLanguage('es', Locale('es'), 'Español', 'Mi Caniche'),
    AppLanguage('fr', Locale('fr'), 'Français', 'Mon Caniche'),
    AppLanguage('de', Locale('de'), 'Deutsch', 'Mein Pudel'),
    AppLanguage(
      'pt-BR',
      Locale('pt', 'BR'),
      'Português (Brasil)',
      'Meu Poodle',
    ),
    AppLanguage('it', Locale('it'), 'Italiano', 'Il mio Barboncino'),
    AppLanguage('ru', Locale('ru'), 'Русский', 'Мой пудель'),
    AppLanguage('ko', Locale('ko'), '한국어', '나의 푸들'),
    AppLanguage('ja', Locale('ja'), '日本語', 'マイプードル'),
    AppLanguage(
      'zh-Hans',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      '简体中文',
      '我的贵宾犬',
    ),
    AppLanguage(
      'zh-Hant',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      '繁體中文',
      '我的貴賓犬',
    ),
  ];
  static List<Locale> get locales => all.map((l) => l.locale).toList();
  static AppLanguage fromTag(String? tag) =>
      all.where((l) => l.tag == tag).firstOrNull ?? all.first;
  static AppLanguage fromLocale(Locale locale) {
    if (locale.languageCode == 'zh') {
      return fromTag(
        locale.scriptCode == 'Hant' ||
                (locale.scriptCode != 'Hans' &&
                    const {'TW', 'HK', 'MO'}.contains(locale.countryCode))
            ? 'zh-Hant'
            : 'zh-Hans',
      );
    }
    return all
            .where((l) => l.locale.languageCode == locale.languageCode)
            .firstOrNull ??
        all.first;
  }

  static Locale resolve(List<Locale>? requested, Iterable<Locale> supported) {
    for (final locale in requested ?? const <Locale>[]) {
      if (all.any((l) => l.locale.languageCode == locale.languageCode)) {
        return fromLocale(locale).locale;
      }
    }
    return all.first.locale;
  }
}

/// Catálogos locales empaquetados; nunca se traducen datos de jugador en red.
class AppStrings {
  AppStrings(this.language, this.messages) {
    _lower = {for (final key in messages.keys) key.toLowerCase(): key};
    _patterns = [
      for (final key in messages.keys)
        if (_placeholder.hasMatch(key)) _MessagePattern(key),
    ]..sort((a, b) => b.specificity.compareTo(a.specificity));
  }
  final AppLanguage language;
  final Map<String, String> messages;
  late final Map<String, String> _lower;
  late final List<_MessagePattern> _patterns;
  static final _placeholder = RegExp(r'\{(?:p\d+|name)\}');
  static AppStrings active = AppStrings(AppLanguage.fromTag('es'), const {});
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? active;
  String get appName => language.appName;
  String numberWords(int n) => spellGateNumber(n, language.tag);

  static const _nameTemplates = [
    "Ahora juega con {p0} para ganar monedas.",
    "Apaga la luz para que {p0} duerma.",
    "Arropa a {p0} con su manta.",
    "Consulta del veterinario con {p0}",
    "Cuenco de agua de {p0}",
    "Fonendo: mantén sobre el pecho de {p0} durante 3 segundos.",
    "La partida de {p0} (nombre, monedas, armario y ajustes) se guarda solo en esta instalación, sin cuentas, servidores ni copias en la nube. Si desinstalas la app o cambias de teléfono, la partida no se transfiere y el nuevo dispositivo empieza por la adopción.",
    "La rutina de {p0}",
    "Primer paso: dale de comer a {p0}.",
    "Salón con la cama de {p0}",
    "Se eliminarán {p0}, sus monedas, su armario y los ajustes de este dispositivo. No se puede deshacer.",
    "Toca a {p0} para hacerle una caricia.",
    "Toca a {p0} para que se ponga a dos patas. Arrastra para girar.",
    "Toca la huella para que {p0} olfatee.",
    "Toca su cama para que {p0} se acueste.",
    "Vista previa de {p0} con el aspecto elegido, {p1}",
    "{p0} descansa en su cama. La energía sube con el tiempo en casa.",
    "{p0} duerme plácidamente… Zzz.",
    "{p0} en el salón, {p1}. Toca para hacerle una caricia.",
    "{p0} está malito. Mantén el fonendo sobre su pecho 3 segundos.",
    "{p0} está masticando…",
    "{p0} está olfateando…",
    "{p0} va de camino…",
    "{p0} va hacia su cama…",
  ];

  String text(String source) => _text(source, 0);

  String _text(String source, int depth) {
    if (source == 'My Poodle') return appName;
    if (language.tag == 'es') return source;
    final exact = messages[source];
    if (exact != null) return exact;
    final key = _lower[source.toLowerCase()];
    if (key != null) {
      final result = messages[key]!;
      return source.length > 1 && source == source.toUpperCase()
          ? result.toUpperCase()
          : result;
    }
    if (!RegExp(r'[A-Za-zÁÉÍÓÚáéíóúñÑüÜ¿¡]').hasMatch(source)) return source;
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(source);
      if (match == null) continue;
      final template = messages[pattern.source]!;
      final values = <String, String>{};
      for (var i = 0; i < pattern.parameters.length; i++) {
        final value = match.group(i + 1) ?? '';
        final parameter = pattern.parameters[i];
        final playerName =
            parameter == 'name' ||
            (parameter == 'p0' && _nameTemplates.contains(pattern.source));
        final translated = playerName || depth >= 3
            ? value
            : _text(value, depth + 1);
        values[parameter] = translated;
      }
      final result = template.replaceAllMapped(
        _placeholder,
        (m) => values[m[0]!.substring(1, m[0]!.length - 1)] ?? m[0]!,
      );
      return source.length > 1 && source == source.toUpperCase()
          ? result.toUpperCase()
          : result;
    }
    return source;
  }
}

class _MessagePattern {
  _MessagePattern(this.source) {
    final expression = StringBuffer('^');
    var offset = 0;
    for (final match in AppStrings._placeholder.allMatches(source)) {
      final literal = source.substring(offset, match.start);
      specificity += literal.length;
      expression.write(RegExp.escape(literal));
      expression.write('(.*?)');
      parameters.add(match.group(0)!.substring(1, match.group(0)!.length - 1));
      offset = match.end;
    }
    final end = source.substring(offset);
    specificity += end.length;
    expression.write(RegExp.escape(end));
    expression.write(r'$');
    regex = RegExp(expression.toString(), caseSensitive: false, dotAll: true);
  }
  final String source;
  final parameters = <String>[];
  int specificity = 0;
  late final RegExp regex;
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      AppLanguage.all.any((l) => l.locale.languageCode == locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) async {
    final language = AppLanguage.fromLocale(locale);
    final json = jsonDecode(
      await rootBundle.loadString('assets/l10n/${language.tag}.json'),
    ) as Map<String, dynamic>;
    return AppStrings(language, json.cast<String, String>());
  }

  @override
  bool shouldReload(_StringsDelegate old) => false;
}

String localize(BuildContext context, String source) =>
    AppStrings.of(context).text(source);

String? localizeNullable(BuildContext context, String? source) =>
    source == null ? null : localize(context, source);
