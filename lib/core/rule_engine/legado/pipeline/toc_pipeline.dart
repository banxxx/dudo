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

class TocPipeline {
  const TocPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;

  Future<LegadoTocResult?> load(
    SourceRule source,
    String tocUrl,
  ) async {
    final rule = source.toc;
    if (rule == null || tocUrl.trim().isEmpty) return null;

    final trace = LegadoTrace();
    final request = await analyzeUrl.compileSearchAsync(
      source: source,
      rawUrl: tocUrl,
      keyword: '',
      ajax: createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: source,
        trace: trace,
      ),
    );
    recordUnsupportedUrlOptionTrace(request, trace, stage: 'toc');
    recordLegadoRequestTrace(request, trace, stage: 'toc');
    final response = await executor.execute(request);
    recordLegadoResponseTrace(response, trace, stage: 'toc');
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
    final list = analyzeRule.elements(decoded.text, rule.chapterList, context);

    return LegadoTocResult(
      chapters: [
        for (final node in list)
          LegadoTocChapter(
            name:
                analyzeRule.fieldString(node, rule.chapterName, context) ?? '',
            url: analyzeRule.absoluteUrl(
              analyzeRule.fieldString(node, rule.chapterUrl, context),
              baseUrl,
            ),
            isVolume: analyzeRule.fieldString(node, rule.isVolume, context),
            isVip: analyzeRule.fieldString(node, rule.isVip, context),
            isPay: analyzeRule.fieldString(node, rule.isPay, context),
            updateTime: analyzeRule.fieldString(node, rule.updateTime, context),
          ),
      ],
      nextTocUrl: analyzeRule.absoluteUrl(
        analyzeRule.fieldString(decoded.text, rule.nextTocUrl, context),
        baseUrl,
      ),
    );
  }
}
