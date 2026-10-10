import 'dart:async';

import 'package:note_together/ui/rich_note_field.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/realtime_feed.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/editor.dart';

import 'support.dart';

class Wire extends http.BaseClient {
  final bytes = StreamController<List<int>>();
  http.BaseRequest? request;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    request = value;
    return http.StreamedResponse(
      bytes.stream,
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  }

  void event(String name, [int version = 1]) => bytes.add(
    utf8.encode(
      'event: $name\ndata: ${name == 'expired' ? '{}' : '{"version":$version}'}\n\n',
    ),
  );
  @override
  void close() {
    closed = true;
    if (!bytes.isClosed) unawaited(bytes.close());
  }
}

Future<void> until(bool Function() value) async {
  for (var i = 0; i < 300 && !value(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(value(), true);
}

http.Response answer(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);
Note note(int revision, String content) => Note(
  id: 'n',
  title: 'Title',
  content: content,
  revision: revision,
  updatedAt: '',
  role: 'editor',
);

void main() {
  test(
    'SSE parser handles chunk boundaries, comments, CRLF and expiration',
    () async {
      final source = utf8.encode(
        ': heartbeat\r\n\r\nevent: ready\r\ndata: {"version":2}\r\n\r\n'
        'event: changed\ndata: {"version":3}\n\nevent: expired\ndata: {}\n\n',
      );
      final frames = await parseRealtime(
        Stream.fromIterable(source.map((b) => [b])),
      ).toList();
      expect(frames.map((f) => f.event), ['ready', 'changed', 'expired']);
      expect(frames.map((f) => f.version), [2, 3, null]);
    },
  );
  test('Malformed, sensitive or oversized frames are rejected', () async {
    for (final data in [
      '{"version":-1}',
      '{"version":1,"title":"secret"}',
      '{"version":"1"}',
      'x' * 4100,
    ]) {
      await expectLater(
        parseRealtime(
          Stream.value(utf8.encode('event: changed\ndata: $data\n\n')),
        ).toList(),
        throwsFormatException,
      );
    }
  });
  test(
    'Reconnect catches up, deduplicates changes and never puts token in URL',
    () async {
      final wires = <Wire>[];
      var refresh = 0;
      final feed = RealtimeFeed(
        'http://test',
        retryBase: const Duration(milliseconds: 10),
        clientFactory: () {
          final wire = Wire();
          wires.add(wire);
          return wire;
        },
      );
      addTearDown(feed.stop);
      feed.start(
        'fixture-token',
        onRefresh: () => refresh++,
        onExpired: () => fail('expired'),
        onState: (_) {},
      );
      await until(() => wires.isNotEmpty && wires.first.request != null);
      expect(wires.first.request!.url.toString(), 'http://test/events');
      expect(
        wires.first.request!.headers['Authorization'],
        'Bearer fixture-token',
      );
      wires.first.event('ready', 4);
      wires.first.event('changed', 4);
      wires.first.event('changed', 5);
      await until(() => refresh == 2);
      wires.first.close();
      await until(() => wires.length == 2 && wires.last.request != null);
      wires.last.event('ready', 5);
      await until(() => refresh == 3);
      expect(feed.status, RealtimeStatus.live);
    },
  );
  test(
    'Account replacement and stop cancel old stream and reconnect timers',
    () async {
      final wires = <Wire>[];
      var first = 0, second = 0;
      final feed = RealtimeFeed(
        'http://test',
        retryBase: const Duration(milliseconds: 10),
        clientFactory: () {
          final wire = Wire();
          wires.add(wire);
          return wire;
        },
      );
      addTearDown(feed.stop);
      feed.start(
        'A',
        onRefresh: () => first++,
        onExpired: () {},
        onState: (_) {},
      );
      await until(() => wires.isNotEmpty && wires.first.request != null);
      wires.first.event(
        'changed',
        9,
      ); // Queued old callback must not cross account boundary.
      feed.start(
        'B',
        onRefresh: () => second++,
        onExpired: () {},
        onState: (_) {},
      );
      await until(() => wires.length == 2 && wires.last.request != null);
      wires.last.event('ready', 1);
      await until(() => second == 1);
      expect(first, 0);
      await until(() => wires.first.closed);
      expect(wires.first.closed, true);
      feed.stop();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(wires.length, 2);
      expect(wires.last.closed, true);
      expect(feed.status, RealtimeStatus.idle);
    },
  );
  test(
    'Expired stream calls session handler once and does not retry',
    () async {
      var expired = 0, connections = 0;
      final wire = Wire();
      final feed = RealtimeFeed(
        'http://test',
        retryBase: const Duration(milliseconds: 10),
        clientFactory: () {
          connections++;
          return wire;
        },
      );
      addTearDown(feed.stop);
      feed.start(
        'A',
        onRefresh: () {},
        onExpired: () => expired++,
        onState: (_) {},
      );
      await until(() => wire.request != null);
      wire.event('expired');
      await until(() => expired == 1);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(connections, 1);
      expect(wire.closed, true);
    },
  );
  test(
    'Signal during GET drains another refresh and preserves latest draft',
    () async {
      final gate = Completer<http.Response>();
      var reads = 0;
      final wire = Wire(), store = MemoryStore();
      final feed = RealtimeFeed('http://test', clientFactory: () => wire);
      final c = AppController(
        Api(
          'http://test',
          client: MockClient((r) async {
            if (r.url.path == '/notes') {
              reads++;
              if (reads == 2) return gate.future;
              return answer([
                note(
                  reads >= 3 ? 3 : 1,
                  reads >= 3 ? 'Latest server' : 'Original',
                ).toJson(),
              ]);
            }
            return answer({'id': 'A'});
          }),
        ),
        store,
        realtime: feed,
      );
      addTearDown(c.dispose);
      await store.write('session', {
        'user': {'id': 'A'},
        'token': 'A',
      });
      await c.initialize();
      await until(() => reads == 1 && !c.syncing && wire.request != null);
      await c.draft('n', '', 'Unsent latest');
      wire.event('ready', 1);
      await until(() => reads == 2);
      wire.event('changed', 2);
      await until(() => c.realtimeSignals == 2);
      await Future<void>.delayed(const Duration(milliseconds: 130));
      gate.complete(answer([note(2, 'Intermediate').toJson()]));
      await until(() => reads == 3 && !c.syncing);
      expect(c.notes.single.content, 'Latest server');
      expect(c.drafts['n']['content'], 'Unsent latest');
      expect(c.pending, isEmpty);
    },
  );
  test('Foreground resume catches up; background and logout close authenticated stream', () async {
    final wires = <Wire>[], store = MemoryStore();
    final feed = RealtimeFeed(
      'http://test',
      clientFactory: () {
        final wire = Wire();
        wires.add(wire);
        return wire;
      },
    );
    final c = AppController(
      Api(
        'http://test',
        client: MockClient(
          (r) async => answer(r.url.path == '/notes' ? [] : {'id': 'A'}),
        ),
      ),
      store,
      realtime: feed,
    );
    addTearDown(c.dispose);
    await store.write('session', {
      'user': {'id': 'A'},
      'token': 'A',
    });
    await c.initialize();
    await until(
      () => wires.isNotEmpty && wires.first.request != null && !c.syncing,
    );
    c.setForeground(false);
    await until(() => wires.first.closed);
    expect(wires.first.closed, true);
    c.setForeground(true);
    await until(() => wires.length == 2 && wires.last.request != null);
    wires.last.event('ready', 9);
    await until(() => c.realtimeLive);
    await c.logout();
    await until(() => wires.last.closed);
    expect(wires.last.closed, true);
    expect(c.user, isNull);
    expect(c.realtimeLive, false);
  });
  testWidgets(
    'Clean live editor preserves selection and explicitly opens a new base',
    (tester) async {
      final sent = <Map<String, dynamic>>[];
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  if (r.url.path == '/sync') {
                    sent.add(jsonDecode(r.body));
                    return answer({});
                  }
                  if (r.url.path == '/notes') {
                    return answer([note(3, 'My edit').toJson()]);
                  }
                  return answer({'id': 'A'});
                }),
              ),
              MemoryStore(),
            )
            ..user = {'id': 'A'}
            ..token = 'A'
            ..notes = [note(1, 'Original')];
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      final field = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      field.document.selection = const TextSelection.collapsed(offset: 3);
      c.notes = [note(2, 'Updated remotely')];
      c.notifyListeners();
      await tester.pump();
      expect(field.document.text, 'Updated remotely');
      expect(field.document.selection.baseOffset, 3);
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .readOnly,
        true,
      );
      expect(sent, isEmpty);
      await tester.tap(find.text('Chỉnh sửa phiên bản mới'));
      await tester.pumpAndSettle();
      await enterDocumentText(
        tester,
        find.byKey(const Key('note-content')),
        'My edit',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(sent.single['base_revision'], 2);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Dirty live editor keeps typed content and frozen base for conflict',
    (tester) async {
      final c = offlineController()..notes = [note(1, 'Original')];
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.enterText(find.byKey(const Key('note-title')), '');
      await enterDocumentText(
        tester,
        find.byKey(const Key('note-content')),
        'Local unsent',
      );
      await tester.pump();
      c.notes = [note(2, 'Peer version')];
      c.notifyListeners();
      await tester.pump();
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Local unsent',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(c.pending, isEmpty);
      expect(c.drafts['n']['content'], 'Local unsent');
      expect(
        find.text('Nhập tiêu đề và nội dung để tạo ghi chú'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('note-title')),
        'Local title',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(c.pending.single['base_revision'], 1);
      expect(c.pending.single['content'], 'Local unsent');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
