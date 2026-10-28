import 'package:dio/dio.dart' show Options, ResponseType;

import '../../../core/network/http_client.dart';
import 'source_text_decoder.dart';

/// Fetches a subscription / source-list URL and returns its decoded text.
///
/// Legado supports a `#requestWithoutUA` suffix to suppress the default
/// User-Agent; callers strip the suffix and pass [withoutUserAgent].
typedef SourceImportFetcher = Future<String> Function(
  String url, {
  bool withoutUserAgent,
});

Future<String> fetchSourceImportUrl(
  String url, {
  bool withoutUserAgent = false,
}) async {
  final response = await HttpClient.instance.dio.get<List<int>>(
    url,
    options: Options(
      responseType: ResponseType.bytes,
      headers: withoutUserAgent ? const {'User-Agent': 'null'} : null,
    ),
  );
  // Source packs are JSON rule files, not HTML pages: decode them with the
  // import decoder so BOM and GBK/GB18030 responses work even when the server
  // omits a charset header.
  return decodeSourceImportText(response.data ?? const <int>[]);
}
