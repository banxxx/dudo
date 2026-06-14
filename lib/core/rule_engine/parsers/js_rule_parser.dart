import '../models/rule_chain.dart';
import 'parser.dart';

/// Placeholder parser for Legado JS rule forms.
///
/// Field-level JS execution is intentionally unsupported until the JS runtime
/// abstraction is added. Registering this parser keeps rule routing explicit
/// and lets validation diagnostics report the unsupported capability.
class JsRuleParser implements RuleParser {
  const JsRuleParser();

  @override
  RuleType get type => RuleType.js;

  @override
  String? parseString(Object source, RuleChain rule) => null;

  @override
  List<String> parseList(Object source, RuleChain rule) => const [];

  @override
  List<Object> parseElements(Object source, RuleChain rule) => const [];

  static bool isJsRule(String rawRule) {
    final text = rawRule.trim();
    return RegExp(r'<js>|@js:', caseSensitive: false).hasMatch(text);
  }
}
