import 'package:dudo/core/rule_engine/legado/rule/analyze_rule.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_ast.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_context.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_value.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/parsers/css_parser.dart';
import 'package:dudo/core/rule_engine/parsers/jsonpath_parser.dart';
import 'package:dudo/core/rule_engine/parsers/parser.dart';
import 'package:dudo/core/rule_engine/parsers/regex_parser.dart';
import 'package:dudo/core/rule_engine/parsers/xpath_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleInput', () {
    test('lazily parses HTML and JSON documents', () {
      final htmlInput = RuleInput(
        rawText: '<html><body><a href="/book">三体</a></body></html>',
        baseUri: Uri.parse('https://source.example'),
      );
      expect(htmlInput.htmlDocument.querySelector('a')?.text, '三体');

      final jsonInput = RuleInput(
        rawText: '{"name":"三体"}',
        baseUri: Uri.parse('https://source.example'),
      );
      expect(jsonInput.jsonDocument, {'name': '三体'});
    });
  });

  group('RuleContext', () {
    test('stores variables and trace events', () {
      final trace = LegadoTrace();
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '',
          baseUri: Uri.parse('https://source.example'),
        ),
        trace: trace,
      );

      context.putVariable('id', 1);

      expect(context.getVariable('id'), 1);
      expect(trace.events, ['put:id']);
    });
  });

  group('AnalyzeRule', () {
    test('evaluates AST skeleton and records trace events', () {
      final trace = LegadoTrace();
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '',
          baseUri: Uri.parse('https://source.example'),
        ),
        trace: trace,
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      final value = analyzeRule.evaluate(
        const LegadoPipelineRule([
          LegadoRuleStep(raw: r'$.name', mode: LegadoRuleMode.jsonPath),
        ]),
        context,
        {'name': '三体'},
      );

      expect(value, isA<RuleListValue>());
      expect(analyzeRule.string({'name': '三体'}, 'name', context), '三体');
      expect(trace.events.first, 'evaluate:LegadoPipelineRule');
    });

    test('extracts elements and fields through parser registry', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '<div class="book"><span class="name">三体</span></div>',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      final nodes = analyzeRule.elements(
        context.input.rawText,
        'class.book',
        context,
      );

      expect(nodes, hasLength(1));
      expect(
          analyzeRule.string(nodes.single, 'class.name@text', context), '三体');
    });
  });
}

SourceRule _source() {
  return const SourceRule(
    id: 'https://source.example',
    name: '测试源',
    url: 'https://source.example',
  );
}

ParserRegistry _registry() {
  return ParserRegistry()
    ..register(CssParser())
    ..register(XPathParser())
    ..register(JsonPathParser())
    ..register(RegexParser());
}
