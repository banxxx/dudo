import 'dart:convert';

class LegadoUrlOptions {
  const LegadoUrlOptions({
    required this.method,
    required this.headers,
    this.body,
    this.charset,
    this.bodyJs,
    this.webJs,
    this.useWebView = false,
    this.webViewDelayTime,
  });

  final String method;
  final Map<String, String> headers;
  final Object? body;
  final String? charset;
  final String? bodyJs;
  final String? webJs;
  final bool useWebView;
  final int? webViewDelayTime;

  static const empty = LegadoUrlOptions(method: 'GET', headers: {});

  factory LegadoUrlOptions.parse(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return empty;

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return empty;
      final rawMethod = decoded['method']?.toString().toUpperCase();
      final method = switch (rawMethod) {
        'POST' => 'POST',
        'HEAD' => 'HEAD',
        _ => 'GET',
      };
      return LegadoUrlOptions(
        method: method,
        headers: _headersFrom(decoded['headers'] ?? decoded['header']),
        body: decoded['body'],
        charset: decoded['charset']?.toString(),
        bodyJs: _blankToNull(decoded['bodyJs']),
        webJs: _blankToNull(decoded['webJs']),
        useWebView: _useWebView(decoded['webView']),
        webViewDelayTime: _intFrom(decoded['webViewDelayTime']),
      );
    } catch (_) {
      return empty;
    }
  }

  static Map<String, String> _headersFrom(Object? rawHeaders) {
    if (rawHeaders is! Map) return const {};
    final headers = <String, String>{};
    for (final entry in rawHeaders.entries) {
      final value = entry.value;
      if (value == null) continue;
      headers[entry.key.toString()] = value.toString();
    }
    return headers;
  }

  static String? _blankToNull(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  static bool _useWebView(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty || text == 'false') return false;
    return true;
  }

  static int? _intFrom(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}

class SplitLegadoUrlOptions {
  const SplitLegadoUrlOptions(this.url, this.optionJson);

  final String url;
  final String? optionJson;
}
