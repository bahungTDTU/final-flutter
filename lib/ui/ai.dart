import 'dart:async';

import 'package:flutter/material.dart';

import '../state/ai_session.dart';
import '../state/app_controller.dart';
import 'design_system.dart';
import 'editor.dart';
import 'note_protection.dart';

class AiQuestionsPanel extends StatefulWidget {
  const AiQuestionsPanel({
    super.key,
    required this.controller,
    this.protectedGate,
    this.gateChanges,
  });
  final AppController controller;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  @override
  State<AiQuestionsPanel> createState() => _AiQuestionsPanelState();
}

class _AiQuestionsPanelState extends State<AiQuestionsPanel>
    with WidgetsBindingObserver {
  late final session = AiSession(
    widget.controller,
    protectedGate: widget.protectedGate,
    gateChanges: widget.gateChanges,
  );
  final question = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    session.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      session.resume();
    } else {
      question.clear();
      session.suspend();
    }
  }

  Future<void> ask() async {
    if (form.currentState!.validate()) {
      await session.generate(question: question.text);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.removeListener(changed);
    session.dispose();
    question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReadingCanvas(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hỏi từ những ghi chú của bạn',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'AI tổng hợp từ ghi chú đã đồng bộ mà bạn có quyền đọc. Kết quả kèm nguồn để bạn kiểm tra.',
        ),
        const SizedBox(height: 16),
        const StatusNotice(
          message: 'Nội dung liên quan sẽ được gửi tới Gemini. Với free tier, Google có thể dùng dữ liệu để cải thiện sản phẩm. Chỉ gửi nội dung phù hợp.',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 24),
        Form(
          key: form,
          child: TextFormField(
            key: const Key('ai-question'),
            controller: question,
            enabled: !session.busy && session.active,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Câu hỏi của bạn',
              hintText:
                  'Ví dụ: Các mốc nộp bài trong những ghi chú của mình là gì?',
            ),
            validator: (v) => (v ?? '').trim().length < 3
                ? 'Nhập câu hỏi ít nhất 3 ký tự.'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('ai-ask'),
              onPressed: session.active && !session.busy ? ask : null,
              icon: const Icon(Icons.auto_awesome),
              label: Text(session.busy ? 'Đang tổng hợp…' : 'Hỏi AI'),
            ),
            if (session.busy || session.result != null)
              TextButton(
                onPressed: () => session.clear(),
                child: Text(session.busy ? 'Hủy yêu cầu' : 'Xóa kết quả'),
              ),
          ],
        ),
        if (session.busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (session.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: StatusNotice(
              message: session.error!,
              icon: Icons.info_outline,
            ),
          ),
        if (session.result != null) ...[
          const SizedBox(height: 24),
          AiResult(session: session),
        ],
        const SizedBox(height: 24),
        const Text(
          'Ghi chú đang khóa được loại khỏi nguồn. Để hỏi về ghi chú bảo vệ, mở khóa ghi chú rồi chọn “Hỏi AI”. Kết quả AI có thể sai; hãy kiểm tra nguồn.',
        ),
      ],
    ),
  );
}

class AiQuestionsScreen extends StatelessWidget {
  const AiQuestionsScreen({
    super.key,
    required this.controller,
    required this.protectedGate,
    required this.gateChanges,
  });
  final AppController controller;
  final bool Function() protectedGate;
  final Listenable gateChanges;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hỏi ghi chú')),
    body: SafeArea(
      child: AiQuestionsPanel(
        controller: controller,
        protectedGate: protectedGate,
        gateChanges: gateChanges,
      ),
    ),
  );
}

class AiSummaryDialog extends StatefulWidget {
  const AiSummaryDialog({
    super.key,
    required this.controller,
    required this.noteId,
    this.protectedGate,
    this.gateChanges,
  });
  final AppController controller;
  final String noteId;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  @override
  State<AiSummaryDialog> createState() => _AiSummaryDialogState();
}

class _AiSummaryDialogState extends State<AiSummaryDialog>
    with WidgetsBindingObserver {
  late final session = AiSession(
    widget.controller,
    noteId: widget.noteId,
    protectedGate: widget.protectedGate,
    gateChanges: widget.gateChanges,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    session.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      session.resume();
    } else {
      session.suspend();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.removeListener(changed);
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Space.reading),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tóm tắt bằng AI',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Gemini đọc phiên bản đã đồng bộ. Tóm tắt không ghi đè nội dung gốc và không được lưu vào ghi chú.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Nội dung sẽ được gửi tới Google. Free tier có thể dùng dữ liệu để cải thiện sản phẩm; hãy dùng ghi chú phù hợp.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('ai-summary-generate'),
                  onPressed: session.active && !session.busy
                      ? () => session.generate()
                      : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    session.busy
                        ? 'Đang tóm tắt…'
                        : session.result == null
                        ? 'Tạo tóm tắt'
                        : 'Tạo lại',
                  ),
                ),
                if (session.busy)
                  TextButton(
                    onPressed: () => session.clear(),
                    child: const Text('Hủy yêu cầu'),
                  ),
              ],
            ),
            if (session.busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            if (session.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: StatusNotice(
                  message: session.error!,
                  icon: Icons.info_outline,
                ),
              ),
            if (session.result != null) ...[
              const SizedBox(height: 24),
              AiResult(session: session),
            ],
          ],
        ),
      ),
    ),
  );
}

class AiResult extends StatelessWidget {
  const AiResult({super.key, required this.session});
  final AiSession session;
  Future<void> open(BuildContext context, String id) async {
    final note = await session.openSource(id);
    if (note == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => note.locked
            ? ProtectedNoteScreen(controller: session.controller, id: id)
            : EditorScreen(controller: session.controller, id: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        session.noteId == null ? 'Câu trả lời' : 'Bản tóm tắt',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      SelectableText(
        session.result?['summary'] as String? ??
            session.result?['answer'] as String? ??
            '',
        key: const Key('ai-result'),
        style: TextStyle(fontSize: session.controller.fontSize, height: 1.6),
      ),
      if (session.sources.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Ghi chú nguồn', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...session.sources.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              key: ValueKey('ai-source-${s['id']}'),
              onPressed: () => open(context, s['id'] as String),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                s['title'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        'Kết quả tạm thời · kiểm tra lại nguồn trước khi sử dụng.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
