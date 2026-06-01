import 'dart:convert';

import '../exceptions/exception_mapper.dart';
import '../network/http_client.dart';
import 'models/rule_chain.dart';
import 'models/source_rule.dart';
import 'parsers/css_parser.dart';
import 'parsers/jsonpath_parser.dart';
import 'parsers/parser.dart';
import 'parsers/regex_parser.dart';
import 'parsers/xpath_parser.dart';

/// Façade for the rule engine. Plug parsers in at construction time and call
/// the high-level methods (`search`, `loadBookInfo`, `loadToc`, `loadContent`).
///
/// The methods below are intentionally light skeletons — they describe the
/// shape that callers can program against today, while the parser
/// implementations grow.
class RuleEngine {
  RuleEngine._(this.registry);

  final ParserRegistry registry;

  static RuleEngine create() {
    final reg = ParserRegistry()
      ..register(CssParser())
      ..register(XPathParser())
      ..register(JsonPathParser())
      ..register(RegexParser());
    return RuleEngine._(reg);
  }

  Future<List<SearchResult>> search(
    SourceRule source,
    String keyword,
  ) async {
    final search = source.search;
    final url = search?.searchUrl;
    if (url == null) return const [];
    final filled = url.replaceAll('{{key}}', Uri.encodeQueryComponent(keyword));
    try {
      final res = await HttpClient.instance.dio.get<List<int>>(filled);
      final body = utf8.decode(res.data ?? const []);
      final list = _list(body, search?.bookList);
      return [
        for (final node in list)
          SearchResult(
            name: _string(node, search?.name) ?? '',
            author: _string(node, search?.author) ?? '',
            coverUrl: _string(node, search?.coverUrl),
            bookUrl: _string(node, search?.bookUrl),
            intro: _string(node, search?.intro),
          ),
      ];
    } catch (e, st) {
      throw ExceptionMapper.map(e, st);
    }
  }

  String? _string(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return null;
    final chain = RuleChain.parse(rawRule);
    final type =
        chain.segments.isEmpty ? RuleType.css : chain.segments.first.type;
    final parser = registry.forType(type);
    return parser?.parseString(source, chain);
  }

  List<Object> _list(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return const <Object>[];
    final chain = RuleChain.parse(rawRule);
    final type =
        chain.segments.isEmpty ? RuleType.css : chain.segments.first.type;
    final parser = registry.forType(type);
    return parser?.parseElements(source, chain) ?? const <Object>[];
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
