import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/state/app_controller.dart';

import 'support.dart';

void main() {
  test(
    'Offline preferences persist per account and survive controller reopen',
    () async {
      final store = MemoryStore();
      final c = offlineController(store: store);
      await store.write('session', {'user': c.user, 'token': c.token});
      await c.setPreferences({'dark': true, 'font_size': 22.0, 'grid': false});
      final op = Map<String, dynamic>.from(c.pendingPreferences.single);
      while (c.syncing) {
        await Future<void>.delayed(Duration.zero);
      }
      c.dispose();
      final reopened = AppController(
        Api(
          'http://test',
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
        store,
      );
      await reopened.initialize();
      expect(reopened.dark, true);
      expect(reopened.grid, false);
      expect(reopened.fontSize, 22);
      expect(reopened.pendingPreferences.single, op);
      await reopened.logout();
      expect(reopened.dark, false);
      expect(reopened.pendingPreferences, isEmpty);
      expect((await store.read('account:A'))!['pending_preferences'], [op]);
      reopened.dispose();
    },
  );

  test(
    'Changes during sync overlay latest server values without losing queue',
    () async {
      final blocked = Completer<http.Response>();
      final calls = <Map<String, dynamic>>[];
      var profile = {'grid': true, 'dark': false, 'font_size': 16.0};
      final client = MockClient((request) async {
        if (request.url.path == '/me/preferences/sync') {
          final op = Map<String, dynamic>.from(jsonDecode(request.body));
          calls.add(op);
          return blocked.future;
        }
        if (request.url.path == '/notes') return http.Response('[]', 200);
        return http.Response(
          jsonEncode({'id': 'A', 'name': 'A', 'preferences': profile}),
          200,
        );
      });
      final c = AppController(
        Api('http://test', client: client),
        MemoryStore(),
      );
      c.user = {'id': 'A'};
      c.token = 'token';
      await c.setPreferences({'dark': true});
      while (calls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await c.setPreferences({'font_size': 22.0});
      profile = {'grid': false, 'dark': true, 'font_size': 18.0};
      blocked.complete(http.Response('{}', 200));
      while (c.syncing) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.grid, false);
      expect(c.dark, true);
      expect(c.fontSize, 22);
      expect(c.pendingPreferences.single['font_size'], 22);
      expect(calls.single, {'op_id': calls.single['op_id'], 'dark': true});
      c.dispose();
    },
  );
}
