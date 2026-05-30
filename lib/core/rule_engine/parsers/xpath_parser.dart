import '../models/rule_chain.dart';
import 'parser.dart';

/// XPath parser skeleton — concrete implementation should plug `xpath_selector`
/// against an `html` `Document` parse tree.
class XPathParser implements RuleParser {
  @override
  RuleType get type => RuleType.xpath;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    // TODO: implement against xpath_selector_html_parser.
    return const [];
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    // TODO: implement.
    return const [];
  }
}
