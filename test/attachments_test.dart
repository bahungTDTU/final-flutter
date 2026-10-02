import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/attachment_files.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/state/attachment_session.dart';
import 'package:note_together/ui/attachments.dart';

import 'support.dart';

const note = Note(
  id: 'note',
  title: 'Title',
  content: 'Unchanged content',
  revision: 7,
  updatedAt: '',
  role: 'owner',
);
Map<String, dynamic> record() => {
  'id': 'file',
  'name': 'fixture.txt',
  'kind': 'file',
  'media_type': 'text/plain',
  'size': 4,
};
http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
AppController make(MockClient client, [MemoryStore? store]) =>
    AppController(Api('http://test', client: client), store ?? MemoryStore())
      ..user = {'id': 'A'}
      ..token = 'A-token'
      ..notes = [note]
      ..ready = true;

void main() {
  testWidgets('Remote lock removes filename from an open delete confirmation', (
    tester,
  ) async {
    final c = make(MockClient((_) async => jsonResponse([record()])));
    await tester.pumpWidget(
      MaterialApp(
        home: AttachmentsDialog(controller: c, noteId: 'note', canEdit: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(
      find.text('Xóa fixture.txt; nội dung ghi chú vẫn giữ.'),
      findsOneWidget,
    );
    c.notes = [
      const Note(
        id: 'note',
        title: '',
        content: '',
        revision: 8,
        updatedAt: '',
        locked: true,
      ),
    ];
    await c.setPreferences({'dark': true});
    await tester.pumpAndSettle();
    expect(
      find.text('Xóa fixture.txt; nội dung ghi chú vẫn giữ.'),
      findsNothing,
    );
    expect(find.text('fixture.txt'), findsNothing);
    expect(
      find.text('Quyền truy cập đã thay đổi. Đóng và kiểm tra lại.'),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Xóa tệp'),
    );
    expect(confirm.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'Preview clears bytes and filename when peer deletes attachment',
    (tester) async {
      var exists = true;
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgaGgAAAGEAQFWjyAjAAAAAElFTkSuQmCC',
      );
      final c = make(
        MockClient(
          (request) async => request.url.path.endsWith('/file')
              ? http.Response.bytes(png, 200)
              : jsonResponse(exists ? [record()] : []),
        ),
      );
      final session = AttachmentSession(c, 'note');
      await session.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: AttachmentPreview(
            session: session,
            file: {...record(), 'kind': 'image'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      exists = false;
      await session.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('fixture.txt'), findsNothing);
      expect(find.text('Nội dung đã được che.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      c.dispose();
    },
  );
  test('Late binary after account switch or remote lock cannot enter preview; no persistent cache', () async {
    final store = MemoryStore(),
        sent = Completer<void>(),
        response = Completer<void>();
    final c = make(
      MockClient((_) async {
        sent.complete();
        await response.future;
        return http.Response('private bytes', 200);
      }),
      store,
    );
    final session = AttachmentSession(c, 'note');
    final read = session.read('file');
    final assertion = expectLater(read, throwsStateError);
    await sent.future;
    c.user = {'id': 'B'};
    c.token = 'B-token';
    session.checkGate();
    response.complete();
    await assertion;
    expect(session.files, isEmpty);
    expect(store.values, isEmpty);
    session.dispose();
    c.dispose();
  });
  test('Upload retry keeps ID/payload and never changes frozen note revision or note outbox', () async {
    final requests = <String>[];
    var fail = true;
    final c = make(
      MockClient((request) async {
        if (request.method == 'POST') {
          requests.add('${request.url}|${request.body}');
          if (fail) throw http.ClientException('lost acknowledgement');
          return jsonResponse(record());
        }
        return jsonResponse([record()]);
      }),
    );
    final session = AttachmentSession(c, 'note');
    final file = SelectedAttachment(
      'fixture.txt',
      Uint8List.fromList([1, 2, 3, 4]),
    );
    await expectLater(
      session.upload(file),
      throwsA(isA<http.ClientException>()),
    );
    fail = false;
    await session.upload(file);
    expect(requests[0], requests[1]);
    expect(c.notes.single.revision, 7);
    expect(c.pending, isEmpty);
    session.dispose();
    c.dispose();
  });
  test('Revoked list and lifecycle epoch invalidate already displayed metadata and future bytes', () async {
    var deny = false;
    final c = make(
      MockClient(
        (_) async => deny
            ? jsonResponse({'detail': 'unavailable'}, 404)
            : jsonResponse([record()]),
      ),
    );
    final session = AttachmentSession(c, 'note');
    await session.refresh();
    expect(session.files, hasLength(1));
    final oldEpoch = session.epoch;
    session.hide('background');
    expect(session.epoch, greaterThan(oldEpoch));
    expect(session.files, isEmpty);
    await session.refresh();
    deny = true;
    await session.refresh();
    expect(session.files, isEmpty);
    expect(session.error, contains('che'));
    session.dispose();
    c.dispose();
  });
  testWidgets(
    'Cancel and denied picker preserve selected retry; mobile scale2 dialog has no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempt = 0;
      final c = make(MockClient((_) async => jsonResponse([])));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    textScaler: TextScaler.linear(2),
                  ),
                  child: AttachmentsDialog(
                    controller: c,
                    noteId: 'note',
                    canEdit: true,
                    picker: () async {
                      attempt++;
                      if (attempt == 1) {
                        return [
                          SelectedAttachment(
                            'keep.txt',
                            Uint8List.fromList([65]),
                          ),
                        ];
                      }
                      if (attempt == 2) return [];
                      throw PlatformException(code: 'denied');
                    },
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(find.byKey(const Key('attachment-pick')));
        await tester.tap(find.byKey(const Key('attachment-pick')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Chờ tải: keep.txt'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Role downgrade disables an open attachment delete confirmation',
    (tester) async {
      final c = make(MockClient((_) async => jsonResponse([record()])));
      await tester.pumpWidget(
        MaterialApp(
          home: AttachmentsDialog(controller: c, noteId: 'note', canEdit: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xóa'));
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(
        find.text('Xóa fixture.txt; nội dung ghi chú vẫn giữ.'),
        findsOneWidget,
      );
      c.notes = [
        Note.fromJson({...c.notes.single.toJson(), 'role': 'viewer'}),
      ];
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      expect(
        find.text('Xóa fixture.txt; nội dung ghi chú vẫn giữ.'),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xóa tệp'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attachment-pick')), findsNothing);
      expect(find.text('fixture.txt'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Viewer has download access but no mutation controls; remote lock clears file names',
    (tester) async {
      final c = make(MockClient((_) async => jsonResponse([record()])));
      await tester.pumpWidget(
        MaterialApp(
          home: AttachmentsDialog(
            controller: c,
            noteId: 'note',
            canEdit: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('fixture.txt'), findsOneWidget);
      expect(find.byKey(const Key('attachment-pick')), findsNothing);
      expect(find.text('Xóa'), findsNothing);
      c.notes = [
        const Note(
          id: 'note',
          title: '',
          content: '',
          revision: 8,
          updatedAt: '',
          locked: true,
        ),
      ];
      // The controller's next notification comes from synchronization in production.
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      expect(find.text('fixture.txt'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
