import '../../models/source_rule.dart';
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

    for (var page = 0; page < maxPages; page++) {
      final currentUrl = nextUrl?.trim();
      if (currentUrl == null || currentUrl.isEmpty) break;
      if (!visited.add(currentUrl)) {
        remainingNextUrl = currentUrl;
        break;
      }

      final parsed = await _loadPage(source, rule, currentUrl);
      title ??= parsed.title;
      if (parsed.content.isNotEmpty) pages.add(parsed.content);
      nextUrl = parsed.nextContentUrl;
      remainingNextUrl = nextUrl;
      if (nextUrl == null || nextUrl.trim().isEmpty) {
        remainingNextUrl = null;
        break;
      }
    }

    return LegadoContentResult(
      title: title ?? '',
      content: pages.join('\n\n'),
      nextContentUrl: remainingNextUrl,
    );
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
    final response = await executor.execute(request);
    recordLegadoResponseTrace(response, trace, stage: 'content');
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
    final content = _applyReplaceRegex(
      _contentText(decoded.text, rule.content, context),
      rule.replaceRegex,
    );

    return _ParsedContentPage(
      title: analyzeRule.fieldString(decoded.text, rule.title, context),
      content: content,
      nextContentUrl: analyzeRule.absoluteUrl(
        analyzeRule.fieldString(decoded.text, rule.nextContentUrl, context),
        baseUrl,
      ),
    );
  }

  String _contentText(
    String decodedText,
    String? contentRule,
    RuleContext context,
  ) {
    final parts = analyzeRule.fieldStrings(decodedText, contentRule, context);
    return parts.join('\n');
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
