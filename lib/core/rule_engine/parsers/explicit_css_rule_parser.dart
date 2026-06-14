import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/rule_chain.dart';
import 'parser.dart';

/// Parser for explicit `@CSS:` rules. Unlike [DefaultHtmlRuleParser], this
/// keeps selector syntax as standard CSS and does not translate Legado tokens
/// such as `class.foo`, `id.foo`, or `tag.a`.
class ExplicitCssRuleParser implements RuleParser {
  const ExplicitCssRuleParser();

  @override
  RuleType get type => RuleType.explicitCss;

  @override
  String? parseString(Object source, RuleChain rule) {
    final list = parseList(source, rule);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<String> parseList(Object source, RuleChain rule) {
    final roots = _rootNodes(source);
    if (roots.isEmpty) return const [];
    final out = <String>[];

    for (final segment in rule.segments) {
      var currentNodes = roots;
      var attr = 'text';
      for (var i = 0; i < segment.steps.length; i++) {
        final raw = segment.steps[i].raw.trim();
        if (raw.isEmpty) continue;
        if (i == segment.steps.length - 1 && _isAttrStep(raw)) {
          attr = raw;
          break;
        }
        try {
          currentNodes = currentNodes
              .expand((node) => node.querySelectorAll(raw))
              .toList(growable: false);
        } catch (_) {
          currentNodes = const [];
          break;
        }
      }
      for (final node in currentNodes) {
        final value = _extractAttr(node, attr);
        if (value.isNotEmpty) out.add(value);
      }
      if (out.isNotEmpty) break;
    }

    return out;
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    final roots = _rootNodes(source);
    if (roots.isEmpty) return const [];
    final result = <dom.Element>[];

    for (final segment in rule.segments) {
      var currentNodes = roots;
      for (final step in segment.steps) {
        final raw = step.raw.trim();
        if (raw.isEmpty || _isAttrStep(raw)) continue;
        try {
          currentNodes = currentNodes
              .expand((node) => node.querySelectorAll(raw))
              .toList(growable: false);
        } catch (_) {
          currentNodes = const [];
          break;
        }
      }
      result.addAll(currentNodes);
      if (result.isNotEmpty) break;
    }

    return result;
  }

  List<dom.Element> _rootNodes(Object source) {
    if (source is dom.Element) return [source];
    if (source is dom.Document) {
      final root = source.documentElement;
      return root == null ? const [] : [root];
    }
    if (source is String) {
      final root = html_parser.parse(source).documentElement;
      return root == null ? const [] : [root];
    }
    return const [];
  }

  bool _isAttrStep(String raw) {
    const attrs = {
      'text',
      'html',
      'innerHTML',
      'href',
      'src',
      'all',
    };
    return attrs.contains(raw) ||
        RegExp(r'^[A-Za-z_:][-A-Za-z0-9_:.]*$').hasMatch(raw) &&
            raw.contains('-');
  }

  String _extractAttr(dom.Element element, String attr) {
    return switch (attr) {
      'text' => element.text.trim(),
      'html' || 'innerHTML' => element.innerHtml,
      'all' => element.outerHtml,
      _ => element.attributes[attr] ?? '',
    };
  }
}
