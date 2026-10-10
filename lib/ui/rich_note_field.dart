import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../domain/note_document.dart';
import 'design_system.dart';

/// Owned by the note session, not by a breakpoint. The existing string remains
/// the immutable draft/outbox value; selection-only changes never save a note.
class NoteDocumentController extends ChangeNotifier {
  NoteDocumentController({
    required this.source,
    required this.canEdit,
    required this.onChanged,
  }) {
    _stored = source.text;
    controller = quill.QuillController(
      document: _document(_stored),
      selection: const TextSelection.collapsed(offset: 0),
      onReplaceText: _beforeReplace,
      config: quill.QuillControllerConfig(
        // Pinned to Quill11.6: keep external HTML/image paste out of the text-only
        // storage contract. Private files use the authenticated attachment UI.
        // ignore: experimental_member_use
        clipboardConfig: quill.QuillClipboardConfig(
          // ignore: experimental_member_use
          enableExternalRichPaste: false,
          onImagePaste: (_) async => null,
        ),
      ),
    );
    controller.addListener(_selectionChanged);
    _snapshot = storeDocumentDelta(delta);
    _plain = documentText(delta);
    source.addListener(_sourceChanged);
    _observe();
  }
  final TextEditingController source;
  final bool Function() canEdit;
  final VoidCallback onChanged;
  late final quill.QuillController controller;
  final editorKey = GlobalKey<quill.QuillEditorState>();
  final scroll = ScrollController();
  StreamSubscription<quill.DocChange>? _changes;
  late String _stored;
  late String _snapshot;
  late String _plain;
  bool _replacing = false, _disposed = false, _normalizingReplace = false;
  String? problem;
  TextSelection get selection => controller.selection;
  set selection(TextSelection value) =>
      controller.updateSelection(value, quill.ChangeSource.local);
  String get text => _plain;

  List<Map<String, dynamic>> get delta => controller.document
      .toDelta()
      .toJson()
      .map((op) => Map<String, dynamic>.from(op))
      .toList();
  String get snapshotSource => _snapshot;

  bool _beforeReplace(int index, int length, Object? data) {
    if (!canEdit() || controller.readOnly) {
      scheduleMicrotask(() {
        if (!_disposed) controller.notifyListeners();
      });
      return false;
    }
    if (_normalizingReplace) return true;
    final lastTextOffset = controller.document.length - 1;
    if (data is String && index + length > lastTextOffset) {
      // Browser Select All includes Quill's terminal newline. Keep this
      // structural sentinel outside deletion; removing it corrupts its tree.
      final start = index.clamp(0, lastTextOffset);
      _normalizingReplace = true;
      try {
        controller.replaceText(
          start,
          (lastTextOffset - start).clamp(0, length),
          data,
          TextSelection.collapsed(offset: start + data.length),
        );
      } finally {
        _normalizingReplace = false;
      }
      return false;
    }
    return true;
  }

  quill.Document _document(String stored) {
    try {
      return quill.Document.fromJson(editableDocumentDelta(stored));
    } catch (_) {
      // Preserve unreadable legacy input as literal text; never discard it.
      return quill.Document.fromJson([
        {'insert': '$stored\n'},
      ]);
    }
  }

  void _observe() {
    final observed = controller.document;
    _changes = observed.changes.listen((change) {
      if (_disposed ||
          _replacing ||
          !identical(observed, controller.document)) {
        return;
      }
      if (change.source != quill.ChangeSource.local) return;
      if (!canEdit()) {
        _install(_stored);
        return;
      }
      final ops = delta;
      if (ops.any((op) => op['insert'] is! String)) {
        problem = 'Dùng Đính kèm để lưu ảnh, video và tệp riêng tư.';
        _install(_stored);
        notifyListeners();
        return;
      }
      final repairTerminal =
          ops.isEmpty || !(ops.last['insert'] as String).endsWith('\n');
      if (repairTerminal) ops.add({'insert': '\n'});
      final encoded = storeDocumentDelta(ops);
      if (encoded.length > 100000) {
        problem = 'Nội dung và định dạng vượt giới hạn lưu. Hãy chia thành ghi chú nhỏ hơn.';
        _install(_stored);
        notifyListeners();
        return;
      }
      if (encoded == _stored) return;
      problem = null;
      _stored = encoded;
      _snapshot = encoded;
      _plain = documentText(ops);
      if (repairTerminal) _install(encoded);
      _replacing = true;
      source.value = TextEditingValue(text: encoded);
      _replacing = false;
      onChanged();
      notifyListeners();
    });
  }

  void _selectionChanged() {
    if (!_replacing && !_disposed) notifyListeners();
  }

  void _sourceChanged() {
    if (_replacing || source.text == _stored) return;
    _stored = source.text;
    problem = null;
    _install(_stored);
    notifyListeners();
  }

  void _install(String stored) {
    final selection = controller.selection;
    _replacing = true;
    unawaited(_changes?.cancel());
    controller.document = _document(stored);
    _snapshot = storeDocumentDelta(delta);
    _plain = documentText(delta);
    controller.updateSelection(
      TextSelection(
        baseOffset: selection.baseOffset.clamp(
          0,
          controller.document.length - 1,
        ),
        extentOffset: selection.extentOffset.clamp(
          0,
          controller.document.length - 1,
        ),
      ),
      quill.ChangeSource.remote,
    );
    _observe();
    _replacing = false;
  }

  void select(int offset) => controller.updateSelection(
    TextSelection.collapsed(
      offset: offset.clamp(0, controller.document.length - 1),
    ),
    quill.ChangeSource.local,
  );

  void requestKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
    editorKey.currentState?.editableTextKey.currentState?.requestKeyboard();
  }

  /// Assistive web input sends a whole value. Apply its smallest text change,
  /// retaining the formatting of unaffected spans and the native undo stack.
  void replaceVisibleText(String next) {
    if (!canEdit()) return;
    final before = text;
    if (before == next) return;
    var start = 0;
    while (start < before.length &&
        start < next.length &&
        before.codeUnitAt(start) == next.codeUnitAt(start)) {
      start++;
    }
    var oldEnd = before.length, newEnd = next.length;
    while (oldEnd > start &&
        newEnd > start &&
        before.codeUnitAt(oldEnd - 1) == next.codeUnitAt(newEnd - 1)) {
      oldEnd--;
      newEnd--;
    }
    controller.replaceText(
      start,
      oldEnd - start,
      next.substring(start, newEnd),
      TextSelection.collapsed(offset: newEnd),
    );
  }

  void selectSourceOffset(int offset) {
    if (storedDocumentDelta(source.text) != null) {
      select(offset);
    } else {
      final prefix = source.text.substring(
        0,
        offset.clamp(0, source.text.length),
      );
      final mapped = documentText(editableDocumentDelta(prefix));
      select(mapped.length);
    }
  }

  bool selected(String key, [Object value = true]) =>
      controller.getSelectionStyle().attributes[key]?.value == value;

  void format(String key, Object? value) {
    if (!canEdit()) return;
    controller.formatSelection(quill.Attribute.fromKeyValue(key, value));
  }

  void toggle(String key, [Object value = true]) =>
      format(key, selected(key, value) ? null : value);

  void setTask(int offset, bool done) {
    if (!canEdit()) return;
    controller.formatText(
      offset,
      0,
      quill.Attribute.fromKeyValue('list', done ? 'checked' : 'unchecked'),
    );
  }

  void clearFormat() {
    if (!canEdit()) return;
    final attrs = controller.getSelectionStyle().attributes.keys.toList();
    for (final key in attrs) {
      format(key, null);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    source.removeListener(_sourceChanged);
    controller.removeListener(_selectionChanged);
    unawaited(_changes?.cancel());
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }
}

class NoteRichTextField extends StatelessWidget {
  const NoteRichTextField({
    super.key,
    required this.document,
    required this.focusNode,
    required this.readOnly,
    this.fontSize = 16,
    this.minHeight = 260,
    this.onSearch,
  });
  final NoteDocumentController document;
  final FocusNode focusNode;
  final bool readOnly;
  final double fontSize, minHeight;
  final VoidCallback? onSearch;
  @override
  Widget build(BuildContext context) {
    document.controller.readOnly = readOnly;
    final theme = Theme.of(context);
    final defaults = quill.DefaultStyles.getInstance(context);
    quill.DefaultTextBlockStyle? style(
      quill.DefaultTextBlockStyle? block,
      double size, {
      bool bold = false,
    }) => block?.copyWith(
      style: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: theme.colorScheme.onSurface,
        height: 1.65,
      ),
    );
    return Localizations.override(
      context: context,
      delegates: const [quill.FlutterQuillLocalizations.delegate],
      child: ListenableBuilder(
        listenable: Listenable.merge([focusNode, document]),
        builder: (context, _) => Semantics(
          label: 'Nội dung',
          textField: true,
          multiline: true,
          enabled: true,
          excludeSemantics: true,
          focused: focusNode.hasFocus,
          readOnly: readOnly,
          value: '${document.text}\n',
          onTap: () => document.requestKeyboard(focusNode),
          onFocus: () => document.requestKeyboard(focusNode),
          onSetText: readOnly ? null : document.replaceVisibleText,
          onSetSelection: (selection) => document.selection = TextSelection(
            baseOffset: selection.baseOffset.clamp(0, document.text.length),
            extentOffset: selection.extentOffset.clamp(0, document.text.length),
          ),
          child: quill.QuillEditor(
            key: document.editorKey,
            controller: document.controller,
            focusNode: focusNode,
            scrollController: document.scroll,
            config: quill.QuillEditorConfig(
              customShortcuts: {
                if (onSearch != null) ...{
                  const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                      const _FindDocumentIntent(),
                  const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                      const _FindDocumentIntent(),
                },
              },
              customActions: {
                _FindDocumentIntent: CallbackAction<_FindDocumentIntent>(
                  onInvoke: (_) {
                    onSearch?.call();
                    return null;
                  },
                ),
              },
              scrollable: false,
              minHeight: minHeight,
              padding: const EdgeInsets.symmetric(vertical: 8),
              placeholder: 'Viết nội dung của bạn…',
              checkBoxReadOnly: readOnly,
              customStyles: quill.DefaultStyles(
                paragraph: style(defaults.paragraph, fontSize),
                lists: defaults.lists?.copyWith(
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: fontSize,
                    color: theme.colorScheme.onSurface,
                    height: 1.65,
                  ),
                ),
                h1: style(defaults.h1, 30, bold: true),
                h2: style(defaults.h2, 25, bold: true),
                h3: style(defaults.h3, 21, bold: true),
                placeHolder: style(defaults.placeHolder, fontSize)?.copyWith(
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: fontSize,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FindDocumentIntent extends Intent {
  const _FindDocumentIntent();
}

class DocumentToolbar extends StatelessWidget {
  const DocumentToolbar({
    super.key,
    required this.document,
    required this.focusNode,
    required this.readOnly,
    required this.compact,
    required this.onSearch,
  });
  final NoteDocumentController document;
  final FocusNode focusNode;
  final bool readOnly, compact;
  final VoidCallback onSearch;

  Future<void> link(BuildContext context) async {
    final expectedDocument = document.snapshotSource;
    final selected = document.controller.selection;
    final existing =
        document.controller.getSelectionStyle().attributes['link']?.value
            as String?;
    final address = TextEditingController(text: existing ?? '');
    final label = TextEditingController(
      text: selected.isCollapsed
          ? ''
          : document.text.substring(selected.start, selected.end),
    );
    final form = GlobalKey<FormState>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const DialogHeading('Chèn liên kết', icon: Icons.link),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Chữ hiển thị'),
                  validator: (v) =>
                      v?.trim().isEmpty != false ? 'Nhập chữ hiển thị.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ liên kết',
                  ),
                  validator: (v) => safeDocumentLink(v ?? '')
                      ? null
                      : 'Dùng https://, http:// hoặc mailto:.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, (label.text, address.text.trim()));
              }
            },
            child: const Text('Chèn'),
          ),
        ],
      ),
    );
    // Dialog keyboard/focus can change; apply to the captured selection only.
    if (result != null &&
        document.canEdit() &&
        context.mounted &&
        document.snapshotSource == expectedDocument) {
      document.controller.replaceText(
        selected.start,
        selected.end - selected.start,
        result.$1,
        TextSelection(
          baseOffset: selected.start,
          extentOffset: selected.start + result.$1.length,
        ),
      );
      document.format('link', result.$2);
      focusNode.requestFocus();
    }
    address.dispose();
    label.dispose();
  }

  Future<void> color(BuildContext context, String key) async {
    const colors = [
      '#19223b',
      '#5c43c9',
      '#2468a7',
      '#126b54',
      '#a52b24',
      '#ad3b7e',
      '#9c6500',
      '#eef0ff',
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(key == 'color' ? 'Màu chữ' : 'Màu đánh dấu'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final hex in colors)
              Semantics(
                label: 'Màu $hex',
                button: true,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, hex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse('ff${hex.substring(1)}', radix: 16),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'default'),
            child: const Text('Màu mặc định'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    if (result != null && document.canEdit()) {
      document.format(key, result == 'default' ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: document,
    builder: (ctx, _) {
      Widget action(
        String tooltip,
        IconData icon,
        VoidCallback? press, {
        bool selected = false,
      }) => IconButton(
        tooltip: tooltip,
        isSelected: selected,
        selectedIcon: Icon(icon),
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(ctx).colorScheme.primaryContainer
              : null,
          foregroundColor: selected
              ? Theme.of(ctx).colorScheme.onPrimaryContainer
              : null,
        ),
        onPressed: press,
      );
      Widget toggle(
        String tip,
        IconData icon,
        String key, [
        Object value = true,
      ]) => action(
        tip,
        icon,
        readOnly
            ? null
            : () {
                document.toggle(key, value);
                focusNode.requestFocus();
              },
        selected: document.selected(key, value),
      );
      final controls = <Widget>[
        action(
          'Hoàn tác (Ctrl+Z)',
          Icons.undo,
          !readOnly && document.controller.hasUndo
              ? document.controller.undo
              : null,
        ),
        action(
          'Làm lại (Ctrl+Y)',
          Icons.redo,
          !readOnly && document.controller.hasRedo
              ? document.controller.redo
              : null,
        ),
        if (!compact) ...[
          PopupMenuButton<int>(
            tooltip: 'Kiểu đoạn văn',
            enabled: !readOnly,
            onSelected: (level) {
              document.format('header', level == 0 ? null : level);
              focusNode.requestFocus();
            },
            itemBuilder: (_) => [
              for (var i = 0; i <= 3; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(i == 0 ? 'Văn bản' : 'Tiêu đề $i'),
                ),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.controller
                                .getSelectionStyle()
                                .attributes['header']
                                ?.value ==
                            null
                        ? 'Văn bản'
                        : 'Tiêu đề ${document.controller.getSelectionStyle().attributes['header']!.value}',
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Cỡ chữ',
            enabled: !readOnly,
            onSelected: (size) {
              document.format('size', size.toString());
              focusNode.requestFocus();
            },
            itemBuilder: (_) => [
              for (final size in [12, 14, 16, 18, 20, 24, 28, 32])
                PopupMenuItem(value: size, child: Text('$size')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${document.controller.getSelectionStyle().attributes['size']?.value ?? 16}',
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
        ],
        toggle('In đậm (Ctrl+B)', Icons.format_bold, 'bold'),
        toggle('In nghiêng (Ctrl+I)', Icons.format_italic, 'italic'),
        toggle('Gạch chân (Ctrl+U)', Icons.format_underlined, 'underline'),
        if (!compact) ...[
          toggle('Gạch ngang', Icons.format_strikethrough, 'strike'),
          action(
            'Màu chữ',
            Icons.format_color_text,
            readOnly ? null : () => color(ctx, 'color'),
          ),
          action(
            'Đánh dấu màu',
            Icons.format_color_fill,
            readOnly ? null : () => color(ctx, 'background'),
          ),
          toggle('Căn trái', Icons.format_align_left, 'align', 'left'),
          toggle('Căn giữa', Icons.format_align_center, 'align', 'center'),
          toggle('Căn phải', Icons.format_align_right, 'align', 'right'),
          toggle('Căn đều', Icons.format_align_justify, 'align', 'justify'),
        ],
        toggle(
          'Danh sách dấu đầu dòng',
          Icons.format_list_bulleted,
          'list',
          'bullet',
        ),
        if (!compact)
          toggle(
            'Danh sách đánh số',
            Icons.format_list_numbered,
            'list',
            'ordered',
          ),
        toggle('Danh sách công việc', Icons.checklist, 'list', 'unchecked'),
        if (!compact) ...[
          toggle('Trích dẫn', Icons.format_quote, 'blockquote'),
          toggle('Khối mã', Icons.code, 'code-block'),
          action(
            'Chèn liên kết',
            Icons.link,
            readOnly ? null : () => link(ctx),
          ),
          action(
            'Xóa định dạng',
            Icons.format_clear,
            readOnly ? null : document.clearFormat,
          ),
        ],
        action('Tìm và thay thế (Ctrl+F)', Icons.search, onSearch),
        if (compact)
          PopupMenuButton<String>(
            tooltip: 'Định dạng khác',
            enabled: !readOnly,
            onSelected: (key) {
              switch (key) {
                case 'link':
                  unawaited(link(ctx));
                case 'color':
                  unawaited(color(ctx, 'color'));
                case 'clear':
                  document.clearFormat();
                case 'header':
                  document.toggle('header', 2);
                case 'ordered':
                  document.toggle('list', 'ordered');
                case 'center':
                  document.toggle('align', 'center');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'header', child: Text('Tiêu đề đoạn')),
              PopupMenuItem(value: 'ordered', child: Text('Danh sách đánh số')),
              PopupMenuItem(value: 'center', child: Text('Căn giữa')),
              PopupMenuItem(value: 'color', child: Text('Màu chữ')),
              PopupMenuItem(value: 'link', child: Text('Chèn liên kết')),
              PopupMenuItem(value: 'clear', child: Text('Xóa định dạng')),
            ],
          ),
      ];
      return Material(
        color: Theme.of(ctx).colorScheme.surfaceContainerLow,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: controls),
        ),
      );
    },
  );
}
