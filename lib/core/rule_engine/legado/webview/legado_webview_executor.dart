import '../rule/rule_context.dart';
import '../url/request_executor.dart';

/// Legado WebView 请求执行器。
///
/// 这里只定义在线书源运行时的抽象边界，具体移动端 WebView 实现后续放到平台层注入，
/// 避免把 WebView 细节塞进 Dio 请求执行器或正文 pipeline。
abstract interface class LegadoWebViewExecutor {
  Future<LegadoHttpResponse> execute(
    LegadoRequest request, {
    required String stage,
    required LegadoTrace trace,
  });
}

class UnsupportedLegadoWebViewExecutor implements LegadoWebViewExecutor {
  const UnsupportedLegadoWebViewExecutor();

  @override
  Future<LegadoHttpResponse> execute(
    LegadoRequest request, {
    required String stage,
    required LegadoTrace trace,
  }) async {
    trace.add('$stage.url.webView:blocked');
    throw LegadoRuntimeException(
      'WebView request mode is not supported yet',
      stage: stage,
      trace: trace,
    );
  }
}

Future<LegadoHttpResponse> executeLegadoRequest({
  required LegadoRequest request,
  required LegadoRequestExecutor httpExecutor,
  required LegadoWebViewExecutor webViewExecutor,
  required String stage,
  required LegadoTrace trace,
}) {
  if (request.useWebView) {
    return webViewExecutor.execute(request, stage: stage, trace: trace);
  }
  return httpExecutor.execute(request);
}
