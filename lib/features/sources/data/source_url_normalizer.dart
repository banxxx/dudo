/// Normalizes a Legado `bookSourceUrl` into an absolute http(s) URL.
///
/// Real-world source packs contain values such as ` https://a.com`,
/// `www.a.com/`, `http:a.com` and plain garbage. This keeps the fix-ups
/// deterministic and returns `null` when the value cannot be used as a base
/// URL.
String? normalizeSourceUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  // Legado allows URL options on the source URL (`url,{...}` or `url, {...}`);
  // the base URL is everything before the option object.
  final optionsMatch = RegExp(r',\s*\{').firstMatch(text);
  if (optionsMatch != null && optionsMatch.start > 0) {
    text = text.substring(0, optionsMatch.start).trim();
  }

  // `http:a.com` / `https:a.com` → `http://a.com`.
  final missingSlashes =
      RegExp(r'^(https?):(?!//)(.+)$', caseSensitive: false).firstMatch(text);
  if (missingSlashes != null) {
    text = '${missingSlashes.group(1)!.toLowerCase()}://'
        '${missingSlashes.group(2)!}';
  }

  var uri = Uri.tryParse(text);
  if (uri == null) return null;

  if (!uri.hasScheme) {
    if (!_bareHostPattern.hasMatch(text)) return null;
    text = 'https://$text';
    uri = Uri.tryParse(text);
    if (uri == null) return null;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (uri.host.isEmpty) return null;

  return text;
}

final RegExp _bareHostPattern = RegExp(
  r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
  r'(?::\d+)?(?:[/?#].*)?$',
);
