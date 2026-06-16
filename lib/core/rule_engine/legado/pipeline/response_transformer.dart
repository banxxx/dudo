import 'dart:convert';

import '../../models/source_rule.dart';
import '../decode/response_decoder.dart';
import '../js/legado_js_engine.dart';
import '../runtime/legado_runtime_context.dart';
import '../rule/rule_context.dart';
import '../url/cookie_merge.dart';
import '../url/request_executor.dart';

class LegadoResponseTransformer {
  const LegadoResponseTransformer();

  Future<DecodedLegadoResponse> decodeAndTransform({
    required ResponseDecoder decoder,
    required LegadoRequest request,
    required LegadoHttpResponse response,
    required SourceRule source,
    required LegadoJsEngine jsEngine,
    required LegadoTrace trace,
    LegadoRuntimeContext? runtimeContext,
    String keyword = '',
    int page = 1,
    Object? book,
    Map<String, Object?>? variables,
    LegadoJsAjax? ajax,
    LegadoCookieStore? cookieStore,
  }) async {
    cookieStore?.saveFromResponse(
      response.finalUri,
      _setCookieHeaders(response.headers.map),
    );
    var decoded = await decoder.decode(
      bytes: response.bytes,
      finalUri: response.finalUri,
      headers: response.headers,
      statusCode: response.statusCode,
      explicitCharset: request.charset,
      trace: runtimeContext?.trace ?? trace,
    );
    final effectiveTrace = runtimeContext?.trace ?? trace;
    final effectiveSource = runtimeContext?.source ?? source;
    final effectiveKeyword = runtimeContext?.keyword ?? keyword;
    final effectivePage = runtimeContext?.page ?? page;
    final effectiveBook = runtimeContext?.book ?? book;
    final effectiveVariables =
        variables ?? runtimeContext?.variables.asMap() ?? <String, Object?>{};
    decoded = _applySourceRegex(decoded, request, effectiveTrace);
    final bodyJs = request.bodyJs?.trim();
    if (bodyJs == null || bodyJs.isEmpty) return decoded;

    effectiveTrace.add('response.bodyJs:start');
    final value = await jsEngine.evalAsync(
      bodyJs,
      context: LegadoJsContext(
        key: effectiveKeyword,
        page: effectivePage,
        baseUrl: decoded.finalUri.toString(),
        src: decoded.text,
        result: decoded.text,
        source: effectiveSource,
        book: effectiveBook,
        variables: effectiveVariables,
        cookie: _cookieHeader(request.headers),
        ajax: ajax,
        trace: effectiveTrace,
      ),
    );
    final transformed = _stringifyBodyJsValue(value);
    effectiveTrace
      ..add('response.bodyJs:done')
      ..add('response.bodyJs.length:${transformed.length}');
    return DecodedLegadoResponse(
      text: transformed,
      charset: 'utf-8',
      finalUri: decoded.finalUri,
      headers: decoded.headers,
      statusCode: decoded.statusCode,
      bytes: utf8.encode(transformed),
    );
  }

  String _stringifyBodyJsValue(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  DecodedLegadoResponse _applySourceRegex(
    DecodedLegadoResponse decoded,
    LegadoRequest request,
    LegadoTrace trace,
  ) {
    final rawPattern = request.sourceRegex?.trim();
    if (rawPattern == null || rawPattern.isEmpty) return decoded;

    try {
      final pattern = RegExp(rawPattern, dotAll: true, multiLine: true);
      final match = pattern.firstMatch(decoded.text);
      if (match == null) {
        trace.add('response.sourceRegex:miss');
        return decoded;
      }
      final extracted = match.groupCount > 0
          ? match.group(1) ?? match.group(0) ?? ''
          : match.group(0) ?? '';
      trace
        ..add('response.sourceRegex:done')
        ..add('response.sourceRegex.length:${extracted.length}');
      return DecodedLegadoResponse(
        text: extracted,
        charset: 'utf-8',
        finalUri: decoded.finalUri,
        headers: decoded.headers,
        statusCode: decoded.statusCode,
        bytes: utf8.encode(extracted),
      );
    } on FormatException catch (error) {
      trace.add('response.sourceRegex.invalid:${error.message}');
      return decoded;
    }
  }

  String? _cookieHeader(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'cookie') return entry.value;
    }
    return null;
  }

  Iterable<String> _setCookieHeaders(Map<String, List<String>> headers) sync* {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      yield* entry.value;
    }
  }
}
