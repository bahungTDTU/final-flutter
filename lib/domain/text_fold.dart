import 'dart:typed_data';

bool _isVietnameseMark(int unit) => switch (unit) {
  0x300 || 0x301 || 0x302 || 0x303 || 0x306 || 0x309 || 0x31b || 0x323 => true,
  _ => false,
};

bool _isVowel(int unit) => switch (unit) {
  97 || 101 || 105 || 111 || 117 || 121 => true,
  _ => false,
};

String foldVietnamese(String input) {
  final units = <int>[];
  var afterVowel = false;
  for (final unit in input.codeUnits) {
    if (afterVowel && _isVietnameseMark(unit)) continue;
    final folded = _foldTable[unit];
    units.add(folded);
    afterVowel = _isVowel(folded);
  }
  return String.fromCharCodes(units);
}

/// Reuse one prefix table across notes. The matched prefix carries across the
/// title/body separator without joining strings or storing folded private text.
class NoteSearchPattern {
  NoteSearchPattern(String query) : pattern = foldVietnamese(query) {
    prefix = Uint32List(pattern.length);
    var matched = 0;
    for (var i = 1; i < pattern.length; i++) {
      matched = _advance(matched, pattern.codeUnitAt(i));
      prefix[i] = matched;
    }
  }
  final String pattern;
  late final Uint32List prefix;

  int _advance(int matched, int unit) {
    while (matched > 0 && pattern.codeUnitAt(matched) != unit) {
      matched = prefix[matched - 1];
    }
    return pattern.codeUnitAt(matched) == unit ? matched + 1 : matched;
  }

  int _scan(String text, int matched) {
    var afterVowel = false;
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (afterVowel && _isVietnameseMark(unit)) continue;
      final folded = _foldTable[unit];
      matched = _advance(matched, folded);
      if (matched == pattern.length) break;
      afterVowel = _isVowel(folded);
    }
    return matched;
  }

  bool matches(String title, String Function() body) {
    if (pattern.isEmpty) return true;
    var matched = _scan(title, 0);
    if (matched == pattern.length) return true;
    matched = _advance(matched, 32);
    return matched == pattern.length ||
        _scan(body(), matched) == pattern.length;
  }
}

/// UTF-16 code unit -> folded code unit. Built lazily on first search.
final Uint16List _foldTable = () {
  final table = Uint16List(0x10000);
  for (var unit = 0; unit < table.length; unit++) {
    // Surrogates are kept as-is; lowercasing a lone surrogate is meaningless.
    if (unit >= 0xD800 && unit <= 0xDFFF) {
      table[unit] = unit;
      continue;
    }
    final lower = String.fromCharCode(unit).toLowerCase();
    table[unit] = lower.length == 1 ? lower.codeUnitAt(0) : unit;
  }
  const groups = {
    'a': 'aàáảãạăằắẳẵặâầấẩẫậ',
    'e': 'eèéẻẽẹêềếểễệ',
    'i': 'iìíỉĩị',
    'o': 'oòóỏõọôồốổỗộơờớởỡợ',
    'u': 'uùúủũụưừứửữự',
    'y': 'yỳýỷỹỵ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    final base = entry.key.codeUnitAt(0);
    for (final unit in '${entry.value}${entry.value.toUpperCase()}'.codeUnits) {
      table[unit] = base;
    }
  }
  return table;
}();
