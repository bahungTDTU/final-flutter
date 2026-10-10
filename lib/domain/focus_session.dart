/// A personal timer, independent of note content and server permissions.
class FocusSession {
  const FocusSession({
    required this.id,
    required this.breakTime,
    required this.seconds,
    required this.remainingSeconds,
    this.endsAtMs,
  });
  final String id;
  final bool breakTime;
  final int seconds, remainingSeconds;
  final int? endsAtMs;
  bool get running => endsAtMs != null;
  int remaining(DateTime now) => endsAtMs == null
      ? remainingSeconds
      : ((endsAtMs! - now.millisecondsSinceEpoch) / 1000).ceil().clamp(
          0,
          seconds,
        );
  FocusSession pause(DateTime now) => FocusSession(
    id: id,
    breakTime: breakTime,
    seconds: seconds,
    remainingSeconds: remaining(now),
  );
  FocusSession resume(DateTime now) => FocusSession(
    id: id,
    breakTime: breakTime,
    seconds: seconds,
    remainingSeconds: remainingSeconds,
    endsAtMs: now.millisecondsSinceEpoch + remainingSeconds * 1000,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'break': breakTime,
    'seconds': seconds,
    'remaining': remainingSeconds,
    'ends_at': endsAtMs,
  };
  static FocusSession? read(dynamic value) {
    if (value is! Map ||
        value['id'] is! String ||
        (value['id'] as String).length > 72 ||
        value['break'] is! bool ||
        value['seconds'] is! int ||
        value['remaining'] is! int) {
      return null;
    }
    final seconds = value['seconds'] as int;
    final remaining = value['remaining'] as int;
    final end = value['ends_at'];
    if (seconds < 300 ||
        seconds > 3000 ||
        remaining < 0 ||
        remaining > seconds ||
        (end == null && remaining == 0) ||
        (end != null && (end is! int || end <= 0 || end > 8640000000000000))) {
      return null;
    }
    return FocusSession(
      id: value['id'],
      breakTime: value['break'],
      seconds: seconds,
      remainingSeconds: remaining,
      endsAtMs: end,
    );
  }
}

class FocusCompletion {
  const FocusCompletion(this.id, this.atMs, this.seconds);
  final String id;
  final int atMs, seconds;
  Map<String, dynamic> toJson() => {'id': id, 'at': atMs, 'seconds': seconds};
}

class FocusData {
  FocusData({
    this.session,
    this.dailyGoal = 4,
    List<FocusCompletion>? completed,
  }) : completed = List.unmodifiable(completed ?? []);
  final FocusSession? session;
  final int dailyGoal;
  final List<FocusCompletion> completed;
  factory FocusData.fromJson(dynamic value) {
    if (value is! Map) return FocusData();
    final goal = value['goal'];
    final records = <FocusCompletion>[];
    final seen = <String>{};
    if (value['completed'] is List) {
      for (final v in (value['completed'] as List).take(100)) {
        if (v is Map &&
            v['id'] is String &&
            (v['id'] as String).length <= 72 &&
            v['at'] is int &&
            v['at'] > 0 &&
            v['at'] <= 8640000000000000 &&
            v['seconds'] is int &&
            v['seconds'] >= 300 &&
            v['seconds'] <= 3000 &&
            seen.add(v['id'])) {
          records.add(FocusCompletion(v['id'], v['at'], v['seconds']));
        }
      }
    }
    return FocusData(
      session: FocusSession.read(value['session']),
      dailyGoal: goal is int && goal >= 1 && goal <= 12 ? goal : 4,
      completed: records,
    );
  }
  List<FocusCompletion> onDay(DateTime now) => completed.where((v) {
    final d = DateTime.fromMillisecondsSinceEpoch(v.atMs);
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
  FocusData copy({
    FocusSession? session,
    bool clearSession = false,
    int? dailyGoal,
    List<FocusCompletion>? completed,
  }) => FocusData(
    session: clearSession ? null : session ?? this.session,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    completed: completed ?? this.completed,
  );
  Map<String, dynamic> toJson() => {
    'session': session?.toJson(),
    'goal': dailyGoal,
    'completed': completed.map((v) => v.toJson()).toList(),
  };
}
