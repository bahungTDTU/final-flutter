import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['PERFORMANCE_OUTPUT_DIR'] ?? 'output/performance',
  );
  await directory.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      // Screenshot bytes belong in PNGs, not a multi-megabyte JSON report.
      final report = {...?data}..remove('screenshots');
      await File('${directory.path}/android-frames.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
        flush: true,
      );
    },
    onScreenshot: (name, bytes, [args]) async {
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
