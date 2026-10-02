import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/state/protected_reader.dart';
import 'package:note_together/ui/note_protection.dart';

import 'support.dart';

const metadata = Note(
  id: 'n',
  title: 'Ghi chú đã khóa',
  content: '',
  revision: 2,
  updatedAt: '',
  locked: true,
);
const secret = {
  'id': 'n',
  'title': 'Private title',
  'content': 'Private body',
  'revision': 2,
  'updated_at': '',
  'locked': true,
  'role': 'owner',
};
http.Response response(Object value, [int status = 200]) =>
    http.Response(jsonEncode(value), status);
AppController controller(
  Future<http.Response> Function(http.Request) handler, {
  MemoryStore? store,
}) =>
    AppController(
        Api('http://test', client: MockClient(handler)),
        store ?? MemoryStore(),
      )
      ..user = {'id': 'A'}
      ..token = 'session'
      ..notes = [metadata];

void main() {
  test('enable redacts and persists before failed refresh, blocks unfinished edits and viewers', () async {
    final local = MemoryStore();
    var calls = 0;
    final c = controller((r) async {
      calls++;
      if (r.url.path.endsWith('/protection')) {
        return response({'revision': 2, 'locked': true});
      }
      throw http.ClientException('offline');
    }, store: local);
    c.notes = [
      const Note(
        id: 'n',
        title: 'Private title',
        content: 'Private body',
        revision: 1,
        updatedAt: '',
      ),
    ];
    c.drafts['n'] = {'title': 'unfinished', 'content': 'edit'};
    await expectLater(
      c.changeNoteProtection(
        'n',
        currentPassword: '',
        password: 'note-password-123',
      ),
      throwsStateError,
    );
    expect(calls, 0);
    c.drafts.clear();
    await c.changeNoteProtection(
      'n',
      currentPassword: '',
      password: 'note-password-123',
    );
    expect(c.notes.single.content, isEmpty);
    expect(c.notes.single.locked, true);
    expect(
      jsonEncode(await local.read(c.accountKey)),
      isNot(contains('Private body')),
    );
    expect(c.recoveries, isEmpty);
    c.notes = [
      Note.fromJson({...metadata.toJson(), 'role': 'viewer'}),
    ];
    final before = calls;
    await expectLater(
      c.changeNoteProtection('n', currentPassword: '', password: null),
      throwsStateError,
    );
    expect(calls, before);
    c.dispose();
  });

  test(
    'reader never fills ordinary cache, clears on permission loss and offline',
    () async {
      var reject = false;
      final c = controller((r) async {
        if (r.url.path.endsWith('/unlock')) {
          return response({'expires_in': 300});
        }
        if (r.url.path.endsWith('/lock')) return response({'ok': true});
        return reject ? response({'detail': 'revoked'}, 404) : response(secret);
      });
      final reader = ProtectedReader(c, 'n');
      await reader.unlock('note-password-123');
      expect(reader.note!.content, 'Private body');
      expect(c.notes.single.content, isEmpty);
      expect(c.drafts, isEmpty);
      expect(c.pending, isEmpty);
      reject = true;
      await reader.refresh();
      expect(reader.note, isNull);
      reject = false;
      await reader.unlock('note-password-123');
      c.online = false;
      c.notifyListeners();
      expect(reader.note, isNull);
      reader.dispose();
      c.dispose();
    },
  );

  test(
    'closing during unlock orders revoke before another reader unlocks',
    () async {
      final delayed = Completer<http.Response>();
      final paths = <String>[];
      var unlocks = 0;
      final c = controller((r) async {
        paths.add(r.url.path);
        if (r.url.path.endsWith('/unlock')) {
          return ++unlocks == 1
              ? delayed.future
              : response({'expires_in': 300});
        }
        return response(r.url.path.endsWith('/lock') ? {'ok': true} : secret);
      });
      final old = ProtectedReader(c, 'n');
      final first = old.unlock('note-password-123');
      await Future<void>.delayed(Duration.zero);
      old.dispose();
      final fresh = ProtectedReader(c, 'n');
      final second = fresh.unlock('note-password-123');
      delayed.complete(response({'expires_in': 300}));
      await first;
      await second;
      expect(old.note, isNull);
      expect(fresh.note!.content, 'Private body');
      expect(paths, [
        '/notes/n/unlock',
        '/notes/n/lock',
        '/notes/n/unlock',
        '/notes/n',
      ]);
      fresh.dispose();
      c.dispose();
    },
  );

  test(
    'wrong unlock can retry; logout invalidates a pending content response',
    () async {
      final delayed = Completer<http.Response>();
      var first = true;
      final c = controller((r) async {
        if (r.url.path.endsWith('/unlock')) {
          if (first) {
            first = false;
            return response({'detail': 'wrong'}, 403);
          }
          return response({'expires_in': 300});
        }
        if (r.url.path.endsWith('/lock')) return response({'ok': true});
        return delayed.future;
      });
      final reader = ProtectedReader(c, 'n');
      await reader.unlock('wrong');
      expect(reader.note, isNull);
      expect(reader.busy, false);
      final opening = reader.unlock('correct');
      await Future<void>.delayed(Duration.zero);
      c.user = null;
      c.token = null;
      c.notifyListeners();
      delayed.complete(response(secret));
      await opening;
      expect(reader.note, isNull);
      expect(reader.active, false);
      reader.dispose();
      c.dispose();
    },
  );

  testWidgets('lease expires and hides late content', (tester) async {
    final delayed = Completer<http.Response>();
    final c = controller((r) async {
      if (r.url.path.endsWith('/unlock')) return response({'expires_in': 1});
      if (r.url.path.endsWith('/lock')) return response({'ok': true});
      return delayed.future;
    });
    final reader = ProtectedReader(c, 'n');
    final opening = reader.unlock('note-password-123');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    delayed.complete(response(secret));
    await tester.pump();
    await opening;
    expect(reader.note, isNull);
    reader.dispose();
    c.dispose();
  });

  testWidgets(
    'viewer reader has no owner controls and hides on app background',
    (tester) async {
      final c = controller((r) async {
        if (r.url.path.endsWith('/unlock')) {
          return response({'expires_in': 300});
        }
        if (r.url.path.endsWith('/lock')) return response({'ok': true});
        return response({...secret, 'role': 'viewer'});
      });
      c.notes = [
        Note.fromJson({...metadata.toJson(), 'role': 'viewer'}),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ProtectedNoteScreen(controller: c, id: 'n'),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        'note-password-123',
      );
      await tester.tap(find.byKey(const Key('unlock-note')));
      await tester.pumpAndSettle();
      expect(find.text('Private body'), findsOneWidget);
      expect(find.text('Đổi mật khẩu ghi chú'), findsNothing);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Private body'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('wrong current password keeps dialog inputs for a retry', (
    tester,
  ) async {
    final c = controller(
      (r) async => response({'detail': 'Current note password incorrect'}, 403),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => NoteProtectionDialog(
                controller: c,
                id: 'n',
                action: ProtectionAction.change,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    for (final key in [
      'note-current-password',
      'note-new-password',
      'note-confirm-password',
    ]) {
      await tester.enterText(find.byKey(Key(key)), 'note-password-123');
    }
    await tester.tap(find.byKey(const Key('confirm-note-protection')));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu ghi chú hiện tại chưa đúng.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('note-new-password')))
          .controller!
          .text,
      'note-password-123',
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
