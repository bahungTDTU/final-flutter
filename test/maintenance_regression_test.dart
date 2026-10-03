import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/state/app_controller.dart';

import 'support.dart';

class DeferredSessionStore extends MemoryStore {
  final session = Completer<Map<String, dynamic>?>();
  int writes = 0;
  @override
  Future<Map<String, dynamic>?> read(String key) =>
      key == 'session' ? session.future : super.read(key);
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    writes++;
    await super.write(key, value);
  }
}

class StalledClient extends http.BaseClient {
  final aborted = Completer<void>();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final result = Completer<http.StreamedResponse>();
    (request as http.AbortableRequest).abortTrigger!.then((_) {
      aborted.complete();
      result.completeError(http.RequestAbortedException(request.url));
    });
    return result.future;
  }
}

http.Response reply(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'Disposing during session load cannot revive polling or write data',
    () async {
      final store = DeferredSessionStore();
      var requests = 0;
      final c = AppController(
        Api(
          'http://test',
          client: MockClient((_) async {
            requests++;
            return reply([]);
          }),
        ),
        store,
      );
      final initializing = c.initialize();
      c.dispose();
      store.session.complete({
        'user': {'id': 'A'},
        'token': 'A',
      });
      await initializing;
      await c.synchronize();
      expect(c.user, isNull);
      expect(requests, 0);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'Background skips periodic sync and resume catches up without SSE',
    (tester) async {
      var requests = 0;
      final store = MemoryStore();
      await store.write('session', {
        'user': {'id': 'A'},
        'token': 'A',
      });
      final c = AppController(
        Api(
          'http://test',
          client: MockClient((r) async {
            requests++;
            return reply(r.url.path == '/notes' ? [] : {'id': 'A'});
          }),
        ),
        store,
      );
      c.setForeground(false);
      await c.initialize();
      await tester.pump(const Duration(seconds: 31));
      expect(requests, 0);
      c.setForeground(true);
      await tester.pumpAndSettle();
      expect(requests, greaterThan(0));
      expect(c.online, true);
      c.dispose();
    },
  );

  test('Plain-text 401 still logs out and retires the local session', () async {
    final store = MemoryStore();
    final c = AppController(
      Api(
        'http://test',
        client: MockClient(
          (_) async => http.Response('<html>Session expired</html>', 401),
        ),
      ),
      store,
    );
    c.user = {'id': 'A'};
    c.token = 'A';
    await store.write('session', {'user': c.user, 'token': c.token});
    await c.synchronize();
    expect(c.user, isNull);
    expect(await store.read('session'), isNull);
    expect(c.error, contains('Phiên hết hạn'));
    c.dispose();
  });

  test('Binary errors preserve status without exposing proxy HTML', () async {
    final api = Api(
      'http://test',
      client: MockClient(
        (_) async => http.Response('<html>Private proxy detail</html>', 502),
      ),
    );
    await expectLater(
      api.binary('GET', '/file', token: 'A'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 502)
            .having((e) => e.detail, 'safe detail', 'Request failed (502)'),
      ),
    );
  });

  test(
    'JSON and binary timeouts abort the underlying request before retry',
    () async {
      for (final binary in [false, true]) {
        final client = StalledClient();
        final api = Api(
          'http://test',
          client: client,
          requestTimeout: const Duration(milliseconds: 20),
        );
        await expectLater(
          binary
              ? api.binary(
                  'POST',
                  '/file',
                  token: 'A',
                  timeout: const Duration(milliseconds: 20),
                )
              : api.call('GET', '/me', token: 'A'),
          throwsA(isA<TimeoutException>()),
        );
        await client.aborted.future.timeout(const Duration(seconds: 1));
        client.close();
      }
    },
  );
}
