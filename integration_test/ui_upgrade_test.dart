import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/editor.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native UI registration, labels, preferences and stable writing session',
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
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      });
      await c.initialize();
      await c.logout();
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      Future<void> type(Finder field, String value) async {
        tester.binding.focusedEditable = null;
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      bool converted = false;
      Future<void> picture(String name) async {
        if (!converted) {
          // This SDK registers restoration in test tearDown itself.
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump();
        final bytes = await binding.takeScreenshot(name);
        final directory = await getApplicationDocumentsDirectory();
        await File('${directory.path}/$name.png')
            .writeAsBytes(bytes, flush: true);
      }

      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      final email =
          'native-ui-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'native-ui-evidence-123';
      await type(find.byKey(const Key('auth-email')), email);
      await type(find.byKey(const Key('auth-name')), 'Không gian học tập');
      await type(find.byKey(const Key('auth-password')), password);
      await type(find.byKey(const Key('auth-confirmation')), password);
      await tester.ensureVisible(find.byKey(const Key('auth-submit')));
      await tester.tap(find.byKey(const Key('auth-submit')));
      await until(() => c.user != null && !c.busy && !c.syncing);
      expect(c.user!['email'], email);
      expect(c.user!['verified'], false);
      await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Giao diện tối'));
      await until(() => c.dark && !c.syncing && c.pendingPreferences.isEmpty);
      await tester.tap(find.byTooltip('Đóng tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm nhãn'));
      await tester.tap(find.text('Thêm nhãn'));
      await tester.pumpAndSettle();
      await type(find.byType(TextFormField), 'Học tập');
      await tester.tap(find.text('Xác nhận'));
      await until(
        () => c.labels.length == 1 && !c.syncing && c.pendingLabels.isEmpty,
      );
      await tester.ensureVisible(find.text('Đóng'));
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-note')));
      await tester.pumpAndSettle();
      await type(find.byKey(const Key('note-title')), 'Ghi chú buổi học');
      await type(
        find.byKey(const Key('note-content')),
        'Giữ ý tưởng và cùng nhau phát triển.',
      );
      await until(() => c.notes.length == 1 && !c.syncing && c.pending.isEmpty);
      final id = c.notes.single.id;
      final field = tester.widget<TextField>(
        find.byKey(const Key('note-content')),
      );
      final selection = field.controller!.selection;
      final themeAction = find.byTooltip('Đổi giao diện');
      if (themeAction.evaluate().isNotEmpty) {
        await tester.tap(themeAction);
      } else {
        // Compact editor exposes secondary actions through its real overflow menu.
        await tester.tap(find.byKey(const Key('editor-tools-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đổi giao diện'));
      }
      await until(() => !c.dark && !c.syncing && c.pendingPreferences.isEmpty);
      expect(tester.widget<EditorScreen>(find.byType(EditorScreen)).id, id);
      expect(field.controller!.text, 'Giữ ý tưởng và cùng nhau phát triển.');
      expect(field.controller!.selection, selection);
      await picture('android-editor-light');
      final remote = await api.call('GET', '/notes/$id', token: c.token);
      expect(remote['content'], field.controller!.text);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Danh sách'));
      await tester.tap(find.text('Danh sách'));
      await until(() => !c.grid && !c.syncing && c.pendingPreferences.isEmpty);
      await type(find.byKey(const Key('note-search')), 'buổi học');
      expect(find.text('Ghi chú buổi học'), findsOneWidget);
      await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Giao diện tối'));
      await until(() => c.dark && !c.syncing && c.pendingPreferences.isEmpty);
      await picture('android-settings-dark');
      await tester.tap(find.byTooltip('Đóng tùy chỉnh'));
      await tester.pumpAndSettle();
      await picture('android-home-dark');
      expect(tester.takeException(), isNull);
    },
  );
}
