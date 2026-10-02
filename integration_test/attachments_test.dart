import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/editor.dart';
import 'package:video_player/video_player.dart';

Future<void> until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 240 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(ready(), true);
  await tester.pumpAndSettle();
}

Future<void> idle(AppController c) async {
  for (var i = 0; i < 200 && c.syncing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(c.syncing, false);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Actual native attachment picker, private image/video preview and SAF save',
    (tester) async {
      final db = await openLocalDatabase();
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      final c = AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      );
      await c.initialize();
      await idle(c);
      await c.logout();
      final email =
          'native-attachments-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'attachments-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Attachment fixture',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await idle(c);
      final noteId = c.uuid.v4();
      await c.save(
        noteId,
        'Native attachment fixture',
        'Keep original content',
      );
      await idle(c);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final navigator = Navigator.of(
        tester.element(find.text('Ghi chú của bạn')),
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => EditorScreen(controller: c, id: noteId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đính kèm'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('attachment-pick')));
      await tester.tap(find.byKey(const Key('attachment-pick')));
      debugPrint(
        'QA_ATTACHMENT_PICKER_READY: choose attachment-fixture.png in DocumentsUI.',
      );
      await until(
        tester,
        () =>
            find.text('Chờ tải: attachment-fixture.png').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.byKey(const Key('attachment-upload')));
      await tester.tap(find.byKey(const Key('attachment-upload')));
      await until(
        tester,
        () => find.text('Server đã lưu tệp đính kèm.').evaluate().isNotEmpty,
      );
      final files = await api.call(
        'GET',
        '/notes/$noteId/attachments',
        token: c.token,
      ) as List;
      expect(files, hasLength(1));
      await tester.ensureVisible(find.text('Xem trước'));
      await tester.tap(find.text('Xem trước'));
      await until(tester, () => find.byType(Image).evaluate().isNotEmpty);
      expect(find.byType(Image), findsOneWidget);
      await api.call(
        'DELETE',
        '/notes/$noteId/attachments/${files.single['id']}',
        token: c.token,
      );
      await until(
        tester,
        () => find.text('Nội dung đã được che.').evaluate().isNotEmpty,
      );
      expect(find.byType(Image), findsNothing);
      debugPrint(
        'QA_PEER_DELETE_HIDDEN: active image preview cleared after attachment deletion.',
      );
      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      final peer = await api.call(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      final token = peer['token'] as String;
      await api.binary(
        'POST',
        '/notes/$noteId/attachments/${c.uuid.v4()}?name=attachment-fixture.mp4&kind=video',
        token: token,
        contentType: 'video/mp4',
        bytes: (await http.get(
          Uri.parse('http://127.0.0.1:8013/attachment-fixture.mp4'),
        )).bodyBytes,
      );
      await api.binary(
        'POST',
        '/notes/$noteId/attachments/${c.uuid.v4()}?name=attachment-fixture.txt&kind=file',
        token: token,
        contentType: 'text/plain',
        bytes: (await http.get(
          Uri.parse('http://127.0.0.1:8013/attachment-fixture.txt'),
        )).bodyBytes,
      );
      await tester.ensureVisible(find.text('Kiểm tra quyền và cập nhật'));
      await tester.tap(find.text('Kiểm tra quyền và cập nhật'));
      await until(
        tester,
        () => find.text('attachment-fixture.mp4').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Xem trước').last);
      await tester.tap(find.text('Xem trước').last);
      await until(tester, () => find.text('Phát video').evaluate().isNotEmpty);
      await tester.tap(find.text('Phát video'));
      await tester.pump(const Duration(seconds: 1));
      final player = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      expect(player.value.position, greaterThan(Duration.zero));
      debugPrint('QA_VIDEO_PLAYED: initialized H264 MP4; position advanced.');
      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tải xuống').last);
      await tester.tap(find.text('Tải xuống').last);
      debugPrint(
        'QA_ATTACHMENT_SAVE_READY: save attachment-fixture.txt through DocumentsUI.',
      );
      await until(
        tester,
        () =>
            find.text('Đã lưu file vào vị trí bạn chọn.').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Kiểm tra quyền và cập nhật'));
      await tester.tap(find.text('Kiểm tra quyền và cập nhật'));
      await until(
        tester,
        () => find.text('attachment-fixture.txt').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Xóa').last);
      await tester.tap(find.text('Xóa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa tệp'));
      await tester.pumpAndSettle();
      expect(
        (await api.call('GET', '/notes/$noteId/attachments', token: token)
            as List),
        hasLength(1),
      );
      final after = await api.call('GET', '/notes/$noteId', token: token);
      expect(after['content'], 'Keep original content');
      expect(after['revision'], 1);
      await tester.ensureVisible(find.text('Xóa'));
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      await api.call(
        'POST',
        '/notes/$noteId/protection',
        token: token,
        body: {
          'password': 'attachment-lock-password',
          'confirmation': 'attachment-lock-password',
        },
      );
      await until(
        tester,
        () => find
            .text('Quyền truy cập đã thay đổi. Đóng và kiểm tra lại.')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('Xóa attachment-fixture.mp4; nội dung ghi chú vẫn giữ.'),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xóa tệp'))
            .onPressed,
        isNull,
      );
      debugPrint(
        'QA_LOCK_CONFIRM_HIDDEN: remote lock clears filename and disables delete confirmation.',
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await api.call(
        'POST',
        '/notes/$noteId/protection',
        token: token,
        body: {
          'current_password': 'attachment-lock-password',
          'password': null,
        },
      );
      final restored = await api.call('GET', '/notes/$noteId', token: token);
      expect(restored['content'], 'Keep original content');
      expect(restored['revision'], 3);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );
}
