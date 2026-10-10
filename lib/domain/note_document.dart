import 'dart:convert';

import 'package:markdown/markdown.dart' as md;

/// A versioned Delta stored inside the existing encrypted content string.
/// Plain notes stay plain; no database, permission or outbox payload is rebased.
const noteDocumentPrefix = 'NTDOC1:';

List<Map<String, dynamic>>? storedDocumentDelta(String content) {
  if (!content.startsWith(noteDocumentPrefix)) return null;
  try {
    final value = jsonDecode(content.substring(noteDocumentPrefix.length));
    if (value is! List || value.isEmpty) return null;
    final ops = <Map<String, dynamic>>[];
    for (final value in value) {
      if (value is! Map ||
          value['insert'] is! String ||
          (value['insert'] as String).isEmpty ||
          value.keys.any((key) => key != 'insert' && key != 'attributes')) {
        return null;
      }
      final attributes = value['attributes'];
      if (attributes != null &&
          (attributes is! Map ||
              attributes.keys.any((key) => key is! String) ||
              attributes.values.any(
                (v) => v is! String && v is! bool && v is! num,
              ) ||
              attributes.entries.any(
                (entry) => !_validAttribute(entry.key, entry.value),
              ))) {
        return null;
      }
      ops.add({
        'insert': value['insert'],
        if (attributes != null)
          'attributes': Map<String, dynamic>.from(attributes as Map),
      });
    }
    if (!(ops.last['insert'] as String).endsWith('\n')) return null;
    return ops;
  } on FormatException {
    return null;
  }
}

bool _validAttribute(String key, Object? value) {
  const bools = {
    'bold',
    'italic',
    'underline',
    'strike',
    'inline-code',
    'code-block',
    'blockquote',
    'small',
  };
  if (bools.contains(key)) return value is bool;
  if (key == 'header') return value is int && value >= 1 && value <= 6;
  if (key == 'indent') return value is int && value >= 0 && value <= 8;
  if (value is! String || value.length > 2000) return false;
  switch (key) {
    case 'link':
      return safeDocumentLink(value);
    case 'color':
    case 'background':
      return RegExp(r'^#[0-9a-fA-F]{6,8}$').hasMatch(value);
    case 'align':
      return {'left', 'center', 'right', 'justify'}.contains(value);
    case 'list':
      return {'bullet', 'ordered', 'checked', 'unchecked'}.contains(value);
    case 'direction':
      return {'ltr', 'rtl'}.contains(value);
    case 'script':
      return {'super', 'sub'}.contains(value);
    case 'size':
      final size = int.tryParse(value);
      return {'small', 'large', 'huge'}.contains(value) ||
          size != null && size >= 8 && size <= 72;
    case 'line-height':
      final height = double.tryParse(value);
      return height != null && height.isFinite && height >= 1 && height <= 3;
    case 'font':
      return value.isNotEmpty;
    default:
      return false;
  }
}

String documentText(List<Map<String, dynamic>> ops) {
  final text = ops.map((op) => op['insert'] as String).join();
  return text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
}

String plainNoteContent(String content) {
  final ops = storedDocumentDelta(content);
  return ops == null ? content : documentText(ops);
}

String storeDocumentDelta(List<Map<String, dynamic>> ops) {
  final text = documentText(ops);
  if (!text.startsWith(noteDocumentPrefix) &&
      ops.every((op) => (op['attributes'] as Map?)?.isNotEmpty != true)) {
    return text;
  }
  return '$noteDocumentPrefix${jsonEncode(ops)}';
}

bool safeDocumentLink(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null &&
      ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty ||
          uri.scheme == 'mailto' && uri.path.isNotEmpty);
}

/// Import the legacy Markdown used by templates without rewriting on open.
/// Images become alt text; private files continue through the existing ACL UI.
List<Map<String, dynamic>> editableDocumentDelta(String content) {
  final stored = storedDocumentDelta(content);
  if (stored != null) return stored;
  final ops = <Map<String, dynamic>>[];
  void insert(String text, [Map<String, dynamic> attributes = const {}]) {
    if (text.isEmpty) return;
    ops.add({
      'insert': text,
      if (attributes.isNotEmpty) 'attributes': attributes,
    });
  }

  void inline(md.Node node, Map<String, dynamic> inherited) {
    if (node is md.Text) {
      insert(node.text, inherited);
      return;
    }
    if (node is! md.Element) return;
    final attributes = <String, dynamic>{...inherited};
    switch (node.tag) {
      case 'strong':
        attributes['bold'] = true;
      case 'em':
        attributes['italic'] = true;
      case 'del':
        attributes['strike'] = true;
      case 'code':
        attributes['inline-code'] = true;
      case 'a':
        final href = node.attributes['href'];
        if (href != null && safeDocumentLink(href)) attributes['link'] = href;
      case 'img':
        insert(node.attributes['alt'] ?? '', inherited);
        return;
      case 'br':
        insert('\n', inherited);
        return;
    }
    for (final child in node.children ?? <md.Node>[]) {
      inline(child, attributes);
    }
  }

  final markdown = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
  String? fence;
  for (final line in content.split('\n')) {
    var text = line;
    final block = <String, dynamic>{};
    final fenceMatch = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
    if (fenceMatch != null) {
      if (fence == null) {
        fence = fenceMatch[1]![0];
      } else if (fence == fenceMatch[1]![0]) {
        fence = null;
      } else {
        insert(line);
        insert('\n', {'code-block': true});
      }
      continue;
    }
    if (fence != null) {
      insert(text);
      insert('\n', {'code-block': true});
      continue;
    }
    final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
    final task = RegExp(r'^\s*[-*+]\s+\[([ xX])\]\s*(.*)$').firstMatch(line);
    final bullet = RegExp(r'^\s*[-*+]\s+(.+)$').firstMatch(line);
    final ordered = RegExp(r'^\s*\d+[.)]\s+(.+)$').firstMatch(line);
    final quote = RegExp(r'^>\s?(.*)$').firstMatch(line);
    if (heading != null) {
      text = heading[2]!;
      block['header'] = heading[1]!.length.clamp(1, 3);
    } else if (task != null) {
      text = task[2]!;
      block['list'] = task[1] == ' ' ? 'unchecked' : 'checked';
    } else if (bullet != null) {
      text = bullet[1]!;
      block['list'] = 'bullet';
    } else if (ordered != null) {
      text = ordered[1]!;
      block['list'] = 'ordered';
    } else if (quote != null) {
      text = quote[1]!;
      block['blockquote'] = true;
    }
    for (final node in markdown.parseInline(text)) {
      inline(node, const {});
    }
    insert('\n', block);
  }
  if (ops.isEmpty || !(ops.last['insert'] as String).endsWith('\n')) {
    insert('\n');
  }
  return ops;
}
