import 'dart:typed_data';

/// Folds precomposed Vietnamese letters for search, preserving UTF-16 length.
/// Each code unit maps to one code unit: Vietnamese vowels lose tone/shape
/// marks, `đ/Đ` becomes `d`, and other characters are lowercased only when
/// that preserves length. NFD combining marks (U+0300–U+0323) are retained;
/// removing them would change offsets used by substring matching.
String foldVietnamese(String input) {
  final table = _foldTable;
  final units = Uint16List(input.length);
  for (var i = 0; i < input.length; i++) {
    units[i] = table[input.codeUnitAt(i)];
  }
  return String.fromCharCodes(units);
}

/// Literal, accent-insensitive substring test. [foldedNeedle] must already be
/// passed through [foldVietnamese]; [haystack] is folded on the fly without
/// allocating a folded copy, and the scan stops at the first match.
bool containsFolded(String haystack, String foldedNeedle) {
  final n = foldedNeedle.length;
  if (n == 0) return true;
  final table = _foldTable;
  final first = foldedNeedle.codeUnitAt(0);
  final last = haystack.length - n;
  for (var i = 0; i <= last; i++) {
    if (table[haystack.codeUnitAt(i)] != first) continue;
    var j = 1;
    while (j < n &&
        table[haystack.codeUnitAt(i + j)] == foldedNeedle.codeUnitAt(j)) {
      j++;
    }
    if (j == n) return true;
  }
  return false;
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
