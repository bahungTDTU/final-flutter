import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/ai_session.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/ai.dart';

import 'support.dart';

Map<String, dynamic> source(String id) => {
  'id': id,
  'title': 'Dự án $id',
  'revision': 1,
  'locked': false,
};
Map<String, dynamic> answer() => {
  'sufficient': true,
  'answer': 'Tổng hợp từ ghi chú test.',
  'sources': [source('n')],
  'context_sources': [source('n'), source('other')],
};
AppController configured(Future<http.Response> Function(http.Request) handler) {
  final c = AppController(
    Api('http://test', client: MockClient(handler)),
    MemoryStore(),
  );
  c.user = {
    'id': 'A',
    'name': 'Test',
    'email': 'test@example.test',
    'verified': false,
  };
  c.token = 'test-token';
  c.ready = true;
  c.notes = ['n', 'other']
      .map(
        (id) => Note(
          id: id,
          title: 'Dự án $id',
          content: 'Nội dung $id',
          revision: 1,
          updatedAt: '2026-10-05',
        ),
      )
      .toList();
  return c;
}

http.Response ok(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'Summary regeneration stays RAM-only and cannot overwrite notes or outbox',
    () async {
      final calls = <String>[];
      final c = configured((r) async {
        calls.add(r.url.path);
        return ok(
          r.url.path == '/ai/validate'
              ? {'valid': true}
              : {
                  'summary': 'Summary test',
                  'sources': [source('n')],
                },
        );
      });
      final session = AiSession(c, noteId: 'n');
      final original = c.notes.map((n) => n.toJson()).toList();
      await session.generate();
      await session.generate();
      expect(session.result?['summary'], 'Summary test');
      expect(c.notes.map((n) => n.toJson()), original);
      expect(c.pending, isEmpty);
      expect((c.local as MemoryStore).values, isEmpty);
      expect(calls.where((p) => p.endsWith('/ai/summary')), hasLength(2));
      session.dispose();
      c.dispose();
    },
  );

  test('Unsent draft blocks summary of stale server version', () async {
    var calls = 0;
    final c = configured((_) async {
      calls++;
      return ok({});
    });
    c.drafts['n'] = {'title': 'Draft', 'content': 'Unsent'};
    final session = AiSession(c, noteId: 'n');
    await session.generate();
    expect(calls, 0);
    expect(session.result, isNull);
    expect(session.error, contains('Đồng bộ bản nháp'));
    session.dispose();
    c.dispose();
  });

  test('Removing an uncited context source clears the whole answer', () async {
    final c = configured(
      (r) async =>
          ok(r.url.path == '/ai/validate' ? {'valid': true} : answer()),
    );
    final session = AiSession(c);
    await session.generate(question: 'Dự án thế nào?');
    expect(session.result, isNotNull);
    c.notes.removeWhere((n) => n.id == 'other');
    c.notifyListeners();
    expect(session.result, isNull);
    expect(session.error, contains('thay đổi'));
    session.dispose();
    c.dispose();
  });

  test(
    'Account switch during inference discards late answer and source metadata',
    () async {
      final pending = Completer<http.Response>();
      final c = configured((_) => pending.future);
      final session = AiSession(c);
      final request = session.generate(question: 'Dự án thế nào?');
      await Future<void>.delayed(Duration.zero);
      c.user = {'id': 'B'};
      c.notifyListeners();
      pending.complete(ok(answer()));
      await request;
      expect(session.result, isNull);
      expect(session.sources, isEmpty);
      expect(session.busy, false);
      session.dispose();
      c.dispose();
    },
  );

  test('Validation failure and citation open both enforce current server permission', () async {
    var revoked = false;
    final c = configured((r) async {
      if (revoked) return http.Response('{"detail":"Note unavailable"}', 404);
      return ok(r.url.path == '/ai/validate' ? {'valid': true} : answer());
    });
    final session = AiSession(c);
    await session.generate(question: 'Dự án thế nào?');
    revoked = true;
    expect(await session.openSource('n'), isNull);
    expect(session.result, isNull);
    revoked = false;
    await session.generate(question: 'Dự án thế nào?');
    revoked = true;
    await session.validate();
    expect(session.result, isNull);
    session.dispose();
    c.dispose();
  });

  test(
    'Protected gate expiry and background hide output immediately',
    () async {
      var granted = true;
      final gate = ChangeNotifier();
      final c = configured(
        (r) async => ok(
          r.url.path == '/ai/validate'
              ? {'valid': true}
              : {
                  'summary': 'Protected test',
                  'sources': [source('n')],
                },
        ),
      );
      final session = AiSession(
        c,
        noteId: 'n',
        protectedGate: () => granted,
        gateChanges: gate,
      );
      await session.generate();
      granted = false;
      gate.notifyListeners();
      expect(session.result, isNull);
      granted = true;
      await session.generate();
      c.setForeground(false);
      expect(session.result, isNull);
      session.dispose();
      gate.dispose();
      c.dispose();
    },
  );

  testWidgets(
    'Question UI validates input, displays synthesis and opens the exact source',
    (tester) async {
      final reads = <String>[];
      final c = configured((r) async {
        reads.add(r.url.path);
        if (r.url.path == '/ai/validate') return ok({'valid': true});
        if (r.url.path == '/notes/n') return ok(cNote());
        return ok(answer());
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AiQuestionsPanel(controller: c)),
        ),
      );
      await tester.tap(find.byKey(const Key('ai-ask')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập câu hỏi ít nhất 3 ký tự.'), findsOneWidget);
      expect(reads, isEmpty);
      await tester.enterText(
        find.byKey(const Key('ai-question')),
        'Dự án thế nào?',
      );
      await tester.tap(find.byKey(const Key('ai-ask')));
      await tester.pumpAndSettle();
      expect(find.text('Tổng hợp từ ghi chú test.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('ai-source-n')));
      await tester.tap(find.byKey(const ValueKey('ai-source-n')));
      await tester.pumpAndSettle();
      expect(reads, contains('/notes/n'));
      expect(find.byKey(const Key('note-title')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Summary dialog regenerate/error state and compact scaled layout remain usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requests = 0;
      final c = configured((r) async {
        if (r.url.path == '/ai/validate') return ok({'valid': true});
        requests++;
        return requests == 1
            ? ok({
                'summary': 'Test summary',
                'sources': [source('n')],
              })
            : http.Response('{"detail":"AI_QUOTA"}', 429);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: AiSummaryDialog(controller: c, noteId: 'n'),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('ai-summary-generate')));
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await tester.pumpAndSettle();
      expect(find.text('Test summary'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('ai-summary-generate')));
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await tester.pumpAndSettle();
      expect(find.text('Test summary'), findsNothing);
      expect(find.textContaining('hạn mức'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}

Map<String, dynamic> cNote() => {
  'id': 'n',
  'title': 'Dự án n',
  'content': 'Nội dung n',
  'revision': 1,
  'updated_at': '2026-10-05',
  'role': 'owner',
};
