enum PlanStage { planned, active, done }

enum PlanPriority { low, normal, high }

enum PlanWindow { all, overdue, today, week }

extension PlanStageLabel on PlanStage {
  String get label => switch (this) {
    PlanStage.planned => 'Dự kiến',
    PlanStage.active => 'Đang làm',
    PlanStage.done => 'Hoàn thành',
  };
}

extension PlanPriorityLabel on PlanPriority {
  String get label => switch (this) {
    PlanPriority.low => 'Thấp',
    PlanPriority.normal => 'Bình thường',
    PlanPriority.high => 'Cao',
  };
}

/// Calendar date, deliberately not a timestamp that shifts with time zones.
String planDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

bool validPlanDay(String? day) {
  if (day == null) return true;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return false;
  final parsed = DateTime.tryParse(day);
  return parsed != null &&
      parsed.year >= 2000 &&
      parsed.year <= 2100 &&
      planDay(parsed) == day;
}

/// Local encrypted organization; never stores a note snapshot or edits its ACL.
class NotePlan {
  const NotePlan(
    this.noteId, {
    this.stage = PlanStage.planned,
    this.priority = PlanPriority.normal,
    this.dueDay,
  });
  final String noteId;
  final PlanStage stage;
  final PlanPriority priority;
  final String? dueDay;

  bool overdue(DateTime now) =>
      stage != PlanStage.done &&
      dueDay != null &&
      dueDay!.compareTo(planDay(now)) < 0;

  bool matches(PlanWindow window, DateTime now) {
    if (window == PlanWindow.all) return true;
    if (stage == PlanStage.done || dueDay == null) return false;
    final day = planDay(now);
    return switch (window) {
      PlanWindow.overdue => overdue(now),
      PlanWindow.today => dueDay == day,
      PlanWindow.week =>
        dueDay!.compareTo(day) >= 0 &&
            dueDay!.compareTo(
                  planDay(DateTime(now.year, now.month, now.day + 6)),
                ) <=
                0,
      PlanWindow.all => true,
    };
  }

  NotePlan move(PlanStage value) =>
      NotePlan(noteId, stage: value, priority: priority, dueDay: dueDay);

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'stage': stage.name,
    'priority': priority.name,
    if (dueDay != null) 'dueDay': dueDay,
  };

  static NotePlan? parse(dynamic value) {
    if (value is! Map || value['noteId'] is! String) return null;
    final id = value['noteId'] as String;
    final stage = PlanStage.values
        .where((v) => v.name == value['stage'])
        .firstOrNull;
    final priority = PlanPriority.values
        .where((v) => v.name == value['priority'])
        .firstOrNull;
    final day = value['dueDay'];
    if (id.isEmpty ||
        id.length > 128 ||
        stage == null ||
        priority == null ||
        (day != null && day is! String) ||
        !validPlanDay(day as String?)) {
      return null;
    }
    return NotePlan(id, stage: stage, priority: priority, dueDay: day);
  }
}

int comparePlans(NotePlan a, NotePlan b) {
  final priority = b.priority.index.compareTo(a.priority.index);
  if (priority != 0) return priority;
  final due = (a.dueDay ?? '9999').compareTo(b.dueDay ?? '9999');
  return due != 0 ? due : a.noteId.compareTo(b.noteId);
}
