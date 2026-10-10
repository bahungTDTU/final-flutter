import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'design_system.dart';

/// Only this panel ticks; Home, the controller and task parser do not rebuild
/// every second. Durable changes happen on explicit actions or completion.
class FocusPanel extends StatefulWidget {
  const FocusPanel({super.key, required this.controller});
  final AppController controller;
  @override
  State<FocusPanel> createState() => _FocusPanelState();
}

class _FocusPanelState extends State<FocusPanel> {
  late final account = widget.controller.user?['id'];
  final clock = ValueNotifier(DateTime.now());
  Timer? ticker;
  int minutes = 25;
  bool busy = false;
  String? error;
  String? failedCompletion;
  AppController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  }

  void tick() {
    if (!mounted || c.user?['id'] != account) return;
    final now = DateTime.now();
    clock.value = now;
    final s = c.workspace.focus.session;
    if (!busy &&
        s != null &&
        s.running &&
        s.remaining(now) == 0 &&
        failedCompletion != s.id) {
      unawaited(act(() => c.changeFocus(s.id, 'finish'), completing: s.id));
    }
  }

  Future<void> act(Future<void> Function() action, {String? completing}) async {
    if (busy || c.user?['id'] != account) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      failedCompletion = null;
    } catch (e) {
      if (mounted && c.user?['id'] == account) {
        failedCompletion = completing;
        error = e is StateError
            ? e.message.toString()
            : 'Chưa lưu được đồng hồ. Hãy thử lại.';
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset() async {
    final session = c.workspace.focus.session;
    if (session == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AnimatedBuilder(
        animation: c,
        builder: (context, _) => AlertDialog(
          title: const Text('Kết thúc phiên hiện tại?'),
          content: Text(
            c.user?['id'] == account
                ? 'Phiên chưa hết giờ sẽ không tính vào mục tiêu. Bạn có thể tạm dừng để tiếp tục sau.'
                : 'Phiên đăng nhập đã thay đổi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: c.user?['id'] != account
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Kết thúc phiên'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted && c.user?['id'] == account) {
      await act(() => c.changeFocus(session.id, 'reset'));
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([c, clock]),
    builder: (context, _) {
      if (c.user?['id'] != account) return const SizedBox.shrink();
      final data = c.workspace.focus;
      final s = data.session;
      final remaining = s?.remaining(clock.value) ?? minutes * 60;
      final today = data.onDay(clock.value);
      final time =
          '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfacePanel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  s?.breakTime == true ? 'Nghỉ ngắn' : 'Tập trung từng phiên',
                  detail: 'Làm một việc, nghỉ một chút và ghi nhận tiến độ của bạn.',
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Semantics(
                    label: 'Thời gian còn lại $time',
                    liveRegion: false,
                    child: ExcludeSemantics(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          time,
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (s != null) ...[
                  LinearProgressIndicator(value: 1 - remaining / s.seconds),
                  const SizedBox(height: 12),
                  Text(
                    remaining == 0
                        ? 'Đã hết giờ. Đang ghi nhận phiên…'
                        : s.running
                        ? 'Đang chạy · có thể rời màn hình và quay lại'
                        : 'Đã tạm dừng',
                  ),
                ] else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in [5, 15, 25, 50])
                        ChoiceChip(
                          label: Text('$v phút'),
                          selected: minutes == v,
                          onSelected: busy
                              ? null
                              : (_) => setState(() => minutes = v),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (s == null) ...[
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => act(() => c.startFocus(minutes)),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Bắt đầu'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => act(() => c.startFocus(5, breakTime: true)),
                        icon: const Icon(Icons.coffee_outlined),
                        label: const Text('Nghỉ 5 phút'),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: busy || remaining == 0
                            ? null
                            : () => act(
                                () => c.changeFocus(
                                  s.id,
                                  s.running ? 'pause' : 'resume',
                                ),
                              ),
                        icon: Icon(
                          s.running ? Icons.pause : Icons.play_arrow_rounded,
                        ),
                        label: Text(s.running ? 'Tạm dừng' : 'Tiếp tục'),
                      ),
                      TextButton(
                        onPressed: busy ? null : reset,
                        child: const Text('Kết thúc phiên'),
                      ),
                    ],
                  ],
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  StatusNotice(message: error!, error: true),
                  if (remaining == 0 && s != null)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => act(
                              () => c.changeFocus(s.id, 'finish'),
                              completing: s.id,
                            ),
                      child: const Text('Thử lưu lại'),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  'Nhịp làm việc hôm nay',
                  detail:
                      '${today.length}/${data.dailyGoal} phiên · ${today.fold<int>(0, (sum, v) => sum + v.seconds) ~/ 60} phút hoàn thành',
                ),
                PrismProgress(
                  value: (today.length / data.dailyGoal).clamp(0, 1),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('focus-goal-${data.dailyGoal}'),
                  isExpanded: true,
                  initialValue: data.dailyGoal,
                  decoration: const InputDecoration(
                    labelText: 'Mục tiêu mỗi ngày',
                  ),
                  items: [
                    for (int i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text('$i phiên')),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          if (v != null) {
                            unawaited(act(() => c.setFocusGoal(v)));
                          }
                        },
                ),
                const SizedBox(height: 20),
                const Text('7 ngày gần đây'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 6; i >= 0; i--)
                      Builder(
                        builder: (_) {
                          final day = DateTime(
                            clock.value.year,
                            clock.value.month,
                            clock.value.day - i,
                          );
                          return MetadataPill(
                            '${day.day}/${day.month} · ${data.onDay(day).length} phiên',
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đồng hồ, mục tiêu và tối đa 100 phiên được mã hóa trên thiết bị này. Phiên hết giờ được ghi nhận khi bạn quay lại; thời gian nghỉ không tính vào mục tiêu. Không có thông báo hệ thống khi ứng dụng đã đóng.',
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
