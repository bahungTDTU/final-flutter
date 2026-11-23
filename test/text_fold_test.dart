import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/text_fold.dart';
import 'package:note_together/l10n/app_strings.dart';
import 'package:note_together/state/note_listing.dart';

void main() {
  test('Vietnamese folding handles composed and decomposed vowels', () {
    expect(foldVietnamese('Mạng Máy Tính'), 'mang may tinh');
    expect(foldVietnamese('Đường'), 'duong');
    expect(foldVietnamese('Σ Д Ñ'), 'σ д ñ');
    expect(foldVietnamese('ASCII 123 [.*]'), 'ascii 123 [.*]');
    const vowels =
        'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩị'
        'òóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
    final expected =
        '${'a' * 17}${'e' * 11}${'i' * 5}'
        '${'o' * 17}${'u' * 11}${'y' * 5}d';
    expect(foldVietnamese(vowels), expected);
    expect(foldVietnamese(vowels.toUpperCase()), expected);
    const mixed = 'Mạng ĐƯỜNG 😀 中 A\u0300';
    expect(foldVietnamese(mixed), 'mang duong 😀 中 a');
    expect(foldVietnamese('İ').length, 1);
    expect(foldVietnamese('😀 中 A\u0300'), '😀 中 a');
  });

  test(
    'Search stops at title matches and handles repeated prefix fallbacks',
    () {
      expect(
        NoteSearchPattern('đường').matches(
          'Đu\u031bo\u031b\u0300ng',
          () => throw StateError('body read'),
        ),
        isTrue,
      );
      expect(
        NoteSearchPattern('aaaaab').matches('', () => '${'a' * 10000}b'),
        isTrue,
      );
      expect(NoteSearchPattern('a.b').matches('axb', () => ''), isFalse);
    },
  );

  test(
    'Listing folds title, content and boundary without exposing locked notes',
    () {
      Note note(
        String id,
        String title,
        String content, {
        bool locked = false,
      }) => Note(
        id: id,
        title: title,
        content: content,
        locked: locked,
        revision: 1,
        updatedAt: '2026-11-20',
      );
      final notes = [
        note('title', 'Mạng máy tính', 'Khác'),
        note('content', 'Khác', 'Mạng máy tính'),
        note('boundary', 'Mạng', 'máy tính'),
        note('locked', 'Mạng máy tính', 'Mạng máy tính', locked: true),
        note('literal', '[mạng.*]', 'Khác'),
      ];
      final cache = NoteListingCache();
      List<String> search(String query) => cache
          .select(
            account: 'A',
            notes: notes,
            query: query,
            shared: false,
            labels: {},
            deletedLabels: {},
          )
          .all
          .map((n) => n.id)
          .toList();
      for (final query in [
        'mang may',
        'MẠNG máy',
        'mạng máy',
        'ma\u0323ng ma\u0301y',
      ]) {
        expect(
          search(query),
          unorderedEquals(['title', 'content', 'boundary']),
        );
      }
      expect(search('không liên quan'), isEmpty);
      expect(search('[mang.*]'), ['literal']);
    },
  );

  test('Header count resources support both locales', () {
    expect(const AppStrings('vi').noteCount(0, total: 3), '0/3 ghi chú');
    expect(const AppStrings('en').noteCount(0, total: 3), 'Notes: 0/3');
    expect(const AppStrings('vi').noteCount(3), '3 ghi chú');
  });
}
