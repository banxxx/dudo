import 'dart:convert';

import 'package:dio/dio.dart' hide ResponseDecoder;
import 'package:dudo/core/rule_engine/legado/common/legado_trace.dart';
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

    test('uses response header charset before HTML meta charset', () async {
      const decoder = legado.ResponseDecoder();
      const html =
          '<html><head><meta charset="gbk"></head><body>中文</body></html>';
      final decoded = await decoder.decode(
        bytes: utf8.encode(html),
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, html);
      expect(decoded.charset, 'utf-8');
    });

    test('decodes GBK fixture', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: [0xD6, 0xD0, 0xCE, 0xC4],
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=gbk'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, '中文');
      expect(decoded.charset, 'gb18030');
    });

    test('decodes GB2312 fixture', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: [0xD6, 0xD0, 0xCE, 0xC4],
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=gb2312'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, '中文');
      expect(decoded.charset, 'gb18030');
    });

    test('decodes GB18030 fixture', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: [0xD6, 0xD0, 0xCE, 0xC4],
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=gb18030'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, '中文');
      expect(decoded.charset, 'gb18030');
    });

    test('decodes Big5 fixture', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: [0xA4, 0xA4, 0xA4, 0xE5],
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=big5'],
        }),
        statusCode: 200,
      );

      expect(decoded.text, '中文');
      expect(decoded.charset, 'big5');
    });

    test('decodes UTF-16 fixture from BOM', () async {
      const decoder = legado.ResponseDecoder();
      final decoded = await decoder.decode(
        bytes: [0xFF, 0xFE, 0x2D, 0x4E, 0x87, 0x65],
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers(),
        statusCode: 200,
      );

      expect(decoded.text, '中文');
      expect(decoded.charset, 'utf-16le');
    });

    test('writes decode diagnostics into trace', () async {
      const decoder = legado.ResponseDecoder();
      final trace = LegadoTrace();

      await decoder.decode(
        bytes: utf8.encode('ok'),
        finalUri: Uri.parse('https://source.example/search'),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['application/json; charset=utf8'],
        }),
        statusCode: 200,
        trace: trace,
      );

      expect(
        trace.events,
        containsAll([
          'response.status:200',
          'response.length:2',
          'response.finalUri:https://source.example/search',
          'decode.charsetSource:header',
          'decode.charset:utf-8',
        ]),
      );
    });
  });
}
