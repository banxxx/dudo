import '../models/source_rule.dart';
import '../parsers/default_html_rule_parser.dart';
import '../parsers/explicit_css_rule_parser.dart';
import '../parsers/json_path_rule_parser.dart';
import '../parsers/parser.dart';
import '../parsers/regex_parser.dart';
import '../parsers/xpath_parser.dart';
import 'decode/response_decoder.dart';
import 'legado_models.dart';
import 'pipeline/search_pipeline.dart';
import 'rule/analyze_rule.dart';
import 'url/analyze_url.dart';
import 'url/request_executor.dart';

class LegadoRuntime {
  LegadoRuntime({
    required this.registry,
    required this.searchPipeline,
  });

  final ParserRegistry registry;
  final SearchPipeline searchPipeline;

  factory LegadoRuntime.create({LegadoRequestExecutor? executor}) {
    final registry = ParserRegistry()
      ..register(const DefaultHtmlRuleParser())
      ..register(const ExplicitCssRuleParser())
      ..register(const XPathParser())
      ..register(const JsonPathRuleParser())
      ..register(const RegexParser());
    final analyzeRule = AnalyzeRule(registry: registry);
    return LegadoRuntime(
      registry: registry,
      searchPipeline: SearchPipeline(
        analyzeUrl: const AnalyzeUrl(),
        executor: executor ?? const DioLegadoRequestExecutor(),
        decoder: const ResponseDecoder(),
        analyzeRule: analyzeRule,
      ),
    );
  }

  Future<List<LegadoSearchItem>> search(
    SourceRule source,
    String keyword,
  ) {
    return searchPipeline.search(source, keyword);
  }
}
