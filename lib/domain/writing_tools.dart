/// Optional, editable starter text. No note IDs, permissions or user data.
class NoteTemplate {
  const NoteTemplate(this.id, this.title, this.description, this.content);
  final String id, title, description, content;
  static const all = [
    NoteTemplate(
      'cornell',
      'Ghi chép Cornell',
      'Học sâu với câu hỏi, ý chính và phần tự tóm tắt.',
      '# Chủ đề bài học\n\n## Câu hỏi gợi nhớ\n- Điều gì cần giải thích?\n\n## Ý chính\n- Khái niệm:\n- Ví dụ:\n\n## Tự tóm tắt\nViết lại bài học bằng lời của bạn.\n\n## Ôn tập\n- [ ] Tự trả lời câu hỏi mà không nhìn tài liệu\n- [ ] Kiểm tra lại phần chưa rõ',
    ),
    NoteTemplate(
      'meeting',
      'Biên bản cuộc họp',
      'Biến trao đổi thành quyết định và việc cần làm.',
      '# Cuộc họp nhóm\n\n## Mục tiêu\nChúng ta cần giải quyết điều gì?\n\n## Nội dung trao đổi\n- Ý kiến:\n\n## Quyết định\n- Thống nhất:\n\n## Việc tiếp theo\n- [ ] Phân công người phụ trách\n- [ ] Xác nhận mốc hoàn thành',
    ),
    NoteTemplate(
      'project',
      'Kế hoạch dự án',
      'Một nơi cho mục tiêu, phạm vi và checklist triển khai.',
      '# Kế hoạch dự án\n\n## Kết quả mong muốn\nMô tả một kết quả có thể kiểm chứng.\n\n## Phạm vi\n- Cần làm:\n- Giới hạn:\n\n## Các mốc\n- [ ] Chốt yêu cầu\n- [ ] Triển khai phiên bản đầu\n- [ ] Kiểm thử và thu thập bằng chứng\n- [ ] Tổng kết\n\n## Rủi ro\n- Vấn đề và cách xử lý:',
    ),
    NoteTemplate(
      'decision',
      'Nhật ký quyết định',
      'Ghi lại lý do để nhóm hiểu và xem xét lại lựa chọn.',
      '# Một quyết định cần đưa ra\n\n## Bối cảnh\nĐiều gì khiến quyết định này cần thiết?\n\n## Các lựa chọn\n- Phương án A:\n- Phương án B:\n\n## Lựa chọn và lý do\nGiải thích lợi ích và đánh đổi.\n\n## Kiểm chứng\n- [ ] Thử nghiệm giả định quan trọng\n- [ ] Ghi nhận kết quả\n\n## Khi nào xem xét lại\nĐiều kiện khiến lựa chọn cần thay đổi.',
    ),
    NoteTemplate(
      'weekly',
      'Tổng kết tuần',
      'Nhìn lại tiến độ và chọn điều quan trọng cho tuần tới.',
      '# Tổng kết tuần\n\n## Đã hoàn thành\n- Kết quả:\n\n## Điều đã học\n- Bài học:\n\n## Vướng mắc\n- Cần hỗ trợ:\n\n## Tuần tới\n- [ ] Ưu tiên thứ nhất\n- [ ] Ưu tiên thứ hai\n- [ ] Dành thời gian xem lại tiến độ',
    ),
    NoteTemplate(
      'idea',
      'Vườn ý tưởng',
      'Từ một ý tưởng đến một thử nghiệm nhỏ.',
      '# Ý tưởng mới\n\n## Vấn đề\nAi đang gặp khó khăn gì?\n\n## Ý tưởng\nMô tả giải pháp bằng một câu.\n\n## Giá trị\nĐiều gì sẽ tốt hơn?\n\n## Thử nghiệm nhỏ\n- [ ] Xác định giả định\n- [ ] Thử với một tình huống thực\n- [ ] Ghi lại điều học được',
    ),
  ];
}

class WritingHeading {
  const WritingHeading(this.text, this.offset, this.level);
  final String text;
  final int offset, level;
}

class WritingTask {
  const WritingTask(this.text, this.markerOffset, this.done);
  final String text;
  final int markerOffset;
  final bool done;
}

/// Linear, local analysis of plain text. UTF-16 offsets match TextSelection.
/// Fenced examples are excluded from the interactive outline and checklist.
class WritingSnapshot {
  static final _whitespace = RegExp(r'\s+');
  static final _word = RegExp(r'[A-Za-z0-9\u00C0-\u1FFF]');
  static final _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
  static final _heading = RegExp(r'^ {0,3}(#{1,6})\s+(.+?)\s*$');
  static final _headingSuffix = RegExp(r'\s+#+\s*$');
  static final _task = RegExp(r'^\s*[-*+]\s+\[([ xX])\]\s+(.+?)\s*$');
  WritingSnapshot(String text) {
    characters = text.runes.length;
    words = text
        .split(_whitespace)
        .where((word) => _word.hasMatch(word))
        .length;
    var offset = 0;
    String? fence;
    var fenceLength = 0;
    for (final line in text.split('\n')) {
      final fenceMatch = _fence.firstMatch(line);
      if (fenceMatch != null) {
        final marker = fenceMatch[1]!;
        if (fence == null) {
          fence = marker[0];
          fenceLength = marker.length;
        } else if (marker[0] == fence &&
            marker.length >= fenceLength &&
            fenceMatch[2]!.trim().isEmpty) {
          fence = null;
        }
      } else if (fence == null) {
        final heading = _heading.firstMatch(line);
        if (heading != null && headings.length < 100) {
          headings.add(
            WritingHeading(
              heading[2]!.replaceFirst(_headingSuffix, ''),
              offset,
              heading[1]!.length,
            ),
          );
        }
        final task = _task.firstMatch(line);
        if (task != null) {
          taskCount++;
          final done = task[1] != ' ';
          if (done) completed++;
          if (tasks.length < 100) {
            tasks.add(
              WritingTask(task[2]!, offset + line.indexOf('[') + 1, done),
            );
          }
        }
      }
      offset += line.length + 1;
    }
  }
  late final int characters, words;
  final headings = <WritingHeading>[];
  final tasks = <WritingTask>[];
  int taskCount = 0, completed = 0;
  int get readingMinutes => (words / 200).ceil();
}

/// Refuse a click rendered from stale text; never edit the wrong line.
String? toggleWritingTask(String expected, String current, WritingTask task) {
  if (expected != current || task.markerOffset >= current.length) return null;
  return current.replaceRange(
    task.markerOffset,
    task.markerOffset + 1,
    task.done ? ' ' : 'x',
  );
}
