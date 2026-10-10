import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../domain/writing_tools.dart';
import 'design_system.dart';
import 'rich_note_field.dart';

class DocumentWorkspace extends StatefulWidget {
  const DocumentWorkspace({
    super.key,
    required this.title,
    required this.document,
    required this.contentFocus,
    required this.scrollController,
    required this.readOnly,
    required this.titleKey,
    required this.contentKey,
    required this.onTitleChanged,
    required this.leading,
    this.organisation,
    required this.tools,
    this.actions = const [],
    this.fontSize = 16,
    this.focusMode = false,
  });
  final TextEditingController title;
  final NoteDocumentController document;
  final FocusNode contentFocus;
  final ScrollController scrollController;
  final bool readOnly, focusMode;
  final Key titleKey, contentKey;
  final VoidCallback onTitleChanged;
  final Widget leading, tools;
  final Widget? organisation;
  final List<Widget> actions;
  final double fontSize;
  @override
  State<DocumentWorkspace> createState() => _DocumentWorkspaceState();
}

class _DocumentWorkspaceState extends State<DocumentWorkspace> {
  double zoom = 1;
  bool reading = false;
  late final GlobalKey paperKey = GlobalKey();
  bool get readOnly => widget.readOnly || reading;
  void search() => showDialog<void>(
    context: context,
    builder: (_) => DocumentFindDialog(
      document: widget.document,
      focusNode: widget.contentFocus,
      readOnly: readOnly,
    ),
  );

  Widget paper(BuildContext context, bool desktop) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final content = Container(
      key: paperKey,
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 36 : 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(desktop ? 18 : 16),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: desktop
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Tiêu đề', style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Tiêu đề',
            child: TextField(
              key: widget.titleKey,
              controller: widget.title,
              readOnly: readOnly,
              maxLength: 200,
              minLines: 1,
              maxLines: null,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontSize: desktop ? 30 : 25,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: 'Đặt tên cho ghi chú…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => widget.onTitleChanged(),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text('Nội dung', style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 12),
          NoteRichTextField(
            key: widget.contentKey,
            document: widget.document,
            focusNode: widget.contentFocus,
            readOnly: readOnly,
            fontSize: widget.fontSize,
            minHeight: desktop ? 370 : 220,
            onSearch: search,
          ),
          ListenableBuilder(
            listenable: widget.document,
            builder: (ctx, _) => widget.document.problem == null
                ? const SizedBox.shrink()
                : StatusNotice(message: widget.document.problem!, error: true),
          ),
        ],
      ),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: zoom == 1
            ? MediaQuery.textScalerOf(context)
            : TextScaler.linear(
                MediaQuery.textScalerOf(context).scale(1) * zoom,
              ),
      ),
      child: content,
    );
  }

  Widget inspector(bool desktop) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.organisation != null) widget.organisation!,
      if (widget.actions.isNotEmpty) ...[
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Công cụ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.actions,
      ],
      const SizedBox(height: 20),
      widget.tools,
    ],
  );

  Widget outline() => ValueListenableBuilder<TextEditingValue>(
    valueListenable: widget.document.source,
    builder: (ctx, _, _) {
      final snapshot = WritingSnapshot(widget.document.snapshotSource);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Semantics(
                header: true,
                child: Text(
                  'Mục lục',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.headings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Dùng kiểu Tiêu đề để tạo mục lục.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            for (final heading in snapshot.headings)
              Padding(
                padding: EdgeInsets.only(left: (heading.level - 1) * 8),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.description_outlined, size: 18),
                  title: Text(
                    heading.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    widget.document.select(heading.offset);
                    widget.contentFocus.requestFocus();
                  },
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Chọn tiêu đề để di chuyển',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget footer(bool desktop) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: widget.document.source,
    builder: (ctx, _, _) {
      final stats = WritingSnapshot(widget.document.snapshotSource);
      return Material(
        color: Theme.of(ctx).colorScheme.surfaceContainerLow,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                if (desktop) ...[
                  const Icon(Icons.cloud_done_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Tự động lưu'),
                  const Spacer(),
                ],
                Expanded(
                  child: Text(
                    '${stats.words} từ · ${stats.characters} ký tự',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(ctx).textTheme.bodySmall,
                    textAlign: desktop ? TextAlign.center : TextAlign.left,
                  ),
                ),
                if (desktop) ...[
                  const Spacer(),
                  IconButton(
                    tooltip: 'Thu nhỏ tài liệu',
                    onPressed: zoom > .8
                        ? () =>
                              setState(() => zoom = (zoom - .1).clamp(.8, 1.4))
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Text('${(zoom * 100).round()}%'),
                  IconButton(
                    tooltip: 'Phóng to tài liệu',
                    onPressed: zoom < 1.4
                        ? () =>
                              setState(() => zoom = (zoom + .1).clamp(.8, 1.4))
                        : null,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): search,
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): search,
    },
    child: LayoutBuilder(
      builder: (ctx, area) {
        final desktop =
            area.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(ctx).scale(16) <= 24;
        final showOutline =
            desktop && area.maxWidth >= 1350 && !widget.focusMode;
        final toolbar = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DocumentToolbar(
              document: widget.document,
              focusNode: widget.contentFocus,
              readOnly: readOnly,
              compact: !desktop,
              onSearch: search,
            ),
            const Divider(),
          ],
        );
        final body = desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showOutline)
                    SizedBox(
                      width: 212,
                      child: SingleChildScrollView(child: outline()),
                    ),
                  Expanded(
                    child: Scrollbar(
                      controller: widget.scrollController,
                      child: SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                widget.leading,
                                const SizedBox(height: 14),
                                paper(ctx, true),
                                if (widget.focusMode)
                                  const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.focusMode)
                    SizedBox(
                      width: 276,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 18, 16, 18),
                        child: inspector(true),
                      ),
                    ),
                ],
              )
            : Scrollbar(
                controller: widget.scrollController,
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.leading,
                      const SizedBox(height: 12),
                      paper(ctx, false),
                      if (!widget.focusMode) ...[
                        const SizedBox(height: 18),
                        inspector(false),
                      ],
                    ],
                  ),
                ),
              );
        return Column(
          children: [
            if (desktop)
              Row(
                children: [
                  Expanded(child: toolbar),
                  IconButton(
                    tooltip: reading ? 'Tiếp tục soạn thảo' : 'Chế độ đọc',
                    onPressed: () => setState(() => reading = !reading),
                    icon: Icon(
                      reading ? Icons.edit_outlined : Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
            Expanded(child: body),
            if (!desktop) toolbar,
            footer(desktop),
          ],
        );
      },
    ),
  );
}

class DocumentFindDialog extends StatefulWidget {
  const DocumentFindDialog({
    super.key,
    required this.document,
    required this.focusNode,
    required this.readOnly,
  });
  final NoteDocumentController document;
  final FocusNode focusNode;
  final bool readOnly;
  @override
  State<DocumentFindDialog> createState() => _DocumentFindDialogState();
}

class _DocumentFindDialogState extends State<DocumentFindDialog> {
  final query = TextEditingController(), replacement = TextEditingController();
  bool matchCase = false;
  int active = -1;
  List<RegExpMatch> matches = [];
  String? message;
  void refresh() {
    final term = query.text;
    matches = term.isEmpty
        ? []
        : RegExp(
            RegExp.escape(term),
            caseSensitive: matchCase,
            unicode: true,
          ).allMatches(widget.document.text).toList();
    active = -1;
    message = null;
  }

  void next(int direction) {
    if (matches.isEmpty) return;
    setState(() => active = (active + direction) % matches.length);
    final match = matches[active];
    widget.document.controller.updateSelection(
      TextSelection(baseOffset: match.start, extentOffset: match.end),
      quill.ChangeSource.local,
    );
  }

  void replace(bool all) {
    if (!widget.document.canEdit() || matches.isEmpty) return;
    final currentText = widget.document.text;
    // Recompute after any local/remote update while the dialog was open.
    final fresh = RegExp(
      RegExp.escape(query.text),
      caseSensitive: matchCase,
      unicode: true,
    ).allMatches(currentText).toList();
    final targets = all
        ? fresh.reversed
        : active >= 0 && active < fresh.length
        ? [fresh[active]]
        : fresh.take(1);
    var count = 0;
    for (final match in targets) {
      widget.document.controller.replaceText(
        match.start,
        match.end - match.start,
        replacement.text,
        null,
      );
      count++;
    }
    setState(() {
      refresh();
      message = 'Đã thay $count kết quả.';
    });
  }

  @override
  void dispose() {
    query.dispose();
    replacement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const DialogHeading('Tìm và thay thế', icon: Icons.find_replace),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('document-find'),
              controller: query,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tìm trong ghi chú'),
              onChanged: (_) => setState(refresh),
              onSubmitted: (_) => next(1),
            ),
            const SizedBox(height: 12),
            Text(
              '${matches.length} kết quả${active >= 0 ? ' · ${active + 1}/${matches.length}' : ''}',
            ),
            CheckboxListTile(
              title: const Text('Phân biệt hoa/thường'),
              value: matchCase,
              onChanged: (v) => setState(() {
                matchCase = v!;
                refresh();
              }),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: matches.isEmpty ? null : () => next(-1),
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('Trước'),
                ),
                TextButton.icon(
                  onPressed: matches.isEmpty ? null : () => next(1),
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Tiếp'),
                ),
              ],
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('document-replacement'),
                controller: replacement,
                decoration: const InputDecoration(labelText: 'Thay bằng'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: matches.isEmpty ? null : () => replace(false),
                    child: const Text('Thay một'),
                  ),
                  FilledButton(
                    onPressed: matches.isEmpty ? null : () => replace(true),
                    child: const Text('Thay tất cả'),
                  ),
                ],
              ),
            ],
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message!),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          widget.focusNode.requestFocus();
        },
        child: const Text('Đóng'),
      ),
    ],
  );
}
