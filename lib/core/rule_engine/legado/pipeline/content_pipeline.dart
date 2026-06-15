import '../../models/source_rule.dart';
import '../../../utils/logger.dart';
import '../../parsers/regex_parser.dart';
import '../decode/response_decoder.dart';
import '../legado_models.dart';
import '../rule/analyze_rule.dart';
import '../rule/rule_context.dart';
import '../rule/rule_value.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import 'java_ajax.dart';
import 'pipeline_trace.dart';

class ContentPipeline {
  const ContentPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
    this.maxPages = 8,
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;
  final int maxPages;

  Future<LegadoContentResult?> load(
    SourceRule source,
    String contentUrl,
  ) async {
    final rule = source.content;
    if (rule == null || contentUrl.trim().isEmpty) return null;

    final visited = <String>{};
    final pages = <String>[];
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
        final parsed = await _loadPage(source, rule, currentUrl);
        title ??= parsed.title;
        if (parsed.content.isNotEmpty) pages.add(parsed.content);
        nextUrl = parsed.nextContentUrl;
        remainingNextUrl = nextUrl;
        log.i(
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
  ) async {
    final trace = LegadoTrace();
    final request = await analyzeUrl.compileSearchAsync(
      source: source,
      rawUrl: contentUrl,
      keyword: '',
      ajax: createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: source,
        trace: trace,
      ),
    );
    recordUnsupportedUrlOptionTrace(request, trace, stage: 'content');
    recordLegadoRequestTrace(request, trace, stage: 'content');
    log.i(
      '[legado-content] request method=${request.method} url=${request.url} '
      'headers=${request.headers.length} charset=${request.charset ?? 'auto'}',
    );
    final response = await executor.execute(request);
    recordLegadoResponseTrace(response, trace, stage: 'content');
    log.i(
      '[legado-content] response status=${response.statusCode} '
      'finalUrl=${response.finalUri} bytes=${response.bytes.length}',
    );
    final decoded = await decoder.decode(
      bytes: response.bytes,
      finalUri: response.finalUri,
      headers: response.headers,
      statusCode: response.statusCode,
      explicitCharset: request.charset,
      trace: trace,
    );
    log.i(
      '[legado-content] decoded finalUrl=${decoded.finalUri} '
      'chars=${decoded.text.length} '
      'firstChar=${decoded.text.isEmpty ? '' : decoded.text[0]} '
      'preview=${_preview(decoded.text)}',
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
    final content = _applyReplaceRegex(
      _contentText(decoded.text, rule.content, context),
      rule.replaceRegex,
    );

    return _ParsedContentPage(
      title: _fieldString(decoded.text, rule.title, context, 'title'),
      content: content,
      nextContentUrl: analyzeRule.absoluteUrl(
        _fieldString(
            decoded.text, rule.nextContentUrl, context, 'nextContentUrl'),
        baseUrl,
      ),
    );
  }

  String _contentText(
    String decodedText,
    String? contentRule,
    RuleContext context,
  ) {
    try {
      final parts = analyzeRule.fieldStrings(decodedText, contentRule, context);
      log.i(
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
      rethrow;
    }
  }

  String? _fieldString(
    Object source,
    String? rawRule,
    RuleContext context,
    String fieldName,
  ) {
    try {
      final value = analyzeRule.fieldString(source, rawRule, context);
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

  String _applyReplaceRegex(String content, String? replaceRegex) {
    final raw = replaceRegex?.trim();
    if (raw == null || raw.isEmpty || content.isEmpty) return content;

    var next = content;
    for (final rule in raw.split(RegExp(r'\r?\n'))) {
      final text = rule.trim();
      if (text.isEmpty) continue;
      next = RegexParser.applyReplacement(next, text);
    }
    return next;
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
