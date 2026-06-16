import 'dart:convert';

import '../../models/source_rule.dart';
import '../decode/response_decoder.dart';
import '../legado_models.dart';
import '../rule/analyze_rule.dart';
import '../rule/rule_context.dart';
import '../rule/rule_value.dart';
import '../url/analyze_url.dart';
import '../url/request_executor.dart';
import '../../../utils/logger.dart';
import 'java_ajax.dart';
import 'pipeline_trace.dart';
import 'response_transformer.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class SearchPipeline {
  const SearchPipeline({
    required this.analyzeUrl,
    required this.executor,
    required this.decoder,
    required this.analyzeRule,
    this.responseTransformer = const LegadoResponseTransformer(),
  });

  final AnalyzeUrl analyzeUrl;
  final LegadoRequestExecutor executor;
  final ResponseDecoder decoder;
  final AnalyzeRule analyzeRule;
  final LegadoResponseTransformer responseTransformer;

  Future<List<LegadoSearchItem>> search(
    SourceRule source,
    String keyword,
  ) async {
    final search = source.search;
    final rawUrl = search?.searchUrl;
    if (search == null || rawUrl == null || rawUrl.trim().isEmpty) {
      return const [];
    }

    final trace = LegadoTrace();
    try {
      final variables = <String, Object?>{};
      final ajax = createLegadoJavaAjax(
        analyzeUrl: analyzeUrl,
        executor: executor,
        decoder: decoder,
        source: source,
        trace: trace,
        keyword: keyword,
        variables: variables,
        responseTransformer: responseTransformer,
      );
      final request = await analyzeUrl.compileSearchAsync(
        source: source,
        rawUrl: rawUrl,
        keyword: keyword,
        variables: variables,
        ajax: ajax,
      );
      recordUnsupportedUrlOptionTrace(request, trace, stage: 'search');
      throwIfUnsupportedWebViewRequest(request, trace, stage: 'search');
      recordLegadoRequestTrace(request, trace, stage: 'search');
      log.i(
        '[legado-search] compiled source="${source.name}" '
        'base="${source.url}" method=${request.method} '
        'url="${request.url}" headers=${request.headers.length} '
        'bodyLength=${request.body?.toString().length ?? 0}',
      );
      final response = await executor.execute(request);
      recordLegadoResponseTrace(response, trace, stage: 'search');
      log.i(
        '[legado-search] response source="${source.name}" '
        'status=${response.statusCode ?? 'unknown'} '
        'finalUrl="${response.finalUri}" bytes=${response.bytes.length}',
      );
      final decoded = await responseTransformer.decodeAndTransform(
        decoder: decoder,
        request: request,
        response: response,
        source: source,
        jsEngine: analyzeUrl.jsEngine,
        trace: trace,
        keyword: keyword,
        variables: variables,
        ajax: ajax,
        cookieStore: analyzeUrl.cookieStore,
      );
      final baseUrl = decoded.finalUri.toString();
      final context = RuleContext(
        source: source,
        keyword: keyword,
        trace: trace,
        variables: variables,
        cookie: _cookieHeader(request.headers),
        ajax: ajax,
        input: RuleInput(
          rawText: decoded.text,
          baseUri: Uri.parse(source.url),
          redirectUri: decoded.finalUri,
        ),
      );
      final isDetailPage = _matchesBookUrlPattern(
        decoded.finalUri.toString(),
        source.bookUrlPattern ?? search.bookUrlPattern,
      );
      final listResult = isDetailPage
          ? _SearchListResult(
              <Object>[decoded.text],
              parseAsDetail: true,
            )
          : await _bookListOrDetailFallback(
              decoded.text,
              search.bookList,
              context,
              source,
            );
      var list = listResult.items;
      list = await _applyBookListJsCompatibility(
        source: source,
        search: search,
        list: list,
        trace: trace,
      );
      trace.add('search.bookList.count:${list.length}');
      final deduped = <String, LegadoSearchItem>{};

      for (final node in list) {
        final detailRule = listResult.parseAsDetail ? source.bookInfo : null;
        final fieldSource = detailRule == null
            ? node
            : _detailRoot(node, detailRule.init, context);
        final nameRule = detailRule?.name ?? search.name;
        final authorRule = detailRule?.author ?? search.author;
        final coverUrlRule = detailRule?.coverUrl ?? search.coverUrl;
        final introRule = detailRule?.intro ?? search.intro;
        final kindRule = detailRule?.kind ?? search.kind;
        final lastChapterRule = detailRule?.lastChapter ?? search.lastChapter;
        final rawBookUrl = detailRule == null
            ? _safeFieldString(fieldSource, search.bookUrl, context, 'bookUrl')
            : baseUrl;
        final name =
            _safeFieldString(fieldSource, nameRule, context, 'name') ?? '';
        final author =
            _safeFieldString(fieldSource, authorRule, context, 'author') ?? '';
        _recordEmptyField(trace, 'name', name, nameRule);
        _recordEmptyField(trace, 'author', author, authorRule);
        _recordEmptyField(trace, 'bookUrl', rawBookUrl, search.bookUrl);
        final item = LegadoSearchItem(
          name: name,
          author: author,
          coverUrl: analyzeRule.absoluteUrl(
            _safeFieldString(fieldSource, coverUrlRule, context, 'coverUrl'),
            baseUrl,
          ),
          bookUrl: analyzeRule.absoluteUrl(
            rawBookUrl ?? (isDetailPage ? baseUrl : null),
            baseUrl,
          ),
          intro: _safeFieldString(fieldSource, introRule, context, 'intro'),
          kind: _safeFieldString(fieldSource, kindRule, context, 'kind'),
          lastChapter: _safeFieldString(
              fieldSource, lastChapterRule, context, 'lastChapter'),
          wordCount: detailRule == null
              ? null
              : _safeFieldString(
                  fieldSource,
                  detailRule.wordCount,
                  context,
                  'wordCount',
                ),
        );
        if (!_isUsableItem(item)) {
          trace.add('search.item.discarded:empty');
          log.d(
            '[legado-search] discard empty item source="${source.name}" '
            'name="${item.name}" author="${item.author}" '
            'bookUrl="${item.bookUrl ?? ''}"',
          );
          continue;
        }
        final key = '${item.name}::${item.author}::${item.bookUrl ?? ''}';
        deduped.putIfAbsent(key, () => item);
      }

      final items = deduped.values.toList(growable: false);
      log.i(
        '[legado-search] parsed source="${source.name}" '
        'bookListCount=${list.length} resultCount=${items.length}',
      );
      return items;
    } on LegadoRuntimeException {
      rethrow;
    } catch (error) {
      throw LegadoRuntimeException(
        'search pipeline failed',
        stage: 'search',
        cause: error,
        trace: trace,
      );
    }
  }

  void _recordEmptyField(
    LegadoTrace trace,
    String field,
    String? value,
    String? rule,
  ) {
    if (value != null && value.trim().isNotEmpty) return;
    final reason =
        rule == null || rule.trim().isEmpty ? 'missing-rule' : 'empty-result';
    trace.add('search.field.empty:$field:$reason');
  }

  bool _isUsableItem(LegadoSearchItem item) {
    return item.name.trim().isNotEmpty ||
        item.author.trim().isNotEmpty ||
        (item.bookUrl?.trim().isNotEmpty ?? false);
  }

  String? _safeFieldString(
    Object source,
    String? rule,
    RuleContext context,
    String field,
  ) {
    try {
      return analyzeRule.fieldString(source, rule, context);
    } catch (error) {
      context.trace?.add('search.field.error:$field:$error');
      return null;
    }
  }

  Future<_SearchListResult> _bookListOrDetailFallback(
    String decodedText,
    String? bookListRule,
    RuleContext context,
    SourceRule source,
  ) async {
    final androidApiList = await _jjwxcAndroidSearchList(
      decodedText: decodedText,
      bookListRule: bookListRule,
      context: context,
      source: source,
    );
    if (androidApiList != null) return _SearchListResult(androidApiList);

    final effectiveRule =
        _isJjwxcBookbaseDetailScript(source, bookListRule ?? '')
            ? _stripEmbeddedJs(bookListRule ?? '')
            : bookListRule;
    final list = analyzeRule.elements(decodedText, effectiveRule, context);
    if (list.isNotEmpty) return _SearchListResult(list);
    return _SearchListResult(
      [decodedText],
      parseAsDetail: true,
    );
  }

  Object _detailRoot(Object node, String? initRule, RuleContext context) {
    if (initRule == null || initRule.trim().isEmpty) return node;
    final roots = analyzeRule.elements(node, initRule, context);
    return roots.isEmpty ? node : roots.first;
  }

  Future<List<Object>?> _jjwxcAndroidSearchList({
    required String decodedText,
    required String? bookListRule,
    required RuleContext context,
    required SourceRule source,
  }) async {
    final rule = bookListRule ?? '';
    if (!_isJjwxcAndroidSearchMergeScript(source, rule)) return null;

    final items = <Object>[];
    items.addAll(_jsonItems(decodedText));

    final keyword = context.keyword;
    if (keyword != null && keyword.trim().isNotEmpty) {
      final authorUrl = 'http://android.jjwxc.net/androidapi/search?keyword='
          '${Uri.encodeQueryComponent(keyword)}'
          '&type=2&page=${context.page}&searchType=7&sortMode=DESC';
      try {
        context.trace?.add('search.bookList.jjwxc.author.request:$authorUrl');
        final response = await executor.execute(
          LegadoRequest(
            url: authorUrl,
            method: 'GET',
            headers: source.headers,
          ),
        );
        final decoded = await decoder.decode(
          bytes: response.bytes,
          finalUri: response.finalUri,
          headers: response.headers,
          statusCode: response.statusCode,
          trace: context.trace,
        );
        items.addAll(_jsonItems(decoded.text));
      } catch (error) {
        context.trace?.add('search.bookList.jjwxc.author.error:$error');
      }
    }

    final deduped = <String, Object>{};
    for (final item in items) {
      final key = item is Map
          ? (item['novelid'] ?? item['novelId'] ?? item).toString()
          : item.toString();
      deduped.putIfAbsent(key, () => item);
    }
    return deduped.values.toList(growable: false);
  }

  bool _isJjwxcAndroidSearchMergeScript(SourceRule source, String rule) {
    final text = rule.toLowerCase();
    return (source.url.contains('jjwxc.net') ||
            source.id.contains('jjwxc.net')) &&
        text.contains('androidapi/search') &&
        text.contains('json.parse(result).items') &&
        text.contains('json.concat');
  }

  List<Object> _jsonItems(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final items = decoded['items'];
        if (items is List) return items.whereType<Object>().toList();
      }
      if (decoded is List) return decoded.whereType<Object>().toList();
    } catch (_) {
      return const [];
    }
    return const [];
  }

  Future<List<Object>> _applyBookListJsCompatibility({
    required SourceRule source,
    required SearchRule search,
    required List<Object> list,
    required LegadoTrace trace,
  }) async {
    final rule = search.bookList ?? '';
    if (list.isEmpty || !_isJjwxcBookbaseDetailScript(source, rule)) {
      return list;
    }

    final converted = <Object>[];
    log.i(
      '[legado-search] applying jjwxc bookList js compatibility '
      'source="${source.name}" listCount=${list.length}',
    );
    for (final item in list) {
      final novelId = _extractJjwxcNovelId(item);
      if (novelId == null) {
        converted.add(item);
        continue;
      }
      try {
        final detail = await _loadJjwxcSearchDetail(source, novelId, trace);
        converted.add(_jjwxcDetailOrFallback(detail, item, novelId));
      } catch (error) {
        trace.add('search.bookList.jsCompat.error:$novelId:$error');
        converted.add(_jjwxcDetailOrFallback(null, item, novelId));
      }
    }
    return converted;
  }

  Map<String, String> _jjwxcDetailOrFallback(
    Map<String, String>? detail,
    Object item,
    String novelId,
  ) {
    final fallbackTitle = switch (item) {
      dom.Element() => item.text.trim(),
      Map() => (item['title'] ?? item['novelname'] ?? item['novelName'] ?? '')
          .toString()
          .trim(),
      _ => '',
    };
    final result = <String, String>{
      'title': fallbackTitle,
      'author': '',
      'cat': '',
      'size': '',
      'url':
          'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=$novelId',
      'des': '',
      'new': '',
      'cover': '',
      'coverUrl': '',
    };
    if (detail != null) {
      for (final entry in detail.entries) {
        if (entry.value.trim().isNotEmpty) result[entry.key] = entry.value;
      }
    }
    return result;
  }

  bool _isJjwxcBookbaseDetailScript(SourceRule source, String rule) {
    final text = rule.toLowerCase();
    return (source.url.contains('jjwxc.net') ||
            source.id.contains('jjwxc.net')) &&
        text.contains('onebook.php?novelid=') &&
        text.contains('java.ajax(url)') &&
        text.contains('json.push');
  }

  String _stripEmbeddedJs(String rule) {
    return rule
        .replaceAll(RegExp(r'<js>[\s\S]*?</js>', caseSensitive: false), '')
        .replaceAll(RegExp(r'@js:[\s\S]*$', caseSensitive: false), '')
        .trim();
  }

  String? _extractJjwxcNovelId(Object item) {
    final href = switch (item) {
      dom.Element(:final attributes) => attributes['href'] ?? item.outerHtml,
      Map() => item['novelid']?.toString() ??
          item['novelId']?.toString() ??
          item['url']?.toString(),
      _ => item.toString(),
    };
    final match = RegExp(r'(?:novelid=|/)(\d{3,})', caseSensitive: false)
        .firstMatch(href ?? '');
    return match?.group(1);
  }

  Future<Map<String, String>?> _loadJjwxcSearchDetail(
    SourceRule source,
    String novelId,
    LegadoTrace trace,
  ) async {
    final url = 'http://www.jjwxc.net/onebook.php?novelid=$novelId';
    final request = LegadoRequest(
      url: url,
      method: 'GET',
      headers: source.headers,
    );
    trace.add('search.bookList.jsCompat.request:$url');
    final response = await executor.execute(request);
    final decoded = await decoder.decode(
      bytes: response.bytes,
      finalUri: response.finalUri,
      headers: response.headers,
      statusCode: response.statusCode,
      trace: trace,
    );
    final document = html_parser.parse(decoded.text);
    final title = _selectText(document, 'h1[itemprop="name"]');
    final author = _selectText(document, 'span[itemprop="author"]');
    if (title.isEmpty && author.isEmpty) return null;

    var cover = _selectAttr(document, '.noveldefaultimage', 'src');
    if (RegExp(r'(?:postimg|bmp|alicdn)\.', caseSensitive: false)
        .hasMatch(cover)) {
      cover = 'https://i9-static.jjwxc.net/novelimage.php?novelid=$novelId';
    } else {
      cover = _absoluteUrl(cover, decoded.finalUri.toString());
    }
    final status = _selectText(document, 'span[itemprop="updataStatus"]');
    final tags = _jjwxcTags(document);
    final genreText = _selectText(document, '[itemprop="genre"]');
    final genreParts = genreText.split('-');
    final genre = genreParts.length > 1 ? genreParts[1].trim() : '';
    final size = _selectText(document, 'span[itemprop="wordCount"]')
        .replaceAll(RegExp(r'\D+$'), '');
    final intro = [
      _selectText(document, 'span[style="color:#F98C4D"]')
          .replaceFirst(RegExp(r'^[^:：]+[:：]\s*'), ''),
      _selectText(document, '#novelintro'),
    ].where((part) => part.isNotEmpty).join();

    return {
      'title': title,
      'author': author,
      'cat': [status, tags, genre]
          .where((part) => part.trim().isNotEmpty)
          .join(','),
      'size': size,
      'url':
          'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=$novelId',
      'des': intro,
      'new': _jjwxcLatestChapter(document),
      'cover': cover,
      'coverUrl': cover,
    };
  }

  String _absoluteUrl(String rawUrl, String baseUrl) {
    final text = rawUrl.trim();
    if (text.isEmpty) return '';
    final uri = Uri.tryParse(text);
    if (uri == null) return text;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
  }

  String _selectText(dom.Document document, String selector) {
    return document.querySelector(selector)?.text.trim() ?? '';
  }

  String _selectAttr(dom.Document document, String selector, String attr) {
    return document.querySelector(selector)?.attributes[attr]?.trim() ?? '';
  }

  String _jjwxcTags(dom.Document document) {
    final values = <String>[];
    for (final anchor in document.querySelectorAll('a')) {
      final style = (anchor.attributes['style'] ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      if (style == 'text-decoration:none;color:red;') {
        final text = anchor.text.trim();
        if (text.isNotEmpty) values.add(text);
      }
    }
    return values.join(',');
  }

  String _jjwxcLatestChapter(dom.Document document) {
    final rows = document.querySelectorAll('#oneboolt tr');
    if (rows.length < 2) return '';
    final row = rows[rows.length - 2];
    final num = row.querySelectorAll('td').isEmpty
        ? ''
        : row.querySelectorAll('td').first.text.trim();
    final chapter = (row.querySelector('span')?.text.trim() ?? '')
        .replaceAll('\n', ' ')
        .replaceAll('*', '')
        .replaceAll('[VIP]', '')
        .trim();
    if (num.isEmpty && chapter.isEmpty) return '';
    if (num.isEmpty) return chapter;
    if (chapter.isEmpty) return num;
    return '$num $chapter';
  }

  bool _matchesBookUrlPattern(String url, String? pattern) {
    final text = pattern?.trim();
    if (text == null || text.isEmpty) return false;
    try {
      return RegExp(text).hasMatch(url);
    } catch (_) {
      return url.contains(text);
    }
  }

  String? _cookieHeader(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'cookie') return entry.value;
    }
    return null;
  }
}

class _SearchListResult {
  const _SearchListResult(
    this.items, {
    this.parseAsDetail = false,
  });

  final List<Object> items;
  final bool parseAsDetail;
}
