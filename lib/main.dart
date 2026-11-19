import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app_root.dart';
import 'app/effect_playback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientación vertical también en los minijuegos.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyPoodleApp(effectPlayback: AssetEffectPlayback()));
}
