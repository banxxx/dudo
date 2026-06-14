import '../models/rule_chain.dart';
import 'parser.dart';

/// Regex parser for extraction and Legado-style replacement rules.
class RegexParser implements RuleParser {
  const RegexParser();

  @override
  RuleType get type => RuleType.regex;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    final input = source.toString();
    final results = <String>[];

    for (final segment in rule.segments) {
      for (final step in segment.steps) {
        final raw = step.raw.trim();
        if (raw.isEmpty) continue;

        final replacement = _parseReplacement(raw);
        if (replacement != null) {
          results.add(_replaceAll(input, replacement));
          continue;
        }

        final extraction = _parseExtraction(raw);
        if (extraction == null) continue;
        results.addAll(_extractAll(input, extraction));
      }
      if (results.isNotEmpty) break;
    }

    return results;
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) =>
      parseList(source, rule).cast<Object>();

  static String applyReplacement(String input, String rawRule) {
    final rule = _parseReplacement(rawRule.trim());
    if (rule == null) return input;
    return _replaceAll(input, rule);
  }

  static List<String> _extractAll(String input, _RegexExtraction rule) {
    final regex = RegExp(rule.pattern, multiLine: true);
    return [
      for (final match in regex.allMatches(input))
        if (rule.output != null)
          _interpolate(rule.output!, match)
        else if (match.groupCount >= rule.group)
          if (match.group(rule.group) case final value?) value,
    ];
  }

  static String _replaceAll(String input, _RegexReplacement rule) {
    final regex = RegExp(rule.pattern, multiLine: true);
    return input.replaceAllMapped(
      regex,
      (match) => _interpolate(rule.replacement, match),
    );
  }

  static _RegexExtraction? _parseExtraction(String raw) {
    if (!raw.startsWith('/')) return null;
    final delimiter = _lastUnescaped(raw, '/');
    if (delimiter <= 0) return null;

    final pattern = raw.substring(1, delimiter);
    if (pattern.isEmpty) return null;
    final output = raw.substring(delimiter + 1);
    if (output.isEmpty) return _RegexExtraction(pattern: pattern, group: 0);

    final group = int.tryParse(output);
    if (group != null) {
      return _RegexExtraction(pattern: pattern, group: group);
    }
    return _RegexExtraction(pattern: pattern, output: output);
  }

  static _RegexReplacement? _parseReplacement(String raw) {
    if (!raw.startsWith('##')) return null;
    final delimiter = _indexOfUnescaped(raw, '##', 2);
    if (delimiter < 0) return null;

    final pattern = raw.substring(2, delimiter);
    if (pattern.isEmpty) return null;
    return _RegexReplacement(
      pattern: pattern,
      replacement: raw.substring(delimiter + 2),
    );
  }

  static String _interpolate(String template, Match match) {
    return template.replaceAllMapped(RegExp(r'\$(\d+)'), (placeholder) {
      final group = int.tryParse(placeholder.group(1)!);
      if (group == null || group > match.groupCount) return '';
      return match.group(group) ?? '';
    });
  }

  static int _lastUnescaped(String input, String token) {
    for (var i = input.length - token.length; i > 0; i--) {
      if (input.startsWith(token, i) && !_isEscaped(input, i)) return i;
    }
    return -1;
  }

  static int _indexOfUnescaped(String input, String token, int start) {
    for (var i = start; i <= input.length - token.length; i++) {
      if (input.startsWith(token, i) && !_isEscaped(input, i)) return i;
    }
    return -1;
  }

  static bool _isEscaped(String input, int index) {
    var backslashes = 0;
    for (var i = index - 1; i >= 0 && input[i] == r'\'; i--) {
      backslashes += 1;
    }
    return backslashes.isOdd;
  }
}

class _RegexExtraction {
  const _RegexExtraction({
    required this.pattern,
    this.group = 0,
    this.output,
  });

  final String pattern;
  final int group;
  final String? output;
}

class _RegexReplacement {
  const _RegexReplacement({
    required this.pattern,
    required this.replacement,
  });

  final String pattern;
  final String replacement;
}
