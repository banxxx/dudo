import '../js/legado_js_engine.dart';

class LegadoUrlPlaceholder {
  const LegadoUrlPlaceholder({this.jsEngine = const SimpleLegadoJsEngine()});

  final LegadoJsEngine jsEngine;

  String apply({
    required String rawUrl,
    required String keyword,
    int page = 1,
  }) {
    final context = LegadoJsContext(key: keyword, page: page);
    return _replacePageSelectors(
      _replaceExpressions(rawUrl, context),
      page,
    );
  }

  String _replaceExpressions(String rawUrl, LegadoJsContext context) {
    final buffer = StringBuffer();
    var index = 0;

    while (index < rawUrl.length) {
      final start = rawUrl.indexOf('{{', index);
      if (start < 0) {
        buffer.write(rawUrl.substring(index));
        break;
      }

      buffer.write(rawUrl.substring(index, start));
      final expressionStart = start + 2;
      final end = _findExpressionEnd(rawUrl, expressionStart);
      if (end < 0) {
        buffer.write(rawUrl.substring(start));
        break;
      }

      final expression = rawUrl.substring(expressionStart, end);
      final original = rawUrl.substring(start, end + 2);
      buffer.write(_replaceExpression(expression, original, context));
      index = end + 2;
    }

    return buffer.toString();
  }

  String _replaceExpression(
    String rawExpression,
    String original,
    LegadoJsContext context,
  ) {
    final expression = rawExpression.trim();
    if (expression == 'key') return context.encodedKey;
    if (expression == 'page') return context.page.toString();

    try {
      return _stringify(jsEngine.eval(expression, context: context));
    } on Exception {
      return original;
    }
  }

  int _findExpressionEnd(String input, int start) {
    var braceDepth = 0;
    var quote = '';
    var escaped = false;

    for (var i = start; i < input.length - 1; i++) {
      final char = input[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = '';
        }
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        continue;
      }
      if (char == '{') {
        braceDepth += 1;
        continue;
      }
      if (char == '}') {
        if (braceDepth > 0) {
          braceDepth -= 1;
          continue;
        }
        if (input[i + 1] == '}') return i;
      }
    }
    return -1;
  }

  String _replacePageSelectors(String rawUrl, int page) {
    final buffer = StringBuffer();
    var quote = '';
    var escaped = false;
    var braceDepth = 0;
    var bracketDepth = 0;
    var parenDepth = 0;

    for (var i = 0; i < rawUrl.length; i++) {
      final char = rawUrl[i];
      if (escaped) {
        escaped = false;
        buffer.write(char);
        continue;
      }
      if (char == r'\') {
        escaped = true;
        buffer.write(char);
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == quote) quote = '';
        buffer.write(char);
        continue;
      }
      if (char == '"' || char == "'") {
        quote = char;
        buffer.write(char);
        continue;
      }

      switch (char) {
        case '{':
          braceDepth += 1;
        case '}':
          if (braceDepth > 0) braceDepth -= 1;
        case '[':
          bracketDepth += 1;
        case ']':
          if (bracketDepth > 0) bracketDepth -= 1;
        case '(':
          parenDepth += 1;
        case ')':
          if (parenDepth > 0) parenDepth -= 1;
      }

      if (char == '<' &&
          braceDepth == 0 &&
          bracketDepth == 0 &&
          parenDepth == 0) {
        final end = rawUrl.indexOf('>', i + 1);
        if (end > i) {
          final replacement = _pageSelectorValue(
            rawUrl.substring(i + 1, end),
            rawUrl.substring(i, end + 1),
            page,
          );
          buffer.write(replacement);
          i = end;
          continue;
        }
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  String _pageSelectorValue(String rawPages, String original, int page) {
    final pages = rawPages
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (pages.isEmpty) return original;
    final index = page - 1;
    if (index < 0) return pages.first;
    if (index >= pages.length) return pages.last;
    return pages[index];
  }

  String _stringify(Object? value) {
    if (value == null) return '';
    if (value is double && value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}
