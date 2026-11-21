import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Captura el framebuffer del simulador, incluidos los WKWebView/WebGL nativos.
Future<void> main() async {
  final device =
      Platform.environment['TABLET_SIMULATOR'] ??
      '9495CF14-6CFE-4489-8D61-5A80673C803F';
  final output = Directory(
    Platform.environment['TABLET_OUTPUT'] ?? '../reviews/tablet-13-20261121',
  )..createSync(recursive: true);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 18476);
  final names = <String>[];
  server.listen((request) async {
    final name = request.uri.queryParameters['name'] ?? '';
    if (request.uri.path != '/capture' ||
        !RegExp(r'^\d\d-[a-z0-9-]+$').hasMatch(name)) {
      request.response.statusCode = 400;
      await request.response.close();
      return;
    }
    final result = await Process.run('xcrun', [
      'simctl',
      'io',
      device,
      'screenshot',
      '--type=png',
      '${output.path}/$name.png',
    ]);
    if (result.exitCode != 0) {
      request.response.statusCode = 500;
      request.response.write(result.stderr);
    } else {
      names.add(name);
      request.response.write('ok');
      stdout.writeln('TABLET_SCREENSHOT=$name');
    }
    await request.response.close();
  });
  try {
    await integrationDriver(
      responseDataCallback: (data) async {
        final report = {
          'device': 'iPad Pro 13-inch (M5)',
          'simulator': device,
          'runtime': 'iOS 26.5',
          'capture': 'simctl framebuffer, native WKWebView 3D enabled',
          'files': names,
          ...?data,
        };
        File(
          '${output.path}/manifest.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      },
    );
  } finally {
    await server.close(force: true);
  }
}
