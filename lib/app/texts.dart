import 'dart:math' as math;

import '../domain/balance.dart';
import '../domain/rules.dart';

/// Textos del juego con plantillas y variantes. {name} se sustituye por el
/// nombre del caniche (siempre como texto plano).
class Texts {
  Texts([math.Random? random]) : _r = random ?? math.Random();
  final math.Random _r;

  String pick(List<String> variants, {String name = ''}) =>
      variants[_r.nextInt(variants.length)].replaceAll('{name}', name);

  static const needLabels = {
    Need.satiety: 'Saciedad',
    Need.hygiene: 'Higiene',
    Need.mood: 'Ánimo',
    Need.energy: 'Energía',
  };

  static const suggestions = {
    Need.satiety: [
      '¿Le preparamos la comida a {name}?',
      '{name} huele la cocina… ¿comemos?',
    ],
    Need.hygiene: [
      '¿Preparamos un baño de espuma?',
      '{name} disfrutaría de un baño.',
    ],
    Need.mood: [
      '¿Jugamos un rato en el parque?',
      '{name} tiene ganas de jugar.',
    ],
    Need.energy: [
      'Un descanso en casa le sentará bien.',
      '{name} se acurrucaría en su cojín.',
    ],
  };

  static const careTitles = {
    CareKind.feed: 'Comer',
    CareKind.bath: 'Bañar',
    CareKind.walk: 'Pasear',
    CareKind.groom: 'Peluquería',
    CareKind.sleep: 'Dormir',
    CareKind.vet: 'Veterinario',
  };

  static const careDone = {
    CareKind.feed: [
      '¡Qué rico! {name} ha comido de maravilla.',
      '{name} ha dejado el cuenco reluciente.',
    ],
    CareKind.bath: [
      '¡{name} está limpio y suave!',
      'Burbujas fuera: {name} huele a lavanda.',
    ],
    CareKind.walk: [
      '¡Qué paseo tan bonito con {name}!',
      '{name} ha olido todas las flores del sendero.',
    ],
    CareKind.groom: [
      '¡Rizos perfectos para {name}!',
      '{name} se mira al espejo encantado.',
    ],
    CareKind.sleep: [
      '{name} ha dormido como un angelito.',
      '¡Qué bien ha descansado {name}!',
    ],
    CareKind.vet: ['{name} está sano y tranquilo.'],
  };

  static const curedMessages = [
    '¡{name} ya está sanito! La pastilla ha funcionado.',
    '¡Adiós, malestar! {name} se encuentra mucho mejor.',
  ];

  /// Qué decir y qué hacer según lo más urgente (para la tarjeta de Casa).
  static const conditionSuggestions = {
    PetCondition.sick: [
      '¡{name} está malito! El veterinario le dará una pastilla.',
      '{name} no se encuentra bien. Vamos al veterinario.',
    ],
    PetCondition.hungry: [
      '{name} tiene hambre. ¿Le preparamos la comida?',
      'Ruge la tripita de {name}. ¿Comemos?',
    ],
    PetCondition.dirty: [
      '{name} está sucio. ¿Un baño de espuma?',
      '{name} necesita un baño.',
    ],
    PetCondition.sad: [
      '{name} está triste. ¿Jugamos un rato?',
      '{name} tiene ganas de jugar contigo.',
    ],
    PetCondition.tired: [
      '{name} está cansado. A dormir un ratito.',
      '{name} se cae de sueño. ¿Lo acostamos?',
    ],
  };

  /// Botón de Casa para los estados que no se resuelven atendiendo su
  /// medida; el resto usa [needActions].
  static const conditionActions = {
    PetCondition.sick: 'Veterinario',
    PetCondition.tired: 'Dormir',
  };

  /// Botón de Casa para atender cada medida (la energía depende de si
  /// está descansando).
  static const needActions = {
    Need.satiety: 'Comer',
    Need.hygiene: 'Bañar',
    Need.mood: 'Jugar',
  };

  static const conditionNames = {
    PetCondition.sick: 'Malito',
    PetCondition.hungry: 'Hambre',
    PetCondition.dirty: 'Sucio',
    PetCondition.sad: 'Triste',
    PetCondition.tired: 'Cansado',
  };

  static const allGood = [
    '{name} está feliz y sano.',
    'Todo en orden con {name}.',
  ];

  static const gameDone = [
    '¡Bien jugado!',
    '¡Gran partida con {name}!',
    '¡{name} lo ha pasado en grande!',
  ];

  static const missFeedback = [
    'Casi. Apunta un poco más cerca del aro.',
    '¡Uy! Prueba a arrastrar con menos fuerza.',
    'Sigue la línea de puntos hasta el aro.',
  ];
}
