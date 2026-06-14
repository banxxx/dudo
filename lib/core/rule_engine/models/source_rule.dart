import 'dart:convert';

/// Source-rule data model — mirrors the Legado 3.0 JSON shape but is
/// intentionally permissive so we can evolve.
class SourceRule {
  final String id;
  final String name;
  final String url;
  final String? group;
  final String? comment;
  final SearchRule? search;
  final BookInfoRule? bookInfo;
  final TocRule? toc;
  final ContentRule? content;
  final ExploreRule? explore;
  final Map<String, String> headers;
  final String? loginUrl;

  const SourceRule({
    required this.id,
    required this.name,
    required this.url,
    this.group,
    this.comment,
    this.search,
    this.bookInfo,
    this.toc,
    this.content,
    this.explore,
    this.headers = const {},
    this.loginUrl,
  });

  factory SourceRule.fromJson(Map<String, dynamic> json) {
    return SourceRule(
      id: (json['bookSourceUrl'] ?? json['id'] ?? '').toString(),
      name: (json['bookSourceName'] ?? json['name'] ?? '').toString(),
      url: (json['bookSourceUrl'] ?? json['url'] ?? '').toString(),
      group: _stringValue(json['bookSourceGroup']),
      comment: _stringValue(json['bookSourceComment']),
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
      headers: _parseHeaders(json['header']),
      loginUrl: json['loginUrl'] as String?,
    );
  }
}

class SearchRule {
  final String? searchUrl;
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? lastChapter;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;
  final String? bookUrlPattern;

  const SearchRule({
    this.searchUrl,
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.intro,
    this.coverUrl,
    this.bookUrl,
    this.bookUrlPattern,
  });

  factory SearchRule.fromJson(Map<String, dynamic> j, {String? searchUrl}) =>
      SearchRule(
        searchUrl: searchUrl,
        bookList: _stringValue(j['bookList']),
        name: _stringValue(j['name']),
        author: _stringValue(j['author']),
        kind: _stringValue(j['kind']),
        lastChapter: _stringValue(j['lastChapter']),
        intro: _stringValue(j['intro']),
        coverUrl: _stringValue(j['coverUrl']),
        bookUrl: _stringValue(j['bookUrl']),
        bookUrlPattern: _stringValue(j['bookUrlPattern']),
      );
}

class BookInfoRule {
  final String? init;
  final String? name;
  final String? author;
  final String? kind;
  final String? lastChapter;
  final String? intro;
  final String? coverUrl;
  final String? tocUrl;
  final String? wordCount;

  const BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.intro,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> j) => BookInfoRule(
        init: j['init'] as String?,
        name: j['name'] as String?,
        author: j['author'] as String?,
        kind: j['kind'] as String?,
        lastChapter: j['lastChapter'] as String?,
        intro: j['intro'] as String?,
        coverUrl: j['coverUrl'] as String?,
        tocUrl: j['tocUrl'] as String?,
        wordCount: _stringValue(j['wordCount']),
      );
}

class TocRule {
  final String? chapterList;
  final String? chapterName;
  final String? chapterUrl;
  final String? nextTocUrl;
  final String? isVolume;
  final String? isVip;
  final String? isPay;
  final String? updateTime;

  const TocRule({
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.nextTocUrl,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
  });

  factory TocRule.fromJson(Map<String, dynamic> j) => TocRule(
        chapterList: j['chapterList'] as String?,
        chapterName: j['chapterName'] as String?,
        chapterUrl: j['chapterUrl'] as String?,
        nextTocUrl: j['nextTocUrl'] as String?,
        isVolume: j['isVolume'] as String?,
        isVip: j['isVip'] as String?,
        isPay: j['isPay'] as String?,
        updateTime: j['updateTime'] as String?,
      );
}

class ContentRule {
  final String? content;
  final String? nextContentUrl;
  final String? replaceRegex;
  final String? title;

  const ContentRule({
    this.content,
    this.nextContentUrl,
    this.replaceRegex,
    this.title,
  });

  factory ContentRule.fromJson(Map<String, dynamic> j) => ContentRule(
        content: j['content'] as String?,
        nextContentUrl: j['nextContentUrl'] as String?,
        replaceRegex: j['replaceRegex'] as String?,
        title: j['title'] as String?,
      );
}

class ExploreRule {
  final String? exploreUrl;
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? intro;
  final String? coverUrl;
  final String? bookUrl;

  const ExploreRule({
    this.exploreUrl,
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.intro,
    this.coverUrl,
    this.bookUrl,
  });

  factory ExploreRule.fromJson(Map<String, dynamic> j, {String? exploreUrl}) =>
      ExploreRule(
        exploreUrl: exploreUrl,
        bookList: j['bookList'] as String?,
        name: j['name'] as String?,
        author: j['author'] as String?,
        kind: j['kind'] as String?,
        intro: j['intro'] as String?,
        coverUrl: j['coverUrl'] as String?,
        bookUrl: j['bookUrl'] as String?,
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

Map<String, String> _parseHeaders(Object? raw) {
  if (raw == null) return const {};
  if (raw is Map) return _headersFromMap(raw);
  if (raw is String) return _headersFromString(raw);
  return const {};
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
