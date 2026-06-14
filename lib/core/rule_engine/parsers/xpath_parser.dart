import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import '../models/rule_chain.dart';
import 'parser.dart';

/// XPath parser backed by `xpath_selector` and `xpath_selector_html_parser`.
class XPathParser implements RuleParser {
  const XPathParser();

  @override
  RuleType get type => RuleType.xpath;

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
      final steps = _xpathSteps(segment);

      for (var i = 0; i < steps.length; i++) {
        final raw = steps[i];
        if (raw.isEmpty) continue;

        final isLast = i == steps.length - 1;
        if (isLast && i > 0 && _isBareAttribute(raw)) {
          out.addAll(_attributeValues(currentNodes, raw));
          break;
        }

        final result = _queryAll(currentNodes, raw);
        currentNodes = result.nodes;

        if (isLast) {
          final attrs =
              result.attrs.whereType<String>().where((v) => v.isNotEmpty);
          if (result.attrs.isNotEmpty) {
            out.addAll(attrs);
          } else {
            out.addAll(
              result.nodes.map(_nodeText).where((value) => value.isNotEmpty),
            );
          }
        }

        if (currentNodes.isEmpty) break;
      }

      if (out.isNotEmpty) break;
    }

    return out;
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    final roots = _rootNodes(source);
    if (roots.isEmpty) return const [];

    final out = <XPathNode<dom.Node>>[];
    for (final segment in rule.segments) {
      var currentNodes = roots;
      final steps = _xpathSteps(segment);

      for (var i = 0; i < steps.length; i++) {
        final raw = steps[i];
        if (raw.isEmpty) continue;
        if (i == steps.length - 1 && i > 0 && _isBareAttribute(raw)) break;
        currentNodes = _queryAll(currentNodes, raw).nodes;
        if (currentNodes.isEmpty) break;
      }

      out.addAll(currentNodes);
      if (out.isNotEmpty) break;
    }

    return out;
  }

  List<XPathNode<dom.Node>> _rootNodes(Object source) {
    if (source is XPathNode<dom.Node>) return [source];
    if (source is dom.Node) return [HtmlNodeTree(source)];
    if (source is String) {
      final root = html_parser.parse(source).documentElement;
      return root == null ? const [] : [HtmlNodeTree(root)];
    }
    return const [];
  }

  List<String> _xpathSteps(RuleSegment segment) {
    final out = <String>[];
    for (final step in segment.steps) {
      final raw = step.raw.trim();
      if (raw.isEmpty) continue;
      if (out.isNotEmpty && out.last.endsWith('/')) {
        out[out.length - 1] = '${out.last}@$raw';
      } else {
        out.add(raw);
      }
    }
    return out;
  }

  _XPathQueryResult _queryAll(
    List<XPathNode<dom.Node>> roots,
    String rawQuery,
  ) {
    final query = _normalizeQuery(rawQuery);
    if (query.isEmpty) return const _XPathQueryResult([], []);

    final nodes = <XPathNode<dom.Node>>[];
    final attrs = <String?>[];
    for (final root in roots) {
      try {
        final result = XPath<dom.Node>(root).query(query);
        for (final node in result.nodes) {
          if (!nodes.contains(node)) nodes.add(node);
        }
        attrs.addAll(result.attrs);
      } catch (_) {
        return const _XPathQueryResult([], []);
      }
    }
    return _XPathQueryResult(nodes, attrs);
  }

  String _normalizeQuery(String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('/') || trimmed.startsWith('.')) return trimmed;
    if (trimmed.startsWith('@')) return '/$trimmed';
    return '//$trimmed';
  }

  bool _isBareAttribute(String raw) =>
      RegExp(r'^[A-Za-z_:][-A-Za-z0-9_:.]*$').hasMatch(raw);

  Iterable<String> _attributeValues(
    List<XPathNode<dom.Node>> nodes,
    String attr,
  ) sync* {
    for (final node in nodes) {
      final value = node.attributes[attr];
      if (value != null && value.isNotEmpty) yield value;
    }
  }

  String _nodeText(XPathNode<dom.Node> node) => (node.text ?? '').trim();
}

class _XPathQueryResult {
  const _XPathQueryResult(this.nodes, this.attrs);

  final List<XPathNode<dom.Node>> nodes;
  final List<String?> attrs;
}
