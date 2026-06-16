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
import 'java_ajax.dart';
import 'pipeline_trace.dart';
import 'response_transformer.dart';

class BookInfoPipeline {
  const BookInfoPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
    this.responseTransformer = const LegadoResponseTransformer(),
    this.webViewExecutor = const UnsupportedLegadoWebViewExecutor(),
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;
  final LegadoResponseTransformer responseTransformer;
  final LegadoWebViewExecutor webViewExecutor;

  Future<LegadoBookInfo?> load(
    SourceRule source,
    String bookUrl, {
    Object? book,
  }) async {
    final rule = source.bookInfo;
    if (rule == null || bookUrl.trim().isEmpty) return null;

    final trace = LegadoTrace();
    try {
      final baseContext = LegadoRuntimeContext(
        source: source,
        baseUrl: source.url,
        book: book,
        trace: trace,
      );
      final ajax = createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        runtimeContext: baseContext,
        responseTransformer: responseTransformer,
        webViewExecutor: webViewExecutor,
      );
      final runtimeContext = baseContext.copyWith(ajax: ajax);
      log.i(
        '[legado-book-info] start source=${source.name} '
        'sourceId=${source.id} bookUrl=$bookUrl book=${_bookSummary(book)}',
      );
      final request = await analyzeUrl.compileSearchAsync(
        source: source,
        rawUrl: bookUrl,
        keyword: '',
        variables: runtimeContext.variables.asMap(),
        ajax: ajax,
        book: book,
      );
      recordUnsupportedUrlOptionTrace(request, trace, stage: 'bookInfo');
      recordLegadoRequestTrace(request, trace, stage: 'bookInfo');
      log.i(
        '[legado-book-info] request method=${request.method} '
        'url=${request.url} headers=${request.headers.length} '
        'charset=${request.charset ?? 'auto'}',
      );
      final response = await executeLegadoRequest(
        request: request,
        httpExecutor: executor,
        webViewExecutor: webViewExecutor,
        stage: 'bookInfo',
        trace: trace,
      );
      recordLegadoResponseTrace(response, trace, stage: 'bookInfo');
      log.i(
        '[legado-book-info] response status=${response.statusCode} '
        'finalUrl=${response.finalUri} bytes=${response.bytes.length}',
      );
      final decoded = await responseTransformer.decodeAndTransform(
        decoder: decoder,
        request: request,
        response: response,
        source: source,
        jsEngine: analyzeUrl.jsEngine,
        trace: trace,
        runtimeContext: runtimeContext,
        ajax: ajax,
        cookieStore: analyzeUrl.cookieStore,
      );
      log.i(
        '[legado-book-info] decoded finalUrl=${decoded.finalUri} '
        'chars=${decoded.text.length} preview=${_preview(decoded.text)}',
      );
      final baseUrl = decoded.finalUri.toString();
      final context = runtimeContext
          .copyWith(
            src: decoded.text,
            result: decoded.text,
            redirectUrl: baseUrl,
            cookie: _cookieHeader(request.headers),
          )
          .toRuleContext(
            input: RuleInput(
              rawText: decoded.text,
              baseUri: Uri.parse(source.url),
              redirectUri: decoded.finalUri,
            ),
            cookie: _cookieHeader(request.headers),
          );
      final root = _initRoot(decoded.text, rule.init, context);

      final name = _fieldString(root, rule.name, context, 'name') ?? '';
      final author = _fieldString(root, rule.author, context, 'author') ?? '';
      final kind = _fieldString(root, rule.kind, context, 'kind');
      final lastChapter =
          _fieldString(root, rule.lastChapter, context, 'lastChapter');
      final intro = _fieldString(root, rule.intro, context, 'intro');
      final coverUrl = analyzeRule.absoluteUrl(
        _fieldString(root, rule.coverUrl, context, 'coverUrl'),
        baseUrl,
      );
      final tocUrl = analyzeRule.absoluteUrl(
        _fieldString(root, rule.tocUrl, context, 'tocUrl'),
        baseUrl,
      );
      final wordCount =
          _fieldString(root, rule.wordCount, context, 'wordCount');
      log.i(
        '[legado-book-info] parsed name=$name author=$author kind=$kind '
        'lastChapter=$lastChapter tocUrl=$tocUrl coverUrl=$coverUrl '
        'wordCount=$wordCount intro=${_preview(intro ?? '')}',
      );
      return LegadoBookInfo(
        name: name,
        author: author,
        kind: kind,
        lastChapter: lastChapter,
        intro: intro,
        coverUrl: coverUrl,
        tocUrl: tocUrl,
        wordCount: wordCount,
      );
    } catch (error, stackTrace) {
      log.e(
        '[legado-book-info] failed source=${source.name} '
        'sourceId=${source.id} bookUrl=$bookUrl trace=${trace.events}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Object _initRoot(String decodedText, String? initRule, RuleContext context) {
    final nodes = analyzeRule.elements(decodedText, initRule, context);
    return nodes.isEmpty ? decodedText : nodes.first;
  }

  String? _fieldString(
    Object source,
    String? rawRule,
    RuleContext context,
    String fieldName,
  ) {
    try {
      final value = analyzeRule.fieldString(source, rawRule, context);
      log.d(
        '[legado-book-info] field $fieldName rule=${_preview(rawRule ?? '')} '
        'value=${_preview(value ?? '')}',
      );
      return value;
    } catch (error, stackTrace) {
      log.w(
        '[legado-book-info] field $fieldName failed '
        'rule=${_preview(rawRule ?? '')}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _bookSummary(Object? book) {
    if (book is Map) {
      return {
        for (final key in const [
          'name',
          'author',
          'bookUrl',
          'tocUrl',
          'origin',
          'originName',
        ])
          if (book[key] != null) key: book[key],
      }.toString();
    }
    return book?.toString() ?? 'null';
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
