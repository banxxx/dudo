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
      group: json['bookSourceGroup'] as String?,
      comment: json['bookSourceComment'] as String?,
      search: json['ruleSearch'] is Map
          ? SearchRule.fromJson(
              (json['ruleSearch'] as Map).cast<String, dynamic>(),
              searchUrl: json['searchUrl'] as String?,
            )
          : null,
      bookInfo: json['ruleBookInfo'] is Map
          ? BookInfoRule.fromJson(
              (json['ruleBookInfo'] as Map).cast<String, dynamic>(),
            )
          : null,
      toc: json['ruleToc'] is Map
          ? TocRule.fromJson(
              (json['ruleToc'] as Map).cast<String, dynamic>(),
            )
          : null,
      content: json['ruleContent'] is Map
          ? ContentRule.fromJson(
              (json['ruleContent'] as Map).cast<String, dynamic>(),
            )
          : null,
      explore: json['ruleExplore'] is Map
          ? ExploreRule.fromJson(
              (json['ruleExplore'] as Map).cast<String, dynamic>(),
              exploreUrl: json['exploreUrl'] as String?,
            )
          : null,
      headers: ((json['header'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
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
  });

  factory SearchRule.fromJson(Map<String, dynamic> j, {String? searchUrl}) =>
      SearchRule(
        searchUrl: searchUrl,
        bookList: j['bookList'] as String?,
        name: j['name'] as String?,
        author: j['author'] as String?,
        kind: j['kind'] as String?,
        lastChapter: j['lastChapter'] as String?,
        intro: j['intro'] as String?,
        coverUrl: j['coverUrl'] as String?,
        bookUrl: j['bookUrl'] as String?,
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

  const BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.kind,
    this.lastChapter,
    this.intro,
    this.coverUrl,
    this.tocUrl,
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

  const TocRule({
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.nextTocUrl,
    this.isVolume,
    this.isVip,
    this.isPay,
  });

  factory TocRule.fromJson(Map<String, dynamic> j) => TocRule(
        chapterList: j['chapterList'] as String?,
        chapterName: j['chapterName'] as String?,
        chapterUrl: j['chapterUrl'] as String?,
        nextTocUrl: j['nextTocUrl'] as String?,
        isVolume: j['isVolume'] as String?,
        isVip: j['isVip'] as String?,
        isPay: j['isPay'] as String?,
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
