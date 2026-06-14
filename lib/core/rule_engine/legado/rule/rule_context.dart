import '../../models/source_rule.dart';
import '../common/legado_trace.dart';
import 'rule_value.dart';

export '../common/legado_trace.dart';

class RuleContext {
  RuleContext({
    required this.source,
    required this.input,
    this.keyword,
    this.page = 1,
    Map<String, Object?>? variables,
    this.trace,
  }) : variables = variables ?? <String, Object?>{};

  final SourceRule source;
  final RuleInput input;
  final String? keyword;
  final int page;
  final Map<String, Object?> variables;
  final LegadoTrace? trace;

  Uri get baseUri => input.baseUri;
  Uri get redirectUri => input.redirectUri;

  Object? getVariable(String key) => variables[key];

  void putVariable(String key, Object? value) {
    variables[key] = value;
    trace?.add('put:$key');
  }
}
