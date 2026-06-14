import 'package:dudo/core/rule_engine/legado/url/analyze_url.dart';
import 'package:dudo/core/rule_engine/legado/url/cookie_merge.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/legado/url/url_placeholder.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyzeUrl', () {
    test('compiles placeholders and merges URL options', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            '/search?q={{key}}&p={{page}}, {"method":"POST","body":"a=1","headers":{"Referer":"https://ref.example"},"charset":"gbk"}',
        keyword: '三体',
        page: 2,
      );

      expect(request.url, 'https://source.example/search');
      expect(request.method, 'POST');
      expect(request.body, 'a=1');
      expect(request.charset, 'gbk');
      expect(request.headers['User-Agent'], 'Test UA');
      expect(request.headers['Referer'], 'https://ref.example');
    });

    test('merges stored cookie into request headers', () {
      const analyzeUrl = AnalyzeUrl(
        cookieProvider: _FakeCookieProvider('sid=stored; theme=dark'),
      );
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search?q={{key}}',
        keyword: '三体',
      );

      expect(request.headers['Cookie'], 'sid=stored; theme=dark');
    });

    test('request cookie overrides stored cookie with same name', () {
      const analyzeUrl = AnalyzeUrl(
        cookieProvider: _FakeCookieProvider('sid=stored; theme=dark'),
      );
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search,{"headers":{"Cookie":"sid=request; token=abc"}}',
        keyword: '三体',
      );

      expect(request.headers['Cookie'], 'sid=request; theme=dark; token=abc');
    });

    test('URL option cookie overrides source cookie after header overlay', () {
      const analyzeUrl = AnalyzeUrl(
        cookieProvider: _FakeCookieProvider('sid=stored; stored=yes'),
      );
      final request = analyzeUrl.compileSearch(
        source: _source(headers: {'Cookie': 'sid=source; source=yes'}),
        rawUrl: '/search,{"headers":{"Cookie":"sid=option; option=yes"}}',
        keyword: '三体',
      );

      expect(request.headers['Cookie'], 'sid=option; stored=yes; option=yes');
    });

    test('normalizes lowercase cookie header to canonical Cookie', () {
      const analyzeUrl = AnalyzeUrl(
        cookieProvider: _FakeCookieProvider('stored=1'),
      );
      final request = analyzeUrl.compileSearch(
        source: _source(headers: {'cookie': 'lower=1'}),
        rawUrl: '/search',
        keyword: '三体',
      );

      expect(request.headers['Cookie'], 'stored=1; lower=1');
      expect(request.headers.containsKey('cookie'), isFalse);
    });

    test('does not inject Cookie header when no cookies exist', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search',
        keyword: '三体',
      );

      expect(request.headers.containsKey('Cookie'), isFalse);
    });

    test('carries bodyJs and webJs URL option metadata', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            '/search,{"bodyJs":"result.replace(\'a\',\'b\')","webJs":"document.body.innerText"}',
        keyword: '三体',
      );

      expect(request.bodyJs, "result.replace('a','b')");
      expect(request.webJs, 'document.body.innerText');
    });

    test('normalizes blank bodyJs and webJs to null', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search,{"bodyJs":"","webJs":"   "}',
        keyword: '三体',
      );

      expect(request.bodyJs, isNull);
      expect(request.webJs, isNull);
    });

    test('parses webView truthiness and delay metadata', () {
      const analyzeUrl = AnalyzeUrl();

      LegadoRequest compile(Object webView) {
        final encoded = webView is String ? '"$webView"' : webView.toString();
        return analyzeUrl.compileSearch(
          source: _source(),
          rawUrl: '/search,{"webView":$encoded,"webViewDelayTime":"500"}',
          keyword: '三体',
        );
      }

      expect(compile(false).useWebView, isFalse);
      expect(compile('false').useWebView, isFalse);
      expect(compile('').useWebView, isFalse);
      expect(compile(true).useWebView, isTrue);
      expect(compile('true').useWebView, isTrue);
      expect(compile('1').useWebView, isTrue);
      expect(compile(true).webViewDelayTime, 500);
    });

    test('POST strips query and uses encoded form body', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search?keyword={{key}}&page={{page}}, {"method":"POST"}',
        keyword: '三体',
        page: 2,
      );

      expect(request.url, 'https://source.example/search');
      expect(request.method, 'POST');
      expect(request.body, 'keyword=%E4%B8%89%E4%BD%93&page=2');
      expect(
          request.headers['Content-Type'], 'application/x-www-form-urlencoded');
    });

    test('POST explicit body overrides query body', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            '/search?ignored={{key}},{"method":"POST","body":"keyword={{key}}"}',
        keyword: '三体',
      );

      expect(request.url, 'https://source.example/search');
      expect(request.body, 'keyword=%E4%B8%89%E4%BD%93');
    });

    test('POST explicit content type preserves raw body', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            '/search,{"method":"POST","body":"keyword=三体","headers":{"content-type":"text/plain"}}',
        keyword: '三体',
      );

      expect(request.body, 'keyword=三体');
      expect(request.headers['content-type'], 'text/plain');
      expect(request.headers.containsKey('Content-Type'), isFalse);
    });

    test('POST JSON string body stays raw with JSON content type', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search,{"method":"POST","body":"{\\"keyword\\":\\"三体\\"}"}',
        keyword: '三体',
      );

      expect(request.body, '{"keyword":"三体"}');
      expect(
          request.headers['Content-Type'], 'application/json; charset=utf-8');
    });

    test('POST JSON object body is encoded as JSON text', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search,{"method":"POST","body":{"keyword":"三体"}}',
        keyword: '三体',
      );

      expect(request.body, '{"keyword":"三体"}');
      expect(
          request.headers['Content-Type'], 'application/json; charset=utf-8');
    });

    test('POST XML body stays raw', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            r'/search,{"method":"POST","body":"<xml><keyword>三体</keyword></xml>"}',
        keyword: '三体',
      );

      expect(request.body, '<xml><keyword>三体</keyword></xml>');
      expect(request.headers.containsKey('Content-Type'), isFalse);
    });

    test('POST preserves already encoded form values', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search?q=%E4%B8%89%E4%BD%93,{"method":"POST"}',
        keyword: '三体',
      );

      expect(request.body, 'q=%E4%B8%89%E4%BD%93');
    });

    test('POST supports escape charset form encoding', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search,{"method":"POST","body":"q=三体","charset":"escape"}',
        keyword: '三体',
      );

      expect(request.body, 'q=%u4e09%u4f53');
    });

    test('evaluates @js URL rules generically', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: r'@js:"/search?q=" + encodeURIComponent(key) + "&p=" + page',
        keyword: '三体',
        page: 2,
      );

      expect(
        request.url,
        'https://source.example/search?q=%E4%B8%89%E4%BD%93&p=2',
      );
      expect(request.url, isNot(contains('jjwxc')));
    });

    test('evaluates <js> URL rules generically', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: r'<js>"/search?q=" + encodeURI(key) + "&p=" + page</js>',
        keyword: '三体',
        page: 2,
      );

      expect(
        request.url,
        'https://source.example/search?q=%E4%B8%89%E4%BD%93&p=2',
      );
    });

    test('evaluates URL JS rules before URL options parsing', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            r'@js:"/search?q=" + encodeURIComponent(key) + ",{" + "\"method\":\"POST\",\"body\":\"k=1\",\"charset\":\"gbk\"}"',
        keyword: '三体',
      );

      expect(request.url, 'https://source.example/search');
      expect(request.method, 'POST');
      expect(request.body, 'k=1');
      expect(request.charset, 'gbk');
    });

    test('supports result assignment in URL JS rules', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: r'@js:result = "/search?p=" + (page + 1);',
        keyword: '三体',
        page: 2,
      );

      expect(request.url, 'https://source.example/search?p=3');
    });

    test('evaluates AnalyzeUrl JS expressions', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl:
            '/search?q={{encodeURIComponent(key + " " + page)}}&p={{page + 1}}',
        keyword: '三体',
        page: 2,
      );

      expect(
        request.url,
        'https://source.example/search?q=%E4%B8%89%E4%BD%93%202&p=3',
      );
    });

    test('evaluates AnalyzeUrl expression before URL options parsing', () {
      const analyzeUrl = AnalyzeUrl();
      final request = analyzeUrl.compileSearch(
        source: _source(),
        rawUrl: '/search?q={{"a,b"}}, {"charset":"utf-8"}',
        keyword: '三体',
      );

      expect(request.url, 'https://source.example/search?q=a,b');
      expect(request.charset, 'utf-8');
    });

    test('keeps unsupported URL JS expressions unchanged', () {
      const placeholder = LegadoUrlPlaceholder();

      expect(
        placeholder.apply(rawUrl: '/search?q={{Math.random()}}', keyword: '三体'),
        '/search?q={{Math.random()}}',
      );
    });

    test('keeps malformed URL JS expressions unchanged', () {
      const placeholder = LegadoUrlPlaceholder();

      expect(
        placeholder.apply(rawUrl: '/search?q={{page + }}', keyword: '三体'),
        '/search?q={{page + }}',
      );
    });

    test('does not end URL JS expressions inside quoted braces', () {
      const placeholder = LegadoUrlPlaceholder();

      expect(
        placeholder.apply(rawUrl: r'/search?q={{"a}}b"}}', keyword: '三体'),
        r'/search?q=a}}b',
      );
    });

    test('keeps legacy page selector behavior', () {
      const placeholder = LegadoUrlPlaceholder();

      expect(
        placeholder.apply(
            rawUrl: '/search/<p1,p2,p3>?q={{key}}', keyword: '三体', page: 2),
        '/search/p2?q=%E4%B8%89%E4%BD%93',
      );
    });

    test(
        'splits options without treating commas inside brackets as option boundary',
        () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        'https://source.example/search?tag=a,b&x=(1,2),{"charset":"utf-8"}',
      );

      expect(split.url, 'https://source.example/search?tag=a,b&x=(1,2)');
      expect(split.optionJson, '{"charset":"utf-8"}');
    });

    test('splits options after nested JSON and quoted comma content', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        'https://source.example/search?q=foo,{"method":"POST","body":{"ids":[1,2,{"x":"a,b"}]},"headers":{"X":"{not split, here}"}}',
      );

      expect(split.url, 'https://source.example/search?q=foo');
      expect(
        split.optionJson,
        '{"method":"POST","body":{"ids":[1,2,{"x":"a,b"}]},"headers":{"X":"{not split, here}"}}',
      );
    });

    test('ignores option-looking commas inside JS-like URL expressions', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        '@js:result = buildUrl(foo({a:[1,2,"x,y"]})),{"charset":"utf-8"}',
      );

      expect(split.url, '@js:result = buildUrl(foo({a:[1,2,"x,y"]}))');
      expect(split.optionJson, '{"charset":"utf-8"}');
    });

    test('ignores commas inside JS blocks before options', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        '<js>result = fn({a: "x,y"}, [1,2]);</js>,{"charset":"utf-8"}',
      );

      expect(split.url, '<js>result = fn({a: "x,y"}, [1,2]);</js>');
      expect(split.optionJson, '{"charset":"utf-8"}');
    });

    test('ignores commas inside backtick strings before options', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        r'@js:result = `${foo},${bar}`,{"charset":"utf-8"}',
      );

      expect(split.url, r'@js:result = `${foo},${bar}`');
      expect(split.optionJson, r'{"charset":"utf-8"}');
    });

    test('does not split top-level comma followed by non-options text', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        'https://source.example/search?a=1,notOptions',
      );

      expect(split.url, 'https://source.example/search?a=1,notOptions');
      expect(split.optionJson, isNull);
    });

    test('does not split object-like text nested in URL side', () {
      const analyzeUrl = AnalyzeUrl();
      final split = analyzeUrl.splitOptions(
        'https://source.example/search?q=fn({"a":"b,c"})',
      );

      expect(split.url, 'https://source.example/search?q=fn({"a":"b,c"})');
      expect(split.optionJson, isNull);
    });
  });
}

SourceRule _source({Map<String, String>? headers}) {
  return SourceRule(
    id: 'https://source.example/base/',
    name: '测试源',
    url: 'https://source.example/base/',
    headers: headers ?? const {'User-Agent': 'Test UA'},
  );
}

class _FakeCookieProvider implements LegadoCookieProvider {
  const _FakeCookieProvider(this.cookie);

  final String? cookie;

  @override
  String? cookieFor(Uri uri) => cookie;
}
