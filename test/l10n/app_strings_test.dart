import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/l10n/app_strings.dart';

import '../support.dart';

AppStrings catalog(String tag) => AppStrings(
  AppLanguage.fromTag(tag),
  (jsonDecode(File('assets/l10n/$tag.json').readAsStringSync()) as Map)
      .cast<String, String>(),
);
void main() {
  final placeholders = RegExp(r'\{(?:p\d+|name)\}');
  test(
    'all eleven packaged catalogs have complete messages and intact parameters',
    () {
      final reference = catalog('es').messages;
      expect(reference.length, greaterThan(500));
      for (final language in AppLanguage.all) {
        final messages = catalog(language.tag).messages;
        expect(
          messages.keys.toSet(),
          reference.keys.toSet(),
          reason: language.tag,
        );
        for (final entry in messages.entries) {
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: '${language.tag}: ${entry.key}',
          );
          expect(
            entry.value,
            isNot(contains('ZX')),
            reason: '${language.tag}: ${entry.key}',
          );
          final expected =
              placeholders.allMatches(entry.key).map((m) => m[0]).toList()
                ..sort();
          final actual =
              placeholders.allMatches(entry.value).map((m) => m[0]).toList()
                ..sort();
          expect(actual, expected, reason: '${language.tag}: ${entry.key}');
        }
      }
    },
  );
  test('English fallback and both Chinese scripts resolve predictably', () {
    expect(AppLanguage.resolve([const Locale('pl')], []), const Locale('en'));
    expect(AppLanguage.fromLocale(const Locale('zh', 'TW')).tag, 'zh-Hant');
    expect(AppLanguage.fromLocale(const Locale('zh', 'CN')).tag, 'zh-Hans');
    expect(
      AppLanguage.fromLocale(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'TW',
        ),
      ).tag,
      'zh-Hans',
    );
    expect(AppLanguage.fromLocale(const Locale('pt', 'BR')).tag, 'pt-BR');
    expect(AppLanguage.fromTag('unsupported').tag, 'en');
  });
  test('localized names agree with native iOS and Android resources', () {
    expect(catalog('es').appName, 'Mi Caniche');
    expect(catalog('en').appName, 'My Poodle');
    for (final language in AppLanguage.all) {
      expect(catalog(language.tag).text('My Poodle'), language.appName);
      expect(
        File('ios/Runner/${language.tag}.lproj/InfoPlist.strings')
            .readAsStringSync(),
        contains('"CFBundleDisplayName" = "${language.appName}";'),
      );
    }
  });
  test(
    'names that match UI labels remain literal inside greetings and titles',
    () {
      final en = catalog('en');
      expect(
        en.text('Toca a Casa para hacerle una caricia.'),
        contains('Casa'),
      );
      expect(en.text('Casa está feliz y sano.'), contains('Casa'));
      expect(en.text('Cuenco de agua de Casa'), contains('Casa'));
      expect(
        en.text('Duración: 20 segundos · 5 lanzamientos.'),
        isNot(contains('segundos')),
      );
      expect(en.text('Pienso diario · Gratis'), isNot(contains('Pienso')));
    },
  );
  test(
    'language choice persists alongside an unchanged pet name and wallet',
    () {
      final b = loadBalance();
      final codec = SaveCodec(b);
      final pet = PetState.adopt(
        validName: 'Casa',
        nowUtc: t0,
        balance: b,
      ).copyWith(coins: 42);
      for (final language in AppLanguage.all) {
        final restored = codec.decode(
          codec.encode(
            pet.copyWith(prefs: pet.prefs.copyWith(language: language.tag)),
          ),
        );
        expect(restored.prefs.language, language.tag);
        expect(restored.name, 'Casa');
        expect(restored.coins, 42);
        expect(restored.prefs.copyWith(systemLanguage: true).language, isNull);
      }
    },
  );
  test('adult gate uses written numbers in every supported language', () {
    final cases = {
      'en': 'twenty-one',
      'es': 'veintiuno',
      'fr': 'vingt et un',
      'de': 'einundzwanzig',
      'pt-BR': 'vinte e um',
      'it': 'ventuno',
      'ru': 'двадцать один',
      'ko': '이십일',
      'ja': '二十一',
      'zh-Hans': '二十一',
      'zh-Hant': '二十一',
    };
    for (final e in cases.entries) {
      expect(catalog(e.key).numberWords(21), e.value);
      for (var n = 21; n <= 99; n++) {
        expect(catalog(e.key).numberWords(n), isNotEmpty);
      }
    }
    expect(catalog('fr').numberWords(71), 'soixante et onze');
    expect(catalog('it').numberWords(23), 'ventitré');
    expect(catalog('de').numberWords(81), 'einundachtzig');
  });
}
