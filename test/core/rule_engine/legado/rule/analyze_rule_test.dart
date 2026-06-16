import 'package:dudo/core/rule_engine/legado/rule/analyze_rule.dart';
import 'package:dudo/core/rule_engine/legado/js/legado_js_engine.dart';
import 'package:dudo/core/rule_engine/legado/runtime/legado_runtime_variables.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_ast.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_context.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_value.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/parsers/css_parser.dart';
import 'package:dudo/core/rule_engine/parsers/explicit_css_rule_parser.dart';
import 'package:dudo/core/rule_engine/parsers/json_path_rule_parser.dart';
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
      expect(trace.events, contains('put:id'));
      expect(trace.events, contains('runtime.variables.request.put:id'));
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

    test('combines JSONPath fallback append and interleave results', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '{"a":["A1","A2"],"b":["B1","B2"]}',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        _strings(analyzeRule.parse(r'$.missing||$.a[0]', context)),
        ['A1'],
      );
      expect(
        _strings(analyzeRule.parse(r'$.a[*]&&$.b[*]', context)),
        ['A1', 'A2', 'B1', 'B2'],
      );
      expect(
        _strings(analyzeRule.parse(r'$.a[*]%%$.b[*]', context)),
        ['A1', 'B1', 'A2', 'B2'],
      );
    });

    test('supports @put and @get variables', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: 'Alpha',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(analyzeRule.parse('@put:{result}', context).isEmpty, isTrue);
      expect(context.getVariable('result'), 'Alpha');
      expect(analyzeRule.string('ignored', '@get:{result}', context), 'Alpha');

      analyzeRule.parse(r'@put:{"name":"Beta","count":2}', context);
      expect(analyzeRule.string('ignored', '@get:{name}', context), 'Beta');
      expect(analyzeRule.string('ignored', '@get:{count}', context), '2');
    });

    test('shares variables through runtime variable container', () {
      final variables = LegadoRuntimeVariables();
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: 'Alpha',
          baseUri: Uri.parse('https://source.example'),
        ),
        runtimeVariables: variables,
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.string(
            'ignored', '<js>java.put("name", "Beta")</js>', context),
        'Beta',
      );
      expect(variables.get('name'), 'Beta');
      expect(
          analyzeRule.string('ignored', '<js>java.get("name")</js>', context),
          'Beta');
    });

    test('evaluates standalone js tag rules without passing wrapper tags', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: 'Alpha',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.string('Alpha', '<js>result + " Beta"</js>', context),
        'Alpha Beta',
      );
    });

    test('keeps closing js tag text inside JS strings while parsing rule tail',
        () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: 'Alpha',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.string(
          'Alpha',
          '<js>"<p>Alpha</p></js>"</js>tag.p@text',
          context,
        ),
        'Alpha',
      );
    });

    test('uses redirect URL as Legado baseUrl in dynamic JS rules', () {
      final jsEngine = _BaseUrlJsEngine();
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '{}',
          baseUri: Uri.parse('https://source.example/channel/'),
          redirectUri: Uri.parse(
            'http://app-cdn.example/androidapi/novelbasicinfo?novelId=3878507',
          ),
        ),
      );
      final analyzeRule = AnalyzeRule(
        registry: _registry(),
        jsEngine: jsEngine,
      );

      expect(
        analyzeRule.string(
          context.input.jsonDocument!,
          r'https://api.example/chapterList?novelId={{baseUrl.match(/novelId=(\d+)/)[1]}}',
          context,
        ),
        'https://api.example/chapterList?novelId=3878507',
      );
      expect(
        jsEngine.lastBaseUrl,
        'http://app-cdn.example/androidapi/novelbasicinfo?novelId=3878507',
      );
    });

    test('runs embedded js after dynamic literal URL placeholders', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '{"cover":"https://img.example/cover.jpg"}',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.string(
          context.input.jsonDocument!,
          r'{{$.cover}} <js>result</js>',
          context,
        ),
        'https://img.example/cover.jpg',
      );
    });

    test('replaces dynamic rule placeholders', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '{"books":[{"name":"Alpha"},{"name":"Beta"}]}',
          baseUri: Uri.parse('https://source.example'),
        ),
        keyword: 'Alpha',
        page: 2,
        variables: {'field': 'name', 'index': '1'},
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.string(context.input.jsonDocument!,
            r'$.books[{{index}}].{{field}}', context),
        'Beta',
      );
      expect(
        analyzeRule.string('Page 2', r'/Page ({{page}})/1', context),
        '2',
      );
      expect(
        analyzeRule.string('Title: Alpha', r'/Title: ({{key}})/1', context),
        'Alpha',
      );
      expect(
        analyzeRule.string('Name: Gamma', r'/{{result}}/0', context),
        'Name: Gamma',
      );
      expect(
        analyzeRule.string('Page 3', r'/Page ({{page + 1}})/1', context),
        '3',
      );
    });

    test('normalizes field HTML entities and resolves URLs', () {
      final context = RuleContext(
        source: _source(),
        input: RuleInput(
          rawText: '<a href="/book?a=1&amp;b=2">Tom &amp; Jerry</a>',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(registry: _registry());

      expect(
        analyzeRule.fieldString(context.input.rawText, 'tag.a@text', context),
        'Tom & Jerry',
      );
      expect(
        analyzeRule.absoluteUrl(
            '/book?a=1&amp;b=2', 'https://source.example/search'),
        'https://source.example/book?a=1&b=2',
      );
      expect(
        analyzeRule.normalizeField('&#65;&#x42;&nbsp;'),
        'AB',
      );
    });
  });
}

class _BaseUrlJsEngine implements LegadoJsEngine {
  String? lastBaseUrl;

  @override
  Object? eval(String script, {required LegadoJsContext context}) {
    lastBaseUrl = context.baseUrl;
    return RegExp(r'novelId=(\d+)').firstMatch(context.baseUrl ?? '')?.group(1);
  }

  @override
  Future<Object?> evalAsync(
    String script, {
    required LegadoJsContext context,
  }) async {
    return eval(script, context: context);
  }
}

List<String> _strings(RuleValue value) {
  return switch (value) {
    RuleStringValue(:final value) => [value],
    RuleListValue(:final values) => values.expand(_strings).toList(),
    RuleNodeSetValue(:final nodes) =>
      nodes.map((node) => node.toString()).toList(),
    RuleJsonValue(:final value) =>
      value == null ? const [] : [value.toString()],
    RuleRegexCapturesValue(:final captures) => captures,
    RuleJsValue(:final value) => value == null ? const [] : [value.toString()],
  };
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
    ..register(const CssParser())
    ..register(const ExplicitCssRuleParser())
    ..register(const XPathParser())
    ..register(const JsonPathRuleParser())
    ..register(const RegexParser());
}
