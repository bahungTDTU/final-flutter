import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

enum RealtimeStatus { idle, connecting, live, retrying }

class RealtimeFrame {
  const RealtimeFrame(this.event, this.version);
  final String event;
  final int? version;
}

/// Parse bounded SSE frames across arbitrary UTF-8/network chunks.
Stream<RealtimeFrame> parseRealtime(Stream<List<int>> bytes) {
  var event = '', data = <String>[];
  var size = 0;
  return bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .transform(
        StreamTransformer<String, RealtimeFrame>.fromHandlers(
          handleData: (line, sink) {
            size += line.length;
            if (size > 4096) {
              throw const FormatException('Event frame too large');
            }
            if (line.isEmpty) {
              if (data.isNotEmpty &&
                  ['ready', 'changed', 'expired'].contains(event)) {
                final value = jsonDecode(data.join('\n'));
                if (value is! Map ||
                    (event == 'expired'
                        ? value.isNotEmpty
                        : value.length != 1 ||
                              value['version'] is! int ||
                              value['version'] < 0)) {
                  throw const FormatException('Invalid event payload');
                }
                sink.add(RealtimeFrame(event, value['version'] as int?));
              }
              event = '';
              data = [];
              size = 0;
            } else if (line.startsWith('event:')) {
              event = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              data.add(line.substring(5).trimLeft());
            }
          },
        ),
      );
}

/// One authenticated account connection; token never appears in a URL/cache.
/// Writes continue through the existing immutable HTTP outbox and revision CAS.
class RealtimeFeed {
  RealtimeFeed(
    this.baseUrl, {
    http.Client Function()? clientFactory,
    this.retryBase = const Duration(seconds: 1),
    this.idleTimeout = const Duration(seconds: 25),
  }) : clientFactory = clientFactory ?? http.Client.new;
  final String baseUrl;
  final http.Client Function() clientFactory;
  final Duration retryBase, idleTimeout;
  Completer<void>? _abort, _done;
  Timer? _retry;
  int _epoch = 0, _failures = 0;
  int? _version;
  RealtimeStatus status = RealtimeStatus.idle;
  void Function()? _refresh, _expired;
  void Function(RealtimeStatus)? _state;

  void start(
    String token, {
    required void Function() onRefresh,
    required void Function() onExpired,
    required void Function(RealtimeStatus) onState,
  }) {
    stop();
    _refresh = onRefresh;
    _expired = onExpired;
    _state = onState;
    _failures = 0;
    _version = null;
    final epoch = _epoch;
    unawaited(_connect(epoch, token));
  }

  void _setState(RealtimeStatus value) {
    if (status == value) return;
    status = value;
    _state?.call(value);
  }

  Future<void> _connect(int epoch, String token) async {
    if (epoch != _epoch) return;
    _setState(
      _failures == 0 ? RealtimeStatus.connecting : RealtimeStatus.retrying,
    );
    final client = clientFactory(),
        abort = Completer<void>(),
        done = Completer<void>();
    StreamSubscription<RealtimeFrame>? subscription;
    _abort = abort;
    _done = done;
    try {
      final request =
          http.AbortableRequest(
              'GET',
              Uri.parse('$baseUrl/events'),
              abortTrigger: abort.future,
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Accept'] = 'text/event-stream';
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 10));
      if (epoch != _epoch) {
        await response.stream.listen((_) {}, onError: (Object _) {}).cancel();
        return;
      }
      if (response.statusCode == 401) {
        _expired?.call();
        stop();
        return;
      }
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').startsWith(
            'text/event-stream',
          )) {
        throw const FormatException('Event stream unavailable');
      }
      subscription = parseRealtime(response.stream.timeout(idleTimeout)).listen(
        (message) {
          if (epoch != _epoch) return;
          if (message.event == 'expired') {
            _expired?.call();
            stop();
          } else {
            _failures = 0;
            _setState(RealtimeStatus.live);
            if (message.event == 'ready' || message.version != _version) {
              _version = message.version;
              _refresh?.call();
            }
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      await done.future;
    } catch (_) {
      // Reconnect/fallback state is visible; errors never log session material.
    } finally {
      if (!abort.isCompleted) abort.complete();
      // IOClient.close(force:true) during an async parser's cancellation can
      // emit an unhandled socket error. Finish cancelling the response first.
      try {
        await subscription?.cancel();
      } catch (_) {
        // Aborting an in-flight response may also complete cancellation with an error.
      }
      client.close();
      if (epoch == _epoch) {
        _abort = null;
        _done = null;
        _failures = min(_failures + 1, 6);
        _setState(RealtimeStatus.retrying);
        final milliseconds = min(
          30000,
          retryBase.inMilliseconds * (1 << (_failures - 1)),
        );
        _retry = Timer(
          Duration(milliseconds: milliseconds),
          () => unawaited(_connect(epoch, token)),
        );
      }
    }
  }

  void stop() {
    _epoch++;
    _retry?.cancel();
    _retry = null;
    if (_abort?.isCompleted == false) _abort!.complete();
    if (_done?.isCompleted == false) _done!.complete();
    // The connection owns its client and closes it in finally after cancellation.
    _abort = null;
    _done = null;
    _setState(RealtimeStatus.idle);
    _refresh = null;
    _expired = null;
    _state = null;
    _version = null;
  }
}
