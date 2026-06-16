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

abstract interface class LegadoCookieStore implements LegadoCookieProvider {
  void saveFromResponse(Uri uri, Iterable<String> setCookieHeaders);
}

class NoopLegadoCookieProvider implements LegadoCookieProvider {
  const NoopLegadoCookieProvider();

  @override
  String? cookieFor(Uri uri) => null;
}

class InMemoryLegadoCookieStore implements LegadoCookieStore {
  InMemoryLegadoCookieStore({this.cookieMerge = const LegadoCookieMerge()});

  final LegadoCookieMerge cookieMerge;
  final Map<String, String> _cookiesByHost = {};

  @override
  String? cookieFor(Uri uri) => _cookiesByHost[_hostKey(uri)];

  @override
  void saveFromResponse(Uri uri, Iterable<String> setCookieHeaders) {
    final responseCookie = _cookieHeaderFromSetCookie(setCookieHeaders);
    if (responseCookie == null) return;
    final key = _hostKey(uri);
    final merged = cookieMerge.merge(
      storedCookie: _cookiesByHost[key],
      headerCookie: responseCookie,
    );
    if (merged == null || merged.trim().isEmpty) {
      _cookiesByHost.remove(key);
      return;
    }
    _cookiesByHost[key] = merged;
  }

  String _hostKey(Uri uri) => uri.host.toLowerCase();

  String? _cookieHeaderFromSetCookie(Iterable<String> setCookieHeaders) {
    final pairs = <String>[];
    for (final header in setCookieHeaders) {
      final cookiePair = header.split(';').first.trim();
      if (cookiePair.isEmpty || !cookiePair.contains('=')) continue;
      pairs.add(cookiePair);
    }
    if (pairs.isEmpty) return null;
    return pairs.join('; ');
  }
}
