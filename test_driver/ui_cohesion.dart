import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot:
      (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final folder = Directory(
          Platform.environment['UI_SCREENSHOT_DIR'] ??
              'output/native-ui-cohesion',
        );
        await folder.create(recursive: true);
        await File('${folder.path}/$name.png').writeAsBytes(bytes, flush: true);
        return true;
      },
);
