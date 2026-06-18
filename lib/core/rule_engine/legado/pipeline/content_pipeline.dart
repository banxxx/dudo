import '../../models/source_rule.dart';
import '../../../utils/logger.dart';
import '../decode/response_decoder.dart';
import '../legado_models.dart';
import '../runtime/legado_runtime_context.dart';
import '../rule/analyze_rule.dart';
import '../rule/rule_context.dart';
import '../rule/rule_value.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import '../webview/legado_webview_executor.dart';
import 'content_compatibility_parser.dart';
import 'content_post_processor.dart';
import 'java_ajax.dart';
import 'pipeline_trace.dart';
import 'response_transformer.dart';

class ContentPipeline {
  const ContentPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
    this.compatibilityParser = const ContentCompatibilityParser(),
    this.postProcessor = const ContentPostProcessor(),
    this.responseTransformer = const LegadoResponseTransformer(),
    this.webViewExecutor = const UnsupportedLegadoWebViewExecutor(),
    this.maxPages = 8,
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;
  final ContentCompatibilityParser compatibilityParser;
  final ContentPostProcessor postProcessor;
  final LegadoResponseTransformer responseTransformer;
  final LegadoWebViewExecutor webViewExecutor;
  final int maxPages;

  Future<LegadoContentResult?> load(
    SourceRule source,
    String contentUrl,
  ) async {
    final rule = source.content;
    if (rule == null || contentUrl.trim().isEmpty) return null;

    final visited = <String>{};
    final pages = <String>[];
    final runtimeContext = LegadoRuntimeContext(
      source: source,
      baseUrl: source.url,
    );
    String? title;
    String? nextUrl = contentUrl;
    String? remainingNextUrl;

    try {
      log.i(
        '[legado-content] start source=${source.name} sourceId=${source.id} '
        'contentUrl=$contentUrl ruleContent=${_preview(rule.content ?? '')} '
        'ruleTitle=${_preview(rule.title ?? '')} '
        'ruleNext=${_preview(rule.nextContentUrl ?? '')}',
      );
      for (var page = 0; page < maxPages; page++) {
        final currentUrl = nextUrl?.trim();
        if (currentUrl == null || currentUrl.isEmpty) break;
        if (!visited.add(currentUrl)) {
          remainingNextUrl = currentUrl;
          log.w(
            '[legado-content] stop duplicate nextUrl=$currentUrl '
            'sourceId=${source.id}',
          );
          break;
        }

        log.i(
          '[legado-content] page ${page + 1}/$maxPages url=$currentUrl',
        );
        final parsed =
            await _loadPage(source, rule, currentUrl, runtimeContext);
        title ??= parsed.title;
        if (parsed.content.isNotEmpty) pages.add(parsed.content);
        nextUrl = parsed.nextContentUrl;
        remainingNextUrl = nextUrl;
        log.d(
          '[legado-content] page parsed title=${_preview(parsed.title ?? '')} '
          'contentChars=${parsed.content.length} '
          'nextContentUrl=${parsed.nextContentUrl} '
          'preview=${_preview(parsed.content)}',
        );
        if (nextUrl == null || nextUrl.trim().isEmpty) {
          remainingNextUrl = null;
          break;
        }
      }

      final joined = pages.join('\n\n');
      if (joined.trim().isEmpty) {
        throw LegadoRuntimeException(
          'content is empty',
          stage: 'content',
          trace: LegadoTrace([
            'source:${source.id}',
            'contentUrl:$contentUrl',
            'maxPages:$maxPages',
            'visited:${visited.length}',
          ]),
        );
      }
      log.i(
        '[legado-content] done pages=${pages.length} '
        'contentChars=${joined.length} nextContentUrl=$remainingNextUrl',
      );
      return LegadoContentResult(
        title: title ?? '',
        content: joined,
        nextContentUrl: remainingNextUrl,
      );
    } catch (error, stackTrace) {
      log.e(
        '[legado-content] failed source=${source.name} sourceId=${source.id} '
        'contentUrl=$contentUrl',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<_ParsedContentPage> _loadPage(
    SourceRule source,
    ContentRule rule,
    String contentUrl,
    LegadoRuntimeContext runtimeContext,
  ) async {
    final ajax = createLegadoJavaAjax(
      analyzeUrl: analyzeUrl,
      executor: executor,
      decoder: decoder,
      runtimeContext: runtimeContext,
      responseTransformer: responseTransformer,
      webViewExecutor: webViewExecutor,
    );
    final pageContext = runtimeContext.copyWith(ajax: ajax);
    final request = await analyzeUrl.compileSearchAsync(
      source: source,
      rawUrl: contentUrl,
      keyword: '',
      variables: pageContext.variables.asMap(),
      ajax: ajax,
      book: pageContext.book,
    );
    final effectiveRequest = _mergeContentRuleRequestOptions(request, rule);
    recordUnsupportedUrlOptionTrace(effectiveRequest, pageContext.trace,
        stage: 'content');
    recordLegadoRequestTrace(effectiveRequest, pageContext.trace,
        stage: 'content');
    log.i(
      '[legado-content] request method=${effectiveRequest.method} '
      'url=${effectiveRequest.url} headers=${effectiveRequest.headers.length} '
      'charset=${effectiveRequest.charset ?? 'auto'}',
    );
    final response = await executeLegadoRequest(
      request: effectiveRequest,
      httpExecutor: executor,
      webViewExecutor: webViewExecutor,
      stage: 'content',
      trace: pageContext.trace,
    );
    recordLegadoResponseTrace(response, pageContext.trace, stage: 'content');
    log.i(
      '[legado-content] response status=${response.statusCode} '
      'finalUrl=${response.finalUri} bytes=${response.bytes.length}',
    );
    final decoded = await responseTransformer.decodeAndTransform(
      decoder: decoder,
      request: effectiveRequest,
      response: response,
      source: source,
      jsEngine: analyzeUrl.jsEngine,
      trace: pageContext.trace,
      runtimeContext: pageContext,
      ajax: ajax,
      cookieStore: analyzeUrl.cookieStore,
    );
    log.d(
      '[legado-content] decoded finalUrl=${decoded.finalUri} '
      'chars=${decoded.text.length} '
      'firstChar=${decoded.text.isEmpty ? '' : decoded.text[0]} '
      'preview=${_preview(decoded.text)}',
    );
    final baseUrl = decoded.finalUri.toString();
    final context = pageContext
        .copyWith(
          src: decoded.text,
          result: decoded.text,
          redirectUrl: baseUrl,
          cookie: _cookieHeader(effectiveRequest.headers),
        )
        .toRuleContext(
          input: RuleInput(
            rawText: decoded.text,
            baseUri: Uri.parse(source.url),
            redirectUri: decoded.finalUri,
          ),
          cookie: _cookieHeader(effectiveRequest.headers),
        );
    final content = postProcessor.apply(
      content: await _contentText(decoded.text, rule.content, context),
      replaceRegex: rule.replaceRegex,
    );

    return _ParsedContentPage(
      title: await _fieldString(decoded.text, rule.title, context, 'title'),
      content: content,
      nextContentUrl: analyzeRule.absoluteUrl(
        await _fieldString(
            decoded.text, rule.nextContentUrl, context, 'nextContentUrl'),
        baseUrl,
      ),
    );
  }

  LegadoRequest _mergeContentRuleRequestOptions(
    LegadoRequest request,
    ContentRule rule,
  ) {
    final sourceRegex = request.sourceRegex ?? _blankToNull(rule.sourceRegex);
    final bodyJs = request.bodyJs ?? _blankToNull(rule.bodyJs);
    final webJs = request.webJs ?? _blankToNull(rule.webJs);
    if (sourceRegex == request.sourceRegex &&
        bodyJs == request.bodyJs &&
        webJs == request.webJs) {
      return request;
    }

    return LegadoRequest(
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: request.body,
      charset: request.charset,
      sourceRegex: sourceRegex,
      bodyJs: bodyJs,
      webJs: webJs,
      useWebView: request.useWebView,
      webViewDelayTime: request.webViewDelayTime,
    );
  }

  String? _blankToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<String> _contentText(
    String decodedText,
    String? contentRule,
    RuleContext context,
  ) async {
    try {
      final parts = await analyzeRule.fieldStringsAsync(
          decodedText, contentRule, context);
      log.d(
        '[legado-content] field content parts=${parts.length} '
        'rule=${_preview(contentRule ?? '')} '
        'preview=${_preview(parts.join('\\n'))}',
      );
      return parts.join('\n');
    } catch (error, stackTrace) {
      log.e(
        '[legado-content] field content failed '
        'rule=${_preview(contentRule ?? '')}',
        error: error,
        stackTrace: stackTrace,
      );
      final compatible = compatibilityParser.parse(decodedText);
      if (compatible != null && compatible.isNotEmpty) {
        context.trace?.add('content.compatibility.json');
        log.w(
          '[legado-content] content compatibility fallback '
          'chars=${compatible.length}',
        );
        return compatible;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String?> _fieldString(
    Object source,
    String? rawRule,
    RuleContext context,
    String fieldName,
  ) async {
    try {
      final value =
          await analyzeRule.fieldStringAsync(source, rawRule, context);
      log.i(
        '[legado-content] field $fieldName '
        'rule=${_preview(rawRule ?? '')} value=${_preview(value ?? '')}',
      );
      return value;
    } catch (error, stackTrace) {
      log.w(
        '[legado-content] field $fieldName failed '
        'rule=${_preview(rawRule ?? '')}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _preview(String value, {int maxLength = 500}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }

  String? _cookieHeader(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'cookie') return entry.value;
    }
    return null;
  }
}

class _ParsedContentPage {
  const _ParsedContentPage({
    this.title,
    required this.content,
    this.nextContentUrl,
  });

  final String? title;
  final String content;
  final String? nextContentUrl;
}
