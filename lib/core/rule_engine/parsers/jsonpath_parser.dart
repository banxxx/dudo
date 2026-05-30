import '../models/rule_chain.dart';
import 'parser.dart';

/// JSONPath parser skeleton — backed by `json_path` package.
class JsonPathParser implements RuleParser {
  @override
  RuleType get type => RuleType.jsonPath;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) => const [];

  @override
  List<Object> parseElements(Object source, RuleChain rule) => const [];
}
