/// Public exports for the dudo source-rule engine.
///
/// The engine is designed to be compatible with Legado-style (阅读 3.0) JSON
/// rule sets while remaining backend-agnostic.
library;

export 'models/source_rule.dart';
export 'models/rule_chain.dart';
export 'parsers/parser.dart';
export 'parsers/xpath_parser.dart';
export 'parsers/jsonpath_parser.dart';
export 'parsers/regex_parser.dart';
export 'parsers/css_parser.dart';
export 'legado/legado_runtime.dart';
export 'legado/legado_models.dart';
export 'legado/url/analyze_url.dart';
export 'legado/url/request_executor.dart';
export 'legado/url/url_options.dart';
export 'legado/url/url_placeholder.dart';
export 'legado/decode/response_decoder.dart';
export 'rule_engine.dart';
