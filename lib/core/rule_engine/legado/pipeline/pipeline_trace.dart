import '../rule/rule_context.dart';
import '../url/request_executor.dart';

void recordLegadoRequestTrace(
  LegadoRequest request,
  LegadoTrace trace, {
  required String stage,
}) {
  trace
    ..add('$stage.request.url:${request.url}')
    ..add('$stage.request.method:${request.method}')
    ..add('$stage.request.headers:${request.headers.length}')
    ..add('$stage.request.charset:${request.charset ?? 'auto'}');
}

void recordLegadoResponseTrace(
  LegadoHttpResponse response,
  LegadoTrace trace, {
  required String stage,
}) {
  trace
    ..add('$stage.response.status:${response.statusCode ?? 'unknown'}')
    ..add('$stage.response.length:${response.bytes.length}');
}

void recordUnsupportedUrlOptionTrace(
  LegadoRequest request,
  LegadoTrace trace, {
  required String stage,
}) {
  if (request.sourceRegex != null) {
    trace.add('$stage.url.sourceRegex:supported');
  }
  if (request.bodyJs != null) trace.add('$stage.url.bodyJs:supported');
  if (request.webJs != null) trace.add('$stage.url.webJs:unsupported');
  if (request.useWebView) trace.add('$stage.url.webView:unsupported');
}

void throwIfUnsupportedWebViewRequest(
  LegadoRequest request,
  LegadoTrace trace, {
  required String stage,
}) {
  if (!request.useWebView) return;
  trace.add('$stage.url.webView:blocked');
  throw LegadoRuntimeException(
    'WebView request mode is not supported yet',
    stage: stage,
    trace: trace,
  );
}
