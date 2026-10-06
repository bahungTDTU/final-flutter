import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    focusNode: focusNode,
    readOnly: readOnly,
    minLines: titleMode ? null : 8,
    maxLines: null,
    maxLength: titleMode ? 200 : 100000,
    style: titleMode
        ? Theme.of(context).textTheme.headlineLarge
        : TextStyle(fontSize: fontSize, height: 1.6),
    decoration: InputDecoration(
      labelText: titleMode ? 'Tiêu đề' : 'Nội dung',
      alignLabelWithHint: !titleMode,
      hintText: titleMode ? 'Điều bạn muốn ghi nhớ' : 'Bắt đầu viết…',
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: const UnderlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    onChanged: onChanged,
  );
}
