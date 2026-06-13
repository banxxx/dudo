import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:charset_converter/charset_converter.dart';

class DecodedLegadoResponse {
  const DecodedLegadoResponse({
    required this.text,
    required this.charset,
    required this.finalUri,
    required this.headers,
    required this.statusCode,
    required this.bytes,
  });

  final String text;
  final String charset;
  final Uri finalUri;
  final Headers headers;
  final int? statusCode;
  final List<int> bytes;
}

class ResponseDecoder {
  const ResponseDecoder();

  Future<DecodedLegadoResponse> decode({
    required List<int> bytes,
    required Uri finalUri,
    required Headers headers,
    required int? statusCode,
    String? explicitCharset,
  }) async {
    final charset = _resolveCharset(
      bytes: bytes,
      headers: headers,
      explicitCharset: explicitCharset,
    );
    return DecodedLegadoResponse(
      text: await _decodeBytes(bytes, charset),
      charset: charset,
      finalUri: finalUri,
      headers: headers,
      statusCode: statusCode,
      bytes: bytes,
    );
  }

  String _resolveCharset({
    required List<int> bytes,
    required Headers headers,
    String? explicitCharset,
  }) {
    final explicit = _normalizeCharset(explicitCharset);
    if (explicit != null) return explicit;

    final contentType = headers.value(Headers.contentTypeHeader);
    final headerCharset = _charsetFromContentType(contentType);
    if (headerCharset != null) return headerCharset;

    final bomCharset = _charsetFromBom(bytes);
    if (bomCharset != null) return bomCharset;

    final preview =
        latin1.decode(bytes.take(4096).toList(), allowInvalid: true);
    final metaCharset = _charsetFromHtmlMeta(preview);
    if (metaCharset != null) return metaCharset;

    return 'utf-8';
  }

  String? _charsetFromContentType(String? contentType) {
    if (contentType == null) return null;
    final match = RegExp(
      r'''charset\s*=\s*["']?([^;'\s]+)''',
      caseSensitive: false,
    ).firstMatch(contentType);
    return _normalizeCharset(match?.group(1));
  }

  String? _charsetFromBom(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'utf-8';
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return 'utf-16le';
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return 'utf-16be';
    }
    return null;
  }

  String? _charsetFromHtmlMeta(String preview) {
    final direct = RegExp(
      r'''<meta[^>]+charset\s*=\s*["']?([^\s"'>/;]+)''',
      caseSensitive: false,
    ).firstMatch(preview);
    final directCharset = _normalizeCharset(direct?.group(1));
    if (directCharset != null) return directCharset;

    final httpEquiv = RegExp(
      r'''<meta[^>]+content\s*=\s*["'][^"']*charset\s*=\s*([^\s"'>/;]+)''',
      caseSensitive: false,
    ).firstMatch(preview);
    return _normalizeCharset(httpEquiv?.group(1));
  }

  String? _normalizeCharset(String? charset) {
    final normalized = charset?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return switch (normalized) {
      'utf8' => 'utf-8',
      'gb2312' || 'gbk' || 'gb18030' => 'gb18030',
      _ => normalized,
    };
  }

  Future<String> _decodeBytes(List<int> bytes, String charset) async {
    final data = Uint8List.fromList(bytes);
    if (charset == 'utf-8') return utf8.decode(data, allowMalformed: true);
    if (charset == 'utf-16le') return _decodeUtf16(data, endian: Endian.little);
    if (charset == 'utf-16be') return _decodeUtf16(data, endian: Endian.big);
    try {
      return await CharsetConverter.decode(charset, data);
    } catch (_) {
      return utf8.decode(data, allowMalformed: true);
    }
  }

  String _decodeUtf16(Uint8List bytes, {required Endian endian}) {
    final offset = bytes.length >= 2 &&
            ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
                (bytes[0] == 0xFE && bytes[1] == 0xFF))
        ? 2
        : 0;
    final data = ByteData.sublistView(bytes, offset);
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < data.lengthInBytes; i += 2) {
      codeUnits.add(data.getUint16(i, endian));
    }
    return String.fromCharCodes(codeUnits);
  }
}
