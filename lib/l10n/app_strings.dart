import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_en.dart';

/// UI resources only. Never pass a note body, title, label name or AI answer here.
class AppStrings {
  const AppStrings(this.languageCode);
  final String languageCode;
  static const supportedLocales = [Locale('vi'), Locale('en')];
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings('vi');
  static final _placeholder = RegExp(r'\{(\d+)\}');

  String text(String source, [List<Object?> arguments = const []]) {
    final value = languageCode == 'en'
        ? englishMessages[source] ?? source
        : source;
    return value.replaceAllMapped(_placeholder, (match) {
      final index = int.parse(match[1]!);
      return index < arguments.length ? '${arguments[index]}' : match[0]!;
    });
  }

  /// Legacy session/error messages remain stable in state. Translate only at
  /// explicit UI-message boundaries, so a locale change also updates old errors.
  String message(String value) {
    if (englishMessages.containsKey(value)) {
      return text(value);
    }
    if (_reverse.containsKey(value)) {
      return languageCode == 'en' ? value : _reverse[value]!;
    }
    for (final entry in languageCode == 'en' ? _templates : _reverseTemplates) {
      final match = entry.pattern.firstMatch(value);
      if (match == null) continue;
      return text(entry.source, [
        for (var i = 1; i <= match.groupCount; i++)
          _nestedFeedback.contains(entry.source)
              ? message(match[i]!)
              : match[i],
      ]);
    }
    return value;
  }

  // Only resource patterns are cached; no private runtime value is retained.
  // These two parameters are generated feedback from friendlyError, not user data.
  static const _nestedFeedback = {
    'Chưa xác nhận lưu ảnh. {0}',
    'Chưa hoàn tất. {0}',
  };
  static final _reverse = {
    for (final e in englishMessages.entries) e.value: e.key,
  };
  static final _templates = _patterns(englishMessages, false);
  static final _reverseTemplates = _patterns(_reverse, true);
  static List<({String source, RegExp pattern})> _patterns(
    Map<String, String> messages,
    bool reverse,
  ) => messages.keys.where((key) => _placeholder.hasMatch(key)).map((key) {
    final pattern = StringBuffer('^');
    var end = 0;
    for (final match in _placeholder.allMatches(key)) {
      pattern.write(RegExp.escape(key.substring(end, match.start)));
      pattern.write(r'([\s\S]*?)');
      end = match.end;
    }
    pattern.write(RegExp.escape(key.substring(end)));
    pattern.write(r'$');
    return (
      source: reverse ? messages[key]! : key,
      pattern: RegExp(pattern.toString()),
    );
  }).toList()..sort((a, b) => b.source.length.compareTo(a.source.length));
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

extension TranslateUi on BuildContext {
  String tr(String source, [List<Object?> arguments = const []]) =>
      AppStrings.of(this).text(source, arguments);
  String trMessage(String value) => AppStrings.of(this).message(value);
}
