import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/home.dart';

import 'support.dart';

http.Response reply(Object value, [int status = 200]) =>
    http.Response(jsonEncode(value), status);
AppController makeController(
  Future<http.Response> Function(http.Request) callback,
) => AppController(
  Api('http://test', client: MockClient(callback)),
  MemoryStore(),
)..ready = true;

void main() {
  testWidgets(
    'verification queue status updates only after an authenticated check',
    (tester) async {
      var state = 'retrying';
      final c =
          makeController((request) async {
              expect(request.url.path, '/auth/email-status');
              expect(request.headers['Authorization'], 'Bearer A');
              return reply({'email_delivery': state, 'retry_after': 15});
            })
            ..user = {'id': 'A', 'verified': false}
            ..token = 'A';
      await tester.pumpWidget(MaterialApp(home: TokenScreen(controller: c)));
      await tester.ensureVisible(
        find.byKey(const Key('email-delivery-status')),
      );
      await tester.tap(find.byKey(const Key('email-delivery-status')));
      await tester.pumpAndSettle();
      expect(find.text(emailDeliveryMessage('retrying')), findsOneWidget);
      expect(c.emailDelivery, 'retrying');
      state = 'smtp_accepted';
      await tester.tap(find.byKey(const Key('email-delivery-status')));
      await tester.pumpAndSettle();
      expect(find.text(emailDeliveryMessage('smtp_accepted')), findsOneWidget);
      expect(c.emailDelivery, 'smtp_accepted');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'public reset can request another code without exposing account delivery status',
    (tester) async {
      final requests = <http.Request>[];
      final c = makeController((request) async {
        requests.add(request);
        return reply({'email_delivery': 'requested'});
      });
      await tester.pumpWidget(
        MaterialApp(
          home: TokenScreen(
            controller: c,
            initialReset: true,
            initialEmail: 'reset@example.test',
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('resend-reset-code')));
      await tester.tap(find.byKey(const Key('resend-reset-code')));
      await tester.pumpAndSettle();
      expect(requests.single.url.path, '/auth/forgot');
      expect(requests.single.headers['Authorization'], isNull);
      expect(jsonDecode(requests.single.body), {'email': 'reset@example.test'});
      expect(find.text(emailDeliveryMessage('requested')), findsOneWidget);
      expect(find.byKey(const Key('email-delivery-status')), findsNothing);
      expect(find.byKey(const Key('email-reset-password')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'late email status from account A is ignored after account switch',
    (tester) async {
      final delayed = Completer<http.Response>();
      final c = makeController((_) => delayed.future)
        ..user = {'id': 'A', 'verified': false}
        ..token = 'A'
        ..emailDelivery = 'queued';
      await tester.pumpWidget(MaterialApp(home: TokenScreen(controller: c)));
      await tester.ensureVisible(
        find.byKey(const Key('email-delivery-status')),
      );
      await tester.tap(find.byKey(const Key('email-delivery-status')));
      await tester.pump();
      c.user = {'id': 'B', 'verified': false};
      c.token = 'B';
      delayed.complete(reply({'email_delivery': 'smtp_accepted'}));
      await tester.pumpAndSettle();
      expect(c.emailDelivery, 'queued');
      expect(find.text(emailDeliveryMessage('smtp_accepted')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'reset validates code before showing passwords and returns to manual login',
    (tester) async {
      final requests = <String>[];
      final c = makeController((r) async {
        requests.add(r.url.path);
        return reply({'ok': true, 'valid': true});
      });
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.ensureVisible(find.text('Kích hoạt / đặt lại'));
      await tester.tap(find.text('Kích hoạt / đặt lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email-reset-password')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('email-code')),
        'fixture-reset-code',
      );
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pumpAndSettle();
      expect(requests, ['/auth/reset/check']);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('email-code')),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        true,
      );
      await tester.enterText(
        find.byKey(const Key('email-reset-password')),
        'next-password-123',
      );
      await tester.enterText(
        find.byKey(const Key('email-reset-confirmation')),
        'mismatch',
      );
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pumpAndSettle();
      expect(requests, ['/auth/reset/check']);
      await tester.enterText(
        find.byKey(const Key('email-reset-confirmation')),
        'next-password-123',
      );
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pumpAndSettle();
      expect(requests, ['/auth/reset/check', '/auth/reset']);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(TokenScreen), findsNothing);
      expect(c.user, isNull);
      expect(c.token, isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'expired code keeps input, busy prevents duplicate verification',
    (tester) async {
      final delayed = Completer<http.Response>();
      var calls = 0;
      final c = makeController((_) async {
        calls++;
        return delayed.future;
      });
      await tester.pumpWidget(MaterialApp(home: TokenScreen(controller: c)));
      await tester.enterText(
        find.byKey(const Key('email-code')),
        'expired-fixture-code',
      );
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pump();
      expect(calls, 1);
      delayed.complete(
        reply({'detail': 'Invalid, expired or reused token'}, 400),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Mã chưa hợp lệ, đã hết hạn hoặc đã được sử dụng.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('email-code')))
            .controller!
            .text,
        'expired-fixture-code',
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'home verification opens resend; transport failure remains honest and does not block notes',
    (tester) async {
      final c =
          makeController(
              (_) async => reply({'email_delivery': 'delivery_failed'}),
            )
            ..user = {'id': 'A', 'verified': false}
            ..token = 'session';
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.tap(find.text('Xác minh'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resend-email-code')));
      await tester.pumpAndSettle();
      expect(
        find.text(emailDeliveryMessage('delivery_failed')),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(UnverifiedBanner), findsOneWidget);
      await tester.tap(find.byKey(const Key('new-note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-title')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('public code/reset form fits mobile with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = makeController((_) async => reply({'valid': true}));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: TokenScreen(controller: c, initialReset: true),
      ),
    );
    await tester.enterText(find.byKey(const Key('email-code')), 'fixture-code');
    await tester.ensureVisible(find.byKey(const Key('email-code-submit')));
    await tester.tap(find.byKey(const Key('email-code-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-reset-password')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
