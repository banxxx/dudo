import '../../models/source_rule.dart';
import '../../../utils/logger.dart';
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
    String tocUrl, {
    Object? book,
  }) async {
    final rule = source.toc;
    if (rule == null || tocUrl.trim().isEmpty) return null;

    final trace = LegadoTrace();
    try {
      log.i(
        '[legado-toc] start source=${source.name} sourceId=${source.id} '
        'tocUrl=$tocUrl book=${_bookSummary(book)}',
      );
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
        book: book,
      );
      recordUnsupportedUrlOptionTrace(request, trace, stage: 'toc');
      recordLegadoRequestTrace(request, trace, stage: 'toc');
      log.i(
        '[legado-toc] request method=${request.method} url=${request.url} '
        'headers=${request.headers.length} charset=${request.charset ?? 'auto'}',
      );
      final response = await executor.execute(request);
      recordLegadoResponseTrace(response, trace, stage: 'toc');
      log.i(
        '[legado-toc] response status=${response.statusCode} '
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
        '[legado-toc] decoded finalUrl=${decoded.finalUri} '
        'chars=${decoded.text.length} preview=${_preview(decoded.text)}',
      );
      final baseUrl = decoded.finalUri.toString();
      final context = RuleContext(
        source: source,
        trace: trace,
        book: book,
        input: RuleInput(
          rawText: decoded.text,
          baseUri: Uri.parse(source.url),
          redirectUri: decoded.finalUri,
        ),
      );
      final list = _elements(decoded.text, rule.chapterList, context);
      log.i(
        '[legado-toc] chapterList count=${list.length} '
        'rule=${_preview(rule.chapterList ?? '')}',
      );

      final chapters = [
        for (final node in list)
          LegadoTocChapter(
            name:
                _fieldString(node, rule.chapterName, context, 'chapterName') ??
                    '',
            url: analyzeRule.absoluteUrl(
              _fieldString(node, rule.chapterUrl, context, 'chapterUrl'),
              baseUrl,
            ),
            isVolume: _fieldString(node, rule.isVolume, context, 'isVolume'),
            isVip: _fieldString(node, rule.isVip, context, 'isVip'),
            isPay: _fieldString(node, rule.isPay, context, 'isPay'),
            updateTime:
                _fieldString(node, rule.updateTime, context, 'updateTime'),
          ),
      ];
      final nextTocUrl = analyzeRule.absoluteUrl(
        _fieldString(decoded.text, rule.nextTocUrl, context, 'nextTocUrl'),
        baseUrl,
      );
      log.i(
        '[legado-toc] parsed chapters=${chapters.length} '
        'nextTocUrl=$nextTocUrl samples=${_chapterSamples(chapters)}',
      );
      return LegadoTocResult(
        chapters: chapters,
        nextTocUrl: nextTocUrl,
      );
    } catch (error, stackTrace) {
      log.e(
        '[legado-toc] failed source=${source.name} sourceId=${source.id} '
        'tocUrl=$tocUrl trace=${trace.events}',
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
      return analyzeRule.fieldString(source, rawRule, context);
    } catch (error, stackTrace) {
      log.w(
        '[legado-toc] field $fieldName failed rule=${_preview(rawRule ?? '')}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<Object> _elements(
    Object source,
    String? rawRule,
    RuleContext context,
  ) {
    try {
      return analyzeRule.elements(source, rawRule, context);
    } catch (error, stackTrace) {
      log.w(
        '[legado-toc] chapterList failed rule=${_preview(rawRule ?? '')}',
        error: error,
        stackTrace: stackTrace,
      );
      return const <Object>[];
    }
  }

  String _chapterSamples(List<LegadoTocChapter> chapters) {
    return [
      for (final chapter in chapters.take(5))
        {
          'name': chapter.name,
          'url': chapter.url,
          'isVip': chapter.isVip,
          'isPay': chapter.isPay,
        },
    ].toString();
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
}
