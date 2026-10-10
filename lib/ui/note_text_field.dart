import 'package:flutter/material.dart';

/// A bounded, naturally sized section; labels never share the input's paint area.
class NoteSection extends StatelessWidget {
  const NoteSection({
    super.key,
    required this.label,
    required this.icon,
    required this.child,
  });
  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerLow,
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Shared writing control for ordinary and password-protected note sessions.
class NoteTextField extends StatelessWidget {
  const NoteTextField({
    super.key,
    required this.controller,
    required this.titleMode,
    required this.fieldKey,
    required this.readOnly,
    required this.onChanged,
    this.fontSize = 16,
    this.focusNode,
  });
  final TextEditingController controller;
  final bool titleMode, readOnly;
  final Key fieldKey;
  final ValueChanged<String> onChanged;
  final double fontSize;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final label = titleMode ? 'Tiêu đề' : 'Nội dung';
    final radius = BorderRadius.circular(12);
    return NoteSection(
      label: label,
      icon: titleMode ? Icons.title : Icons.notes_outlined,
      child: Semantics(
        label: label,
        child: TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          minLines: titleMode ? 1 : 6,
          maxLines: null,
          maxLength: titleMode ? 200 : 100000,
          style: titleMode
              ? theme.textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 24 : 28,
                  height: 1.35,
                )
              : TextStyle(fontSize: fontSize, height: 1.6),
          decoration: InputDecoration(
            hintText: titleMode
                ? 'Đặt tên cho ghi chú…'
                : 'Viết nội dung của bạn…',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: radius),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) {
                final locale = MaterialLocalizations.of(context);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${locale.formatDecimal(currentLength)} / ${locale.formatDecimal(maxLength!)} ký tự',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
          onChanged: onChanged,
        ),
      ),
    );
  }
}
