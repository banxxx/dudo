import 'dart:convert';

import 'package:flutter_js/flutter_js.dart' as flutter_js;

import '../../models/source_rule.dart';
import 'legado_js_bindings.dart';
import 'legado_js_context.dart';

export 'legado_js_context.dart';

const _cacheVariableKey = '__cache';

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
  final LegadoJsBindings _bindings = const LegadoJsBindings();
  final Map<String, LegadoJsAjax> _ajaxHandlers = {};
  String? _ajaxBridgeRuntimeId;
  int _ajaxContextSequence = 0;

  @override
  Object? eval(String script, {required LegadoJsContext context}) {
    _traceCookieGetKeyWithoutCookie(script, context);
    try {
      final result = _runtimeForEval().evaluate(_wrapScript(script, context));
      if (result.isError) throw LegadoJsException(result.stringResult);
      _checkOutputSize(result.rawResult);
      return _decodeResult(result.rawResult, context);
    } on LegadoJsException {
      rethrow;
    } catch (error) {
      if (_isRuntimeUnavailable(error)) {
        if (!canUseSimpleLegadoJsFallback(script)) {
          throw LegadoJsException(
            'Full JS runtime is required for complex Legado JS, '
            'but QuickJS runtime is unavailable: $error',
          );
        }
        return const SimpleLegadoJsEngine().eval(script, context: context);
      }
      throw LegadoJsException('JS execution failed: $error');
    }
  }

  flutter_js.JavascriptRuntime _runtimeForEval() {
    return _runtime ??= _createRuntime();
  }

  flutter_js.JavascriptRuntime _createRuntime() {
    final runtime = flutter_js.QuickJsRuntime2(
      timeout: timeout.inMilliseconds,
    );
    flutter_js.HandlePromises(runtime).enableHandlePromises();
    return runtime;
  }

  @override
  Future<Object?> evalAsync(
    String script, {
    required LegadoJsContext context,
  }) async {
    _traceCookieGetKeyWithoutCookie(script, context);
    final ajaxContextId = 'ajax_${_ajaxContextSequence++}';
    try {
      final runtime = _runtimeForEval();
      if (context.ajax != null) {
        _ajaxHandlers[ajaxContextId] = context.ajax!;
        _ensureAjaxBridge(runtime);
      }
      final result = runtime.evaluate(
        _wrapScript(
          script,
          context,
          allowAsync: true,
          ajaxContextId: ajaxContextId,
        ),
      );
      if (result.isError) throw LegadoJsException(result.stringResult);
      final awaited = await flutter_js.HandlePromises(runtime).handlePromise(
        result,
        timeout: timeout,
      );
      if (awaited.isError) throw LegadoJsException(awaited.stringResult);
      _checkOutputSize(awaited.rawResult);
      return _decodeResult(awaited.rawResult, context);
    } on LegadoJsException {
      rethrow;
    } catch (error) {
      if (_isRuntimeUnavailable(error)) {
        if (!canUseSimpleLegadoJsFallback(script)) {
          throw LegadoJsException(
            'Full JS runtime is required for complex Legado JS, '
            'but QuickJS runtime is unavailable: $error',
          );
        }
        return const SimpleLegadoJsEngine().evalAsync(
          script,
          context: context,
        );
      }
      throw LegadoJsException('JS execution failed: $error');
    } finally {
      _ajaxHandlers.remove(ajaxContextId);
    }
  }

  void _ensureAjaxBridge(flutter_js.JavascriptRuntime runtime) {
    final runtimeId = runtime.getEngineInstanceId();
    if (_ajaxBridgeRuntimeId == runtimeId) return;
    runtime.onMessage('LegadoJavaAjax', (dynamic message) {
      final decoded = message is Map
          ? message
          : jsonDecode(message?.toString() ?? '{}') as Map;
      final id = decoded['id']?.toString() ?? '';
      final rawUrl = decoded['url']?.toString() ?? '';
      final ajax = _ajaxHandlers[id];
      if (ajax == null) {
        throw StateError('java.ajax context $id is not available');
      }
      return Future.sync(() => ajax(rawUrl)).then((value) {
        if (value == null) return '';
        if (value is String) return value;
        if (value is Map || value is List) return jsonEncode(value);
        return value.toString();
      });
    });
    _ajaxBridgeRuntimeId = runtimeId;
  }

  String _wrapScript(
    String script,
    LegadoJsContext context, {
    bool allowAsync = false,
    String? ajaxContextId,
  }) {
    final encodedBindings = _bindings.contextJson(context);
    final effectiveScript =
        allowAsync ? _asyncCompatibleScript(script) : script;
    final escapedScript = jsonEncode(effectiveScript.trim());
    final functionStart = allowAsync ? '(async function(){' : '(function(){';
    final evalStatement = allowAsync
        ? 'var __value = await eval($escapedScript);'
        : 'var __value = eval($escapedScript);';
    final globals = _bindings.globals(
      allowAsync: allowAsync,
      hasAjax: context.ajax != null,
      ajaxContextId: ajaxContextId,
    );
    return '''
$functionStart
  var __ctx = $encodedBindings;
$globals
  $evalStatement
  if (typeof __value === "undefined") {
    __value = result;
  }
  return JSON.stringify({ value: __value, variables: __ctx.variables });
})()
''';
  }

  String _asyncCompatibleScript(String script) {
    final pattern = RegExp(r'java\.ajax\s*\(');
    final buffer = StringBuffer();
    var start = 0;
    for (final match in pattern.allMatches(script)) {
      buffer.write(script.substring(start, match.start));
      final before = script.substring(0, match.start).trimRight();
      if (before.endsWith('await')) {
        buffer.write(match.group(0));
      } else {
        // Legado 书源通常把 java.ajax 当同步函数写；异步运行时统一补 await。
        buffer.write('await java.ajax(');
      }
      start = match.end;
    }
    buffer.write(script.substring(start));
    return buffer.toString();
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

  void _traceCookieGetKeyWithoutCookie(
    String script,
    LegadoJsContext context,
  ) {
    if (!script.contains('cookie.getKey')) return;
    if (context.cookie != null && context.cookie!.trim().isNotEmpty) return;
    context.trace?.add('cookie.getKey.empty');
  }
}

bool canUseSimpleLegadoJsFallback(String script) {
  final text = _stripJsComments(script).trim();
  if (text.isEmpty) return true;

  // 简化解释器只兜底 Legado 常见的单表达式/简单赋值；控制流、局部变量、
  // 函数和对象构造等复杂脚本必须交给完整 JS runtime，避免误执行出错。
  final complexPattern = RegExp(
    r'\b(if|else|for|while|switch|try|catch|finally|function|return|var|let|const|new|class|with|importPackage)\b|=>',
  );
  return !complexPattern.hasMatch(text);
}

String _stripJsComments(String script) {
  final buffer = StringBuffer();
  var quote = '';
  var escaped = false;
  var lineComment = false;
  var blockComment = false;

  for (var i = 0; i < script.length; i++) {
    final char = script[i];
    final next = i + 1 < script.length ? script[i + 1] : '';

    if (lineComment) {
      if (char == '\n' || char == '\r') {
        lineComment = false;
        buffer.write(char);
      }
      continue;
    }
    if (blockComment) {
      if (char == '*' && next == '/') {
        blockComment = false;
        i += 1;
      }
      continue;
    }
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
    if (char == '/' && next == '/') {
      lineComment = true;
      i += 1;
      continue;
    }
    if (char == '/' && next == '*') {
      blockComment = true;
      i += 1;
      continue;
    }
    buffer.write(char);
  }

  return buffer.toString();
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
    Object? value;
    if (_matchType(_TokenType.number)) {
      value = _previous().literal;
    } else if (_matchType(_TokenType.string)) {
      value = _previous().literal;
    } else if (_match('(')) {
      value = _parseAdditive();
      _consume(')', 'Expected closing parenthesis');
    } else if (_matchType(_TokenType.identifier)) {
      final name = _qualifiedIdentifier(_previous().lexeme);
      value = _match('(') ? _callFunction(name) : _resolveIdentifier(name);
    } else {
      throw LegadoJsException('Unexpected token ${_peek().lexeme}');
    }

    while (_match('.')) {
      if (!_matchType(_TokenType.identifier)) {
        throw const LegadoJsException('Expected identifier after dot');
      }
      final property = _previous().lexeme;
      value = _readProperty(value, property, property);
    }
    return value;
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
      'JSON.parse' => _jsonParse(arguments),
      'java.getString' => _javaGetString(arguments),
      'java.ajax' => _javaAjax(arguments),
      'java.put' => _javaPut(arguments),
      'java.get' => _javaGet(arguments),
      'java.setContent' => _javaSetContent(arguments),
      'java.log' => arguments.isEmpty ? null : arguments.last,
      'cookie.getKey' => _cookieGetKey(arguments),
      'cache.get' => _cacheGet(arguments),
      'cache.put' => _cachePut(arguments),
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
    if (name.contains('.')) return _resolveQualifiedIdentifier(name);
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
      'cache' => context.variables[_cacheVariableKey],
      'null' => null,
      'true' => true,
      'false' => false,
      _ when context.variables.containsKey(name) => context.variables[name],
      _ => throw LegadoJsException('Unsupported identifier $name'),
    };
  }

  Object? _resolveQualifiedIdentifier(String name) {
    final parts = name.split('.');
    Object? current = _resolveIdentifier(parts.first);
    for (final part in parts.skip(1)) {
      current = _readProperty(current, part, name);
    }
    return current;
  }

  Object? _readProperty(Object? target, String property, String fullName) {
    if (target is Map) return target[property];
    if (target is List) {
      final index = int.tryParse(property);
      if (index != null && index >= 0 && index < target.length) {
        return target[index];
      }
    }
    if (target is SourceRule) {
      return switch (property) {
        'id' => target.id,
        'name' => target.name,
        'url' => target.url,
        'group' => target.group,
        'comment' => target.comment,
        'bookUrlPattern' => target.bookUrlPattern,
        'headers' => target.headers,
        'loginUrl' => target.loginUrl,
        _ => throw LegadoJsException('Unsupported identifier $fullName'),
      };
    }
    throw LegadoJsException('Unsupported identifier $fullName');
  }

  Object? _javaPut(List<Object?> arguments) {
    final key = _stringify(_expectArgument('java.put', arguments, 0));
    final value = arguments.length > 1 ? arguments[1] : null;
    context.variables[key] = value;
    return value;
  }

  String _javaGetString(List<Object?> arguments) {
    final value = _expectArgument('java.getString', arguments, 0);
    if (value is String && value.trim().startsWith(r'$')) {
      final resolved = _readRulePath(context.result, value) ??
          _readRulePath(context.src, value);
      return _stringify(resolved);
    }
    return _stringify(value);
  }

  Object? _javaAjax(List<Object?> arguments) {
    final ajax = context.ajax;
    if (ajax == null) {
      throw const LegadoJsException('java.ajax is not configured');
    }
    // 第二个 timeout 参数是 Legado 常见写法；简化引擎先接收参数，
    // 实际超时仍由统一请求执行层控制，避免在 JS 兜底里分叉网络行为。
    return ajax(_stringify(_expectArgument('java.ajax', arguments, 0)));
  }

  Object? _jsonParse(List<Object?> arguments) {
    final raw = _stringify(_expectArgument('JSON.parse', arguments, 0)).trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (error) {
      throw LegadoJsException('JSON.parse failed: $error');
    }
  }

  Object? _javaGet(List<Object?> arguments) {
    final key = _stringify(_expectArgument('java.get', arguments, 0));
    return context.variables[key];
  }

  Object? _cacheGet(List<Object?> arguments) {
    final key = _stringify(_expectArgument('cache.get', arguments, 0));
    return _cacheMap()[key];
  }

  Object? _cachePut(List<Object?> arguments) {
    final key = _stringify(_expectArgument('cache.put', arguments, 0));
    final value = arguments.length > 1 ? arguments[1] : null;
    _cacheMap()[key] = value;
    return value;
  }

  Map<String, Object?> _cacheMap() {
    final existing = context.variables[_cacheVariableKey];
    if (existing is Map<String, Object?>) return existing;
    if (existing is Map) {
      final normalized = existing.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      context.variables[_cacheVariableKey] = normalized;
      return normalized;
    }
    final cache = <String, Object?>{};
    context.variables[_cacheVariableKey] = cache;
    return cache;
  }

  Object? _readRulePath(Object? root, String rawPath) {
    if (root == null) return null;
    final path = rawPath.trim();
    if (path == r'$') return _parseMaybeJson(root);
    if (!path.startsWith(r'$.')) return null;

    Object? current = _parseMaybeJson(root);
    for (final segment in _splitPathSegments(path.substring(2))) {
      if (current == null) return null;
      final match = RegExp(r'^([^\[]+)(?:\[(\d+)\])?$').firstMatch(segment);
      if (match == null) return null;
      current = _readPropertyValue(current, match.group(1)!);
      final indexText = match.group(2);
      if (indexText != null) {
        final index = int.parse(indexText);
        if (current is! List || index < 0 || index >= current.length) {
          return null;
        }
        current = current[index];
      }
    }
    return current;
  }

  Object? _parseMaybeJson(Object? value) {
    if (value is! String) return value;
    final text = value.trim();
    if (text.isEmpty || (!text.startsWith('{') && !text.startsWith('['))) {
      return value;
    }
    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  List<String> _splitPathSegments(String path) {
    final segments = <String>[];
    final buffer = StringBuffer();
    var bracketDepth = 0;
    for (var i = 0; i < path.length; i++) {
      final char = path[i];
      if (char == '[') bracketDepth += 1;
      if (char == ']' && bracketDepth > 0) bracketDepth -= 1;
      if (char == '.' && bracketDepth == 0) {
        final segment = buffer.toString();
        if (segment.isNotEmpty) segments.add(segment);
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    final tail = buffer.toString();
    if (tail.isNotEmpty) segments.add(tail);
    return segments;
  }

  Object? _readPropertyValue(Object? target, String property) {
    if (target is Map) return target[property];
    if (target is SourceRule) {
      return switch (property) {
        'id' => target.id,
        'name' => target.name,
        'url' => target.url,
        'group' => target.group,
        'comment' => target.comment,
        'bookUrlPattern' => target.bookUrlPattern,
        'headers' => target.headers,
        'loginUrl' => target.loginUrl,
        _ => null,
      };
    }
    return null;
  }

  Object? _javaSetContent(List<Object?> arguments) {
    final value = _expectArgument('java.setContent', arguments, 0);
    // Legado 中 setContent 会把后续规则的正文源切换为新内容；
    // 简化 JS 引擎没有可变 src/result，只把值返回给调用链继续使用。
    return value;
  }

  String? _cookieGetKey(List<Object?> arguments) {
    final key = _stringify(
      arguments.length > 1
          ? arguments[1]
          : _expectArgument('cookie.getKey', arguments, 0),
    );
    final cookie = context.cookie;
    if (cookie == null || cookie.trim().isEmpty) {
      context.trace?.add('cookie.getKey.empty:$key');
      return null;
    }
    for (final part in cookie.split(';')) {
      final trimmed = part.trim();
      final equals = trimmed.indexOf('=');
      if (equals <= 0) continue;
      if (trimmed.substring(0, equals).trim() == key) {
        return trimmed.substring(equals + 1).trim();
      }
    }
    context.trace?.add('cookie.getKey.miss:$key');
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
