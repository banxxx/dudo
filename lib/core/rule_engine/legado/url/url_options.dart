import 'dart:convert';

class LegadoUrlOptions {
  const LegadoUrlOptions({
    required this.method,
    required this.headers,
    this.body,
    this.charset,
  });

  final String method;
  final Map<String, String> headers;
  final Object? body;
  final String? charset;

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
}

class SplitLegadoUrlOptions {
  const SplitLegadoUrlOptions(this.url, this.optionJson);

  final String url;
  final String? optionJson;
}
