import 'package:dudo/core/rule_engine/legado/rule/analyze_rule.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_context.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_value.dart';
import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/parsers/parser.dart';
import 'package:dudo/core/rule_engine/parsers/xpath_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XPathParser', () {
    const html = '''
      <html>
        <body>
          <main>
            <div class="book"><a href="/book/1"><span>Alpha</span></a></div>
            <div class="book"><a href="/book/2"><span>Beta</span></a></div>
          </main>
        </body>
      </html>
    ''';

    test('extracts node sets, text functions, and attributes', () {
      const parser = XPathParser();

      final nodes = parser.parseElements(
        html,
        RuleChain.parse('@XPath://div[@class="book"]'),
      );

      expect(nodes, hasLength(2));
      expect(
        parser.parseList(html, RuleChain.parse('@XPath://span/text()')),
        ['Alpha', 'Beta'],
      );
      expect(
        parser.parseString(nodes.first, RuleChain.parse('@XPath://a/@href')),
        '/book/1',
      );
    });

    test('treats rules starting with slash as XPath', () {
      const parser = XPathParser();

      expect(
        parser.parseString(html, RuleChain.parse('/body/main/div[2]//span')),
        'Beta',
      );
    });

    test('passes XPath node sets to downstream field rules', () {
      final context = RuleContext(
        source: const SourceRule(
          id: 'source',
          name: 'Source',
          url: 'https://source.example',
        ),
        input: RuleInput(
          rawText: html,
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(
        registry: ParserRegistry()..register(const XPathParser()),
      );

      final nodes = analyzeRule.elements(
        context.input.rawText,
        '@XPath://div[@class="book"]',
        context,
      );

      expect(nodes, hasLength(2));
      expect(analyzeRule.string(nodes.last, '//a/@href', context), '/book/2');
      expect(analyzeRule.string(nodes.last, '//span/text()', context), 'Beta');
    });
  });
}
