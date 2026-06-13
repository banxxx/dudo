import 'package:dio/dio.dart';

import '../../../network/http_client.dart';

class LegadoRequest {
  const LegadoRequest({
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
}

class LegadoHttpResponse {
  const LegadoHttpResponse({
    required this.bytes,
    required this.finalUri,
    required this.headers,
    required this.statusCode,
  });

  final List<int> bytes;
  final Uri finalUri;
  final Headers headers;
  final int? statusCode;
}

abstract interface class LegadoRequestExecutor {
  Future<LegadoHttpResponse> execute(LegadoRequest request);
}

class DioLegadoRequestExecutor implements LegadoRequestExecutor {
  const DioLegadoRequestExecutor();

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    final response = await HttpClient.instance.dio.request<List<int>>(
      request.url,
      data: request.body,
      options: Options(
        method: request.method,
        headers: request.headers.isEmpty ? null : request.headers,
        responseType: ResponseType.bytes,
      ),
    );
    return LegadoHttpResponse(
      bytes: response.data ?? const [],
      finalUri: response.realUri,
      headers: response.headers,
      statusCode: response.statusCode,
    );
  }
}
