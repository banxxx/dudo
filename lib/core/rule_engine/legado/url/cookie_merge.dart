class LegadoCookieMerge {
  const LegadoCookieMerge();

  String? merge({String? storedCookie, String? headerCookie}) {
    final cookies = <String, String>{};
    _addCookies(cookies, storedCookie);
    _addCookies(cookies, headerCookie);
    if (cookies.isEmpty) return null;
    return cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  void _addCookies(Map<String, String> cookies, String? rawCookie) {
    if (rawCookie == null || rawCookie.trim().isEmpty) return;
    for (final part in rawCookie.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final equals = trimmed.indexOf('=');
      if (equals <= 0) continue;
      final key = trimmed.substring(0, equals).trim();
      final value = trimmed.substring(equals + 1).trim();
      if (key.isEmpty) continue;
      if (value.isEmpty && value != 'null') continue;
      cookies[key] = value;
    }
  }
}

abstract interface class LegadoCookieProvider {
  String? cookieFor(Uri uri);
}

class NoopLegadoCookieProvider implements LegadoCookieProvider {
  const NoopLegadoCookieProvider();

  @override
  String? cookieFor(Uri uri) => null;
}
