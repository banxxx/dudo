import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dudo/core/rule_engine/legado/legado_runtime.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TocPipeline', () {
    test('loads chapters and resolves toc URLs', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/book/toc/index.html'),
          html: '''
            <html><body>
              <ol class="chapters">
                <li class="chapter">
                  <a href="1.html">Chapter&nbsp;1</a>
                  <span class="volume">false</span>
                  <span class="vip">0</span>
                  <span class="pay">free</span>
                  <time>2026-01-01</time>
                </li>
                <li class="chapter">
                  <a href="/book/2.html">Chapter 2</a>
                  <span class="volume">true</span>
                  <span class="vip">1</span>
                  <span class="pay">paid</span>
                  <time>2026-01-02</time>
                </li>
              </ol>
              <a class="next" href="../toc/page-2.html">next</a>
            </body></html>
          ''',
        ),
      );

      final toc = await runtime.loadToc(_source(), '/book/toc/index.html');

      expect(toc, isNotNull);
      expect(toc!.nextTocUrl, 'https://source.example/book/toc/page-2.html');
      expect(toc.chapters, hasLength(2));
      expect(toc.chapters[0].name, 'Chapter 1');
      expect(
        toc.chapters[0].url,
        'https://source.example/book/toc/1.html',
      );
      expect(toc.chapters[0].isVolume, 'false');
      expect(toc.chapters[0].isVip, '0');
      expect(toc.chapters[0].isPay, 'free');
      expect(toc.chapters[0].updateTime, '2026-01-01');
      expect(toc.chapters[1].name, 'Chapter 2');
      expect(toc.chapters[1].url, 'https://source.example/book/2.html');
      expect(toc.chapters[1].isVolume, 'true');
      expect(toc.chapters[1].isVip, '1');
      expect(toc.chapters[1].isPay, 'paid');
      expect(toc.chapters[1].updateTime, '2026-01-02');
    });

    test('is exposed through RuleEngine facade', () async {
      final engine = RuleEngine.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/toc.html'),
          html:
              '<ul><li class="chapter"><a href="c1.html">Chapter 1</a></li></ul>',
        ),
      );

      final toc = await engine.loadToc(_source(), '/toc.html');

      expect(toc?.chapters, hasLength(1));
      expect(toc?.chapters.single.name, 'Chapter 1');
      expect(toc?.chapters.single.url, 'https://source.example/c1.html');
    });
  });
}

SourceRule _source() {
  return const SourceRule(
    id: 'source',
    name: 'Source',
    url: 'https://source.example/',
    toc: TocRule(
      chapterList: 'class.chapter',
      chapterName: 'tag.a@text',
      chapterUrl: 'tag.a@href',
      nextTocUrl: 'class.next@href',
      isVolume: 'class.volume@text',
      isVip: 'class.vip@text',
      isPay: 'class.pay@text',
      updateTime: 'tag.time@text',
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
