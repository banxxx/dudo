import 'package:dudo/core/rule_engine/legado/rule/rule_ast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegadoRuleAstParser', () {
    const parser = LegadoRuleAstParser();

    test('parses fallback, append, interleave, and pipeline nodes', () {
      final ast = parser.parse(r'$.a&&$.b%%$.c||class.book@tag.a@href');

      expect(ast, isA<LegadoFallbackRule>());
      final fallback = ast as LegadoFallbackRule;
      expect(fallback.alternatives, hasLength(2));
      expect(fallback.alternatives.first, isA<LegadoAppendRule>());
      expect(fallback.alternatives.last, isA<LegadoPipelineRule>());

      final append = fallback.alternatives.first as LegadoAppendRule;
      expect(append.parts, hasLength(2));
      expect(append.parts.first, isA<LegadoPipelineRule>());
      expect(append.parts.last, isA<LegadoInterleaveRule>());
    });

    test('detects parser modes for pipeline steps', () {
      final ast = parser.parse(
        r'@JSon:$.items[*]@CSS:.name@XPath://a@js:result + 1@webjs:document.body.innerText',
      ) as LegadoPipelineRule;

      expect(ast.steps.map((step) => step.mode), [
        LegadoRuleMode.jsonPath,
        LegadoRuleMode.css,
        LegadoRuleMode.xpath,
        LegadoRuleMode.js,
        LegadoRuleMode.webJs,
      ]);
      expect(ast.steps.map((step) => step.raw), [
        r'$.items[*]',
        '.name',
        '//a',
        'result + 1',
        'document.body.innerText',
      ]);
    });
  });
}
