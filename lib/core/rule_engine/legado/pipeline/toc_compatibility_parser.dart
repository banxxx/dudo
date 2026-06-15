import 'dart:convert';

import '../rule/analyze_rule.dart';
import '../rule/rule_context.dart';
import 'toc_pagination.dart';

/// Compatibility layer for source TOC rules that mix a valid base selector with
/// unsupported embedded JavaScript. Keep these fallbacks isolated from the main
/// TOC pipeline so new mock/source response shapes can be added without turning
/// the pipeline into source-specific branching.
class TocCompatibilityParser {
  const TocCompatibilityParser();

  List<Object> fallbackChapterList({
    required Object source,
    required String? rawRule,
    required AnalyzeRule analyzeRule,
    required RuleContext context,
  }) {
    final strippedRule = _stripEmbeddedJs(rawRule);
    if (strippedRule != null && strippedRule != rawRule?.trim()) {
      final list = _tryElements(
        source: source,
        rawRule: strippedRule,
        analyzeRule: analyzeRule,
        context: context,
      );
      final normalized = _flattenObjectLists(list);
      if (normalized.isNotEmpty) return normalized;
    }

    if (source is String) {
      for (final list in _jsonCatalogLists(source)) {
        if (list.isNotEmpty) return list;
      }
    }
    return const <Object>[];
  }

  String? fallbackFieldString({
    required Object source,
    required String? rawRule,
    required AnalyzeRule analyzeRule,
    required RuleContext context,
    required String fieldName,
  }) {
    final strippedRule = _stripEmbeddedJs(rawRule);
    if (strippedRule != null && strippedRule != rawRule?.trim()) {
      final value = _tryFieldString(
        source: source,
        rawRule: strippedRule,
        analyzeRule: analyzeRule,
        context: context,
      );
      if (value != null && value.trim().isNotEmpty) return value;
    }

    if (source is Map) {
      final value = _fieldAliasValue(source, fieldName);
      if (value != null) return value;
      if (fieldName == 'chapterUrl') {
        return _derivedChapterContentUrl(source, context);
      }
    }
    return null;
  }

  int? fallbackTotalCount(Object source, int parsedChapterCount) {
    final decoded = _decodeJsonMap(source);
    if (decoded == null) return null;

    final total = _firstInt(decoded, const [
      'total',
      'totalCount',
      'chapterCount',
      'chaptersCount',
      'chapterTotal',
      'chapterTotalCount',
      'totalChapter',
      'totalChapters',
      'allChapterCount',
    ]);
    if (total != null) return total;

    final data = decoded['data'];
    if (data is Map) {
      return _firstInt(data, const [
        'total',
        'totalCount',
        'chapterCount',
        'chaptersCount',
        'chapterTotal',
        'totalChapter',
      ]);
    }
    return null;
  }

  String? fallbackNextTocUrl({
    required Object source,
    required RuleContext context,
    required AnalyzeRule analyzeRule,
    required int parsedChapterCount,
    required int? totalCount,
  }) {
    final decoded = _decodeJsonMap(source);
    if (decoded != null) {
      final explicit = _firstMapString(decoded, const [
            'nextTocUrl',
            'nextUrl',
            'next',
            'nextPageUrl',
          ]) ??
          switch (decoded['data']) {
            final Map data => _firstMapString(data, const [
                'nextTocUrl',
                'nextUrl',
                'next',
                'nextPageUrl',
              ]),
            _ => null,
          };
      final normalized = analyzeRule.absoluteUrl(explicit, context.currentUrl);
      if (normalized?.trim().isNotEmpty ?? false) return normalized;
    }

    return TocPagination.nextPageUrl(
      context.currentUrl,
      loadedCount: parsedChapterCount,
      totalCount: totalCount,
    );
  }

  List<Object> _tryElements({
    required Object source,
    required String rawRule,
    required AnalyzeRule analyzeRule,
    required RuleContext context,
  }) {
    try {
      return analyzeRule.elements(source, rawRule, context);
    } catch (_) {
      return const <Object>[];
    }
  }

  String? _tryFieldString({
    required Object source,
    required String rawRule,
    required AnalyzeRule analyzeRule,
    required RuleContext context,
  }) {
    try {
      return analyzeRule.fieldString(source, rawRule, context);
    } catch (_) {
      return null;
    }
  }

  Iterable<List<Object>> _jsonCatalogLists(String text) sync* {
    final decoded = _tryDecodeJson(text);

    final rootList = _asObjectList(decoded);
    if (rootList != null) {
      yield rootList;
      return;
    }

    if (decoded is Map) {
      for (final key in const [
        'chapterlist',
        'chapterList',
        'chapters',
        'chapterListData',
        'list',
        'items',
      ]) {
        final list = _asObjectList(decoded[key]);
        if (list != null && list.isNotEmpty) yield list;
      }

      final data = decoded['data'];
      if (data is Map) {
        for (final key in const ['chapterlist', 'chapterList', 'chapters']) {
          final list = _asObjectList(data[key]);
          if (list != null && list.isNotEmpty) yield list;
        }
      }
    }
  }

  List<Object>? _asObjectList(Object? value) {
    if (value is! List) return null;
    final list = value.whereType<Object>().toList(growable: false);
    return list.isEmpty ? null : list;
  }

  List<Object> _flattenObjectLists(List<Object> values) {
    if (values.isEmpty) return const <Object>[];
    final flattened = <Object>[];
    for (final value in values) {
      if (value is List) {
        flattened.addAll(value.whereType<Object>());
      } else {
        flattened.add(value);
      }
    }
    return flattened;
  }

  String? _fieldAliasValue(Map source, String fieldName) {
    final keys = switch (fieldName) {
      'chapterName' => const [
          'chaptername',
          'chapterName',
          'name',
          'title',
        ],
      'chapterUrl' => const [
          'chapterurl',
          'chapterUrl',
          'contentUrl',
          'readUrl',
          'url',
          'href',
          'link',
        ],
      'isVolume' => const ['isVolume', 'chaptertype'],
      'isVip' => const ['isvip', 'isVip', 'vip'],
      'isPay' => const ['isPay', 'pay'],
      'updateTime' => const ['chapterdate', 'updateTime', 'updatedAt'],
      _ => const <String>[],
    };

    for (final key in keys) {
      final value = source[key];
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String? _derivedChapterContentUrl(Map source, RuleContext context) {
    final chapterId = _firstMapString(source, const [
      'chapterid',
      'chapterId',
      'chapterID',
      'id',
    ]);
    if (chapterId == null) return null;

    final novelId = _firstMapString(source, const [
          'novelid',
          'novelId',
          'novelID',
        ]) ??
        _queryValue(context.currentUrl, const ['novelId', 'novelid']) ??
        _bookValue(context.book, const ['novelId', 'novelid']);
    if (novelId == null) return null;

    final currentUrl = _chapterContentUrlFromCurrentUrl(
      context.currentUrl,
      novelId: novelId,
      chapterId: chapterId,
    );
    if (currentUrl != null) return currentUrl;

    if (_isJjwxcLike(context)) {
      return Uri(
        scheme: 'http',
        host: 'app-cdn.jjwxc.net',
        path: '/androidapi/chapterContent',
        queryParameters: {
          'novelId': novelId,
          'chapterId': chapterId,
        },
      ).toString();
    }
    return null;
  }

  String? _chapterContentUrlFromCurrentUrl(
    String currentUrl, {
    required String novelId,
    required String chapterId,
  }) {
    final uri = Uri.tryParse(currentUrl);
    if (uri == null) return null;
    final path = uri.path.replaceFirst(
      RegExp(r'chapterList$', caseSensitive: false),
      'chapterContent',
    );
    if (path == uri.path) return null;
    return uri.replace(
      path: path,
      queryParameters: {
        'novelId': novelId,
        'chapterId': chapterId,
      },
    ).toString();
  }

  String? _queryValue(String url, List<String> keys) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    for (final key in keys) {
      final value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _bookValue(Object? book, List<String> keys) {
    if (book is! Map) return null;
    return _firstMapString(book, keys);
  }

  String? _firstMapString(Map source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  int? _firstInt(Map source, List<String> keys) {
    for (final key in keys) {
      final raw = source[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      final text = raw?.toString().trim();
      if (text == null || text.isEmpty) continue;
      final value = int.tryParse(text);
      if (value != null) return value;
    }
    return null;
  }

  Map? _decodeJsonMap(Object source) {
    if (source is Map) return source;
    if (source is String) {
      final decoded = _tryDecodeJson(source);
      if (decoded is Map) return decoded;
    }
    return null;
  }

  Object? _tryDecodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  bool _isJjwxcLike(RuleContext context) {
    final source = context.source;
    return source.id.contains('jjwxc.net') ||
        source.url.contains('jjwxc.net') ||
        context.currentUrl.contains('jjwxc.net');
  }

  String? _stripEmbeddedJs(String? rawRule) {
    final rule = rawRule?.trim();
    if (rule == null || rule.isEmpty) return null;
    final stripped = rule
        .replaceAll(RegExp(r'<js>[\s\S]*?</js>', caseSensitive: false), '')
        .replaceAll(RegExp(r'@js:[\s\S]*$', caseSensitive: false), '')
        .trim();
    return stripped.isEmpty ? null : stripped;
  }
}
