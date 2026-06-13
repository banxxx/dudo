import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/rule_chain.dart';
import 'parser.dart';

/// CSS-selector parser (Legado's default), powered by package:html.
class CssParser implements RuleParser {
  @override
  RuleType get type => RuleType.css;

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
    for (final seg in rule.segments) {
      // Legado-style segments use @-separated steps where the last step is
      // an attribute extractor (text, html, href, src…).
      List<dom.Element> currentNodes = roots;
      var attr = 'text';
      for (var i = 0; i < seg.steps.length; i++) {
        final s = seg.steps[i].raw;
        if (i == seg.steps.length - 1 && _isAttrStep(s)) {
          attr = s;
          break;
        }
        final selector = _normalizeSelector(s);
        if (selector == null || selector.isEmpty) continue;
        try {
          currentNodes = currentNodes.expand((n) {
            final selected = n.querySelectorAll(selector.value).toList();
            return _applySelectorIndex(selected, selector);
          }).toList();
        } catch (_) {
          currentNodes = const [];
          break;
        }
      }
      for (final n in currentNodes) {
        final value = _extractAttr(n, attr);
        if (value.isNotEmpty) out.add(value);
      }
      if (out.isNotEmpty) break; // first non-empty segment wins
    }
    return out;
  }

  @override
  List<Object> parseElements(Object source, RuleChain rule) {
    final roots = _rootNodes(source);
    if (roots.isEmpty) return const [];
    final result = <dom.Element>[];
    for (final seg in rule.segments) {
      List<dom.Element> currentNodes = roots;
      for (final step in seg.steps) {
        if (_isAttrStep(step.raw)) continue;
        final selector = _normalizeSelector(step.raw);
        if (selector == null || selector.isEmpty) continue;
        try {
          currentNodes = currentNodes.expand((n) {
            final selected = n.querySelectorAll(selector.value).toList();
            return _applySelectorIndex(selected, selector);
          }).toList();
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
    final doc = _toDocument(source);
    final root = doc?.documentElement;
    return root == null ? const [] : [root];
  }

  dom.Document? _toDocument(Object source) {
    if (source is dom.Document) return source;
    if (source is String) return html_parser.parse(source);
    return null;
  }

  bool _isAttrStep(String s) {
    const attrs = {
      'text',
      'textNodes',
      'html',
      'innerHTML',
      'href',
      'src',
      'all'
    };
    return attrs.contains(s) ||
        RegExp(r'^[A-Za-z_:][-A-Za-z0-9_:.]*$').hasMatch(s) && s.contains('-');
  }

  _CssSelector? _normalizeSelector(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    final range = RegExp(r'^(.*)\[(-?\d+):(-?\d+)\]$').firstMatch(s);
    if (range != null) {
      s = range.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        start: int.tryParse(range.group(2)!),
        end: int.tryParse(range.group(3)!),
      );
    }
    final bracketIndex = RegExp(r'^(.*)\[(-?\d+)\]$').firstMatch(s);
    if (bracketIndex != null && _isLegadoSelector(bracketIndex.group(1)!)) {
      s = bracketIndex.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        start: int.tryParse(bracketIndex.group(2)!),
      );
    }
    final dotIndex = RegExp(r'^(.*)\.(-?\d+)$').firstMatch(s);
    if (dotIndex != null) {
      s = dotIndex.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        start: int.tryParse(dotIndex.group(2)!),
      );
    }
    return _CssSelector(_normalizeSelectorValue(s));
  }

  bool _isLegadoSelector(String s) {
    return s.startsWith('class.') ||
        s.startsWith('id.') ||
        s.startsWith('tag.');
  }

  String _normalizeSelectorValue(String s) {
    if (s.startsWith('class.')) return '.${s.substring(6)}';
    if (s.startsWith('id.')) return '#${s.substring(3)}';
    if (s.startsWith('tag.')) return s.substring(4);
    return s;
  }

  List<dom.Element> _applySelectorIndex(
    List<dom.Element> nodes,
    _CssSelector selector,
  ) {
    if (nodes.isEmpty) return const [];
    final start = selector.start;
    final end = selector.end;
    if (start == null) return nodes;
    final normalizedStart = start < 0 ? nodes.length + start : start;
    if (normalizedStart < 0 || normalizedStart >= nodes.length) return const [];
    if (end == null) return [nodes[normalizedStart]];
    final normalizedEnd = end < 0 ? nodes.length + end : end;
    final clampedEnd = normalizedEnd.clamp(normalizedStart, nodes.length);
    return nodes.sublist(normalizedStart, clampedEnd);
  }

  String _extractAttr(dom.Element n, String attr) {
    switch (attr) {
      case 'text':
        return n.text.trim();
      case 'html':
      case 'innerHTML':
        return n.innerHtml;
      default:
        return n.attributes[attr] ?? '';
    }
  }
}

class _CssSelector {
  const _CssSelector(this.value, {this.start, this.end});

  final String value;
  final int? start;
  final int? end;

  bool get isEmpty => value.isEmpty;
}
