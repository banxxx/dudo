import '../../models/source_rule.dart';
import '../decode/response_decoder.dart';
import '../js/legado_js_engine.dart';
import '../rule/rule_context.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import 'pipeline_trace.dart';

LegadoJsAjax createLegadoJavaAjax({
  required AnalyzeUrl analyzeUrl,
  required LegadoRequestExecutor executor,
  required ResponseDecoder decoder,
  required SourceRule source,
  required LegadoTrace trace,
  String keyword = '',
  int page = 1,
  int depth = 0,
  int maxDepth = 4,
}) {
  return (rawUrl) async {
    if (depth >= maxDepth) {
      throw StateError('java.ajax exceeded max depth $maxDepth');
    }

    final request = await analyzeUrl.compileSearchAsync(
      source: source,
      rawUrl: rawUrl,
      keyword: keyword,
      page: page,
      ajax: createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: source,
        trace: trace,
        keyword: keyword,
        page: page,
        depth: depth + 1,
        maxDepth: maxDepth,
      ),
    );
    trace.add('java.ajax:${request.method}:${request.url}');
    recordUnsupportedUrlOptionTrace(request, trace, stage: 'java.ajax');
    recordLegadoRequestTrace(request, trace, stage: 'java.ajax');

    final response = await executor.execute(request);
    recordLegadoResponseTrace(response, trace, stage: 'java.ajax');
    final decoded = await decoder.decode(
      bytes: response.bytes,
      finalUri: response.finalUri,
      headers: response.headers,
      statusCode: response.statusCode,
      explicitCharset: request.charset,
      trace: trace,
    );
    return decoded.text;
  };
}
