import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import 'app_flow_test.dart' show boot, saved, reopen;
import 'features_test.dart' show backendWith;

class FailTrialWrite extends MemoryBackend {
  bool fail = false;
  @override
  Future<void> write(String name, String text) async {
    if (fail) throw StateError('unavailable');
    await super.write(name, text);
  }
}

void main() {
  setUp(rootBundle.clear);
  testWidgets(
    'failed start keeps trial; concurrent starts consume only once; abandon persists',
    (t) async {
      final backend = FailTrialWrite()
        ..files.addAll(backendWith((s) => s).files);
      await boot(t, backend);
      var controller = AppScope.read(t.element(find.byType(StatusBubbles)));
      backend.fail = true;
      expect(await controller.beginGame(GameId.fruit), isNull);
      expect(controller.canPlay(GameId.fruit), isTrue);
      expect(saved(backend).premiumTrialStartedUtc, isEmpty);
      backend.fail = false;
      final results = await Future.wait([
        controller.beginGame(GameId.fruit),
        controller.beginGame(GameId.fruit),
      ]);
      expect(results.whereType<String>().length, 1);
      controller.cancelActivity(results.whereType<String>().single);
      expect(controller.canPlay(GameId.fruit), isFalse);
      expect(saved(backend).coins, 0);
      await reopen(t, backend);
      controller = AppScope.read(t.element(find.byType(StatusBubbles)));
      expect(controller.canPlay(GameId.fruit), isFalse);
      expect(controller.canPlay(GameId.frisbee), isTrue);
    },
  );
}
