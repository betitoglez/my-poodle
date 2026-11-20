String spellGateNumber(int n, String language) {
  if (n < 20 || n > 99) throw RangeError.range(n, 20, 99);
  final t = n ~/ 10, u = n % 10;
  if (language == 'zh-Hans' ||
      language == 'zh-Hant' ||
      language == 'ja' ||
      language == 'ko') {
    final digits = language == 'ko' ? '영일이삼사오육칠팔구' : '零一二三四五六七八九';
    final ten = language == 'ko' ? '십' : '十';
    return '${digits[t]}$ten${u == 0 ? '' : digits[u]}';
  }
  const units = {
    'en': [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
    ],
    'es': [
      '',
      'uno',
      'dos',
      'tres',
      'cuatro',
      'cinco',
      'seis',
      'siete',
      'ocho',
      'nueve',
    ],
    'fr': [
      '',
      'un',
      'deux',
      'trois',
      'quatre',
      'cinq',
      'six',
      'sept',
      'huit',
      'neuf',
    ],
    'de': [
      '',
      'eins',
      'zwei',
      'drei',
      'vier',
      'fünf',
      'sechs',
      'sieben',
      'acht',
      'neun',
    ],
    'pt-BR': [
      '',
      'um',
      'dois',
      'três',
      'quatro',
      'cinco',
      'seis',
      'sete',
      'oito',
      'nove',
    ],
    'it': [
      '',
      'uno',
      'due',
      'tre',
      'quattro',
      'cinque',
      'sei',
      'sette',
      'otto',
      'nove',
    ],
    'ru': [
      '',
      'один',
      'два',
      'три',
      'четыре',
      'пять',
      'шесть',
      'семь',
      'восемь',
      'девять',
    ],
  };
  const tens = {
    'en': [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ],
    'es': [
      '',
      '',
      'veinte',
      'treinta',
      'cuarenta',
      'cincuenta',
      'sesenta',
      'setenta',
      'ochenta',
      'noventa',
    ],
    'fr': ['', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante'],
    'de': [
      '',
      '',
      'zwanzig',
      'dreißig',
      'vierzig',
      'fünfzig',
      'sechzig',
      'siebzig',
      'achtzig',
      'neunzig',
    ],
    'pt-BR': [
      '',
      '',
      'vinte',
      'trinta',
      'quarenta',
      'cinquenta',
      'sessenta',
      'setenta',
      'oitenta',
      'noventa',
    ],
    'it': [
      '',
      '',
      'venti',
      'trenta',
      'quaranta',
      'cinquanta',
      'sessanta',
      'settanta',
      'ottanta',
      'novanta',
    ],
    'ru': [
      '',
      '',
      'двадцать',
      'тридцать',
      'сорок',
      'пятьдесят',
      'шестьдесят',
      'семьдесят',
      'восемьдесят',
      'девяносто',
    ],
  };
  if (language == 'es' && t == 2) {
    return const [
      'veinte',
      'veintiuno',
      'veintidós',
      'veintitrés',
      'veinticuatro',
      'veinticinco',
      'veintiséis',
      'veintisiete',
      'veintiocho',
      'veintinueve',
    ][u];
  }
  if (language == 'fr') {
    const teen = [
      'dix',
      'onze',
      'douze',
      'treize',
      'quatorze',
      'quinze',
      'seize',
      'dix-sept',
      'dix-huit',
      'dix-neuf',
    ];
    if (t == 7) return u == 1 ? 'soixante et onze' : 'soixante-${teen[u]}';
    if (t == 8) {
      return u == 0 ? 'quatre-vingts' : 'quatre-vingt-${units['fr']![u]}';
    }
    if (t == 9) return 'quatre-vingt-${teen[u]}';
    return '${tens['fr']![t]}${u == 0
        ? ''
        : u == 1
        ? ' et un'
        : '-${units['fr']![u]}'}';
  }
  final tag = units.containsKey(language) ? language : 'en';
  var ten = tens[tag]![t];
  if (u == 0) return ten;
  final unit = units[tag]![u];
  if (tag == 'de') return '${u == 1 ? 'ein' : unit}und$ten';
  if (tag == 'it') {
    if (u == 1 || u == 8) ten = ten.substring(0, ten.length - 1);
    return '$ten${u == 3 ? 'tré' : unit}';
  }
  return '$ten${tag == 'en'
      ? '-'
      : tag == 'es'
      ? ' y '
      : tag == 'pt-BR'
      ? ' e '
      : ' '}$unit';
}
