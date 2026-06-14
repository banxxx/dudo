class LegadoJsContext {
  const LegadoJsContext({
    required this.key,
    required this.page,
    this.baseUrl,
    this.result,
  });

  final String key;
  final int page;
  final String? baseUrl;
  final Object? result;

  String get encodedKey => Uri.encodeQueryComponent(key);
}

abstract interface class LegadoJsEngine {
  Object? eval(String script, {required LegadoJsContext context});
}

class SimpleLegadoJsEngine implements LegadoJsEngine {
  const SimpleLegadoJsEngine();

  @override
  Object? eval(String script, {required LegadoJsContext context}) {
    final expression = _normalizeScript(script);
    return _SimpleJsExpressionParser(expression, context).parse();
  }

  String _normalizeScript(String script) {
    var expression = script.trim();
    while (expression.endsWith(';')) {
      expression = expression.substring(0, expression.length - 1).trimRight();
    }

    final assignment = RegExp(
      r'^(?:(?:var|let|const)\s+)?result\s*=\s*([\s\S]+)$',
    ).firstMatch(expression);
    if (assignment != null) return assignment.group(1)!.trim();

    return expression;
  }
}

class LegadoJsException implements Exception {
  const LegadoJsException(this.message);

  final String message;

  @override
  String toString() => 'LegadoJsException: $message';
}

class _SimpleJsExpressionParser {
  _SimpleJsExpressionParser(String source, this.context)
      : tokens = _Tokenizer(source).tokenize();

  final LegadoJsContext context;
  final List<_Token> tokens;
  var index = 0;

  Object? parse() {
    final value = _parseAdditive();
    if (!_isAtEnd) {
      throw LegadoJsException('Unexpected token ${_peek().lexeme}');
    }
    return value;
  }

  Object? _parseAdditive() {
    var left = _parseMultiplicative();
    while (_match('+') || _match('-')) {
      final operator = _previous().lexeme;
      final right = _parseMultiplicative();
      left = operator == '+' ? _add(left, right) : _subtract(left, right);
    }
    return left;
  }

  Object? _parseMultiplicative() {
    var left = _parseUnary();
    while (_match('*') || _match('/') || _match('%')) {
      final operator = _previous().lexeme;
      final right = _parseUnary();
      left = switch (operator) {
        '*' => _toNumber(left) * _toNumber(right),
        '/' => _toNumber(left) / _toNumber(right),
        '%' => _toNumber(left) % _toNumber(right),
        _ => throw const LegadoJsException('Unsupported operator'),
      };
    }
    return left;
  }

  Object? _parseUnary() {
    if (_match('+')) return _toNumber(_parseUnary());
    if (_match('-')) return -_toNumber(_parseUnary());
    return _parsePrimary();
  }

  Object? _parsePrimary() {
    if (_matchType(_TokenType.number)) return _previous().literal;
    if (_matchType(_TokenType.string)) return _previous().literal;
    if (_match('(')) {
      final value = _parseAdditive();
      _consume(')', 'Expected closing parenthesis');
      return value;
    }
    if (_matchType(_TokenType.identifier)) {
      final name = _previous().lexeme;
      if (_match('(')) return _callFunction(name);
      return _resolveIdentifier(name);
    }
    throw LegadoJsException('Unexpected token ${_peek().lexeme}');
  }

  Object? _callFunction(String name) {
    final arguments = <Object?>[];
    if (!_check(')')) {
      do {
        arguments.add(_parseAdditive());
      } while (_match(','));
    }
    _consume(')', 'Expected closing parenthesis');

    return switch (name) {
      'encodeURIComponent' => Uri.encodeComponent(
          _stringify(_expectArgument(name, arguments, 0)),
        ),
      'encodeURI' => Uri.encodeFull(
          _stringify(_expectArgument(name, arguments, 0)),
        ),
      'String' => _stringify(_expectArgument(name, arguments, 0)),
      'Number' => _toNumber(_expectArgument(name, arguments, 0)),
      'parseInt' => _parseInt(_expectArgument(name, arguments, 0)),
      _ => throw LegadoJsException('Unsupported function $name'),
    };
  }

  Object? _expectArgument(String name, List<Object?> arguments, int position) {
    if (arguments.length <= position) {
      throw LegadoJsException('Function $name expects an argument');
    }
    return arguments[position];
  }

  Object? _resolveIdentifier(String name) {
    return switch (name) {
      'key' || 'keyword' => context.key,
      'page' => context.page.toDouble(),
      'baseUrl' => context.baseUrl,
      'result' => context.result,
      'null' => null,
      'true' => true,
      'false' => false,
      _ => throw LegadoJsException('Unsupported identifier $name'),
    };
  }

  Object? _add(Object? left, Object? right) {
    if (left is String || right is String) {
      return _stringify(left) + _stringify(right);
    }
    return _toNumber(left) + _toNumber(right);
  }

  Object? _subtract(Object? left, Object? right) {
    return _toNumber(left) - _toNumber(right);
  }

  int _parseInt(Object? value) {
    if (value is num) return value.toInt();
    return int.parse(_stringify(value));
  }

  double _toNumber(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1 : 0;
    return double.parse(value.toString());
  }

  String _stringify(Object? value) {
    if (value == null) return '';
    if (value is double && value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  bool _match(String lexeme) {
    if (!_check(lexeme)) return false;
    index += 1;
    return true;
  }

  bool _matchType(_TokenType type) {
    if (_peek().type != type) return false;
    index += 1;
    return true;
  }

  void _consume(String lexeme, String message) {
    if (_match(lexeme)) return;
    throw LegadoJsException(message);
  }

  bool _check(String lexeme) => !_isAtEnd && _peek().lexeme == lexeme;

  _Token _peek() => tokens[index];

  _Token _previous() => tokens[index - 1];

  bool get _isAtEnd => _peek().type == _TokenType.eof;
}

enum _TokenType { identifier, number, string, symbol, eof }

class _Token {
  const _Token(this.type, this.lexeme, [this.literal]);

  final _TokenType type;
  final String lexeme;
  final Object? literal;
}

class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  final tokens = <_Token>[];
  var index = 0;

  List<_Token> tokenize() {
    while (!_isAtEnd) {
      final char = _advance();
      if (_isWhitespace(char)) continue;
      if (_isIdentifierStart(char)) {
        _identifier(char);
      } else if (_isDigit(char)) {
        _number(char);
      } else if (char == '"' || char == "'" || char == '`') {
        _string(char);
      } else if ('+-*/%(),'.contains(char)) {
        tokens.add(_Token(_TokenType.symbol, char));
      } else {
        throw LegadoJsException('Unsupported character $char');
      }
    }
    tokens.add(const _Token(_TokenType.eof, ''));
    return tokens;
  }

  void _identifier(String first) {
    final buffer = StringBuffer(first);
    while (!_isAtEnd && _isIdentifierPart(source[index])) {
      buffer.write(_advance());
    }
    tokens.add(_Token(_TokenType.identifier, buffer.toString()));
  }

  void _number(String first) {
    final buffer = StringBuffer(first);
    while (!_isAtEnd && _isDigit(source[index])) {
      buffer.write(_advance());
    }
    if (!_isAtEnd && source[index] == '.') {
      buffer.write(_advance());
      while (!_isAtEnd && _isDigit(source[index])) {
        buffer.write(_advance());
      }
    }
    final text = buffer.toString();
    tokens.add(_Token(_TokenType.number, text, double.parse(text)));
  }

  void _string(String quote) {
    final buffer = StringBuffer();
    var escaped = false;
    while (!_isAtEnd) {
      final char = _advance();
      if (escaped) {
        buffer.write(switch (char) {
          'n' => '\n',
          'r' => '\r',
          't' => '\t',
          _ => char,
        });
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == quote) {
        tokens.add(
            _Token(_TokenType.string, buffer.toString(), buffer.toString()));
        return;
      }
      buffer.write(char);
    }
    throw const LegadoJsException('Unterminated string');
  }

  String _advance() => source[index++];

  bool get _isAtEnd => index >= source.length;

  bool _isWhitespace(String char) => char.trim().isEmpty;

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
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
}
