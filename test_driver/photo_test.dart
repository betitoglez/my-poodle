import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) throw StateError('Missing native photo evidence');
    final directory = Directory(
      Platform.environment['POODLE_PHOTO_EVIDENCE'] ?? '.build/photo-evidence',
    );
    await directory.create(recursive: true);
    for (final entry in {
      'nativePng': 'native.png',
      'photoPng': 'photo.png',
      'restingPhotoPng': 'resting-photo.png',
    }.entries) {
      final encoded = data.remove(entry.key) as String;
      await File('${directory.path}/${entry.value}')
          .writeAsBytes(base64Decode(encoded));
    }
    await File('${directory.path}/results.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln('Native photo evidence: ${directory.path}');
  },
);
