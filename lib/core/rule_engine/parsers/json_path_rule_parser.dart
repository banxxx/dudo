import 'dart:convert';

import 'package:json_path/json_path.dart';

import '../models/rule_chain.dart';
import 'parser.dart';

/// JSONPath parser backed by `json_path` package.
class JsonPathRuleParser implements RuleParser {
  const JsonPathRuleParser();

  @override
  RuleType get type => RuleType.jsonPath;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    final embedded = _parseEmbeddedJsonPath(source, rule);
    if (embedded != null) return embedded;
    return parseElements(source, rule)
        .map(_stringify)
        .where((value) => value.isNotEmpty)
        .toList();
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    final jsonSource = _toJsonSource(source);
    for (final segment in rule.segments) {
      var current = <Object>[jsonSource];
      for (final step in segment.steps) {
        final expression = _normalizeJsonPath(step.raw);
        final next = <Object>[];
        for (final item in current) {
          try {
            final jsonPath = JsonPath(expression);
            next.addAll(
              jsonPath
                  .read(item)
                  .map((match) => match.value)
                  .whereType<Object>(),
            );
          } catch (_) {
            next.clear();
            break;
          }
        }
        current = next;
        if (current.isEmpty) break;
      }
      if (current.isNotEmpty) return current;
    }
    return const [];
  }

  String _normalizeJsonPath(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;
    if (text.startsWith(r'$.') || text.startsWith(r'$..')) return text;
    if (text.startsWith(r'$[')) return text;
    if (text == r'$') return text;
    return r'$.' + text;
  }

  Object _toJsonSource(Object source) {
    if (source is String) {
      try {
        return jsonDecode(source) as Object;
      } catch (_) {
        return source;
      }
    }
    return source;
  }

  List<String>? _parseEmbeddedJsonPath(Object source, RuleChain rule) {
    if (rule.segments.length != 1) return null;
    final segment = rule.segments.single;
    if (segment.steps.length != 1) return null;
    final raw = segment.steps.single.raw;
    final pattern = RegExp(r'\{\s*(\$[^\}]+?)\s*\}');
    if (!pattern.hasMatch(raw)) return null;

    final jsonSource = _toJsonSource(source);
    final replaced = raw.replaceAllMapped(pattern, (match) {
      final expression = _normalizeJsonPath(match.group(1) ?? '');
      try {
        final matches = JsonPath(expression).read(jsonSource).toList();
        if (matches.isEmpty) return '';
        return _stringify(matches.first.value);
      } catch (_) {
        return '';
      }
    }).trim();
    return replaced.isEmpty ? const [] : [replaced];
  }

  String _stringify(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }
}
