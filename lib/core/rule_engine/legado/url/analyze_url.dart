import 'dart:convert';

import '../../models/source_rule.dart';
import '../common/balanced_text_scanner.dart';
import '../js/legado_js_engine.dart';
import 'cookie_merge.dart';
import 'request_executor.dart';
import 'url_options.dart';
import 'url_placeholder.dart';

class AnalyzeUrl {
  const AnalyzeUrl({
    this.placeholder = const LegadoUrlPlaceholder(),
    this.scanner = const BalancedTextScanner(),
    this.jsEngine = const SimpleLegadoJsEngine(),
    this.cookieProvider = const NoopLegadoCookieProvider(),
    this.cookieMerge = const LegadoCookieMerge(),
  });

  final LegadoUrlPlaceholder placeholder;
  final BalancedTextScanner scanner;
  final LegadoJsEngine jsEngine;
  final LegadoCookieProvider cookieProvider;
  final LegadoCookieMerge cookieMerge;

  LegadoRequest compileSearch({
    required SourceRule source,
    required String rawUrl,
    required String keyword,
    int page = 1,
  }) {
    final analyzedUrl = _analyzeSearchUrl(rawUrl, keyword, page, source);
    final replaced = placeholder.apply(
      rawUrl: analyzedUrl,
      keyword: keyword,
      page: page,
    );
    final split = splitOptions(replaced);
    final options = LegadoUrlOptions.parse(split.optionJson);
    final headers = <String, String>{
      ...source.headers,
      ...options.headers,
    };
    final resolvedUri = Uri.parse(source.url).resolve(split.url.trim());
    _mergeCookieHeader(headers, resolvedUri);
    final resolvedUrl = resolvedUri.toString();
    final request = options.method == 'POST'
        ? _preparePostRequest(
            resolvedUrl: resolvedUrl,
            headers: headers,
            body: options.body,
            charset: options.charset,
          )
        : _PreparedRequest(
            url: resolvedUrl,
            headers: headers,
            body: options.body,
          );
    return LegadoRequest(
      url: request.url,
      method: options.method,
      headers: request.headers,
      body: request.body,
      charset: options.charset,
      bodyJs: options.bodyJs,
      webJs: options.webJs,
      useWebView: options.useWebView,
      webViewDelayTime: options.webViewDelayTime,
    );
  }

  Future<LegadoRequest> compileSearchAsync({
    required SourceRule source,
    required String rawUrl,
    required String keyword,
    int page = 1,
    Map<String, Object?> variables = const {},
    LegadoJsAjax? ajax,
  }) async {
    final analyzedUrl = await _analyzeSearchUrlAsync(
      rawUrl,
      keyword,
      page,
      source,
      variables: variables,
      ajax: ajax,
    );
    final replaced = await placeholder.applyAsync(
      rawUrl: analyzedUrl,
      keyword: keyword,
      page: page,
      baseUrl: source.url,
      source: source,
      variables: variables,
      ajax: ajax,
    );
    final split = splitOptions(replaced);
    final options = LegadoUrlOptions.parse(split.optionJson);
    final headers = <String, String>{
      ...source.headers,
      ...options.headers,
    };
    final resolvedUri = Uri.parse(source.url).resolve(split.url.trim());
    _mergeCookieHeader(headers, resolvedUri);
    final resolvedUrl = resolvedUri.toString();
    final request = options.method == 'POST'
        ? _preparePostRequest(
            resolvedUrl: resolvedUrl,
            headers: headers,
            body: options.body,
            charset: options.charset,
          )
        : _PreparedRequest(
            url: resolvedUrl,
            headers: headers,
            body: options.body,
          );
    return LegadoRequest(
      url: request.url,
      method: options.method,
      headers: request.headers,
      body: request.body,
      charset: options.charset,
      bodyJs: options.bodyJs,
      webJs: options.webJs,
      useWebView: options.useWebView,
      webViewDelayTime: options.webViewDelayTime,
    );
  }

  SplitLegadoUrlOptions splitOptions(String rawUrl) {
    final index = scanner.indexWhereTopLevel(
      rawUrl,
      ',',
      (index) => rawUrl.substring(index + 1).trimLeft().startsWith('{'),
    );
    if (index < 0) return SplitLegadoUrlOptions(rawUrl, null);

    return SplitLegadoUrlOptions(
      rawUrl.substring(0, index),
      rawUrl.substring(index + 1).trimLeft(),
    );
  }

  String _analyzeSearchUrl(
    String rawUrl,
    String keyword,
    int page,
    SourceRule source,
  ) {
    final jsPattern = RegExp(
      r'<js>([\s\S]*?)</js>|@js:([\s\S]*)',
      caseSensitive: false,
    );
    final matches = jsPattern.allMatches(rawUrl).toList();
    if (matches.isEmpty) return rawUrl;

    final buffer = StringBuffer();
    Object? result;
    var start = 0;

    for (final match in matches) {
      _writeLiteralWithResult(
        buffer,
        rawUrl.substring(start, match.start),
        result,
      );
      final script = match.group(1) ?? match.group(2) ?? '';
      result = jsEngine.eval(
        script,
        context: LegadoJsContext(
          key: keyword,
          page: page,
          baseUrl: source.url,
          result: result,
          source: source,
        ),
      );
      buffer.write(_stringifyJsResult(result));
      start = match.end;
    }

    _writeLiteralWithResult(
      buffer,
      rawUrl.substring(start),
      result,
    );
    return buffer.toString();
  }

  Future<String> _analyzeSearchUrlAsync(
    String rawUrl,
    String keyword,
    int page,
    SourceRule source, {
    required Map<String, Object?> variables,
    LegadoJsAjax? ajax,
  }) async {
    final jsPattern = RegExp(
      r'<js>([\s\S]*?)</js>|@js:([\s\S]*)',
      caseSensitive: false,
    );
    final matches = jsPattern.allMatches(rawUrl).toList();
    if (matches.isEmpty) return rawUrl;

    final buffer = StringBuffer();
    Object? result;
    var start = 0;

    for (final match in matches) {
      _writeLiteralWithResult(
        buffer,
        rawUrl.substring(start, match.start),
        result,
      );
      final script = match.group(1) ?? match.group(2) ?? '';
      result = await jsEngine.evalAsync(
        script,
        context: LegadoJsContext(
          key: keyword,
          page: page,
          baseUrl: source.url,
          result: result,
          source: source,
          variables: variables,
          ajax: ajax,
        ),
      );
      buffer.write(_stringifyJsResult(result));
      start = match.end;
    }

    _writeLiteralWithResult(
      buffer,
      rawUrl.substring(start),
      result,
    );
    return buffer.toString();
  }

  void _writeLiteralWithResult(
    StringBuffer buffer,
    String literal,
    Object? result,
  ) {
    if (literal.isEmpty) return;
    buffer.write(literal.replaceAll('@result', _stringifyJsResult(result)));
  }

  String _stringifyJsResult(Object? value) {
    if (value == null) return '';
    if (value is double && value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  void _mergeCookieHeader(Map<String, String> headers, Uri uri) {
    final headerCookie = _removeCookieHeader(headers);
    final mergedCookie = cookieMerge.merge(
      storedCookie: cookieProvider.cookieFor(uri),
      headerCookie: headerCookie,
    );
    if (mergedCookie != null) headers['Cookie'] = mergedCookie;
  }

  String? _removeCookieHeader(Map<String, String> headers) {
    String? cookie;
    final keys = headers.keys.toList();
    for (final key in keys) {
      if (key.toLowerCase() != 'cookie') continue;
      cookie = headers.remove(key);
    }
    return cookie;
  }

  _PreparedRequest _preparePostRequest({
    required String resolvedUrl,
    required Map<String, String> headers,
    required Object? body,
    required String? charset,
  }) {
    final uri = Uri.parse(resolvedUrl);
    final urlWithoutQuery = uri.replace(query: '').toString().replaceFirst(
          RegExp(r'\?$'),
          '',
        );
    final preparedHeaders = Map<String, String>.from(headers);
    final rawBody = body ?? uri.query;
    final normalizedBody = _normalizeBodyToString(rawBody);

    if (_contentTypeOf(preparedHeaders) != null) {
      return _PreparedRequest(
        url: urlWithoutQuery,
        headers: preparedHeaders,
        body: normalizedBody,
      );
    }

    if (_isJsonBody(normalizedBody)) {
      preparedHeaders['Content-Type'] = 'application/json; charset=utf-8';
      return _PreparedRequest(
        url: urlWithoutQuery,
        headers: preparedHeaders,
        body: normalizedBody,
      );
    }
    if (_isXmlBody(normalizedBody)) {
      return _PreparedRequest(
        url: urlWithoutQuery,
        headers: preparedHeaders,
        body: normalizedBody,
      );
    }

    preparedHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
    return _PreparedRequest(
      url: urlWithoutQuery,
      headers: preparedHeaders,
      body: normalizedBody.trimLeft().isEmpty
          ? ''
          : _encodeParams(normalizedBody, charset),
    );
  }

  String _normalizeBodyToString(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    if (body is Map || body is List) return jsonEncode(body);
    return body.toString();
  }

  String? _contentTypeOf(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') return entry.value;
    }
    return null;
  }

  bool _isJsonBody(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  bool _isXmlBody(String body) => body.trimLeft().startsWith('<');

  String _encodeParams(String params, String? charset) {
    return params.split('&').map((part) {
      final equals = part.indexOf('=');
      if (equals < 0) return _encodeParamPart(part, charset);
      final key = part.substring(0, equals);
      final value = part.substring(equals + 1);
      return '${_encodeParamPart(key, charset)}=${_encodeParamPart(value, charset)}';
    }).join('&');
  }

  String _encodeParamPart(String value, String? charset) {
    final normalizedCharset = charset?.trim().toLowerCase();
    if (normalizedCharset == 'escape') return _escape(value);

    final bytes = switch (normalizedCharset) {
      null || '' || 'utf8' || 'utf-8' => utf8.encode(value),
      _ => utf8.encode(value),
    };
    return _percentEncodeBytes(bytes, preserveEscapesFrom: value);
  }

  String _percentEncodeBytes(
    List<int> bytes, {
    required String preserveEscapesFrom,
  }) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      final char = String.fromCharCode(byte);
      if (_isFormSafeByte(byte)) {
        buffer.write(char);
      } else if (byte == 0x20) {
        buffer.write('+');
      } else if (byte == 0x25 &&
          _hasValidPercentEscape(preserveEscapesFrom, i)) {
        buffer.write('%');
      } else {
        buffer
            .write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return buffer.toString();
  }

  bool _hasValidPercentEscape(String value, int index) {
    return index + 2 < value.length &&
        value.codeUnitAt(index) == 0x25 &&
        _isHex(value.codeUnitAt(index + 1)) &&
        _isHex(value.codeUnitAt(index + 2));
  }

  bool _isHex(int code) {
    return (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x46) ||
        (code >= 0x61 && code <= 0x66);
  }

  bool _isFormSafeByte(int byte) {
    return (byte >= 0x30 && byte <= 0x39) ||
        (byte >= 0x41 && byte <= 0x5A) ||
        (byte >= 0x61 && byte <= 0x7A) ||
        byte == 0x2A ||
        byte == 0x2D ||
        byte == 0x2E ||
        byte == 0x5F;
  }

  String _escape(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if ((rune >= 0x30 && rune <= 0x39) ||
          (rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          rune == 0x2A ||
          rune == 0x2B ||
          rune == 0x2D ||
          rune == 0x2E ||
          rune == 0x2F ||
          rune == 0x40 ||
          rune == 0x5F) {
        buffer.writeCharCode(rune);
      } else if (rune < 256) {
        buffer
            .write('%${rune.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      } else {
        buffer.write('%u${rune.toRadixString(16).padLeft(4, '0')}');
      }
    }
    return buffer.toString();
  }
}

class _PreparedRequest {
  const _PreparedRequest({
    required this.url,
    required this.headers,
    required this.body,
  });

  final String url;
  final Map<String, String> headers;
  final Object? body;
}
