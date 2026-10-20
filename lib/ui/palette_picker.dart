import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/app_controller.dart';
import 'design_system.dart';

Future<void> showPalettePicker(
  BuildContext context,
  AppController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: .9,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SectionHeading(
                    context.tr('Bảng màu giao diện'),
                    icon: Icons.palette_outlined,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Đóng'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: PalettePicker(controller: controller),
            ),
          ),
        ],
      ),
    ),
  ),
);

class PalettePicker extends StatefulWidget {
  const PalettePicker({super.key, required this.controller});
  final AppController controller;
  @override
  State<PalettePicker> createState() => _PalettePickerState();
}

class _PalettePickerState extends State<PalettePicker> {
  late final account = widget.controller.user?['id'];
  late final token = widget.controller.token;
  bool saving = false;
  String? error;
  bool get active =>
      account != null &&
      widget.controller.user?['id'] == account &&
      widget.controller.token == token;
  Future<void> choose(AppPalette value) async {
    if (!active || saving || value == widget.controller.palette) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.setPreferences({'palette': value.name});
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Chưa lưu được bảng màu. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller, scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'Chọn một tổ hợp màu. Mỗi tổ hợp có phiên bản sáng và tối.',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, area) {
              final columns =
                  area.maxWidth >= 440 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.5
                  ? 2
                  : 1;
              final width = (area.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in AppPalette.values)
                    SizedBox(
                      width: width,
                      child: MergeSemantics(
                        child: Semantics(
                          selected: c.palette == p,
                          child: OutlinedButton(
                            key: ValueKey('palette-${p.name}'),
                            onPressed: active && !saving
                                ? () => choose(p)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                              backgroundColor: c.palette == p
                                  ? scheme.primaryContainer
                                  : scheme.surface,
                              foregroundColor: c.palette == p
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                              side: BorderSide(
                                color: c.palette == p
                                    ? scheme.primary
                                    : scheme.outline,
                                width: c.palette == p ? 2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExcludeSemantics(
                                  child: PaletteThumbnail(palette: p),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.tr(p.label),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      c.palette == p
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 21,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr(p.description),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('Nội dung và màu chữ trong ghi chú giữ nguyên.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!active)
            StatusNotice(message: context.tr('Phiên đăng nhập đã thay đổi.')),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StatusNotice(message: error!, error: true),
            ),
        ],
      );
    },
  );
}

/// A small, noninteractive preview of the current brightness; never note content.
class PaletteThumbnail extends StatelessWidget {
  const PaletteThumbnail({super.key, required this.palette});
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    final theme = noteTheme(Theme.of(context).brightness, palette: palette);
    final s = theme.colorScheme;
    Widget bar(Color color, double width) => Container(
      height: 5,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Container(
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            height: 16,
            color: s.primary,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                bar(s.onPrimary, 12),
                const SizedBox(width: 5),
                bar(s.onPrimary.withValues(alpha: .6), 22),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: s.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            bar(s.secondary, 28),
                            const SizedBox(height: 5),
                            bar(s.outlineVariant, 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 30,
                    decoration: BoxDecoration(
                      color: s.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: s.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
