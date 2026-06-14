import 'dart:async';
import 'dart:convert';

import 'package:flutter_js/flutter_js.dart' as flutter_js;

import '../../models/source_rule.dart';

class LegadoJsContext {
  const LegadoJsContext({
    required this.key,
    required this.page,
    this.baseUrl,
    this.src,
    this.result,
    this.source,
    this.book,
    this.variables = const {},
    this.cookie,
    this.ajax,
  });

  final String key;
  final int page;
  final String? baseUrl;
  final Object? src;
  final Object? result;
  final Object? source;
  final Object? book;
  final Map<String, Object?> variables;
  final String? cookie;
  final LegadoJsAjax? ajax;

  String get encodedKey => Uri.encodeQueryComponent(key);
}

abstract interface class LegadoJsEngine {
  Object? eval(String script, {required LegadoJsContext context});

  Future<Object?> evalAsync(String script, {required LegadoJsContext context});
}

class SimpleLegadoJsEngine implements LegadoJsEngine {
  const SimpleLegadoJsEngine();

  @override
  Object? eval(String script, {required LegadoJsContext context}) {
    final expression = _normalizeScript(script);
    Object? result;
    for (final statement in _splitStatements(expression)) {
      result = _SimpleJsExpressionParser(
        _normalizeScript(statement),
        context,
      ).parse();
    }
    return result;
  }

  @override
  Future<Object?> evalAsync(
    String script, {
    required LegadoJsContext context,
  }) async {
    return eval(script, context: context);
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

  List<String> _splitStatements(String script) {
    final statements = <String>[];
    final buffer = StringBuffer();
    var quote = '';
    var escaped = false;
    var parenDepth = 0;
    var bracketDepth = 0;
    var braceDepth = 0;

    for (var i = 0; i < script.length; i++) {
      final char = script[i];
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
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        buffer.write(char);
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
      if (char == ';' &&
          parenDepth == 0 &&
          bracketDepth == 0 &&
          braceDepth == 0) {
        final statement = buffer.toString().trim();
        if (statement.isNotEmpty) statements.add(statement);
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }

    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) statements.add(tail);
    return statements;
  }
}

class FlutterJsLegadoJsEngine implements LegadoJsEngine {
  FlutterJsLegadoJsEngine({
    flutter_js.JavascriptRuntime? runtime,
    this.timeout = const Duration(seconds: 2),
    this.maxOutputLength = 256 * 1024,
  }) : _runtime = runtime;

  flutter_js.JavascriptRuntime? _runtime;
  final Duration timeout;
  final int maxOutputLength;

  @override
  Object? eval(String script, {required LegadoJsContext context}) {
    try {
      final result = _runtimeForEval().evaluate(_wrapScript(script, context));
      if (result.isError) throw LegadoJsException(result.stringResult);
      _checkOutputSize(result.rawResult);
      return _decodeResult(result.rawResult, context);
    } on LegadoJsException {
      rethrow;
    } catch (error) {
      if (_isRuntimeUnavailable(error)) {
        return const SimpleLegadoJsEngine().eval(script, context: context);
      }
      throw LegadoJsException('JS execution failed: $error');
    }
  }

  flutter_js.JavascriptRuntime _runtimeForEval() {
    return _runtime ??=
        flutter_js.QuickJsRuntime2(timeout: timeout.inMilliseconds);
  }

  @override
  Future<Object?> evalAsync(
    String script, {
    required LegadoJsContext context,
  }) async {
    try {
      return await Future<Object?>(
        () => eval(script, context: context),
      ).timeout(
        timeout,
        onTimeout: () {
          throw LegadoJsException(
            'JS execution timed out after ${timeout.inMilliseconds}ms',
          );
        },
      );
    } on LegadoJsException {
      rethrow;
    } catch (error) {
      throw LegadoJsException('JS execution failed: $error');
    }
  }

  String _wrapScript(String script, LegadoJsContext context) {
    final bindings = <String, Object?>{
      'key': context.key,
      'keyword': context.key,
      'page': context.page,
      'baseUrl': context.baseUrl,
      'src': context.src,
      'result': context.result,
      'source': _sourceToJson(context.source),
      'book': context.book,
      'variables': context.variables,
      'cookie': context.cookie,
    };
    final encodedBindings = jsonEncode(bindings);
    final escapedScript = jsonEncode(_normalizeScript(script));
    return '''
(function(){
  var __ctx = $encodedBindings;
  var key = __ctx.key;
  var keyword = __ctx.keyword;
  var page = __ctx.page;
  var baseUrl = __ctx.baseUrl;
  var src = __ctx.src;
  var result = __ctx.result;
  var source = __ctx.source;
  var book = __ctx.book;
  var java = {
    getString: function(value) { return value == null ? "" : String(value); },
    put: function(name, value) {
      __ctx.variables[String(name)] = value;
      return value;
    },
    get: function(name) { return __ctx.variables[String(name)]; },
    ajax: function() {
      throw new Error("java.ajax is only available through SimpleLegadoJsEngine");
    }
  };
  var cookie = {
    getKey: function(name) {
      if (!__ctx.cookie) return null;
      var parts = String(__ctx.cookie).split(';');
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i].trim();
        var index = part.indexOf('=');
        if (index <= 0) continue;
        if (part.substring(0, index).trim() === String(name)) {
          return part.substring(index + 1).trim();
        }
      }
      return null;
    }
  };
  var __value = eval($escapedScript);
  if (typeof __value === "undefined") {
    __value = result;
  }
  return JSON.stringify({ value: __value, variables: __ctx.variables });
})()
''';
  }

  Object? _decodeResult(Object? rawResult, LegadoJsContext context) {
    final text = rawResult?.toString();
    if (text == null || text == 'null') return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded.containsKey('value')) {
        final variables = decoded['variables'];
        if (variables is Map) {
          for (final entry in variables.entries) {
            context.variables[entry.key.toString()] = entry.value;
          }
        }
        return decoded['value'];
      }
    } catch (_) {
      return rawResult;
    }
    return rawResult;
  }

  void _checkOutputSize(Object? rawResult) {
    final length = rawResult?.toString().length ?? 0;
    if (length > maxOutputLength) {
      throw LegadoJsException(
        'JS output exceeds max length $maxOutputLength',
      );
    }
  }

  bool _isRuntimeUnavailable(Object error) {
    final message = error.toString();
    return message.contains('Failed to load dynamic library') ||
        message.contains('quickjs_c_bridge');
  }

  Object? _sourceToJson(Object? source) {
    if (source == null) return null;
    if (source is String || source is num || source is bool || source is Map) {
      return source;
    }
    if (source is Iterable) return source.toList(growable: false);
    if (source is SourceRule) {
      return {
        'id': source.id,
        'name': source.name,
        'url': source.url,
        'headers': source.headers,
      };
    }
    return source.toString();
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
      final name = _qualifiedIdentifier(_previous().lexeme);
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
      'java.getString' => _stringify(_expectArgument(name, arguments, 0)),
      'java.ajax' => _javaAjax(arguments),
      'java.put' => _javaPut(arguments),
      'java.get' => _javaGet(arguments),
      'cookie.getKey' => _cookieGetKey(arguments),
      _ => throw LegadoJsException('Unsupported function $name'),
    };
  }

  String _qualifiedIdentifier(String first) {
    final parts = <String>[first];
    while (_match('.')) {
      if (!_matchType(_TokenType.identifier)) {
        throw const LegadoJsException('Expected identifier after dot');
      }
      parts.add(_previous().lexeme);
    }
    return parts.join('.');
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
      'src' => context.src,
      'result' => context.result,
      'source' => context.source,
      'book' => context.book,
      'java' => context.variables['java'],
      'cookie' => context.cookie,
      'null' => null,
      'true' => true,
      'false' => false,
      _ when context.variables.containsKey(name) => context.variables[name],
      _ => throw LegadoJsException('Unsupported identifier $name'),
    };
  }

  Object? _javaPut(List<Object?> arguments) {
    final key = _stringify(_expectArgument('java.put', arguments, 0));
    final value = arguments.length > 1 ? arguments[1] : null;
    context.variables[key] = value;
    return value;
  }

  Object? _javaAjax(List<Object?> arguments) {
    final ajax = context.ajax;
    if (ajax == null) {
      throw const LegadoJsException('java.ajax is not configured');
    }
    return ajax(_stringify(_expectArgument('java.ajax', arguments, 0)));
  }

  Object? _javaGet(List<Object?> arguments) {
    final key = _stringify(_expectArgument('java.get', arguments, 0));
    return context.variables[key];
  }

  String? _cookieGetKey(List<Object?> arguments) {
    final key = _stringify(_expectArgument('cookie.getKey', arguments, 0));
    final cookie = context.cookie;
    if (cookie == null || cookie.trim().isEmpty) return null;
    for (final part in cookie.split(';')) {
      final trimmed = part.trim();
      final equals = trimmed.indexOf('=');
      if (equals <= 0) continue;
      if (trimmed.substring(0, equals).trim() == key) {
        return trimmed.substring(equals + 1).trim();
      }
    }
    return null;
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

typedef LegadoJsAjax = FutureOr<Object?> Function(String rawUrl);

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
      } else if ('+-*/%(),.'.contains(char)) {
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
