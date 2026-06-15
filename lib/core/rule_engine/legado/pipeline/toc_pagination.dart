class TocPagination {
  const TocPagination._();

  static const defaultPageSize = 80;

  static String firstPageUrl(String rawUrl, {int limit = defaultPageSize}) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !_looksLikePagedTocUrl(uri)) return rawUrl;
    return _replaceQuery(uri, {
      'whole': '0',
      'more': '0',
      'limit': '$limit',
    });
  }

  static String? nextPageUrl(
    String currentUrl, {
    required int loadedCount,
    required int? totalCount,
    int limit = defaultPageSize,
  }) {
    if (loadedCount <= 0) return null;
    if (totalCount == null || loadedCount >= totalCount) return null;

    final uri = Uri.tryParse(currentUrl.trim());
    if (uri == null || !_looksLikePagedTocUrl(uri)) return null;
    return _replaceQuery(uri, {
      'whole': '0',
      'more': '$loadedCount',
      'limit': '$limit',
    });
  }

  static bool _looksLikePagedTocUrl(Uri uri) {
    final lowerPath = uri.path.toLowerCase();
    return lowerPath.contains('chapterlist') ||
        uri.queryParameters.containsKey('whole') ||
        uri.queryParameters.containsKey('more');
  }

  static String _replaceQuery(Uri uri, Map<String, String> values) {
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...values,
    }).toString();
  }
}
