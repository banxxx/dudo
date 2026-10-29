import 'dart:convert';

/// Source-rule data model — mirrors the Legado 3.0 JSON shape but is
/// intentionally permissive so we can evolve.
///
/// Field names and defaults follow Legado's `BookSource` / rule entities.
/// Rule strings are kept verbatim; only identity fields (url / name / group)
/// are trimmed.
class SourceRule {
  final String id;
  final String name;
  final String url;
  final String? group;
  final String? comment;
  final String? bookUrlPattern;
  final SearchRule? search;
  final BookInfoRule? bookInfo;
  final TocRule? toc;
  final ContentRule? content;
  final ExploreRule? explore;
  final Map<String, String> headers;

  /// Raw `header` value. Kept for dynamic headers (`@js:` / `<js>`) that must
  /// be evaluated at request time; [headers] is empty in that case.
  final String? headerRaw;
  final String? loginUrl;
  final String? loginUi;
  final String? loginCheckJs;
  final String? coverDecodeJs;
  final String? jsLib;
  final String? concurrentRate;
  final String? variableComment;
  final String? exploreScreen;
  final Map<String, dynamic>? review;

  /// Legado `bookSourceType`: 0 text, 1 audio, 2 image, 3 file, 4 video.
  final int sourceType;
  final bool enabled;
  final bool enabledExplore;
  final int? lastUpdateTime;
  final int? respondTime;
  final int? weight;
  final bool enabledCookieJar;
  final bool eventListener;
  final bool customButton;

  const SourceRule({
    required this.id,
    required this.name,
    required this.url,
    this.group,
    this.comment,
    this.bookUrlPattern,
    this.search,
    this.bookInfo,
    this.toc,
    this.content,
    this.explore,
    this.headers = const {},
    this.headerRaw,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.jsLib,
    this.concurrentRate,
    this.variableComment,
    this.exploreScreen,
    this.review,
    this.sourceType = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.lastUpdateTime,
    this.respondTime,
    this.weight,
    this.enabledCookieJar = true,
    this.eventListener = false,
    this.customButton = false,
  });

  /// Whether this source can participate in keyword search.
  bool get hasSearchUrl => search?.searchUrl?.trim().isNotEmpty ?? false;

  /// Whether this source is a text source (the only type dudo can read).
  bool get isTextSource => sourceType == 0;

  /// Whether the header is a JS expression that has to be evaluated per request.
  bool get hasDynamicHeader {
    final raw = headerRaw?.trim().toLowerCase();
    return raw != null && (raw.startsWith('@js:') || raw.startsWith('<js>'));
  }

  factory SourceRule.fromJson(Map<String, dynamic> json) {
    final rawUrl = _stringValue(json['bookSourceUrl'] ?? json['url']) ?? '';
    final rawName = _stringValue(json['bookSourceName'] ?? json['name']) ?? '';
    final rawId =
        _stringValue(json['bookSourceUrl'] ?? json['id'] ?? json['url']) ?? '';
    final header = _parseHeader(json['header']);
    return SourceRule(
      id: rawId.trim(),
      name: rawName.trim(),
      url: rawUrl.trim(),
      group: _trimmedString(json['bookSourceGroup']),
      comment: _trimmedString(json['bookSourceComment']),
      bookUrlPattern: _stringValue(json['bookUrlPattern']),
      search: _parseRuleMap(json['ruleSearch']) == null
          ? null
          : SearchRule.fromJson(
              _parseRuleMap(json['ruleSearch'])!,
              searchUrl: _stringValue(json['searchUrl']),
            ),
      bookInfo: _parseRuleMap(json['ruleBookInfo']) == null
          ? null
          : BookInfoRule.fromJson(_parseRuleMap(json['ruleBookInfo'])!),
      toc: _parseRuleMap(json['ruleToc']) == null
          ? null
          : TocRule.fromJson(_parseRuleMap(json['ruleToc'])!),
      content: _parseRuleMap(json['ruleContent']) == null
          ? null
          : ContentRule.fromJson(_parseRuleMap(json['ruleContent'])!),
      explore: _parseRuleMap(json['ruleExplore']) == null
          ? null
          : ExploreRule.fromJson(
              _parseRuleMap(json['ruleExplore'])!,
              exploreUrl: _stringValue(json['exploreUrl']),
            ),
      headers: header.headers,
      headerRaw: header.raw,
      loginUrl: _stringValue(json['loginUrl']),
      loginUi: _stringValue(json['loginUi']),
      loginCheckJs: _stringValue(json['loginCheckJs']),
      coverDecodeJs: _stringValue(json['coverDecodeJs']),
      jsLib: _stringValue(json['jsLib']),
      concurrentRate: _stringValue(json['concurrentRate']),
      variableComment: _stringValue(json['variableComment']),
      exploreScreen: _stringValue(json['exploreScreen']),
      review: _parseRuleMap(json['ruleReview']),
      sourceType: _intValue(json['bookSourceType']) ?? 0,
      enabled: _boolValue(json['enabled']) ?? true,
      enabledExplore: _boolValue(json['enabledExplore']) ?? true,
      lastUpdateTime: _intValue(json['lastUpdateTime']),
      respondTime: _intValue(json['respondTime']),
      weight: _intValue(json['weight']),
      enabledCookieJar: _boolValue(json['enabledCookieJar']) ?? true,
      eventListener: _boolValue(json['eventListener']) ?? false,
      customButton: _boolValue(json['customButton']) ?? false,
    );
  }
}

class SearchRule {
  final String? searchUrl;
  final String? checkKeyWord;
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? lastChapter;
  final String? updateTime;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;
  final String? wordCount;
  final String? bookUrlPattern;

  const SearchRule({
    this.searchUrl,
    this.checkKeyWord,
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.intro,
    this.coverUrl,
    this.bookUrl,
    this.wordCount,
    this.bookUrlPattern,
  });

  factory SearchRule.fromJson(Map<String, dynamic> j, {String? searchUrl}) =>
      SearchRule(
        searchUrl: searchUrl,
        checkKeyWord: _stringValue(j['checkKeyWord']),
        bookList: _stringValue(j['bookList']),
        name: _stringValue(j['name']),
        author: _stringValue(j['author']),
        kind: _stringValue(j['kind']),
        lastChapter: _stringValue(j['lastChapter']),
        updateTime: _stringValue(j['updateTime']),
        intro: _stringValue(j['intro']),
        coverUrl: _stringValue(j['coverUrl']),
        bookUrl: _stringValue(j['bookUrl']),
        wordCount: _stringValue(j['wordCount']),
        bookUrlPattern: _stringValue(j['bookUrlPattern']),
      );
}

class BookInfoRule {
  final String? init;
  final String? name;
  final String? author;
  final String? kind;
  final String? lastChapter;
  final String? updateTime;
  final String? intro;
  final String? coverUrl;
  final String? tocUrl;
  final String? wordCount;
  final String? canReName;
  final String? downloadUrls;

  const BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.intro,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
    this.canReName,
    this.downloadUrls,
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> j) => BookInfoRule(
        init: _stringValue(j['init']),
        name: _stringValue(j['name']),
        author: _stringValue(j['author']),
        kind: _stringValue(j['kind']),
        lastChapter: _stringValue(j['lastChapter']),
        updateTime: _stringValue(j['updateTime']),
        intro: _stringValue(j['intro']),
        coverUrl: _stringValue(j['coverUrl']),
        tocUrl: _stringValue(j['tocUrl']),
        wordCount: _stringValue(j['wordCount']),
        canReName: _stringValue(j['canReName']),
        downloadUrls: _stringValue(j['downloadUrls']),
      );
}

class TocRule {
  final String? preUpdateJs;
  final String? chapterList;
  final String? chapterName;
  final String? chapterUrl;
  final String? formatJs;
  final String? nextTocUrl;
  final String? isVolume;
  final String? isVip;
  final String? isPay;
  final String? updateTime;

  const TocRule({
    this.preUpdateJs,
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.formatJs,
    this.nextTocUrl,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
  });

  factory TocRule.fromJson(Map<String, dynamic> j) => TocRule(
        preUpdateJs: _stringValue(j['preUpdateJs']),
        chapterList: _stringValue(j['chapterList']),
        chapterName: _stringValue(j['chapterName']),
        chapterUrl: _stringValue(j['chapterUrl']),
        formatJs: _stringValue(j['formatJs']),
        nextTocUrl: _stringValue(j['nextTocUrl']),
        isVolume: _stringValue(j['isVolume']),
        isVip: _stringValue(j['isVip']),
        isPay: _stringValue(j['isPay']),
        updateTime: _stringValue(j['updateTime']),
      );
}

class ContentRule {
  final String? content;
  final String? subContent;
  final String? nextContentUrl;
  final String? replaceRegex;
  final String? title;
  final String? webJs;
  final String? sourceRegex;
  final String? bodyJs;
  final String? imageStyle;
  final String? imageDecode;
  final String? payAction;
  final String? callBackJs;

  const ContentRule({
    this.content,
    this.subContent,
    this.nextContentUrl,
    this.replaceRegex,
    this.title,
    this.webJs,
    this.sourceRegex,
    this.bodyJs,
    this.imageStyle,
    this.imageDecode,
    this.payAction,
    this.callBackJs,
  });

  factory ContentRule.fromJson(Map<String, dynamic> j) => ContentRule(
        content: _stringValue(j['content']),
        subContent: _stringValue(j['subContent']),
        nextContentUrl: _stringValue(j['nextContentUrl']),
        replaceRegex: _stringValue(j['replaceRegex']),
        title: _stringValue(j['title']),
        webJs: _stringValue(j['webJs']),
        sourceRegex: _stringValue(j['sourceRegex']),
        bodyJs: _stringValue(j['bodyJs']),
        imageStyle: _stringValue(j['imageStyle']),
        imageDecode: _stringValue(j['imageDecode']),
        payAction: _stringValue(j['payAction']),
        callBackJs: _stringValue(j['callBackJs']),
      );
}

class ExploreRule {
  final String? exploreUrl;
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? lastChapter;
  final String? updateTime;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;
  final String? wordCount;

  const ExploreRule({
    this.exploreUrl,
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.intro,
    this.coverUrl,
    this.bookUrl,
    this.wordCount,
  });

  factory ExploreRule.fromJson(Map<String, dynamic> j, {String? exploreUrl}) =>
      ExploreRule(
        exploreUrl: exploreUrl,
        bookList: _stringValue(j['bookList']),
        name: _stringValue(j['name']),
        author: _stringValue(j['author']),
        kind: _stringValue(j['kind']),
        lastChapter: _stringValue(j['lastChapter']),
        updateTime: _stringValue(j['updateTime']),
        intro: _stringValue(j['intro']),
        coverUrl: _stringValue(j['coverUrl']),
        bookUrl: _stringValue(j['bookUrl']),
        wordCount: _stringValue(j['wordCount']),
      );
}

Map<String, dynamic>? _parseRuleMap(Object? raw) {
  if (raw is Map) return raw.cast<String, dynamic>();
  if (raw is! String || raw.trim().isEmpty) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {
    return null;
  }
  return null;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String? _trimmedString(Object? value) {
  final text = _stringValue(value)?.trim();
  return text == null || text.isEmpty ? null : text;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return null;
}

class _ParsedHeader {
  const _ParsedHeader(this.headers, this.raw);

  final Map<String, String> headers;
  final String? raw;
}

_ParsedHeader _parseHeader(Object? raw) {
  if (raw == null) return const _ParsedHeader({}, null);
  if (raw is Map) return _ParsedHeader(_headersFromMap(raw), null);
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return const _ParsedHeader({}, null);
    if (_isDynamicHeader(text)) return _ParsedHeader(const {}, text);
    return _ParsedHeader(_headersFromString(text), text);
  }
  return const _ParsedHeader({}, null);
}

bool _isDynamicHeader(String text) {
  final lower = text.toLowerCase();
  return lower.startsWith('@js:') || lower.startsWith('<js>');
}

Map<String, String> _headersFromMap(Map raw) {
  final headers = <String, String>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value == null) continue;
    headers[entry.key.toString()] = value.toString();
  }
  return headers;
}

Map<String, String> _headersFromString(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const {};

  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) return _headersFromMap(decoded);
  } catch (_) {
    // Fall through to Legado's common single-quoted flat-object format.
  }

  return _headersFromFlatObjectString(text);
}

Map<String, String> _headersFromFlatObjectString(String text) {
  final objectMatch = RegExp(r'^\s*\{([\s\S]*)\}\s*$').firstMatch(text);
  if (objectMatch == null) return const {};

  final body = objectMatch.group(1) ?? '';
  final headers = <String, String>{};
  final pairPattern = RegExp(
    r'''["']([^"']+)["']\s*:\s*["']([^"']*)["']''',
  );
  for (final match in pairPattern.allMatches(body)) {
    final key = match.group(1)?.trim();
    if (key == null || key.isEmpty) continue;
    headers[key] = match.group(2) ?? '';
  }
  return headers;
}
