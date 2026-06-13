class BalancedTextScanner {
  const BalancedTextScanner();

  List<String> split(
    String input,
    String token, {
    bool trim = true,
    bool omitEmpty = true,
    bool protectJsBlocks = true,
    bool Function(StringBuffer buffer, int index)? shouldSkipToken,
  }) {
    final parts = <String>[];
    final buffer = StringBuffer();

    forEachSegment(
      input,
      token,
      protectJsBlocks: protectJsBlocks,
      onTopLevelToken: (index) {
        if (shouldSkipToken?.call(buffer, index) ?? false) return false;
        _addPart(parts, buffer, trim: trim, omitEmpty: omitEmpty);
        return true;
      },
      onText: buffer.write,
    );
    _addPart(parts, buffer, trim: trim, omitEmpty: omitEmpty);
    return parts;
  }

  int indexWhereTopLevel(
    String input,
    String token,
    bool Function(int index) predicate, {
    bool protectJsBlocks = true,
  }) {
    var matchedIndex = -1;
    forEachSegment(
      input,
      token,
      protectJsBlocks: protectJsBlocks,
      onTopLevelToken: (index) {
        if (!predicate(index)) return false;
        matchedIndex = index;
        return true;
      },
      onText: (_) {},
    );
    return matchedIndex;
  }

  void forEachSegment(
    String input,
    String token, {
    required bool Function(int index) onTopLevelToken,
    required void Function(String text) onText,
    bool protectJsBlocks = true,
  }) {
    var parenDepth = 0;
    var bracketDepth = 0;
    var braceDepth = 0;
    var quote = '';
    var escaped = false;
    var inJsBlock = false;

    for (var i = 0; i < input.length; i++) {
      if (protectJsBlocks &&
          !inJsBlock &&
          _startsWithIgnoreCase(input, i, '<js>')) {
        inJsBlock = true;
        onText(input.substring(i, i + 4));
        i += 3;
        continue;
      }
      if (inJsBlock) {
        if (_startsWithIgnoreCase(input, i, '</js>')) {
          inJsBlock = false;
          onText(input.substring(i, i + 5));
          i += 4;
          continue;
        }
        onText(input[i]);
        continue;
      }

      final char = input[i];
      if (escaped) {
        escaped = false;
        onText(char);
        continue;
      }
      if (char == r'\') {
        escaped = true;
        onText(char);
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == quote) quote = '';
        onText(char);
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        onText(char);
        continue;
      }

      if (_atTopLevel(parenDepth, bracketDepth, braceDepth) &&
          input.startsWith(token, i) &&
          onTopLevelToken(i)) {
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
      onText(char);
    }
  }

  bool _atTopLevel(int parenDepth, int bracketDepth, int braceDepth) {
    return parenDepth == 0 && bracketDepth == 0 && braceDepth == 0;
  }

  bool _startsWithIgnoreCase(String input, int index, String pattern) {
    if (index + pattern.length > input.length) return false;
    return input.substring(index, index + pattern.length).toLowerCase() ==
        pattern.toLowerCase();
  }

  void _addPart(
    List<String> parts,
    StringBuffer buffer, {
    required bool trim,
    required bool omitEmpty,
  }) {
    final raw = buffer.toString();
    final part = trim ? raw.trim() : raw;
    if (!omitEmpty || part.isNotEmpty) parts.add(part);
    buffer.clear();
  }
}
