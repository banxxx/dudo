/// Public exports for the dudo source-rule engine.
///
/// The engine is designed to be compatible with Legado-style (阅读 3.0) JSON
/// rule sets while remaining backend-agnostic.
library;

export 'models/source_rule.dart';
export 'models/rule_chain.dart';
export 'parsers/parser.dart';
export 'parsers/xpath_parser.dart';
export 'parsers/json_path_rule_parser.dart';
export 'parsers/jsonpath_parser.dart';
export 'parsers/regex_parser.dart';
export 'parsers/js_rule_parser.dart';
export 'parsers/default_html_rule_parser.dart';
export 'parsers/explicit_css_rule_parser.dart';
export 'parsers/css_parser.dart';
export 'legado/legado_runtime.dart';
export 'legado/legado_models.dart';
export 'legado/url/analyze_url.dart';
export 'legado/url/request_executor.dart';
export 'legado/url/url_options.dart';
export 'legado/url/url_placeholder.dart';
export 'legado/decode/response_decoder.dart';
export 'legado/js/legado_js_engine.dart';
export 'legado/rule/rule_analyzer.dart';
export 'legado/rule/rule_ast.dart';
export 'legado/rule/rule_value.dart';
export 'legado/rule/rule_context.dart';
export 'legado/rule/analyze_rule.dart';
export 'rule_engine.dart';
