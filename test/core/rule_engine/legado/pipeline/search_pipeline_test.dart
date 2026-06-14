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
          bookUrlPattern: r'/book/\d+$',
          search: SearchRule(
            searchUrl: '/book/1',
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

    test('uses ruleBookInfo when empty bookList falls back to detail page',
        () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/book/1'),
          html: '''
            <html><body>
              <main>
                <h1>Alpha</h1>
                <span class="author">Author</span>
                <span class="kind">Fantasy</span>
              </main>
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
            bookList: 'class.missing',
          ),
          bookInfo: BookInfoRule(
            init: 'tag.main',
            name: 'tag.h1@text',
            author: 'class.author@text',
            kind: 'class.kind@text',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(1));
      expect(results.single.name, 'Alpha');
      expect(results.single.author, 'Author');
      expect(results.single.kind, 'Fantasy');
      expect(results.single.bookUrl, 'https://source.example/book/1');
    });

    test('evaluates multi-statement searchUrl javascript', () async {
      final requests = <LegadoRequest>[];
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          requests: requests,
          finalUri: Uri.parse('https://source.example/search?q=alpha'),
          html: '''
            <html><body>
              <h1>Alpha</h1>
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
            searchUrl:
                "@js:java.put('key', key); result = '/search?q={{key}}&page={{page}}'",
            name: 'tag.h1@text',
            bookUrl: 'class.detail@href',
          ),
        ),
        'Alpha',
      );

      expect(
        requests.single.url,
        'https://source.example/search?q=Alpha&page=1',
      );
      expect(results.single.bookUrl, 'https://source.example/book/1');
    });

    test('parses jjwxc android API merged title and author search', () async {
      final requests = <LegadoRequest>[];
      final runtime = LegadoRuntime.create(
        executor: _RoutingExecutor((request) {
          requests.add(request);
          if (request.url.contains('type=2')) {
            return _FakeResponse(
              Uri.parse(request.url),
              jsonEncode({
                'items': [
                  {
                    'novelId': 456,
                    'novelname': 'By Author',
                    'authorname': 'Beta',
                  },
                ],
              }),
            );
          }
          return _FakeResponse(
            Uri.parse(request.url),
            jsonEncode({
              'items': [
                {
                  'novelid': 123,
                  'novelname': 'By Title',
                  'authorname': 'Alpha',
                },
              ],
            }),
          );
        }),
      );

      final results = await runtime.search(
        const SourceRule(
          id: 'https://apps.jjwxc.net',
          name: 'jjwxc api',
          url: 'https://apps.jjwxc.net',
          search: SearchRule(
            searchUrl:
                'http://android.jjwxc.net/androidapi/search?keyword={{key}}&type=1&page={{page}}&searchType=1&sortMode=DESC',
            bookList: '''
              <js>
              json=[];
              if(JSON.parse(result).items){ json=JSON.parse(result).items; }
              json1=JSON.parse(java.ajax('http://android.jjwxc.net/androidapi/search?keyword='+key+'&type=2&page='+page+'&searchType=7&sortMode=DESC'));
              json2=json1.items || [];
              list=json.concat(json2);
              result=JSON.stringify(list)
              </js>
              \$.[*]
            ''',
            name: r'$.novelname@put:{id:$.novelid||$.novelId}',
            author: r'$.authorname',
            bookUrl:
                r'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId={{$.novelid||$.novelId}}',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(2));
      expect(
        results.map((item) => item.name),
        containsAll(['By Title', 'By Author']),
      );
      expect(
        results.map((item) => item.bookUrl),
        containsAll([
          'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=123',
          'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=456',
        ]),
      );
      expect(requests.any((request) => request.url.contains('type=2')), isTrue);
    });

    test('discards empty fallback items', () async {
      final runtime = LegadoRuntime.create(
        executor: _FakeExecutor(
          finalUri: Uri.parse('https://source.example/search?q=alpha'),
          html: '{"code":200,"message":"empty"}',
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
            name: 'class.title@text',
            author: 'class.author@text',
            bookUrl: 'class.detail@href',
          ),
        ),
        'Alpha',
      );

      expect(results, isEmpty);
    });

    test('converts jjwxc bookbase js detail list into field maps', () async {
      final runtime = LegadoRuntime.create(
        executor: _RoutingExecutor((request) {
          if (request.url.contains('onebook.php?novelid=123')) {
            return _FakeResponse(
              Uri.parse('http://www.jjwxc.net/onebook.php?novelid=123'),
              '''
                <html><body>
                  <h1 itemprop="name">Alpha</h1>
                  <span itemprop="author">Author</span>
                  <span itemprop="updataStatus">连载中</span>
                  <span itemprop="wordCount">1000字</span>
                  <span itemprop="genre">原创-言情</span>
                  <span style="color:#F98C4D">一句话简介：Intro</span>
                  <div id="novelintro">Long intro</div>
                  <img class="noveldefaultimage" src="/cover.jpg">
                  <table id="oneboolt">
                    <tr><td>1</td><td><span>第一章</span></td></tr>
                    <tr><td>2</td><td><span>*最新更新第二章[VIP]</span></td></tr>
                    <tr><td>footer</td></tr>
                  </table>
                </body></html>
              ''',
            );
          }
          return _FakeResponse(
            Uri.parse('https://www.jjwxc.net/bookbase.php?searchkeywords=x'),
            '''
              <html><body>
                <table class="cytable">
                  <tr><td>header</td></tr>
                  <tr>
                    <td>row</td>
                    <td>
                      <a href="/onebook.php?novelid=ignored">first</a>
                      <a href="/onebook.php?novelid=123">Alpha</a>
                    </td>
                  </tr>
                </table>
              </body></html>
            ''',
          );
        }),
      );

      final results = await runtime.search(
        const SourceRule(
          id: 'https://m.jjwxc.net/channel/',
          name: 'jjwxc',
          url: 'https://m.jjwxc.net/channel/',
          search: SearchRule(
            searchUrl: 'https://www.jjwxc.net/bookbase.php?searchkeywords=x',
            bookList: '''
              class.cytable@tag.tr[1:20]@tag.a[1]||\$.items[:20]
              <js>
              url="http://www.jjwxc.net/onebook.php?novelid="+id;
              html=String(java.ajax(url));
              json.push({title:title,author:author,url:url})
              </js>
            ''',
            name: 'title',
            author: 'author',
            bookUrl: 'url',
            kind: 'cat',
            lastChapter: 'new',
            intro: 'des',
            coverUrl: 'cover',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(1));
      expect(results.single.name, 'Alpha');
      expect(results.single.author, 'Author');
      expect(
        results.single.bookUrl,
        'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=123',
      );
      expect(results.single.kind, isNotEmpty);
      expect(results.single.lastChapter, isNotEmpty);
    });

    test('keeps jjwxc bookbase anchor when detail compatibility fails',
        () async {
      final runtime = LegadoRuntime.create(
        executor: _RoutingExecutor((request) {
          if (request.url.contains('onebook.php?novelid=123')) {
            return _FakeResponse(
              Uri.parse('http://www.jjwxc.net/onebook.php?novelid=123'),
              '<html><body>temporarily unavailable</body></html>',
            );
          }
          return _FakeResponse(
            Uri.parse('https://www.jjwxc.net/bookbase.php?searchkeywords=x'),
            '''
              <html><body>
                <table class="cytable">
                  <tr><td>header</td></tr>
                  <tr>
                    <td>row</td>
                    <td>
                      <a href="/onebook.php?novelid=ignored">first</a>
                      <a href="/onebook.php?novelid=123">Fallback Title</a>
                    </td>
                  </tr>
                </table>
              </body></html>
            ''',
          );
        }),
      );

      final results = await runtime.search(
        const SourceRule(
          id: 'https://m.jjwxc.net/channel/',
          name: 'jjwxc',
          url: 'https://m.jjwxc.net/channel/',
          search: SearchRule(
            searchUrl: 'https://www.jjwxc.net/bookbase.php?searchkeywords=x',
            bookList: '''
              class.cytable@tag.tr[1:20]@tag.a[1]||\$.items[:20]
              <js>
              url="http://www.jjwxc.net/onebook.php?novelid="+id;
              html=String(java.ajax(url));
              json.push({title:title,author:author,url:url})
              </js>
            ''',
            name: 'title',
            author: 'author',
            bookUrl: 'url',
          ),
        ),
        'Alpha',
      );

      expect(results, hasLength(1));
      expect(results.single.name, 'Fallback Title');
      expect(
        results.single.bookUrl,
        'http://app-cdn.jjwxc.net/androidapi/novelbasicinfo?novelId=123',
      );
    });
  });
}

class _FakeExecutor implements LegadoRequestExecutor {
  const _FakeExecutor({
    required this.finalUri,
    required this.html,
    this.requests,
  });

  final Uri finalUri;
  final String html;
  final List<LegadoRequest>? requests;

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    requests?.add(request);
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

class _FakeResponse {
  const _FakeResponse(this.finalUri, this.html);

  final Uri finalUri;
  final String html;
}

class _RoutingExecutor implements LegadoRequestExecutor {
  const _RoutingExecutor(this.handler);

  final _FakeResponse Function(LegadoRequest request) handler;

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    final response = handler(request);
    return LegadoHttpResponse(
      bytes: utf8.encode(response.html),
      finalUri: response.finalUri,
      headers: Headers.fromMap({
        'content-type': ['text/html; charset=utf-8'],
      }),
      statusCode: 200,
    );
  }
}
