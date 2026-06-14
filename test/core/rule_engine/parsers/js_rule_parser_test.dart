import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/legado/js/legado_js_engine.dart';
import 'package:dudo/core/rule_engine/parsers/js_rule_parser.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsRuleParser', () {
    test('evaluates JS rules through the configured engine', () {
      const parser = JsRuleParser(jsEngine: SimpleLegadoJsEngine());

      expect(
        parser.parseString('input', _jsRule('result + "!"')),
        'input!',
      );
      expect(
        parser.parseList('input', _jsRule('<js>result + "?"</js>')),
        ['input?'],
      );
      expect(JsRuleParser.isJsRule('@js:result + 1'), isTrue);
      expect(JsRuleParser.isJsRule('<js>result + 1</js>'), isTrue);
    });

    test('is registered in RuleEngine runtime', () {
      final engine = RuleEngine.create();

      expect(engine.registry.forType(RuleType.js), isA<JsRuleParser>());
    });

    test('does not report unsupported JS diagnostics for rule fields', () {
      final report = RuleEngine.create().validate(
        const SourceRule(
          id: 'source',
          name: 'Source',
          url: 'https://source.example',
          search: SearchRule(
            searchUrl: 'https://source.example/search?q={{key}}',
            bookList: 'class.book',
            name: '@js:result + 1',
            bookUrl: 'tag.a@href',
          ),
        ),
      );

      expect(
        report.diagnostics.where((diagnostic) =>
            diagnostic.code == 'rule-js-unsupported' &&
            diagnostic.path == 'ruleSearch.name'),
        isEmpty,
      );
    });
  });
}

RuleChain _jsRule(String script) {
  return RuleChain([
    RuleSegment(RuleType.js, [RuleStep(script)]),
  ]);
}
