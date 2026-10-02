import 'package:flutter/material.dart';

import 'data/api.dart';
import 'data/encrypted_account_store.dart';
import 'data/local_store.dart';
import 'data/realtime_feed.dart';
import 'data/open_database.dart';
import 'state/app_controller.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
