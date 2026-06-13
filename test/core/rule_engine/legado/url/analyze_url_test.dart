import 'package:dudo/core/rule_engine/legado/url/analyze_url.dart';
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

      expect(request.url,
          'https://source.example/search?q=%E4%B8%89%E4%BD%93&p=2');
      expect(request.method, 'POST');
      expect(request.body, 'a=1');
      expect(request.charset, 'gbk');
      expect(request.headers['User-Agent'], 'Test UA');
      expect(request.headers['Referer'], 'https://ref.example');
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

SourceRule _source() {
  return const SourceRule(
    id: 'https://source.example/base/',
    name: '测试源',
    url: 'https://source.example/base/',
    headers: {'User-Agent': 'Test UA'},
  );
}
