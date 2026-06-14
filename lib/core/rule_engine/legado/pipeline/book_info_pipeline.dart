import '../../models/source_rule.dart';
import '../decode/response_decoder.dart';
import '../legado_models.dart';
import '../rule/analyze_rule.dart';
import '../rule/rule_context.dart';
import '../rule/rule_value.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import 'java_ajax.dart';
import 'pipeline_trace.dart';

class BookInfoPipeline {
  const BookInfoPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;

  Future<LegadoBookInfo?> load(
    SourceRule source,
    String bookUrl,
  ) async {
    final rule = source.bookInfo;
    if (rule == null || bookUrl.trim().isEmpty) return null;

    final trace = LegadoTrace();
    final request = await analyzeUrl.compileSearchAsync(
      source: source,
      rawUrl: bookUrl,
      keyword: '',
      ajax: createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: source,
        trace: trace,
      ),
    );
    recordUnsupportedUrlOptionTrace(request, trace, stage: 'bookInfo');
    recordLegadoRequestTrace(request, trace, stage: 'bookInfo');
    final response = await executor.execute(request);
    recordLegadoResponseTrace(response, trace, stage: 'bookInfo');
    final decoded = await decoder.decode(
      bytes: response.bytes,
      finalUri: response.finalUri,
      headers: response.headers,
      statusCode: response.statusCode,
      explicitCharset: request.charset,
      trace: trace,
    );
    final baseUrl = decoded.finalUri.toString();
    final context = RuleContext(
      source: source,
      trace: trace,
      input: RuleInput(
        rawText: decoded.text,
        baseUri: Uri.parse(source.url),
        redirectUri: decoded.finalUri,
      ),
    );
    final root = _initRoot(decoded.text, rule.init, context);

    return LegadoBookInfo(
      name: analyzeRule.fieldString(root, rule.name, context) ?? '',
      author: analyzeRule.fieldString(root, rule.author, context) ?? '',
      kind: analyzeRule.fieldString(root, rule.kind, context),
      lastChapter: analyzeRule.fieldString(root, rule.lastChapter, context),
      intro: analyzeRule.fieldString(root, rule.intro, context),
      coverUrl: analyzeRule.absoluteUrl(
        analyzeRule.fieldString(root, rule.coverUrl, context),
        baseUrl,
      ),
      tocUrl: analyzeRule.absoluteUrl(
        analyzeRule.fieldString(root, rule.tocUrl, context),
        baseUrl,
      ),
      wordCount: analyzeRule.fieldString(root, rule.wordCount, context),
    );
  }

  Object _initRoot(String decodedText, String? initRule, RuleContext context) {
    final nodes = analyzeRule.elements(decodedText, initRule, context);
    return nodes.isEmpty ? decodedText : nodes.first;
  }
}
