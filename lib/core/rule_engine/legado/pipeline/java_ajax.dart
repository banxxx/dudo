import '../../models/source_rule.dart';
import '../decode/response_decoder.dart';
import '../js/legado_js_engine.dart';
import '../runtime/legado_runtime_context.dart';
import '../rule/rule_context.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import '../webview/legado_webview_executor.dart';
import 'pipeline_trace.dart';
import 'response_transformer.dart';

LegadoJsAjax createLegadoJavaAjax({
  required AnalyzeUrl analyzeUrl,
  required LegadoRequestExecutor executor,
  required ResponseDecoder decoder,
  SourceRule? source,
  LegadoTrace? trace,
  LegadoRuntimeContext? runtimeContext,
  String keyword = '',
  int page = 1,
  Map<String, Object?>? variables,
  int depth = 0,
  int maxDepth = 4,
  LegadoResponseTransformer responseTransformer =
      const LegadoResponseTransformer(),
  LegadoWebViewExecutor webViewExecutor =
      const UnsupportedLegadoWebViewExecutor(),
}) {
  final effectiveSource = source ?? runtimeContext?.source;
  if (effectiveSource == null) {
    throw ArgumentError('source or runtimeContext is required');
  }
  final effectiveTrace = trace ?? runtimeContext?.trace ?? LegadoTrace();
  final effectiveKeyword = runtimeContext?.keyword ?? keyword;
  final effectivePage = runtimeContext?.page ?? page;
  final sharedVariables =
      variables ?? runtimeContext?.variables.asMap() ?? <String, Object?>{};
  return (rawUrl) async {
    if (depth >= maxDepth) {
      throw StateError('java.ajax exceeded max depth $maxDepth');
    }

    final request = await analyzeUrl.compileSearchAsync(
      source: effectiveSource,
      rawUrl: rawUrl,
      keyword: effectiveKeyword,
      page: effectivePage,
      ajax: createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: effectiveSource,
        trace: effectiveTrace,
        keyword: effectiveKeyword,
        page: effectivePage,
        variables: sharedVariables,
        depth: depth + 1,
        maxDepth: maxDepth,
        responseTransformer: responseTransformer,
        webViewExecutor: webViewExecutor,
      ),
      variables: sharedVariables,
      book: runtimeContext?.book,
    );
    effectiveTrace.add('java.ajax:${request.method}:${request.url}');
    recordUnsupportedUrlOptionTrace(request, effectiveTrace,
        stage: 'java.ajax');
    recordLegadoRequestTrace(request, effectiveTrace, stage: 'java.ajax');

    final response = await executeLegadoRequest(
      request: request,
      httpExecutor: executor,
      webViewExecutor: webViewExecutor,
      stage: 'java.ajax',
      trace: effectiveTrace,
    );
    recordLegadoResponseTrace(response, effectiveTrace, stage: 'java.ajax');
    final decoded = await responseTransformer.decodeAndTransform(
      decoder: decoder,
      request: request,
      response: response,
      source: effectiveSource,
      jsEngine: analyzeUrl.jsEngine,
      trace: effectiveTrace,
      keyword: effectiveKeyword,
      page: effectivePage,
      book: runtimeContext?.book,
      variables: sharedVariables,
      cookieStore: analyzeUrl.cookieStore,
    );
    return decoded.text;
  };
}
