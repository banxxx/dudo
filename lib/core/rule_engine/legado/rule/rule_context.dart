import '../../models/source_rule.dart';
import '../common/legado_trace.dart';
import '../js/legado_js_engine.dart';
import '../runtime/legado_runtime_variables.dart';
import 'rule_value.dart';

export '../common/legado_trace.dart';

class RuleContext {
  RuleContext({
    required this.source,
    required this.input,
    this.keyword,
    this.page = 1,
    this.book,
    Map<String, Object?>? variables,
    LegadoRuntimeVariables? runtimeVariables,
    this.cookie,
    this.ajax,
    this.trace,
  }) : runtimeVariables = runtimeVariables ??
            LegadoRuntimeVariables(request: variables, trace: trace);

  final SourceRule source;
  final RuleInput input;
  final String? keyword;
  final int page;
  final Object? book;
  final LegadoRuntimeVariables runtimeVariables;
  final String? cookie;
  final LegadoJsAjax? ajax;
  final LegadoTrace? trace;

  Map<String, Object?> get variables => runtimeVariables.asMap();

  Uri get baseUri => input.baseUri;
  Uri get redirectUri => input.redirectUri;
  String get currentUrl => redirectUri.toString();

  Object? getVariable(String key) => variables[key];

  void putVariable(String key, Object? value) {
    runtimeVariables.put(key, value);
    trace?.add('put:$key');
  }
}
