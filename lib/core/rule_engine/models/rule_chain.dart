/// A composite rule expression — a `||`-separated chain where the first
/// non-empty result wins, optionally with `@`-chained sub-selectors.
class RuleChain {
  final List<RuleSegment> segments;
  RuleChain(this.segments);

  /// Parses a Legado-flavored rule like `class.book-list@tag.li@a@href`.
  factory RuleChain.parse(String raw) {
    if (raw.trim().isEmpty) {
      return RuleChain(const []);
    }
    final segs = raw
        .split('||')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(RuleSegment.parse)
        .toList();
    return RuleChain(segs);
  }

  bool get isEmpty => segments.isEmpty;
}

class RuleSegment {
  final List<RuleStep> steps;
  final RuleType type;

  RuleSegment(this.type, this.steps);

  factory RuleSegment.parse(String raw) {
    final type = _detectType(raw);
    final clean = _stripPrefix(raw, type);
    final steps =
        clean.split('@').map((s) => s.trim()).map(RuleStep.parse).toList();
    return RuleSegment(type, steps);
  }

  static RuleType _detectType(String s) {
    if (s.startsWith('@CSS:') || s.startsWith('@css:')) return RuleType.css;
    if (s.startsWith('@XPath:') || s.startsWith('//')) return RuleType.xpath;
    if (s.startsWith(r'$.') || s.startsWith(r'$..')) return RuleType.jsonPath;
    if (s.startsWith('@JS:') || s.startsWith('<js>')) return RuleType.js;
    if (s.contains(':') && RegExp(r'^\s*/.+/').hasMatch(s)) {
      return RuleType.regex;
    }
    return RuleType.css; // default legado-style
  }

  static String _stripPrefix(String s, RuleType type) {
    switch (type) {
      case RuleType.css:
        return s.replaceFirst(RegExp(r'^@(?:CSS|css):'), '');
      case RuleType.xpath:
        return s.replaceFirst('@XPath:', '');
      case RuleType.jsonPath:
      case RuleType.regex:
      case RuleType.js:
        return s;
    }
  }
}

class RuleStep {
  final String raw;
  const RuleStep(this.raw);
  factory RuleStep.parse(String s) => RuleStep(s);
}

enum RuleType { css, xpath, jsonPath, regex, js }
