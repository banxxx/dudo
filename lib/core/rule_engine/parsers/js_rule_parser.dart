import '../models/rule_chain.dart';
import '../legado/js/legado_js_engine.dart';
import 'parser.dart';

class JsRuleParser implements RuleParser {
  const JsRuleParser({required this.jsEngine});

  final LegadoJsEngine jsEngine;

  @override
  RuleType get type => RuleType.js;

  @override
  String? parseString(Object source, RuleChain rule) {
    final script = _script(rule);
    if (script == null) return null;
    final result = jsEngine.eval(
      script,
      context: LegadoJsContext(
        key: '',
        page: 1,
        src: source,
        result: source,
      ),
    );
    return result?.toString();
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    final value = parseString(source, rule);
    if (value == null || value.isEmpty) return const [];
    return [value];
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    final value = parseString(source, rule);
    if (value == null || value.isEmpty) return const [];
    return [value];
  }

  String? _script(RuleChain rule) {
    for (final segment in rule.segments) {
      if (segment.type != RuleType.js) continue;
      final raw = segment.steps.map((step) => step.raw).join('@').trim();
      if (raw.isEmpty) continue;
      final match = RegExp(
        r'^<js>([\s\S]*?)</js>$',
        caseSensitive: false,
      ).firstMatch(raw);
      return (match?.group(1) ?? raw).trim();
    }
    return null;
  }

  static bool isJsRule(String rawRule) {
    final text = rawRule.trim();
    return RegExp(r'<js>|@js:', caseSensitive: false).hasMatch(text);
  }
}
