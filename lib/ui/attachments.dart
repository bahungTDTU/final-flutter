import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/attachment_files.dart';
import '../data/attachment_platform.dart';
import '../state/app_controller.dart';
import '../state/attachment_session.dart';
import 'app.dart';
import 'design_system.dart';

class AttachmentsDialog extends StatefulWidget {
  const AttachmentsDialog({
    super.key,
    required this.controller,
    required this.noteId,
    required this.canEdit,
    this.protectedGate,
    this.gateChanges,
    this.picker = pickAttachments,
  });
  final AppController controller;
  final String noteId;
  final bool canEdit;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  final Future<List<SelectedAttachment>> Function() picker;
  @override
  State<AttachmentsDialog> createState() => _AttachmentsDialogState();
}

class _AttachmentsDialogState extends State<AttachmentsDialog>
    with WidgetsBindingObserver {
  late final session = AttachmentSession(
    widget.controller,
    widget.noteId,
    protectedGate: widget.protectedGate,
    gateChanges: widget.gateChanges,
  );
  List<SelectedAttachment> selected = [];
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(session.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      session.hide(
        'Nội dung đã che khi ứng dụng ra nền. Kiểm tra lại khi trở về.',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.dispose();
    selected = [];
    super.dispose();
  }

  Future<void> action(Future<void> Function() work) async {
    if (busy || !session.active) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await work();
    } on ArgumentError catch (e) {
      if (mounted) setState(() => message = '${e.message}');
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Chưa hoàn tất. ${friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: const DialogHeading('Đính kèm', icon: Icons.attach_file),
        scrollable: true,
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusNotice(
                message: 'Tệp được bảo vệ theo quyền của ghi chú. Cần kết nối để tải lên, tải xuống và xem trước.',
                icon: Icons.shield_outlined,
              ),
              const SizedBox(height: 12),
              Text(
                'Tối đa 10 tệp/ghi chú · PNG/JPEG: 10 MiB · MP4/PDF/TXT/CSV/ZIP: 20 MiB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              SectionHeading(
                'Tệp của ghi chú',
                detail: '${session.files.length} tệp',
              ),
              if (session.error != null) Text(session.error!),
              if (message != null)
                Text(message!, key: const Key('attachment-message')),
              if (!session.active)
                const Text('Đóng cửa sổ này và mở lại ghi chú.'),
              if (session.active) ...[
                if (session.files.isEmpty && !session.busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Chưa có tệp đính kèm.'),
                  ),
                for (final file in session.files)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['name'] as String,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: MetadataPill(
                              '${file['kind'] == 'image'
                                  ? 'Ảnh'
                                  : file['kind'] == 'video'
                                  ? 'Video'
                                  : 'Tệp'} · ${((file['size'] as int) / 1024).ceil()} KiB',
                              icon: file['kind'] == 'image'
                                  ? Icons.image_outlined
                                  : file['kind'] == 'video'
                                  ? Icons.videocam_outlined
                                  : Icons.insert_drive_file_outlined,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (file['kind'] != 'file')
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => AttachmentPreview(
                                            session: session,
                                            file: file,
                                          ),
                                        ),
                                  child: const Text('Xem trước'),
                                ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => action(() async {
                                        final bytes = await session.read(
                                          file['id'] as String,
                                        );
                                        final saved = await saveAttachment(
                                          file['kind'] == 'image'
                                              ? '${file['name']}.png'
                                              : file['name'] as String,
                                          file['media_type'] as String,
                                          bytes,
                                        );
                                        if (mounted && session.active) {
                                          setState(
                                            () => message = saved
                                                ? (kIsWeb
                                                      ? 'Đã chuyển file cho trình duyệt tải xuống.'
                                                      : 'Đã lưu file vào vị trí bạn chọn.')
                                                : 'Đã hủy lưu file.',
                                          );
                                        }
                                      }),
                                child: const Text('Tải xuống'),
                              ),
                              if (widget.canEdit && session.canEdit)
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          final accepted = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AnimatedBuilder(
                                              animation: session,
                                              builder: (context, _) {
                                                final available =
                                                    session.canEdit &&
                                                    session.files.any(
                                                      (row) =>
                                                          row['id'] ==
                                                          file['id'],
                                                    );
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Xóa tệp đính kèm?',
                                                  ),
                                                  content: Text(
                                                    available
                                                        ? 'Xóa ${file['name']}; nội dung ghi chú vẫn giữ.'
                                                        : 'Quyền truy cập đã thay đổi. Đóng và kiểm tra lại.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: available
                                                          ? () => Navigator.pop(
                                                              context,
                                                              true,
                                                            )
                                                          : null,
                                                      child: const Text(
                                                        'Xóa tệp',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          );
                                          if (accepted == true) {
                                            await action(
                                              () => session.delete(
                                                file['id'] as String,
                                              ),
                                            );
                                          }
                                        },
                                  child: const Text('Xóa'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.canEdit && session.canEdit) ...[
                  for (final file in selected)
                    Row(
                      children: [
                        Expanded(child: Text('Chờ tải: ${file.name}')),
                        IconButton(
                          tooltip: 'Bỏ ${file.name}',
                          onPressed: busy
                              ? null
                              : () => setState(
                                  () => selected = selected
                                      .where((p) => p.id != file.id)
                                      .toList(),
                                ),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  OutlinedButton.icon(
                    key: const Key('attachment-pick'),
                    onPressed: busy
                        ? null
                        : () => action(() async {
                            final files = await widget.picker();
                            if (mounted && session.active && files.isNotEmpty) {
                              setState(() => selected = files);
                            }
                          }),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Chọn tệp'),
                  ),
                  FilledButton(
                    key: const Key('attachment-upload'),
                    onPressed: busy || selected.isEmpty
                        ? null
                        : () => action(() async {
                            for (final file in List<SelectedAttachment>.from(
                              selected,
                            )) {
                              await session.upload(file);
                              if (!mounted || !session.active) return;
                              setState(
                                () => selected = selected
                                    .where((p) => p.id != file.id)
                                    .toList(),
                              );
                            }
                            if (mounted) {
                              setState(
                                () => message = 'Server đã lưu tệp đính kèm.',
                              );
                            }
                          }),
                    child: Text(busy ? 'Đang xử lý…' : 'Tải tệp lên'),
                  ),
                ],
                TextButton(
                  onPressed: busy || session.busy ? null : session.refresh,
                  child: const Text('Kiểm tra quyền và cập nhật'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}

class AttachmentPreview extends StatefulWidget {
  const AttachmentPreview({
    super.key,
    required this.session,
    required this.file,
  });
  final AttachmentSession session;
  final Map<String, dynamic> file;
  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  Uint8List? bytes;
  AttachmentVideoSource? video;
  String? error;
  late final epoch = widget.session.epoch;
  bool get active =>
      widget.session.active &&
      widget.session.epoch == epoch &&
      widget.session.files.any((file) => file['id'] == widget.file['id']);
  @override
  void initState() {
    super.initState();
    widget.session.addListener(changed);
    unawaited(load());
  }

  void changed() {
    if (!active) {
      bytes = null;
      final old = video;
      video = null;
      if (old != null) unawaited(old.dispose());
    }
    if (mounted) setState(() {});
  }

  Future<void> load() async {
    try {
      final data = await widget.session.read(widget.file['id'] as String);
      if (!mounted || !active) return;
      if (widget.file['kind'] == 'video') {
        final source = AttachmentVideoSource(
          '${widget.session.controller.api.baseUrl}${widget.session.path}/${widget.file['id']}',
          widget.session.sessionToken!,
          data,
        );
        video = source;
        await source.controller.initialize();
        if (!mounted || !active || video != source) return;
      } else {
        bytes = data;
      }
    } catch (_) {
      error =
          'Chưa xem được tệp. Kiểm tra quyền, kết nối hoặc định dạng video.';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.session.removeListener(changed);
    bytes = null;
    if (video != null) unawaited(video!.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(active ? widget.file['name'] as String : 'Phiên xem đã đóng'),
    content: SizedBox(
      width: 540,
      child: !active
          ? const Text('Nội dung đã được che.')
          : error != null
          ? Text(error!)
          : video != null && video!.controller.value.isInitialized
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: video!.controller.value.aspectRatio,
                  child: VideoPlayer(video!.controller),
                ),
                TextButton(
                  onPressed: () async {
                    final player = video!.controller;
                    player.value.isPlaying
                        ? await player.pause()
                        : await player.play();
                    if (mounted) setState(() {});
                  },
                  child: Text(
                    video!.controller.value.isPlaying
                        ? 'Tạm dừng'
                        : 'Phát video',
                  ),
                ),
              ],
            )
          : bytes != null
          ? Image.memory(
              bytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text('Không đọc được ảnh.'),
            )
          : const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng xem trước'),
      ),
    ],
  );
}
