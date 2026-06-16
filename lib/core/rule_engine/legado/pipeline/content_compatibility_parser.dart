import 'dart:convert';

class ContentCompatibilityParser {
  const ContentCompatibilityParser();

  static const _contentKeys = [
    'content',
    'chapterContent',
    'chaptercontent',
    'body',
    'text',
    'sayBody',
    'saybody',
    'chapterIntro',
    'chapterintro',
    'intro',
  ];

  String? parse(String rawText) {
    final decoded = _tryDecodeJson(rawText);
    if (decoded == null) return null;

    final parts = <String>[];
    _collectText(decoded, parts);
    final content = parts
        .map(_normalizeText)
        .where((value) => value.isNotEmpty)
        .join('\n\n')
        .trim();
    return content.isEmpty ? null : content;
  }

  Object? _tryDecodeJson(String rawText) {
    final text = rawText.trimLeft();
    if (!text.startsWith('{') && !text.startsWith('[')) return null;
    try {
      return jsonDecode(rawText);
    } catch (_) {
      return null;
    }
  }

  void _collectText(Object? node, List<String> out) {
    if (node is Map) {
      for (final key in _contentKeys) {
        final value = node[key];
        if (value is String && value.trim().isNotEmpty) {
          out.add(value);
        }
      }

      // 只在常见容器字段中继续向下找，避免把整段元数据误拼进正文。
      for (final key in const ['data', 'chapter', 'result', 'contentData']) {
        final value = node[key];
        if (value != null) _collectText(value, out);
      }
      return;
    }

    if (node is List) {
      for (final item in node) {
        _collectText(item, out);
      }
    }
  }

  String _normalizeText(String raw) {
    final withoutScripts = raw
        .replaceAll(
            RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
    final withBreaks = withoutScripts
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'</\s*(p|div|section|article|li)\s*>',
                caseSensitive: false),
            '\n');
    final withoutTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
    return _htmlUnescape(withoutTags)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  String _htmlUnescape(String input) {
    return input.replaceAllMapped(RegExp(r'&(#x?[0-9A-Fa-f]+|\w+);'), (match) {
      final entity = match.group(1)!;
      if (entity.startsWith('#x') || entity.startsWith('#X')) {
        final codePoint = int.tryParse(entity.substring(2), radix: 16);
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      }
      if (entity.startsWith('#')) {
        final codePoint = int.tryParse(entity.substring(1));
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      }
      return _namedHtmlEntities[entity] ?? match.group(0)!;
    });
  }
}

const _namedHtmlEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};
