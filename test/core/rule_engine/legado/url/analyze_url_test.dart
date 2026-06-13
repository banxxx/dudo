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
