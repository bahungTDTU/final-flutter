import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:uuid/uuid.dart';

import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native locked pin/shared status, password cooldown and encrypted offline reopen',
    (tester) async {
      const url = String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8016',
      );
      const password = 'Native-status-2026!';
      const notePassword = 'Native-note-2026!';
      const uuid = Uuid();
      final api = Api(url);
      final filename = path.join(
        (await getApplicationSupportDirectory()).path,
        'qa-status-${uuid.v4()}.db',
      );
      var db = await databaseFactoryIo.openDatabase(filename);
      AppController makeController(Api service) => AppController(
        service,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      );
      var c = makeController(api)..setForeground(false);
      await c.initialize();
      final suffix = uuid.v4();
      expect(
        await c.authenticate(
          register: true,
          email: 'native-status-$suffix@example.test',
          password: password,
          confirmation: password,
          name: 'Native status',
        ),
        true,
      );
      final peer = await api.call(
        'POST',
        '/auth/register',
        body: {
          'email': 'native-peer-$suffix@example.test',
          'name': 'Peer',
          'password': password,
          'confirmation': password,
        },
      );
      for (var i = 0; i < 120 && c.syncing; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(c.syncing, false);
      final id = uuid.v4(), normal = uuid.v4();
      for (final key in [id, normal]) {
        await api.call(
          'POST',
          '/sync',
          token: c.token,
          body: {
            'op_id': uuid.v4(),
            'note_id': key,
            'base_revision': 0,
            'kind': 'upsert',
            'title': key == id ? 'Private native title' : 'Earlier pin',
            'content': key == id
                ? 'Private native body'
                : 'Visible ordinary body',
            'pinned_at': key == id
                ? '2026-10-07T02:00:00Z'
                : '2026-10-07T01:00:00Z',
          },
        );
      }
      await api.call(
        'POST',
        '/notes/$id/shares',
        token: c.token,
        body: {'email': peer['user']['email'], 'role': 'viewer'},
      );
      await api.call(
        'POST',
        '/notes/$id/protection',
        token: c.token,
        body: {'password': notePassword, 'confirmation': notePassword},
      );
      await c.synchronize();
      expect(c.notes.firstWhere((n) => n.id == id).isShared, true);
      expect(c.notes.firstWhere((n) => n.id == id).content, isEmpty);

      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      final card = find.byKey(ValueKey('card-$id'));
      Future<void> reveal() async {
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }

      bool converted = false;
      Future<void> picture(String name) async {
        if (!converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      void statusVisible() {
        expect(
          find.descendant(of: card, matching: find.text('Đã ghim')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.people_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.byIcon(Icons.lock_outline)),
          findsWidgets,
        );
        expect(find.text('Private native title'), findsNothing);
        expect(find.text('Private native body'), findsNothing);
        expect(find.text('Peer'), findsNothing);
      }

      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await reveal();
      statusVisible();
      await picture('native-status-grid');
      await tester.scrollUntilVisible(
        find.text('Danh sách'),
        -200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Danh sách'));
      await until(() => !c.grid && !c.syncing && c.pendingPreferences.isEmpty);
      await reveal();
      statusVisible();
      await picture('native-status-list');
      for (final action in [
        'unlock',
        'protection',
        'unlock',
        'protection',
        'protection',
      ]) {
        await expectLater(
          api.call(
            'POST',
            '/notes/$id/$action',
            token: c.token,
            body: action == 'unlock'
                ? {'password': 'wrong'}
                : {'current_password': 'wrong'},
          ),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
        );
      }
      await expectLater(
        api.call(
          'POST',
          '/notes/$id/protection',
          token: c.token,
          body: {'current_password': notePassword},
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 429)),
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        notePassword,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mở khóa'));
      await until(
        () => find.textContaining('Đợi một phút').evaluate().isNotEmpty,
      );
      expect(find.text('Private native body'), findsNothing);
      await picture('native-status-cooldown');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await databaseFactoryIo.openDatabase(filename);
      final offline = Api('http://127.0.0.1:65530');
      c = makeController(offline)..setForeground(false);
      await c.initialize();
      await c.synchronize(); // Actual unreachable socket, not a mocked offline flag.
      expect(c.online, false);
      expect(c.grid, false);
      expect(c.notes.firstWhere((n) => n.id == id).isShared, true);
      expect(c.notes.firstWhere((n) => n.id == id).content, isEmpty);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await reveal();
      statusVisible();
      await picture('native-status-offline-reopen');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      offline.client.close();
      api.client.close();
      await db.close();
      await databaseFactoryIo.deleteDatabase(filename);
    },
  );
}
