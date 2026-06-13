import 'dart:convert';

import 'package:dio/dio.dart' hide ResponseDecoder;
import 'package:dudo/core/rule_engine/legado/decode/response_decoder.dart'
    as legado;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponseDecoder', () {
    test('uses explicit charset over headers', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: utf8.encode('三体'),
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=iso-8859-1'],
        }),
        statusCode: 200,
        explicitCharset: 'utf-8',
      );

      expect(decoded.text, '三体');
      expect(decoded.charset, 'utf-8');
    });

    test('detects charset from content type header', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: utf8.encode('ok'),
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['application/json; charset=utf8'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, 'ok');
      expect(decoded.charset, 'utf-8');
    });
  });
}
