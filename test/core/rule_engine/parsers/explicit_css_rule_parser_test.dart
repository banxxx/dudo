import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/parsers/default_html_rule_parser.dart';
import 'package:dudo/core/rule_engine/parsers/explicit_css_rule_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExplicitCssRuleParser', () {
    test('uses standard CSS selectors without Legado token translation', () {
      const html = '<div class="book"><a href="/book">三体</a></div>';
      const defaultParser = DefaultHtmlRuleParser();
      const explicitParser = ExplicitCssRuleParser();

      expect(
        defaultParser.parseString(html, RuleChain.parse('class.book@text')),
        '三体',
      );
      expect(
        explicitParser.parseString(html, RuleChain.parse('@CSS:.book@text')),
        '三体',
      );
      expect(
        explicitParser.parseString(
            html, RuleChain.parse('@CSS:class.book@text')),
        isNull,
      );
    });
  });
}
