import 'rule_analyzer.dart';

enum LegadoRuleMode { defaultHtml, css, jsonPath, xpath, regex, js, webJs }

sealed class LegadoRuleAst {
  const LegadoRuleAst();
}

class LegadoFallbackRule extends LegadoRuleAst {
  const LegadoFallbackRule(this.alternatives);

  final List<LegadoRuleAst> alternatives;
}

class LegadoAppendRule extends LegadoRuleAst {
  const LegadoAppendRule(this.parts);

  final List<LegadoRuleAst> parts;
}

class LegadoInterleaveRule extends LegadoRuleAst {
  const LegadoInterleaveRule(this.parts);

  final List<LegadoRuleAst> parts;
}

class LegadoPipelineRule extends LegadoRuleAst {
  const LegadoPipelineRule(this.steps);

  final List<LegadoRuleStep> steps;
}

class LegadoRuleStep {
  const LegadoRuleStep({required this.raw, required this.mode});

  final String raw;
  final LegadoRuleMode mode;
}

class LegadoRuleAstParser {
  const LegadoRuleAstParser({this.analyzer = const RuleAnalyzer()});

  final RuleAnalyzer analyzer;

  LegadoRuleAst parse(String rawRule) {
    final rule = rawRule.trim();
    if (rule.isEmpty) return const LegadoPipelineRule([]);
    return _parseFallback(rule);
  }

  LegadoRuleAst _parseFallback(String rule) {
    final parts = analyzer.split(rule, LegadoRuleDelimiter.fallback);
    if (parts.length > 1) {
      return LegadoFallbackRule(
          parts.map(_parseAppend).toList(growable: false));
    }
    return _parseAppend(rule);
  }

  LegadoRuleAst _parseAppend(String rule) {
    final parts = analyzer.split(rule, LegadoRuleDelimiter.append);
    if (parts.length > 1) {
      return LegadoAppendRule(
          parts.map(_parseInterleave).toList(growable: false));
    }
    return _parseInterleave(rule);
  }

  LegadoRuleAst _parseInterleave(String rule) {
    final parts = analyzer.split(rule, LegadoRuleDelimiter.interleave);
    if (parts.length > 1) {
      return LegadoInterleaveRule(
        parts.map(_parsePipeline).toList(growable: false),
      );
    }
    return _parsePipeline(rule);
  }

  LegadoPipelineRule _parsePipeline(String rule) {
    final parts = analyzer.split(rule, LegadoRuleDelimiter.pipeline);
    return LegadoPipelineRule(
      parts
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .map((part) =>
              LegadoRuleStep(raw: _stripModePrefix(part), mode: _modeOf(part)))
          .toList(growable: false),
    );
  }

  LegadoRuleMode _modeOf(String raw) {
    final text = raw.trim();
    if (text.startsWith('@CSS:') ||
        text.startsWith('@css:') ||
        text.startsWith('CSS:') ||
        text.startsWith('css:')) {
      return LegadoRuleMode.css;
    }
    if (_looksLikeRegex(text)) return LegadoRuleMode.regex;
    if (text.startsWith('@XPath:') ||
        text.startsWith('XPath:') ||
        text.startsWith('/')) {
      return LegadoRuleMode.xpath;
    }
    if (text.startsWith('@JSon:') ||
        text.startsWith('@Json:') ||
        text.startsWith('@json:') ||
        text.startsWith('JSon:') ||
        text.startsWith('Json:') ||
        text.startsWith('json:') ||
        text.startsWith(r'$.') ||
        text.startsWith(r'$..') ||
        text.startsWith(r'$[')) {
      return LegadoRuleMode.jsonPath;
    }
    if (text.startsWith('@JS:') ||
        text.startsWith('@js:') ||
        text.startsWith('JS:') ||
        text.startsWith('js:') ||
        text.startsWith('<js>')) {
      return LegadoRuleMode.js;
    }
    if (text.startsWith('@WebJS:') ||
        text.startsWith('@WebJs:') ||
        text.startsWith('@webjs:') ||
        text.startsWith('WebJS:') ||
        text.startsWith('WebJs:') ||
        text.startsWith('webjs:')) {
      return LegadoRuleMode.webJs;
    }
    return LegadoRuleMode.defaultHtml;
  }

  bool _looksLikeRegex(String text) {
    if (text.startsWith('##')) return true;
    return RegExp(r'^/(?:\\.|[^/])+/([\d$][\s\S]*)?$').hasMatch(text);
  }

  String _stripModePrefix(String raw) {
    final text = raw.trim();
    return text
        .replaceFirst(RegExp(r'^@?(?:CSS|css):'), '')
        .replaceFirst(RegExp(r'^@?(?:XPath):'), '')
        .replaceFirst(RegExp(r'^@?(?:JSon|Json|json):'), '')
        .replaceFirst(RegExp(r'^@?(?:WebJS|WebJs|webjs):'), '')
        .replaceFirst(RegExp(r'^@?(?:JS|js):'), '');
  }
}
