import 'package:dudo/core/rule_engine/legado/rule/rule_analyzer.dart';
import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleAnalyzer', () {
    const analyzer = RuleAnalyzer();

    test('splits fallback only at top level', () {
      expect(
        analyzer.split(
          r'$.items[?(@.name=="a||b")]||$.books',
          LegadoRuleDelimiter.fallback,
        ),
        [r'$.items[?(@.name=="a||b")]', r'$.books'],
      );
    });

    test('does not split inside JS blocks', () {
      expect(
        analyzer.split(
          '<js>result = a@b || c && d;</js>@text',
          LegadoRuleDelimiter.pipeline,
        ),
        ['<js>result = a@b || c && d;</js>', 'text'],
      );
    });

    test('does not split inside backtick strings', () {
      expect(
        analyzer.split(
          r'@js:result = `${a}@${b}`@text',
          LegadoRuleDelimiter.pipeline,
        ),
        [r'@js:result = `${a}@${b}`', 'text'],
      );
    });

    test('splits append and interleave delimiters', () {
      expect(
        analyzer.split(r'$.a&&$.b', LegadoRuleDelimiter.append),
        [r'$.a', r'$.b'],
      );
      expect(
        analyzer.split(r'$.a%%$.b', LegadoRuleDelimiter.interleave),
        [r'$.a', r'$.b'],
      );
    });
  });
  group('RuleChain', () {
    test('uses balanced splitting for fallback and pipeline segments', () {
      final chain = RuleChain.parse(
        r'$.items[?(@.name=="a||b")]||class.book@a[href="x@y"]@text',
      );

      expect(chain.segments, hasLength(2));
      expect(
        chain.segments.first.steps.single.raw,
        r'$.items[?(@.name=="a||b")]',
      );
      expect(chain.segments.last.steps.map((step) => step.raw), [
        'class.book',
        'a[href="x@y"]',
        'text',
      ]);
    });
  });
}
