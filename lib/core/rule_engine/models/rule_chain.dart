import '../legado/rule/rule_analyzer.dart';

/// A composite rule expression — a `||`-separated chain where the first
/// non-empty result wins, optionally with `@`-chained sub-selectors.
class RuleChain {
  final List<RuleSegment> segments;
  RuleChain(this.segments);

  /// Parses a Legado-flavored rule like `class.book-list@tag.li@a@href`.
  factory RuleChain.parse(String raw) {
    final cleaned = _stripEmbeddedScripts(raw).trim();
    if (cleaned.isEmpty) {
      return RuleChain(const []);
    }
    const analyzer = RuleAnalyzer();
    final fallbackParts = analyzer.split(cleaned, LegadoRuleDelimiter.fallback);
    final appendExpanded = fallbackParts.expand(
      (part) => analyzer.split(part, LegadoRuleDelimiter.append),
    );
    final segs = appendExpanded
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(RuleSegment.parse)
        .toList();
    return RuleChain(segs);
  }

  static String _stripEmbeddedScripts(String raw) {
    return raw
        .replaceAll(RegExp(r'<js>[\s\S]*?</js>', caseSensitive: false), '')
        .replaceAll(RegExp(r'@js:[\s\S]*$', caseSensitive: false), '')
        .trim();
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
    const analyzer = RuleAnalyzer();
    final steps = analyzer
        .split(clean, LegadoRuleDelimiter.pipeline)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(RuleStep.parse)
        .toList();
    return RuleSegment(type, steps);
  }

  static RuleType _detectType(String s) {
    if (s.startsWith('@CSS:') || s.startsWith('@css:')) {
      return RuleType.explicitCss;
    }
    if (_looksLikeRegex(s)) return RuleType.regex;
    if (RegExp(r'^@?XPath:', caseSensitive: false).hasMatch(s) ||
        s.startsWith('/')) {
      return RuleType.xpath;
    }
    if (s.startsWith('@JSon:') ||
        s.startsWith('@Json:') ||
        s.startsWith('@json:')) {
      return RuleType.jsonPath;
    }
    if (s.startsWith(r'$.') || s.startsWith(r'$..')) return RuleType.jsonPath;
    if (s.startsWith('@JS:') || s.startsWith('<js>')) return RuleType.js;
    return RuleType.css; // default legado-style
  }

  static bool _looksLikeRegex(String s) {
    if (s.startsWith('##')) return true;
    final match = RegExp(r'^/(?:\\.|[^/])+/([\d$][\s\S]*)?$').firstMatch(s);
    return match != null;
  }

  static String _stripPrefix(String s, RuleType type) {
    switch (type) {
      case RuleType.explicitCss:
        return s.replaceFirst(RegExp(r'^@(?:CSS|css):'), '');
      case RuleType.css:
        return s;
      case RuleType.xpath:
        return s.replaceFirst(RegExp(r'^@?XPath:', caseSensitive: false), '');
      case RuleType.jsonPath:
        return s.replaceFirst(RegExp(r'^@(?:JSon|Json|json):'), '');
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

enum RuleType { css, explicitCss, xpath, jsonPath, regex, js }
