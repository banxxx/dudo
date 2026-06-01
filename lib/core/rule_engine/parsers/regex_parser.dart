import '../models/rule_chain.dart';
import 'parser.dart';

/// Regex parser for fallback / inline rules: `/pattern/group`.
class RegexParser implements RuleParser {
  @override
  RuleType get type => RuleType.regex;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    if (source is! String) return const [];
    final results = <String>[];
    for (final seg in rule.segments) {
      for (final step in seg.steps) {
        final m = RegExp(r'^/(.+)/(\d+)?$').firstMatch(step.raw);
        if (m == null) continue;
        final pattern = m.group(1)!;
        final group = int.tryParse(m.group(2) ?? '0') ?? 0;
        for (final match
            in RegExp(pattern, multiLine: true).allMatches(source)) {
          final v = match.group(group);
          if (v != null) results.add(v);
        }
      }
    }
    return results;
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) =>
      parseList(source, rule).cast<Object>();
}
