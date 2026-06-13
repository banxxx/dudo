import 'models/source_rule.dart';
import 'parsers/parser.dart';
import 'legado/legado_runtime.dart';

/// Façade for the rule engine. Plug parsers in at construction time and call
/// the high-level methods (`search`, `loadBookInfo`, `loadToc`, `loadContent`).
///
/// The concrete Legado-compatible behavior lives in [LegadoRuntime]; this class
/// stays as the stable API used by feature repositories.
class RuleEngine {
  RuleEngine._(this.registry, this._runtime);

  final ParserRegistry registry;
  final LegadoRuntime _runtime;

  static RuleEngine create() {
    final runtime = LegadoRuntime.create();
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
        ),
    ];
  }

  /// Validate a freshly-imported source. Returns a human-readable report.
  RuleValidationReport validate(SourceRule rule) {
    final issues = <String>[];
    if (rule.url.isEmpty) issues.add('source url is empty');
    if (rule.search?.searchUrl == null) {
      issues.add('searchUrl is missing — search will not work');
    }
    return RuleValidationReport(rule: rule, issues: issues);
  }
}

class SearchResult {
  final String name;
  final String author;
  final String? coverUrl;
  final String? bookUrl;
  final String? intro;
  const SearchResult({
    required this.name,
    required this.author,
    this.coverUrl,
    this.bookUrl,
    this.intro,
  });
}

class RuleValidationReport {
  final SourceRule rule;
  final List<String> issues;
  RuleValidationReport({required this.rule, required this.issues});
  bool get ok => issues.isEmpty;
}
