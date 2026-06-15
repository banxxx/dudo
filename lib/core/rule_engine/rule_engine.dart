import 'models/source_rule.dart';
import 'parsers/parser.dart';
import 'legado/legado_runtime.dart';
import 'legado/rule/rule_ast.dart';
import 'legado/url/request_executor.dart';

/// Façade for the rule engine. Plug parsers in at construction time and call
/// the high-level methods (`search`, `loadBookInfo`, `loadToc`, `loadContent`).
///
/// The concrete Legado-compatible behavior lives in [LegadoRuntime]; this class
/// stays as the stable API used by feature repositories.
class RuleEngine {
  RuleEngine._(this.registry, this._runtime);

  final ParserRegistry registry;
  final LegadoRuntime _runtime;

  static RuleEngine create({LegadoRequestExecutor? executor}) {
    final runtime = LegadoRuntime.create(executor: executor);
    return RuleEngine._(runtime.registry, runtime);
  }

  Future<List<SearchResult>> search(
    SourceRule source,
    String keyword,
  ) async {
    final items = await _runtime.search(source, keyword);
    return [
      for (final item in items)
        SearchResult(
          name: item.name,
          author: item.author,
          coverUrl: item.coverUrl,
          bookUrl: item.bookUrl,
          intro: item.intro,
          kind: item.kind,
          lastChapter: item.lastChapter,
          wordCount: item.wordCount,
        ),
    ];
  }

  Future<BookInfoResult?> loadBookInfo(
    SourceRule source,
    String bookUrl, {
    Object? book,
  }) async {
    final info = await _runtime.loadBookInfo(source, bookUrl, book: book);
    if (info == null) return null;
    return BookInfoResult(
      name: info.name,
      author: info.author,
      kind: info.kind,
      lastChapter: info.lastChapter,
      intro: info.intro,
      coverUrl: info.coverUrl,
      tocUrl: info.tocUrl,
      wordCount: info.wordCount,
    );
  }

  Future<TocResult?> loadToc(
    SourceRule source,
    String tocUrl, {
    Object? book,
  }) async {
    final toc = await _runtime.loadToc(source, tocUrl, book: book);
    if (toc == null) return null;
    return TocResult(
      chapters: [
        for (final chapter in toc.chapters)
          TocChapterResult(
            name: chapter.name,
            url: chapter.url,
            isVolume: chapter.isVolume,
            isVip: chapter.isVip,
            isPay: chapter.isPay,
            updateTime: chapter.updateTime,
          ),
      ],
      nextTocUrl: toc.nextTocUrl,
      totalCount: toc.totalCount,
    );
  }

  Future<ContentResult?> loadContent(
    SourceRule source,
    String contentUrl,
  ) async {
    final content = await _runtime.loadContent(source, contentUrl);
    if (content == null) return null;
    return ContentResult(
      title: content.title,
      content: content.content,
      nextContentUrl: content.nextContentUrl,
    );
  }

  /// Validate a freshly-imported source. Returns a human-readable report.
  RuleValidationReport validate(SourceRule rule) {
    final diagnostics = <SourceCompatibilityDiagnostic>[];

    void add(
      SourceCompatibilitySeverity severity,
      String code,
      String path,
      String message,
    ) {
      diagnostics.add(
        SourceCompatibilityDiagnostic(
          severity: severity,
          code: code,
          path: path,
          message: message,
        ),
      );
    }

    final sourceUrl = rule.url.trim();
    if (sourceUrl.isEmpty) {
      add(
        SourceCompatibilitySeverity.error,
        'source-url-empty',
        'bookSourceUrl',
        'source url is empty',
      );
    } else {
      final parsed = Uri.tryParse(sourceUrl);
      if (parsed == null || !parsed.hasScheme) {
        add(
          SourceCompatibilitySeverity.warning,
          'source-url-not-absolute',
          'bookSourceUrl',
          'source url should be absolute for relative URL resolution',
        );
      }
    }

    final search = rule.search;
    if (search == null || _blank(search.searchUrl)) {
      add(
        SourceCompatibilitySeverity.error,
        'search-url-missing',
        'searchUrl',
        'searchUrl is missing; search will not work',
      );
    } else {
      _diagnoseUrlOptions(search.searchUrl!, 'searchUrl', add);
      if (_blank(search.bookList)) {
        add(
          SourceCompatibilitySeverity.warning,
          'search-book-list-missing',
          'ruleSearch.bookList',
          'bookList is missing; detail-page fallback is not implemented yet',
        );
      }
      if (_blank(search.name)) {
        add(
          SourceCompatibilitySeverity.warning,
          'search-name-missing',
          'ruleSearch.name',
          'name is missing; search results may be empty or unusable',
        );
      }
      if (_blank(search.bookUrl)) {
        add(
          SourceCompatibilitySeverity.warning,
          'search-book-url-missing',
          'ruleSearch.bookUrl',
          'bookUrl is missing; search results cannot open book details',
        );
      }
    }

    if (rule.bookInfo == null) {
      add(
        SourceCompatibilitySeverity.info,
        'book-info-missing',
        'ruleBookInfo',
        'book info pipeline cannot run without ruleBookInfo',
      );
    }
    if (rule.toc == null) {
      add(
        SourceCompatibilitySeverity.info,
        'toc-missing',
        'ruleToc',
        'toc pipeline cannot run without ruleToc',
      );
    }
    if (rule.content == null) {
      add(
        SourceCompatibilitySeverity.info,
        'content-missing',
        'ruleContent',
        'content pipeline cannot run without ruleContent',
      );
    }

    for (final field in _ruleFields(rule)) {
      _diagnoseRule(field.value, field.path, add);
    }

    return RuleValidationReport(
      rule: rule,
      diagnostics: diagnostics,
      issues: diagnostics
          .where((diagnostic) => diagnostic.severity.isError)
          .map((diagnostic) => diagnostic.message)
          .toList(growable: false),
    );
  }

  bool _blank(String? value) => value == null || value.trim().isEmpty;

  void _diagnoseUrlOptions(
    String rawUrl,
    String path,
    void Function(
      SourceCompatibilitySeverity severity,
      String code,
      String path,
      String message,
    ) add,
  ) {
    final lower = rawUrl.toLowerCase();
    if (lower.contains('bodyjs')) {
      add(
        SourceCompatibilitySeverity.warning,
        'url-body-js-unsupported',
        path,
        'bodyJs is parsed for diagnostics but WebView execution is not implemented',
      );
    }
    if (lower.contains('webjs')) {
      add(
        SourceCompatibilitySeverity.warning,
        'url-web-js-unsupported',
        path,
        'webJs is parsed for diagnostics but WebView execution is not implemented',
      );
    }
    if (lower.contains('webview')) {
      add(
        SourceCompatibilitySeverity.warning,
        'url-web-view-unsupported',
        path,
        'WebView request mode is not implemented',
      );
    }
  }

  void _diagnoseRule(
    String rawRule,
    String path,
    void Function(
      SourceCompatibilitySeverity severity,
      String code,
      String path,
      String message,
    ) add,
  ) {
    final text = rawRule.trim();
    if (text.isEmpty) return;

    if (RegExp(r'\{\{[\s\S]+?\}\}').hasMatch(text)) {
      add(
        SourceCompatibilitySeverity.warning,
        'rule-dynamic-placeholder-unsupported',
        path,
        'dynamic rule placeholders are not implemented yet',
      );
    }

    final ast = const LegadoRuleAstParser().parse(text);
    final steps = _steps(ast).toList(growable: false);
    final hasRegexStep = steps.any((step) => step.mode == LegadoRuleMode.regex);
    if (!hasRegexStep && RegExp(r'\$[1-9]').hasMatch(text)) {
      add(
        SourceCompatibilitySeverity.warning,
        'rule-regex-capture-reference-unsupported',
        path,
        'regex capture references are not implemented yet',
      );
    }

    for (final step in steps) {
      switch (step.mode) {
        case LegadoRuleMode.css:
        case LegadoRuleMode.xpath:
          break;
        case LegadoRuleMode.js:
          break;
        case LegadoRuleMode.regex:
          add(
            SourceCompatibilitySeverity.warning,
            'rule-regex-partial',
            path,
            'regex rule support is partial and replacement pipelines are not implemented yet',
          );
        case LegadoRuleMode.jsonPath:
        case LegadoRuleMode.defaultHtml:
          break;
      }
    }
  }

  Iterable<LegadoRuleStep> _steps(LegadoRuleAst ast) sync* {
    switch (ast) {
      case LegadoFallbackRule(:final alternatives):
        for (final alternative in alternatives) {
          yield* _steps(alternative);
        }
      case LegadoAppendRule(:final parts):
        for (final part in parts) {
          yield* _steps(part);
        }
      case LegadoInterleaveRule(:final parts):
        for (final part in parts) {
          yield* _steps(part);
        }
      case LegadoPipelineRule(:final steps):
        yield* steps;
    }
  }

  Iterable<_RuleField> _ruleFields(SourceRule rule) sync* {
    final search = rule.search;
    if (search != null) {
      yield _RuleField('ruleSearch.bookList', search.bookList);
      yield _RuleField('ruleSearch.name', search.name);
      yield _RuleField('ruleSearch.author', search.author);
      yield _RuleField('ruleSearch.kind', search.kind);
      yield _RuleField('ruleSearch.lastChapter', search.lastChapter);
      yield _RuleField('ruleSearch.intro', search.intro);
      yield _RuleField('ruleSearch.coverUrl', search.coverUrl);
      yield _RuleField('ruleSearch.bookUrl', search.bookUrl);
    }

    final bookInfo = rule.bookInfo;
    if (bookInfo != null) {
      yield _RuleField('ruleBookInfo.init', bookInfo.init);
      yield _RuleField('ruleBookInfo.name', bookInfo.name);
      yield _RuleField('ruleBookInfo.author', bookInfo.author);
      yield _RuleField('ruleBookInfo.kind', bookInfo.kind);
      yield _RuleField('ruleBookInfo.lastChapter', bookInfo.lastChapter);
      yield _RuleField('ruleBookInfo.intro', bookInfo.intro);
      yield _RuleField('ruleBookInfo.coverUrl', bookInfo.coverUrl);
      yield _RuleField('ruleBookInfo.tocUrl', bookInfo.tocUrl);
      yield _RuleField('ruleBookInfo.wordCount', bookInfo.wordCount);
    }

    final toc = rule.toc;
    if (toc != null) {
      yield _RuleField('ruleToc.chapterList', toc.chapterList);
      yield _RuleField('ruleToc.chapterName', toc.chapterName);
      yield _RuleField('ruleToc.chapterUrl', toc.chapterUrl);
      yield _RuleField('ruleToc.nextTocUrl', toc.nextTocUrl);
      yield _RuleField('ruleToc.isVolume', toc.isVolume);
      yield _RuleField('ruleToc.isVip', toc.isVip);
      yield _RuleField('ruleToc.isPay', toc.isPay);
      yield _RuleField('ruleToc.updateTime', toc.updateTime);
    }

    final content = rule.content;
    if (content != null) {
      yield _RuleField('ruleContent.content', content.content);
      yield _RuleField('ruleContent.nextContentUrl', content.nextContentUrl);
      yield _RuleField('ruleContent.replaceRegex', content.replaceRegex);
      yield _RuleField('ruleContent.title', content.title);
    }

    final explore = rule.explore;
    if (explore != null) {
      yield _RuleField('ruleExplore.bookList', explore.bookList);
      yield _RuleField('ruleExplore.name', explore.name);
      yield _RuleField('ruleExplore.author', explore.author);
      yield _RuleField('ruleExplore.kind', explore.kind);
      yield _RuleField('ruleExplore.intro', explore.intro);
      yield _RuleField('ruleExplore.coverUrl', explore.coverUrl);
      yield _RuleField('ruleExplore.bookUrl', explore.bookUrl);
    }
  }
}

class SearchResult {
  final String name;
  final String author;
  final String? coverUrl;
  final String? bookUrl;
  final String? intro;
  final String? kind;
  final String? lastChapter;
  final String? wordCount;
  const SearchResult({
    required this.name,
    required this.author,
    this.coverUrl,
    this.bookUrl,
    this.intro,
    this.kind,
    this.lastChapter,
    this.wordCount,
  });
}

class BookInfoResult {
  const BookInfoResult({
    required this.name,
    required this.author,
    this.kind,
    this.lastChapter,
    this.intro,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
  });

  final String name;
  final String author;
  final String? kind;
  final String? lastChapter;
  final String? intro;
  final String? coverUrl;
  final String? tocUrl;
  final String? wordCount;
}

class TocChapterResult {
  const TocChapterResult({
    required this.name,
    this.url,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
  });

  final String name;
  final String? url;
  final String? isVolume;
  final String? isVip;
  final String? isPay;
  final String? updateTime;
}

class TocResult {
  const TocResult({
    required this.chapters,
    this.nextTocUrl,
    this.totalCount,
  });

  final List<TocChapterResult> chapters;
  final String? nextTocUrl;
  final int? totalCount;
}

class ContentResult {
  const ContentResult({
    required this.title,
    required this.content,
    this.nextContentUrl,
  });

  final String title;
  final String content;
  final String? nextContentUrl;
}

class RuleValidationReport {
  final SourceRule rule;
  final List<String> issues;
  final List<SourceCompatibilityDiagnostic> diagnostics;
  RuleValidationReport({
    required this.rule,
    required this.issues,
    this.diagnostics = const [],
  });
  bool get ok => issues.isEmpty;
}

class SourceCompatibilityDiagnostic {
  const SourceCompatibilityDiagnostic({
    required this.severity,
    required this.code,
    required this.path,
    required this.message,
  });

  final SourceCompatibilitySeverity severity;
  final String code;
  final String path;
  final String message;
}

enum SourceCompatibilitySeverity {
  info,
  warning,
  error;

  bool get isError => this == SourceCompatibilitySeverity.error;
}

class _RuleField {
  const _RuleField(this.path, String? value) : value = value ?? '';

  final String path;
  final String value;
}
