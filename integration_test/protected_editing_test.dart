import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/data/realtime_feed.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

class SocketOfflineClient extends http.BaseClient {
  final live = http.Client();
  bool offline = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (offline) {
      // Actual connection refusal, no fabricated HTTP response; not an OS Wi-Fi toggle.
      await live.send(
        http.Request('GET', Uri.parse('http://127.0.0.1:65530/health')),
      );
      throw StateError('Offline QA port65530 unexpectedly accepts connections');
    }
    return live.send(request);
  }

  @override
  void close() {
    live.close();
    super.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native protected edits: SSE, frozen base, encrypted offline reopen, unlock revalidation and confirmed delete',
    (tester) async {
      var db = await openLocalDatabase();
      final transport = SocketOfflineClient();
      const base = String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8000',
      );
      var api = Api(base, client: transport);
      AppController make(Api api) => AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
        realtime: RealtimeFeed(base),
      );
      var c = make(api);
      await c.initialize();
      await c.logout();
      final email =
          'protected-native-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const accountPassword = 'Protected-native-2026!',
          notePassword = 'protected-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Protected Native QA',
          password: accountPassword,
          confirmation: accountPassword,
        ),
        true,
      );
      final id = c.uuid.v4();
      await c.save(id, 'Protected native core', 'Protected initial body');
      await c.synchronize();
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 300 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      await until(() => !c.syncing && c.pending.isEmpty && c.drafts.isEmpty);
      // Set up the protected fixture through the real API. An SSE refresh may
      // begin between idle observation and a controller owner command.
      await api.call(
        'POST',
        '/notes/$id/protection',
        token: c.token,
        body: {'password': notePassword, 'confirmation': notePassword},
      );
      await c.synchronize();
      await until(() => c.notes.any((note) => note.id == id && note.locked));
      final peer = await api.call(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': accountPassword},
      );
      final peerToken = peer['token'] as String;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      Future<void> open() async {
        await tester.tap(find.text('Ghi chú đã khóa'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('unlock-note-password')),
          notePassword,
        );
        await tester.tap(find.byKey(const Key('unlock-note')));
        await until(
          () =>
              find
                  .byKey(const Key('protected-content'))
                  .evaluate()
                  .isNotEmpty ||
              find
                  .byKey(const Key('protected-content-editor'))
                  .evaluate()
                  .isNotEmpty,
        );
      }

      await open();
      await api.call(
        'POST',
        '/notes/$id/unlock',
        token: peerToken,
        body: {'password': notePassword},
      );
      final remote = await api.call('GET', '/notes/$id', token: peerToken);
      await api.call(
        'POST',
        '/sync',
        token: peerToken,
        body: {
          'op_id': c.uuid.v4(),
          'note_id': id,
          'base_revision': remote['revision'],
          'kind': 'upsert',
          'title': 'Protected native core',
          'content': 'Peer protected live content',
          'labels': [],
          'labels_format': 'ids',
        },
      );
      await until(
        () => find.text('Peer protected live content').evaluate().isNotEmpty,
      );
      expect(find.text('Chỉnh sửa phiên bản mới'), findsOneWidget);
      await tester.ensureVisible(find.text('Chỉnh sửa phiên bản mới'));
      await tester.tap(find.text('Chỉnh sửa phiên bản mới'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('protected-content-editor')),
        'Native protected autosave',
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));
      await until(() => find.text('Đã đồng bộ').evaluate().isNotEmpty);
      expect(
        (await api.call('GET', '/notes/$id', token: peerToken))['content'],
        'Native protected autosave',
      );
      expect(c.pending, isEmpty);
      expect(c.drafts.containsKey(id), false);
      expect(
        jsonEncode(c.notes.map((n) => n.toJson()).toList()),
        isNot(contains('Native protected autosave')),
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('protected-native-editor');
      c.realtime?.stop();
      transport.offline = true;
      await c.synchronize();
      await tester.pumpAndSettle();
      expect(c.online, false);
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        notePassword,
      );
      await tester.tap(find.byKey(const Key('unlock-note')));
      await until(
        () => find.byKey(const Key('protected-content')).evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Chỉnh sửa'));
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('protected-content-editor')),
        'Protected offline survives encrypted reopen',
      );
      await tester.pumpAndSettle();
      await c.readProtectedEnvelope(id, c.user!['id'] as String);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await openLocalDatabase();
      api = Api(base);
      c = make(api);
      await c.initialize();
      await c.synchronize();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await open();
      await until(() => find.text('Đã đồng bộ').evaluate().isNotEmpty);
      final freshToken = c.token;
      expect(
        (await api.call('GET', '/notes/$id', token: freshToken))['content'],
        'Protected offline survives encrypted reopen',
      );
      expect(c.pending, isEmpty);
      expect(c.notes.single.content, isEmpty);
      await binding.takeScreenshot('protected-native-reopened');
      await tester.ensureVisible(find.byKey(const Key('protected-delete')));
      await tester.tap(find.byKey(const Key('protected-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('protected-delete-confirm')));
      await until(
        () => find.text('Ghi chú đã khóa').evaluate().isEmpty && !c.syncing,
      );
      await expectLater(
        api.call('GET', '/notes/$id', token: freshToken),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );
}
