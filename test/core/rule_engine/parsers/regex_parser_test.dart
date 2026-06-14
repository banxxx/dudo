import 'package:dudo/core/rule_engine/legado/rule/analyze_rule.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_context.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_value.dart';
import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:dudo/core/rule_engine/parsers/parser.dart';
import 'package:dudo/core/rule_engine/parsers/regex_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegexParser', () {
    test('extracts whole matches and numbered capture groups', () {
      const parser = RegexParser();
      const input = 'Title: Alpha\nTitle: Beta';

      expect(
        parser.parseList(input, RuleChain.parse(r'/Title: \w+/')),
        ['Title: Alpha', 'Title: Beta'],
      );
      expect(
        parser.parseList(input, RuleChain.parse(r'/Title: (\w+)/1')),
        ['Alpha', 'Beta'],
      );
    });

    test(r'interpolates $1 and $2 from capture groups', () {
      const parser = RegexParser();

      expect(
        parser.parseList(
          'Name: Alpha\nName: Beta',
          RuleChain.parse(r'/Name: (\w)(\w+)/$2-$1'),
        ),
        ['lpha-A', 'eta-B'],
      );
    });

    test('supports Legado replacement syntax', () {
      const parser = RegexParser();

      expect(
        parser.parseString(
          'Alpha   Beta',
          RuleChain.parse(r'##\s+##-'),
        ),
        'Alpha-Beta',
      );
      expect(
        RegexParser.applyReplacement('A  B', r'##\s+##:'),
        'A:B',
      );
    });

    test('is routed by AnalyzeRule for explicit regex forms', () {
      final context = RuleContext(
        source: const SourceRule(
          id: 'source',
          name: 'Source',
          url: 'https://source.example',
        ),
        input: RuleInput(
          rawText: 'Book: Alpha',
          baseUri: Uri.parse('https://source.example'),
        ),
      );
      final analyzeRule = AnalyzeRule(
        registry: ParserRegistry()..register(const RegexParser()),
      );

      expect(
          analyzeRule.string(context.input.rawText, r'/Book: (\w+)/1', context),
          'Alpha');
      expect(
        analyzeRule.string(context.input.rawText, r'##Book: ##', context),
        'Alpha',
      );
    });
  });
}
