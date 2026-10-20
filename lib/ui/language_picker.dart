import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/app_controller.dart';
import 'app.dart' show showMessage;

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.controller,
    this.compact = false,
    this.iconOnly = false,
  });
  final AppController controller;
  final bool compact;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      Future<void> change(String? value) async {
        if (value == null || value == controller.language) return;
        try {
          await controller.setLanguage(value);
        } catch (_) {
          if (context.mounted) {
            showMessage(
              context,
              context.tr('Chưa lưu được ngôn ngữ. Hãy thử lại.'),
            );
          }
        }
      }

      const items = [
        DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
        DropdownMenuItem(value: 'en', child: Text('English')),
      ];
      if (iconOnly ||
          compact && MediaQuery.textScalerOf(context).scale(1) >= 1.4) {
        return PopupMenuButton<String>(
          key: Key(iconOnly ? 'editor-language-picker' : 'language-picker'),
          tooltip: 'Tiếng Việt / English',
          icon: const Icon(Icons.translate),
          initialValue: controller.language,
          onSelected: change,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'vi', child: Text('Tiếng Việt')),
            PopupMenuItem(value: 'en', child: Text('English')),
          ],
        );
      }
      return compact
          ? Tooltip(
              message: 'Tiếng Việt / English',
              child: Semantics(
                label: context.tr('Ngôn ngữ'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('language-picker'),
                    value: controller.language,
                    icon: const Icon(Icons.translate),
                    items: items,
                    onChanged: change,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemHeight: 56,
                  ),
                ),
              ),
            )
          : DropdownButtonFormField<String>(
              key: ValueKey('language-setting-${controller.language}'),
              initialValue: controller.language,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Ngôn ngữ'),
                prefixIcon: const Icon(Icons.translate),
                helperText: context.tr(
                  'Đổi ngôn ngữ chỉ đổi giao diện, không dịch nội dung ghi chú.',
                ),
                helperMaxLines: 3,
              ),
              items: items,
              onChanged: change,
            );
    },
  );
}
