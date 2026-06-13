import 'models/rule_chain.dart';
import 'parsers/parser.dart';

class LegacyRuleEvaluator {
  const LegacyRuleEvaluator(this.registry);

  final ParserRegistry registry;

  String? string(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return null;
    final chain = RuleChain.parse(rawRule);
    final type = _parserTypeFor(source, chain);
    final parser = registry.forType(type);
    return parser?.parseString(source, chain);
  }

  List<Object> list(Object source, String? rawRule) {
    if (rawRule == null || rawRule.isEmpty) return const <Object>[];
    final chain = RuleChain.parse(rawRule);
    final type = _parserTypeFor(source, chain);
    final parser = registry.forType(type);
    return parser?.parseElements(source, chain) ?? const <Object>[];
  }

  String? absoluteUrl(String? rawUrl, String baseUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return rawUrl;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return rawUrl;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
  }

  RuleType _parserTypeFor(Object source, RuleChain chain) {
    final detected =
        chain.segments.isEmpty ? RuleType.css : chain.segments.first.type;
    if (detected == RuleType.css && (source is Map || source is List)) {
      return RuleType.jsonPath;
    }
    return detected;
  }
}
