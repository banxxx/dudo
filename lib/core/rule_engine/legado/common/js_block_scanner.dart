/// Locates the end of a `<js>...</js>` block inside a Legado rule.
///
/// A naive `indexOf('</js>')` breaks rules whose JavaScript contains a string
/// like `"</js>"`, while tracking only quotes breaks rules whose regex literals
/// contain quotes (for example `result.match(/&v=(.*?)"/)`). This scanner
/// understands strings, template literals, comments and regex literals so the
/// real closing tag is found in both cases.
class JsBlockScanner {
  const JsBlockScanner();

  static const _regexPrefixTokens = {
    '(',
    '[',
    '{',
    ',',
    ';',
    ':',
    '=',
    '!',
    '?',
    '+',
    '-',
    '*',
    '%',
    '&',
    '|',
    '^',
    '~',
  };

  static const _regexPrefixKeywords = {
    'return',
    'case',
    'throw',
    'else',
    'do',
    'typeof',
    'void',
    'delete',
    'in',
    'instanceof',
    'new',
  };

  /// Returns the index of the closing `</js>` tag for a block whose body
  /// starts at [start], or `-1` when the block is not closed.
  int findBlockEnd(String input, int start) {
    var index = start;
    String? quote;
    var escaped = false;
    var lineComment = false;
    var blockComment = false;
    var regexLiteral = false;
    var regexCharClass = false;
    String? previousToken;

    while (index < input.length) {
      final char = input[index];
      final next = index + 1 < input.length ? input[index + 1] : '';

      if (lineComment) {
        if (char == '\n' || char == '\r') lineComment = false;
        index += 1;
        continue;
      }

      if (blockComment) {
        if (char == '*' && next == '/') {
          blockComment = false;
          index += 2;
          continue;
        }
        index += 1;
        continue;
      }

      if (quote != null) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = null;
          previousToken = 'value';
        }
        index += 1;
        continue;
      }

      if (regexLiteral) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '[') {
          regexCharClass = true;
        } else if (char == ']' && regexCharClass) {
          regexCharClass = false;
        } else if (char == '/' && !regexCharClass) {
          regexLiteral = false;
          var flagsEnd = index + 1;
          while (
              flagsEnd < input.length && _isIdentifierPart(input[flagsEnd])) {
            flagsEnd += 1;
          }
          index = flagsEnd;
          previousToken = 'value';
          continue;
        }
        index += 1;
        continue;
      }

      if (_startsWithIgnoreCase(input, index, '</js>')) return index;

      if (char == '/' && next == '/') {
        lineComment = true;
        index += 2;
        continue;
      }
      if (char == '/' && next == '*') {
        blockComment = true;
        index += 2;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        escaped = false;
        index += 1;
        continue;
      }
      if (char == '/' && _canStartRegex(previousToken)) {
        regexLiteral = true;
        regexCharClass = false;
        escaped = false;
        index += 1;
        continue;
      }
      if (_isIdentifierStart(char)) {
        var end = index + 1;
        while (end < input.length && _isIdentifierPart(input[end])) {
          end += 1;
        }
        previousToken = input.substring(index, end);
        index = end;
        continue;
      }
      if (_isDigit(char)) {
        var end = index + 1;
        while (end < input.length && _isDigit(input[end])) {
          end += 1;
        }
        previousToken = 'value';
        index = end;
        continue;
      }
      if (char.trim().isNotEmpty) previousToken = char;
      index += 1;
    }

    // Some imported sources contain malformed JavaScript (an unterminated
    // string, a slash in a replacement pattern, ...). Legado still closes the
    // block at the first `</js>` in that case, so do the same instead of
    // passing the remaining rule text to the JS engine.
    return _findRawBlockEnd(input, start);
  }

  int _findRawBlockEnd(String input, int start) {
    for (var index = start; index + 5 <= input.length; index++) {
      if (_startsWithIgnoreCase(input, index, '</js>')) return index;
    }
    return -1;
  }

  bool _canStartRegex(String? previousToken) {
    if (previousToken == null) return true;
    return _regexPrefixTokens.contains(previousToken) ||
        _regexPrefixKeywords.contains(previousToken);
  }

  bool _startsWithIgnoreCase(String input, int index, String pattern) {
    if (index + pattern.length > input.length) return false;
    return input.substring(index, index + pattern.length).toLowerCase() ==
        pattern.toLowerCase();
  }

  bool _isIdentifierStart(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        char == '_' ||
        char == r'$';
  }

  bool _isIdentifierPart(String char) {
    return _isIdentifierStart(char) || _isDigit(char);
  }

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}
