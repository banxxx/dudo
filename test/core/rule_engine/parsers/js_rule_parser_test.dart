import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/parsers/js_rule_parser.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsRuleParser', () {
    test('is an explicit unsupported placeholder', () {
      const parser = JsRuleParser();

      expect(
          parser.parseString('input', RuleChain.parse('@js:result')), isNull);
      expect(parser.parseList('input', RuleChain.parse('<js>result</js>')),
          isEmpty);
      expect(JsRuleParser.isJsRule('@js:result + 1'), isTrue);
      expect(JsRuleParser.isJsRule('<js>result + 1</js>'), isTrue);
    });

    test('is registered in RuleEngine runtime', () {
      final engine = RuleEngine.create();

      expect(engine.registry.forType(RuleType.js), isA<JsRuleParser>());
    });

    test('reports unsupported JS diagnostics once per rule field', () {
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
        hasLength(1),
      );
    });
  });
}
