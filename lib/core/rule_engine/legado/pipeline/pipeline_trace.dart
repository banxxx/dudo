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
  if (request.bodyJs != null) trace.add('$stage.url.bodyJs:unsupported');
  if (request.webJs != null) trace.add('$stage.url.webJs:unsupported');
  if (request.useWebView) trace.add('$stage.url.webView:unsupported');
}
