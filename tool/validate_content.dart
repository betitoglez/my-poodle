// Validación de contenido antes de compilar: dart run tool/validate_content.dart
//
// Comprueba que la copia empaquetada del balance coincide con la fuente de
// docs/, que el catálogo es válido (IDs únicos, costes, ranuras, fallbacks,
// versión gratuita o completa de cada artículo y juego, producto de la tienda)
// y que cada artículo tiene metadatos visuales y cada pose sus capas. También
// comprueba que no vuelven publicidad ni intermediarios de compras.
import 'dart:convert';
import 'dart:io';

import 'package:my_poodle/domain/achievements.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/games/puzzle_deals.dart';

const requiredLayers = {
  'shadow',
  'tail',
  'legsBack',
  'body',
  'legsFront',
  'outfit',
  'ears',
  'head',
  'hair',
  'face',
  'neck',
};
const slotSections = {
  Slot.coat: 'coats',
  Slot.hair: 'hair',
  Slot.outfit: 'outfits',
  Slot.neck: 'necks',
  Slot.head: 'heads',
  Slot.eyes: 'eyes',
  Slot.collar: 'collars',
  Slot.paws: 'paws',
};
final assets = [
  for (final dog in PuzzleDeals.poodles) 'assets/images/poodles/$dog.webp',
  'assets/images/cards/kitchen.jpg',
  'assets/images/cards/bath.jpg',
  'assets/images/cards/walk.jpg',
  'assets/images/cards/salon.jpg',
  'assets/images/cards/orchard.jpg',
  'assets/images/cards/frisbee.jpg',
  'assets/images/cards/cushion.jpg',
  'assets/images/scenes/orchard.jpg',
  'assets/images/scenes/meadow.jpg',
  'assets/images/rooms/living.jpg',
  'assets/images/rooms/kitchen.jpg',
  'assets/images/rooms/bath.jpg',
  'assets/images/rooms/bath_spa.jpg',
  'assets/images/rooms/salon.jpg',
  'assets/images/rooms/wardrobe.jpg',
  'assets/images/rooms/nursery.jpg',
  'assets/images/props/tub.webp',
  'assets/images/props/bath_extras.webp',
  'assets/images/props/foam.webp',
  'assets/images/props/bowl_full.webp',
  'assets/images/props/bowl_empty.webp',
  'assets/images/props/bed.webp',
  'assets/images/props/blanket.webp',
  'assets/images/icons/hungry.webp',
  'assets/images/icons/dirty.webp',
  'assets/images/icons/sad.webp',
  'assets/images/icons/sick.webp',
  'assets/images/icons/tired.webp',
  'assets/images/rooms/vet.jpg',
  for (final name in [
    'basic',
    'premium',
    'salmon',
    'vegan',
    'cake',
    'bone',
    'bath_premium',
    'bath_massage',
    'drink_water',
    'drink_bottled',
    'drink_vitamins',
    'drink_juice',
  ])
    'assets/images/food/$name.webp',
  'assets/images/materials/beanie-front-v1.png',
  'assets/images/materials/beanie-side-v1.png',
  'assets/images/materials/beanie-back-v1.png',
  'assets/images/materials/sweater-front-v1.png',
  'assets/images/materials/sweater-side-v1.png',
  'assets/images/materials/sweater-back-v1.png',
  'assets/images/materials/bandana-front-v1.png',
  'assets/images/materials/bandana-side-v1.png',
  'assets/images/materials/bandana-back-v1.png',
  for (final family in ['overalls', 'raincoat', 'dress', 'knit', 'bowtie'])
    for (final angle in ['front', 'side', 'back'])
      'assets/images/materials/$family-$angle-v1.webp',
];

void main() {
  final errors = <String>[];
  final source = File('docs/datos/balance-v1.json').readAsStringSync();
  final packaged = File('assets/data/balance-v1.json').readAsStringSync();
  if (jsonEncode(jsonDecode(source)) != jsonEncode(jsonDecode(packaged))) {
    errors.add(
      'assets/data/balance-v1.json difiere de docs/datos/balance-v1.json',
    );
  }
  // Versión gratuita/completa: `tier` obligatorio (Balance.fromJson lo exige
  // junto con un artículo gratuito comprable por ranura, un juego gratuito y
  // fullVersion.productId); sin bloque de publicidad.
  final raw = jsonDecode(packaged) as Map<String, dynamic>;
  if (raw.containsKey('ads')) {
    errors.add(
      'balance-v1.json: el bloque «ads» ya no existe (sin publicidad)',
    );
  }
  final pubspec = File('pubspec.yaml').readAsStringSync();
  for (final banned in [
    'google_mobile_ads',
    'unity_ads',
    'applovin',
    'firebase_analytics',
    'purchases_flutter',
    'adapty',
  ]) {
    if (pubspec.contains(banned)) {
      errors.add('pubspec.yaml: dependencia no permitida $banned');
    }
  }
  Balance? balance;
  try {
    balance = Balance.fromJson(jsonDecode(packaged) as Map<String, dynamic>);
  } on BalanceFormatException catch (e) {
    errors.add('balance-v1.json: ${e.message}');
  }
  final looks = jsonDecode(
    File('assets/data/appearance-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (balance != null) {
    for (final item in balance.styles) {
      final section = looks[slotSections[item.slot]] as Map<String, dynamic>?;
      if (section == null || !section.containsKey(item.id)) {
        errors.add(
          'appearance-v1.json: falta ${item.id} en ${slotSections[item.slot]}',
        );
      }
    }
  }
  final poses = looks['poses'] as Map<String, dynamic>;
  for (final pose in ['front', 'side']) {
    final p = poses[pose] as Map<String, dynamic>?;
    if (p == null) {
      errors.add('appearance-v1.json: falta la pose $pose');
      continue;
    }
    final order = (p['drawOrder'] as List).cast<String>();
    final missing = requiredLayers.difference(order.toSet());
    if (missing.isNotEmpty) errors.add('pose $pose sin capas: $missing');
    if (order.toSet().length != order.length) {
      errors.add('pose $pose con capas repetidas');
    }
  }
  // Atlas ilustrado: cada peinado necesita base en frente, perfil y espalda;
  // cada artículo, capa (o «no se ve») en esas tres poses; cada pelaje, su
  // matriz de color; y todos los ficheros referenciados deben existir.
  final sprites = jsonDecode(
    File('assets/data/pet-sprites-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final spritePoses = (sprites['poses'] as Map<String, dynamic>).keys.toList();
  const mainPoses = ['front', 'side', 'back'];
  Map<String, dynamic> group(String k) =>
      (sprites[k] as Map<String, dynamic>?) ?? const {};
  void checkFile(Object? entry, String what) {
    if (entry == null) return;
    final file = entry is String
        ? entry
        : (entry as Map<String, dynamic>)['file'] as String;
    if (!File('assets/images/pet/$file').existsSync()) {
      errors.add('pet-sprites: no existe assets/images/pet/$file ($what)');
    }
  }

  for (final kind in ['hair', 'items', 'expressions']) {
    group(kind).forEach((id, poses) {
      (poses as Map<String, dynamic>).forEach((pose, e) {
        if (!spritePoses.contains(pose)) {
          errors.add('pet-sprites: pose desconocida $pose en $id');
        }
        checkFile(e, '$id/$pose');
      });
    });
  }
  if (balance != null) {
    final variants = group('variants');
    final hair = group('hair');
    final hairAliases = group('hairAliases');
    for (final entry in hairAliases.entries) {
      if (entry.value is! String || !hair.containsKey(entry.value)) {
        errors.add(
          'pet-sprites: el peinado ${entry.key} usa una base inexistente',
        );
      }
    }
    for (final item in balance.styles) {
      if (item.slot == Slot.coat) {
        if (!group('coats').containsKey(item.id)) {
          errors.add('pet-sprites: falta el pelaje ${item.id}');
        }
        continue;
      }
      if (item.slot == Slot.hair) {
        final entry =
            hair[hairAliases[item.id] ?? item.id] as Map<String, dynamic>?;
        for (final pose in mainPoses) {
          if (entry == null || !entry.containsKey(pose)) {
            errors.add('pet-sprites: falta ${item.id} en la pose $pose');
          }
        }
        continue;
      }
      // «Sin prenda», «sin gafas»… no tienen capa.
      if (item.initial) continue;
      final layerId =
          (variants[item.id] as Map<String, dynamic>?)?['of'] ?? item.id;
      final entry = group('items')[layerId] as Map<String, dynamic>?;
      for (final pose in mainPoses) {
        if (entry == null || !entry.containsKey(pose)) {
          errors.add(
            'pet-sprites: falta ${item.id} ($layerId) en la pose $pose',
          );
        }
      }
    }
    // Cada variante apunta a una capa que existe.
    variants.forEach((id, v) {
      final of = (v as Map<String, dynamic>)['of'];
      if (!group('items').containsKey(of)) {
        errors.add('pet-sprites: la variante $id usa «$of», que no tiene capa');
      }
    });
  }
  for (final color in ['red', 'blue', 'green', 'yellow']) {
    final path = 'assets/audio/sfx/memory_$color.wav';
    if (!File(path).existsSync()) errors.add('Falta $path');
  }
  // Decoración del salón: IDs únicos con el prefijo de su hueco y distintos
  // de los del armario, un artículo vacío inicial y gratuito por hueco, al
  // menos uno gratuito comprable por hueco y precio positivo en lo comprable.
  // Álbum: IDs de logro únicos y estables, cada página con logros y un bono
  // positivo en `album.pageBonus`, sin páginas desconocidas.
  if (balance != null) {
    final achIds = <String>{};
    for (final a in Achievements.catalog) {
      if (!achIds.add(a.id)) errors.add('album: logro repetido ${a.id}');
      if (!a.id.startsWith('ach.')) errors.add('album: ID sin «ach.» ${a.id}');
    }
    for (final page in AlbumPage.values) {
      if (Achievements.onPage(page).isEmpty) {
        errors.add('album: página ${page.name} sin logros');
      }
      if ((balance.albumPageBonus[page.name] ?? 0) <= 0) {
        errors.add('album: página ${page.name} sin bono');
      }
    }
    for (final key in balance.albumPageBonus.keys) {
      if (!AlbumPage.values.any((p) => p.name == key)) {
        errors.add('album: página desconocida $key');
      }
    }
  }
  if (balance != null) {
    final styleIds = {for (final s in balance.styles) s.id};
    final decorIds = <String>{};
    for (final d in balance.decor) {
      if (!decorIds.add(d.id)) errors.add('decor: ID repetido ${d.id}');
      if (styleIds.contains(d.id)) {
        errors.add('decor: ${d.id} coincide con un artículo del armario');
      }
      if (!d.id.startsWith('${d.slot.name}.')) {
        errors.add('decor: ${d.id} no empieza por «${d.slot.name}.»');
      }
      if (d.initial && (d.cost != 0 || d.tier != Tier.free)) {
        errors.add('decor: el inicial ${d.id} debe ser gratis');
      }
      if (!d.initial && d.cost <= 0) {
        errors.add('decor: ${d.id} necesita un precio positivo');
      }
    }
    for (final slot in DecorSlot.values) {
      final items = balance.decorFor(slot);
      if (items.where((d) => d.initial).length != 1) {
        errors.add('decor: el hueco ${slot.name} necesita un inicial');
      }
      if (!items.any((d) => !d.initial && d.tier == Tier.free)) {
        errors.add(
          'decor: el hueco ${slot.name} sin artículo gratis comprable',
        );
      }
    }
  }
  for (final a in assets) {
    if (!File(a).existsSync()) errors.add('recurso ausente: $a');
  }
  if (errors.isEmpty) {
    final free = balance!.styles.where((s) => s.tier == Tier.free).length;
    stdout.writeln(
      'Contenido válido: ${balance.styles.length} artículos ($free gratis, ${balance.styles.length - free} de la versión completa), '
      '${balance.decor.length} de decoración, '
      '${balance.photoPacks.length} packs de fotos, '
      'producto ${balance.fullVersionProductId}, ${spritePoses.length} poses ilustradas, ${assets.length} imágenes.',
    );
  } else {
    for (final e in errors) {
      stderr.writeln('ERROR $e');
    }
    exit(1);
  }
}
