import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/haircuts.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/scenes/stage_game.dart';
import 'package:my_poodle/ui/screens/wardrobe_screen.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';

import 'app_flow_test.dart' show boot, fullStore, saved, tapText;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);
  for (final full in [false, true]) {
    testWidgets(
      'lomo/cola se ven de perfil y la cola estándar se equipa gratis, completa=$full',
      (t) async {
        final backend = backendWith((s) => s.copyWith(coins: 0));
        await boot(t, backend, store: full ? fullStore() : null);
        await tapText(t, 'Armario');
        await tapText(t, 'Peinados');
        for (final zone in ['Lomo', 'Cola']) {
          await tapText(t, zone);
          final thumbs = t.widgetList<PetThumb>(find.byType(PetThumb));
          expect(thumbs, isNotEmpty);
          expect(thumbs.every((thumb) => thumb.pose == PetPose.side), isTrue);
          final game =
              t.widget<SceneView>(find.byType(SceneView)).game as StageGame;
          expect(game.pet.pose, PetPose.side);
        }
        await tapText(t, 'Corte estándar · Cola');
        await tapText(t, 'Usar');
        expect(saved(backend).appearance.cuts[HairZone.tail], 'standard');
        expect(saved(backend).coins, 0);
        await tapText(t, 'Cabeza');
        expect(
          t
              .widgetList<PetThumb>(find.byType(PetThumb))
              .every((thumb) => thumb.pose == PetPose.front),
          isTrue,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
