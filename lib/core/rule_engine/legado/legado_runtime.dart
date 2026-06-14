import '../models/source_rule.dart';
import '../parsers/default_html_rule_parser.dart';
import '../parsers/explicit_css_rule_parser.dart';
import '../parsers/js_rule_parser.dart';
import '../parsers/json_path_rule_parser.dart';
import '../parsers/parser.dart';
import '../parsers/regex_parser.dart';
import '../parsers/xpath_parser.dart';
import 'decode/response_decoder.dart';
import 'js/legado_js_engine.dart';
import 'legado_models.dart';
import 'pipeline/book_info_pipeline.dart';
import 'pipeline/content_pipeline.dart';
import 'pipeline/search_pipeline.dart';
import 'pipeline/toc_pipeline.dart';
import 'rule/analyze_rule.dart';
import 'url/analyze_url.dart';
import 'url/request_executor.dart';

class LegadoRuntime {
  LegadoRuntime({
    required this.registry,
    required this.searchPipeline,
    required this.bookInfoPipeline,
    required this.tocPipeline,
    required this.contentPipeline,
  });

  final ParserRegistry registry;
  final SearchPipeline searchPipeline;
  final BookInfoPipeline bookInfoPipeline;
  final TocPipeline tocPipeline;
  final ContentPipeline contentPipeline;

  factory LegadoRuntime.create({LegadoRequestExecutor? executor}) {
    final jsEngine = FlutterJsLegadoJsEngine();
    final registry = ParserRegistry()
      ..register(const DefaultHtmlRuleParser())
      ..register(const ExplicitCssRuleParser())
      ..register(const XPathParser())
      ..register(const JsonPathRuleParser())
      ..register(const RegexParser())
      ..register(JsRuleParser(jsEngine: jsEngine));
    final analyzeRule = AnalyzeRule(registry: registry, jsEngine: jsEngine);
    final requestExecutor = executor ?? const DioLegadoRequestExecutor();
    const analyzeUrl = AnalyzeUrl();
    return LegadoRuntime(
      registry: registry,
      searchPipeline: SearchPipeline(
        analyzeUrl: analyzeUrl,
        executor: requestExecutor,
        decoder: const ResponseDecoder(),
        analyzeRule: analyzeRule,
      ),
      bookInfoPipeline: BookInfoPipeline(
        analyzeUrl: analyzeUrl,
        executor: requestExecutor,
        decoder: const ResponseDecoder(),
        analyzeRule: analyzeRule,
      ),
      tocPipeline: TocPipeline(
        analyzeUrl: analyzeUrl,
        executor: requestExecutor,
        decoder: const ResponseDecoder(),
        analyzeRule: analyzeRule,
      ),
      contentPipeline: ContentPipeline(
        analyzeUrl: analyzeUrl,
        executor: requestExecutor,
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

  Future<LegadoBookInfo?> loadBookInfo(
    SourceRule source,
    String bookUrl,
  ) {
    return bookInfoPipeline.load(source, bookUrl);
  }

  Future<LegadoTocResult?> loadToc(
    SourceRule source,
    String tocUrl,
  ) {
    return tocPipeline.load(source, tocUrl);
  }

  Future<LegadoContentResult?> loadContent(
    SourceRule source,
    String contentUrl,
  ) {
    return contentPipeline.load(source, contentUrl);
  }
}
