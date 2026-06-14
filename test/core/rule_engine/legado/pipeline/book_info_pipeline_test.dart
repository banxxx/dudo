import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dudo/core/rule_engine/legado/legado_runtime.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookInfoPipeline', () {
    test('loads book info with init and resolves URL fields', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/book/1'),
          html: '''
            <html><body>
              <main class="book">
                <h1>Alpha &amp; Beta</h1>
                <span class="author">Author</span>
                <span class="kind">Sci-Fi</span>
                <span class="last">Chapter 10</span>
                <p class="intro">Intro&nbsp;text</p>
                <img class="cover" src="/covers/1.jpg" />
                <a class="toc" href="toc.html">toc</a>
                <span class="words">12345</span>
              </main>
            </body></html>
          ''',
        ),
      );

      final info = await runtime.loadBookInfo(_source(), '/book/1');

      expect(info, isNotNull);
      expect(info!.name, 'Alpha & Beta');
      expect(info.author, 'Author');
      expect(info.kind, 'Sci-Fi');
      expect(info.lastChapter, 'Chapter 10');
      expect(info.intro, 'Intro text');
      expect(info.coverUrl, 'https://source.example/covers/1.jpg');
      expect(info.tocUrl, 'https://source.example/book/toc.html');
      expect(info.wordCount, '12345');
    });

    test('is exposed through RuleEngine facade', () async {
      final engine = RuleEngine.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/book/1'),
          html:
              '<main class="book"><h1>Alpha</h1><span class="author">Author</span></main>',
        ),
      );

      final info = await engine.loadBookInfo(_source(), '/book/1');

      expect(info?.name, 'Alpha');
      expect(info?.author, 'Author');
    });
  });
}

SourceRule _source() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    bookInfo: BookInfoRule(
      init: 'class.book',
      name: 'tag.h1@text',
      author: 'class.author@text',
      kind: 'class.kind@text',
      lastChapter: 'class.last@text',
      intro: 'class.intro@text',
      coverUrl: 'class.cover@src',
      tocUrl: 'class.toc@href',
      wordCount: 'class.words@text',
    ),
  );
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
