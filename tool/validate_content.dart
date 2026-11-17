// Validación de contenido antes de compilar: dart run tool/validate_content.dart
//
// Comprueba que la copia empaquetada del balance coincide con la fuente de
// docs/, que el catálogo es válido (IDs únicos, costes, ranuras, fallbacks) y
// que cada artículo tiene metadatos visuales y cada pose sus capas.
import 'dart:convert';
import 'dart:io';

import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';

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
};
const assets = [
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
  'assets/images/rooms/salon.jpg',
  'assets/images/rooms/wardrobe.jpg',
  'assets/images/rooms/nursery.jpg',
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
  // Atlas ilustrado: cada peinado y artículo visible del catálogo necesita
  // capa en todas las poses, y cada pelaje su entrada de color.
  final sprites = jsonDecode(
    File('assets/data/pet-sprites-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final spritePoses = (sprites['poses'] as Map<String, dynamic>).keys.toList();
  if (balance != null) {
    for (final item in balance.styles) {
      final group = switch (item.slot) {
        Slot.coat => 'coats',
        Slot.hair => 'hair',
        _ => 'items',
      };
      final entry = (sprites[group] as Map<String, dynamic>)[item.id];
      if (item.slot == Slot.coat) {
        if (!(sprites['coats'] as Map<String, dynamic>).containsKey(item.id)) {
          errors.add('pet-sprites: falta el pelaje ${item.id}');
        }
        continue;
      }
      // «Sin prenda» y «sin accesorio» no tienen capa.
      if (item.initial && item.slot != Slot.hair) continue;
      for (final pose in spritePoses) {
        final file = (entry as Map<String, dynamic>?)?[pose] as String?;
        if (file == null) {
          errors.add('pet-sprites: falta ${item.id} en la pose $pose');
        } else if (!File('assets/images/pet/$file').existsSync()) {
          errors.add('pet-sprites: no existe assets/images/pet/$file');
        }
      }
    }
  }
  for (final a in assets) {
    if (!File(a).existsSync()) errors.add('recurso ausente: $a');
  }
  if (errors.isEmpty) {
    stdout.writeln(
      'Contenido válido: ${balance!.styles.length} artículos, 2 poses vectoriales, ${spritePoses.length} poses ilustradas, ${assets.length} imágenes.',
    );
  } else {
    for (final e in errors) {
      stderr.writeln('ERROR $e');
    }
    exit(1);
  }
}
