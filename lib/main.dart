import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'data/api.dart';
import 'data/encrypted_account_store.dart';
import 'data/local_store.dart';
import 'data/realtime_feed.dart';
import 'data/open_database.dart';
import 'state/app_controller.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter Web otherwise hides the semantics tree behind an off-screen
  // "Enable accessibility" button that most screen-reader users never find.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  try {
    final controller = AppController(
      Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      ),
      EncryptedAccountStore(
        SembastLocalStore(await openLocalDatabase()),
        const DeviceRecoveryKeys(),
      ),
      realtime: RealtimeFeed(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      ),
    );
    runApp(NoteTogetherApp(controller: controller));
    await controller.initialize();
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Không mở được kho local: $e')),
        ),
      ),
    );
  }
}
