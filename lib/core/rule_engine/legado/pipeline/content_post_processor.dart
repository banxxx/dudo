import '../../parsers/regex_parser.dart';

class ContentPostProcessor {
  const ContentPostProcessor();

  String apply({
    required String content,
    String? replaceRegex,
  }) {
    return _applyReplaceRegex(content, replaceRegex);
  }

  String _applyReplaceRegex(String content, String? replaceRegex) {
    final raw = replaceRegex?.trim();
    if (raw == null || raw.isEmpty || content.isEmpty) return content;

    var next = content;
    for (final rule in raw.split(RegExp(r'\r?\n'))) {
      final text = rule.trim();
      if (text.isEmpty) continue;
      next = RegexParser.applyReplacement(next, text);
    }
    return next;
  }
}
