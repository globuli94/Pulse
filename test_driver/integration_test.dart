import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('screenshots');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    for (final entry in data.entries) {
      final bytes = base64Decode(entry.value as String);
      File('screenshots/${entry.key}.png').writeAsBytesSync(bytes);
      print('Saved screenshots/${entry.key}.png');
    }
  },
);
