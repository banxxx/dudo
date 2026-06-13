enum LegadoRuleDelimiter { pipeline, fallback, append, interleave }

class RuleAnalyzer {
  const RuleAnalyzer();

  List<String> split(String rule, LegadoRuleDelimiter delimiter) {
    final token = switch (delimiter) {
      LegadoRuleDelimiter.pipeline => '@',
      LegadoRuleDelimiter.fallback => '||',
      LegadoRuleDelimiter.append => '&&',
      LegadoRuleDelimiter.interleave => '%%',
    };
    return _splitByToken(rule, token);
  }

  List<String> _splitByToken(String input, String token) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var parenDepth = 0;
    var bracketDepth = 0;
    var braceDepth = 0;
    var quote = '';
    var escaped = false;
    var inJsBlock = false;

    for (var i = 0; i < input.length; i++) {
      if (!inJsBlock && _startsWithIgnoreCase(input, i, '<js>')) {
        inJsBlock = true;
        buffer.write(input.substring(i, i + 4));
        i += 3;
        continue;
      }
      if (inJsBlock) {
        if (_startsWithIgnoreCase(input, i, '</js>')) {
          inJsBlock = false;
          buffer.write(input.substring(i, i + 5));
          i += 4;
          continue;
        }
        buffer.write(input[i]);
        continue;
      }

      final char = input[i];
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

      if (_atTopLevel(parenDepth, bracketDepth, braceDepth) &&
          input.startsWith(token, i)) {
        if (token == '@' && buffer.isEmpty) {
          buffer.write(char);
          continue;
        }
        _addPart(parts, buffer);
        i += token.length - 1;
        continue;
      }

      switch (char) {
        case '(':
          parenDepth += 1;
        case ')':
          if (parenDepth > 0) parenDepth -= 1;
        case '[':
          bracketDepth += 1;
        case ']':
          if (bracketDepth > 0) bracketDepth -= 1;
        case '{':
          braceDepth += 1;
        case '}':
          if (braceDepth > 0) braceDepth -= 1;
      }
      buffer.write(char);
    }
    _addPart(parts, buffer);
    return parts;
  }

  bool _atTopLevel(int parenDepth, int bracketDepth, int braceDepth) {
    return parenDepth == 0 && bracketDepth == 0 && braceDepth == 0;
  }

  bool _startsWithIgnoreCase(String input, int index, String pattern) {
    if (index + pattern.length > input.length) return false;
    return input.substring(index, index + pattern.length).toLowerCase() ==
        pattern.toLowerCase();
  }

  void _addPart(List<String> parts, StringBuffer buffer) {
    final part = buffer.toString().trim();
    if (part.isNotEmpty) parts.add(part);
    buffer.clear();
  }
}
