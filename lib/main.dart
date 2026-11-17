import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientación vertical también en los minijuegos.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyPoodleApp());
}
