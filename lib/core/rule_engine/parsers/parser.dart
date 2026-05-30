import '../models/rule_chain.dart';

/// Abstract interface for any parser that can resolve a [RuleChain] against
/// a content source (HTML, JSON, plain text).
abstract class RuleParser {
  RuleType get type;

  /// Returns the first matched string, or null.
  String? parseString(Object source, RuleChain rule);

  /// Returns all matched strings.
  List<String> parseList(Object source, RuleChain rule);

  /// Returns all matched sub-elements as opaque objects (HTML nodes,
  /// JSON sub-trees, etc.) that downstream parsers can resolve again.
  List<Object> parseElements(Object source, RuleChain rule);
}

/// Routes a rule to the appropriate parser. Concrete parser implementations
/// are registered by [RuleEngine] at boot.
class ParserRegistry {
  final Map<RuleType, RuleParser> _parsers = {};

  void register(RuleParser parser) {
    _parsers[parser.type] = parser;
  }

  RuleParser? forType(RuleType type) => _parsers[type];

  RuleParser require(RuleType type) {
    final p = _parsers[type];
    if (p == null) {
      throw StateError('No parser registered for $type');
    }
    return p;
  }
}
