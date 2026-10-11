import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/state/security_session.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/security_center.dart';

import 'encrypted_recovery_test.dart' show TestKeys;
import 'maintenance_regression_test.dart' show StalledClient;
import 'support.dart';

Map<String, dynamic> sessionRows({bool other = true}) => {
  'total': other ? 2 : 1,
  'limit': 20,
  'sessions': [
    {
      'id': 'current',
      'label': 'Chrome · Windows',
      'created_at': '2026-10-11T01:00:00Z',
      'expires_at': '2026-10-12T01:00:00Z',
      'is_current': true,
    },
    if (other)
      {
        'id': 'other',
        'label': 'Ứng dụng · Android',
        'created_at': null,
        'expires_at': '2026-10-12T01:00:00Z',
        'is_current': false,
      },
  ],
};

class SessionApi extends Api {
  SessionApi() : super('http://fixture');
  dynamic rows = sessionRows();
  Object? error;
  Completer<dynamic>? gate;
  Future<void>? cancellation;
  int reads = 0, revocations = 0;
  Map<String, dynamic>? submitted;
  @override
  Future<dynamic> call(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
    Future<void>? cancellation,
  }) async {
    if (path == '/auth/logout') return {'ok': true};
    if (path == '/me/sessions') {
      reads++;
      this.cancellation = cancellation;
      if (gate != null) return gate!.future;
      if (error != null) throw error!;
      return rows;
    }
    if (path == '/me/sessions/revoke') {
      revocations++;
      submitted = body;
      if (error != null) throw error!;
      rows = sessionRows(other: false);
      return {'ok': true, 'revoked': 1};
    }
    throw const FormatException('Non-security fixture is offline');
  }
}

AppController signedIn(SessionApi api, {MemoryStore? store}) =>
    AppController(api, store ?? MemoryStore())
      ..user = {'id': 'A', 'name': 'Owner', 'verified': true}
      ..token = 'fixture-token'
      ..ready = true;

void main() {
  test('online session controls never write metadata/password to draft/outbox or local store', () async {
    final api = SessionApi(), store = MemoryStore();
    final c = signedIn(api, store: store);
    final s = SecuritySession(c);
    addTearDown(s.dispose);
    addTearDown(c.dispose);
    await c.draft('n', 'Unfinished', 'Keep this draft');
    final before = jsonEncode(store.values);
    await s.refresh();
    expect(s.otherCount, 1);
    expect(s.sessions.last.createdAt, isNull);
    expect(() => s.sessions.clear(), throwsUnsupportedError);
    expect(await s.revoke('confirmed password', id: 'current'), false);
    expect(api.revocations, 0);
    expect(await s.revoke('confirmed password', id: 'other'), true);
    expect(api.submitted, {
      'scope': 'one',
      'password': 'confirmed password',
      'session_id': 'other',
    });
    expect(api.reads, 2);
    expect(s.otherCount, 0);
    expect(jsonEncode(store.values), before);
    expect(c.drafts['n']['content'], 'Keep this draft');
    expect(c.pending, isEmpty);
    api.rows = sessionRows();
    await s.refresh();
    expect(await s.revoke('confirmed password'), true);
    expect(api.submitted!.containsKey('session_id'), false);
  });

  test('wrong password permits retry; timeout hides stale actions until a successful reload', () async {
    final api = SessionApi();
    final controller = signedIn(api);
    final s = SecuritySession(controller);
    addTearDown(s.dispose);
    addTearDown(controller.dispose);
    await s.refresh();
    api.error = ApiException(403, 'wrong');
    expect(await s.revoke('wrong', id: 'other'), false);
    expect(s.canManage, true);
    expect(s.message, contains('chưa đúng'));
    api.error = TimeoutException('response lost after server commit');
    expect(await s.revoke('secret', id: 'other'), false);
    expect(s.sessions, isEmpty);
    expect(s.canManage, false);
    api.error = null;
    api.rows = sessionRows(other: false);
    await s.refresh();
    expect(s.canManage, true);
    expect(s.otherCount, 0);
  });

  test(
    'invalid, duplicated or oversized catalogue fails closed and can recover',
    () async {
      final api = SessionApi();
      final controller = signedIn(api);
      final active = SecuritySession(controller);
      addTearDown(active.dispose);
      addTearDown(controller.dispose);
      for (final bad in [
        {...sessionRows(), 'limit': 21},
        {
          ...sessionRows(),
          'sessions': [
            sessionRows()['sessions'][0],
            sessionRows()['sessions'][0],
          ],
        },
        {
          ...sessionRows(),
          'total': 21,
          'sessions': List.filled(21, sessionRows()['sessions'][0]),
        },
        {
          ...sessionRows(),
          'sessions': [
            {'id': 'x'},
          ],
        },
      ]) {
        api.rows = bad;
        await active.refresh();
        expect(active.sessions, isEmpty);
        expect(active.canManage, false);
      }
      api.rows = sessionRows();
      await active.refresh();
      expect(active.canManage, true);
    },
  );

  test('background cancels requests and ignores late responses; resume fetches once', () async {
    final api = SessionApi();
    final c = signedIn(api), gate = Completer<dynamic>();
    final s = SecuritySession(c);
    addTearDown(s.dispose);
    addTearDown(c.dispose);
    api.gate = gate;
    final reading = s.refresh();
    var cancelled = false;
    api.cancellation!.then((_) => cancelled = true);
    c.setForeground(false);
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, true);
    expect(s.busy, false);
    api.gate = null;
    c.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(api.reads, 2);
    expect(s.sessions.last.id, 'other');
    gate.complete(sessionRows(other: false));
    await reading;
    expect(s.sessions.last.id, 'other');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(api.reads, 2);
  });

  test('background aborts the actual HTTP request rather than only dropping the result', () async {
    final client = StalledClient();
    final c =
        AppController(Api('http://fixture', client: client), MemoryStore())
          ..user = {'id': 'A'}
          ..token = 'fixture-token';
    final s = SecuritySession(c);
    addTearDown(s.dispose);
    addTearDown(c.dispose);
    final reading = s.refresh();
    c.setForeground(false);
    await client.aborted.future;
    await reading;
    expect(s.sessions, isEmpty);
    expect(s.busy, false);
    expect(s.canManage, false);
  });

  test(
    'same-account token switch and route disposal cancel and discard results',
    () async {
      for (final mode in ['token', 'account', 'dispose']) {
        final api = SessionApi(), gate = Completer<dynamic>();
        final c = signedIn(api);
        final active = SecuritySession(c);
        api.gate = gate;
        final read = active.refresh();
        var cancelled = false;
        api.cancellation!.then((_) => cancelled = true);
        if (mode == 'dispose') {
          active.dispose();
        } else {
          if (mode == 'token') c.token = 'fresh-session';
          if (mode == 'account') c.user = {'id': 'B'};
          c.notifyListeners();
        }
        await Future<void>.delayed(Duration.zero);
        expect(cancelled, true);
        gate.complete(sessionRows());
        await read;
        expect(active.sessions, isEmpty);
        if (mode != 'dispose') active.dispose();
        c.dispose();
      }
    },
  );

  test('expired token retires encrypted session while durable encrypted drafts remain', () async {
    final raw = MemoryStore(), keys = TestKeys(), api = SessionApi();
    final local = EncryptedAccountStore(raw, keys);
    final c = AppController(api, local)
      ..user = {'id': 'A', 'name': 'Owner'}
      ..token = 'fixture-token';
    final s = SecuritySession(c);
    addTearDown(s.dispose);
    addTearDown(c.dispose);
    await local.write('session', {'user': c.user, 'token': c.token});
    await c.draft('n', 'Durable', 'Unfinished body');
    final encrypted = await raw.read('account:A');
    api.error = ApiException(401, 'expired');
    await s.refresh();
    expect(c.token, isNull);
    expect(await local.read('session'), isNull);
    expect(await raw.read('account:A'), encrypted);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Unfinished body',
    );
    expect(jsonEncode(raw.values), isNot(contains('Unfinished body')));
  });

  testWidgets(
    'confirmation keeps retry input on resize, clears on background, and handles 320px/200%/keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final api = SessionApi();
      final controller = signedIn(api);
      var large = false;
      Widget host() => MaterialApp(
        theme: noteTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(large ? 2 : 1),
            viewInsets: EdgeInsets.only(bottom: large ? 160 : 0),
          ),
          child: child!,
        ),
        home: SecurityCenterScreen(controller: controller),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('revoke-current')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('revoke-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận thu hồi'));
      await tester.pumpAndSettle();
      expect(api.revocations, 0);
      final field = find.byType(TextFormField);
      await tester.enterText(field, 'wrong-password');
      api.error = ApiException(403, 'wrong');
      await tester.tap(find.text('Xác nhận thu hồi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('chưa đúng'), findsWidgets);
      large = true;
      tester.view.physicalSize = const Size(320, 760);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'wrong-password',
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        true,
      );
      controller.setForeground(false);
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(find.text('wrong-password'), findsNothing);
      api.error = null;
      controller.setForeground(true);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
      await tester.enterText(field, 'correct');
      await tester.ensureVisible(find.text('Xác nhận thu hồi'));
      await tester.tap(find.text('Xác nhận thu hồi'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Đang dùng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đang dùng'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
