import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';

/// Connection pulses update this control rather than rebuilding the library.
class DashboardSync extends StatelessWidget {
  const DashboardSync({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final pending =
          c.pending.length +
          c.pendingPreferences.length +
          c.pendingLabels.length;
      final label = c.syncing
          ? context.tr("Đang đồng bộ…")
          : !c.online
          ? context.tr("Offline · {0} thay đổi chờ", [pending])
          : pending > 0
          ? context.tr("{0} thay đổi chờ đồng bộ", [pending])
          : c.realtimeLive
          ? context.tr("Trực tiếp")
          : c.realtime != null
          ? context.tr("Đang nối lại")
          : context.tr("Đã đồng bộ");
      return TextButton.icon(
        onPressed: c.syncing ? null : c.synchronize,
        icon: Icon(
          c.syncing || c.online && !c.realtimeLive && c.realtime != null
              ? Icons.sync_outlined
              : c.online
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_outlined,
          size: 18,
        ),
        label: Text(label),
      );
    },
  );
}
