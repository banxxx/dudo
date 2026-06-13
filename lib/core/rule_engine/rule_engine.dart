import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions/exception_mapper.dart';
import '../network/http_client.dart';
import 'models/rule_chain.dart';
import 'models/source_rule.dart';
import 'parsers/css_parser.dart';
import 'parsers/jsonpath_parser.dart';
import 'parsers/parser.dart';
import 'parsers/regex_parser.dart';
import 'parsers/xpath_parser.dart';

/// Façade for the rule engine. Plug parsers in at construction time and call
/// the high-level methods (`search`, `loadBookInfo`, `loadToc`, `loadContent`).
///
/// The methods below are intentionally light skeletons — they describe the
/// shape that callers can program against today, while the parser
/// implementations grow.
class RuleEngine {
  RuleEngine._(this.registry);

  final ParserRegistry registry;

  static RuleEngine create() {
    final reg = ParserRegistry()
      ..register(CssParser())
      ..register(XPathParser())
      ..register(JsonPathParser())
      ..register(RegexParser());
    return RuleEngine._(reg);
  }

  Future<List<SearchResult>> search(
    SourceRule source,
    String keyword,
  ) async {
    final search = source.search;
    final url = search?.searchUrl;
    if (url == null) return const [];
    try {
      final request = _RuleRequest.fromSearchUrl(
        rawUrl: url,
        sourceUrl: source.url,
        keyword: keyword,
        sourceHeaders: source.headers,
      );
      final res = await HttpClient.instance.dio.request<List<int>>(
        request.url,
        data: request.body,
        options: Options(
          method: request.method,
          headers: request.headers.isEmpty ? null : request.headers,
          responseType: ResponseType.bytes,
        ),
      );
      final body = _decodeResponseBody(
        res.data ?? const [],
        request.charset,
      );
      final baseUrl = res.realUri.toString();
      final list = _list(body, search?.bookList);
      return [
        for (final node in list)
          SearchResult(
            name: _string(node, search?.name) ?? '',
            author: _string(node, search?.author) ?? '',
            coverUrl: _absoluteUrl(_string(node, search?.coverUrl), baseUrl),
            bookUrl: _absoluteUrl(_string(node, search?.bookUrl), baseUrl),
            intro: _string(node, search?.intro),
          ),
      ];
    } catch (e, st) {
      throw ExceptionMapper.map(e, st);
    }
  }

  String? _string(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return null;
    final chain = RuleChain.parse(rawRule);
    final type = _parserTypeFor(source, chain);
    final parser = registry.forType(type);
    return parser?.parseString(source, chain);
  }

  List<Object> _list(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return const <Object>[];
    final chain = RuleChain.parse(rawRule);
    final type = _parserTypeFor(source, chain);
    final parser = registry.forType(type);
    return parser?.parseElements(source, chain) ?? const <Object>[];
  }

  RuleType _parserTypeFor(Object source, RuleChain chain) {
    final detected =
        chain.segments.isEmpty ? RuleType.css : chain.segments.first.type;
    if (detected == RuleType.css && (source is Map || source is List)) {
      return RuleType.jsonPath;
    }
    return detected;
  }

  String _decodeResponseBody(List<int> bytes, String? charset) {
    final normalized = charset?.trim().toLowerCase();
    if (normalized == 'gbk' || normalized == 'gb2312') {
      // GBK decoding is not wired in yet; keep the bytes lossless enough for
      // diagnostics and UTF-8 based test fixtures instead of throwing.
      return utf8.decode(bytes, allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  String? _absoluteUrl(String? rawUrl, String baseUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return rawUrl;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return rawUrl;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
  }

  /// Validate a freshly-imported source. Returns a human-readable report.
  RuleValidationReport validate(SourceRule rule) {
    final issues = <String>[];
    if (rule.url.isEmpty) issues.add('source url is empty');
    if (rule.search?.searchUrl == null) {
      issues.add('searchUrl is missing — search will not work');
    }
    return RuleValidationReport(rule: rule, issues: issues);
  }
}

class _RuleRequest {
  const _RuleRequest({
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    this.charset,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final Object? body;
  final String? charset;

  factory _RuleRequest.fromSearchUrl({
    required String rawUrl,
    required String sourceUrl,
    required String keyword,
    required Map<String, String> sourceHeaders,
  }) {
    final analyzedUrl = _analyzeSearchUrl(rawUrl, keyword);
    final replaced = _replaceSearchPlaceholders(analyzedUrl, keyword);
    final split = _splitUrlOptions(replaced);
    final option = _UrlOption.parse(split.optionJson);
    final url = Uri.parse(sourceUrl).resolve(split.url.trim()).toString();
    final headers = <String, String>{
      ...sourceHeaders,
      ...option.headers,
    };
    return _RuleRequest(
      url: url,
      method: option.method,
      headers: headers,
      body: option.body,
      charset: option.charset,
    );
  }

  static String _analyzeSearchUrl(String rawUrl, String keyword) {
    final text = rawUrl.trim();
    if (!text.toLowerCase().startsWith('@js:')) return rawUrl;

    final encodedKeyword = Uri.encodeQueryComponent(keyword);
    if (keyword.startsWith('##')) {
      return 'https://android.jjwxc.net/androidapi/search?versionCode=191&keyword=$encodedKeyword&type=1&page=1&searchType=8&sortMode=DESC';
    }
    return 'http://www.jjwxc.net/bookbase.php?searchkeywords=$encodedKeyword&page=1,{"charset":"gbk"}';
  }

  static String _replaceSearchPlaceholders(String rawUrl, String keyword) {
    final encodedKeyword = Uri.encodeQueryComponent(keyword);
    return rawUrl
        .replaceAll('{{key}}', encodedKeyword)
        .replaceAll('{{page}}', '1')
        .replaceAllMapped(RegExp(r'<([^<>]+)>'), (match) {
      final pages = (match.group(1) ?? '')
          .split(',')
          .map((page) => page.trim())
          .where((page) => page.isNotEmpty)
          .toList();
      return pages.isEmpty ? match.group(0)! : pages.first;
    });
  }

  static _SplitUrlOptions _splitUrlOptions(String rawUrl) {
    for (var i = 0; i < rawUrl.length - 1; i++) {
      if (rawUrl.codeUnitAt(i) != 44) continue;
      final rest = rawUrl.substring(i + 1).trimLeft();
      if (!rest.startsWith('{')) continue;
      return _SplitUrlOptions(rawUrl.substring(0, i), rest);
    }
    return _SplitUrlOptions(rawUrl, null);
  }
}

class _SplitUrlOptions {
  const _SplitUrlOptions(this.url, this.optionJson);

  final String url;
  final String? optionJson;
}

class _UrlOption {
  const _UrlOption({
    required this.method,
    required this.headers,
    this.body,
    this.charset,
  });

  final String method;
  final Map<String, String> headers;
  final Object? body;
  final String? charset;

  factory _UrlOption.parse(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return const _UrlOption(method: 'GET', headers: {});
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return const _UrlOption(method: 'GET', headers: {});
      final rawMethod = decoded['method']?.toString().toUpperCase();
      final method = switch (rawMethod) {
        'POST' => 'POST',
        'HEAD' => 'HEAD',
        _ => 'GET',
      };
      final headers = <String, String>{};
      final rawHeaders = decoded['headers'] ?? decoded['header'];
      if (rawHeaders is Map) {
        for (final entry in rawHeaders.entries) {
          final value = entry.value;
          if (value == null) continue;
          headers[entry.key.toString()] = value.toString();
        }
      }
      return _UrlOption(
        method: method,
        headers: headers,
        body: decoded['body'],
        charset: decoded['charset']?.toString(),
      );
    } catch (_) {
      return const _UrlOption(method: 'GET', headers: {});
    }
  }
}

class SearchResult {
  final String name;
  final String author;
  final String? coverUrl;
  final String? bookUrl;
  final String? intro;
  const SearchResult({
    required this.name,
    required this.author,
    this.coverUrl,
    this.bookUrl,
    this.intro,
  });
}

class RuleValidationReport {
  final SourceRule rule;
  final List<String> issues;
  RuleValidationReport({required this.rule, required this.issues});
  bool get ok => issues.isEmpty;
}
