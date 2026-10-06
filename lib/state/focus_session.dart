import 'dart:async';

import 'package:flutter/foundation.dart';

/// Route-local monotonic timer. No notifications, service or persisted history.
class FocusSession extends ChangeNotifier {
  FocusSession({this.duration = const Duration(minutes: 25)});
  final Duration duration;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool get running => _watch.isRunning;
  Duration get remaining {
    final value = duration - _watch.elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  bool get complete => remaining == Duration.zero;
  void start() {
    if (running || complete) return;
    _watch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (complete) {
        _watch.stop();
        _ticker?.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _watch.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() {
    _watch.stop();
    _watch.reset();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }
}
