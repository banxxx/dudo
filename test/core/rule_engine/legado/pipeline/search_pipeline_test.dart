import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dudo/core/rule_engine/legado/legado_runtime.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchPipeline', () {
    test('uses detail page shortcut when bookUrlPattern matches final URL',
        () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/book/1'),
          html: '''
            <html><body>
              <h1>Alpha</h1>
              <span class="author">Author</span>
            </body></html>
          ''',
        ),
      );

      final results = await runtime.search(
        const SourceRule(
          id: 'source',
          name: 'Source',
          url: 'https://source.example/',
          search: SearchRule(
            searchUrl: '/book/1',
            bookUrlPattern: r'/book/\d+$',
            name: 'tag.h1@text',
            author: 'class.author@text',
            bookUrl: '@get:{result}',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(1));
      expect(results.single.name, 'Alpha');
      expect(results.single.author, 'Author');
      expect(results.single.bookUrl, 'https://source.example/book/1');
    });

    test('falls back to detail page parsing when bookList is empty', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/search?q=alpha'),
          html: '''
            <html><body>
              <h1>Alpha</h1>
              <span class="author">Author</span>
              <a class="detail" href="/book/1">detail</a>
            </body></html>
          ''',
        ),
      );

      final results = await runtime.search(
        const SourceRule(
          id: 'source',
          name: 'Source',
          url: 'https://source.example/',
          search: SearchRule(
            searchUrl: '/search?q={{key}}',
            bookList: 'class.missing',
            name: 'tag.h1@text',
            author: 'class.author@text',
            bookUrl: 'class.detail@href',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(1));
      expect(results.single.name, 'Alpha');
      expect(results.single.bookUrl, 'https://source.example/book/1');
    });
  });
}

class _FakeExecutor implements LegadoRequestExecutor {
  const _FakeExecutor({
    required this.finalUri,
    required this.html,
  });

  final Uri finalUri;
  final String html;

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    return LegadoHttpResponse(
      bytes: utf8.encode(html),
      finalUri: finalUri,
      headers: Headers.fromMap({
        'content-type': ['text/html; charset=utf-8'],
      }),
      statusCode: 200,
    );
  }
}
