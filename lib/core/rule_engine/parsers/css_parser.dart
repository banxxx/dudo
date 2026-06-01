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
    final doc = _toDocument(source);
    if (doc == null) return const [];
    final out = <String>[];
    for (final seg in rule.segments) {
      // Legado-style segments use @-separated steps where the last step is
      // an attribute extractor (text, html, href, src…).
      List<dom.Element> currentNodes = [doc.documentElement!];
      String attr = 'text';
      for (var i = 0; i < seg.steps.length; i++) {
        final s = seg.steps[i].raw;
        if (i == seg.steps.length - 1 && _isAttrStep(s)) {
          attr = s;
          break;
        }
        currentNodes =
            currentNodes.expand((n) => n.querySelectorAll(s)).toList();
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
    final doc = _toDocument(source);
    if (doc == null) return const [];
    final result = <dom.Element>[];
    for (final seg in rule.segments) {
      List<dom.Element> currentNodes = [doc.documentElement!];
      for (final step in seg.steps) {
        if (_isAttrStep(step.raw)) continue;
        currentNodes =
            currentNodes.expand((n) => n.querySelectorAll(step.raw)).toList();
      }
      result.addAll(currentNodes);
      if (result.isNotEmpty) break;
    }
    return result;
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
    return attrs.contains(s);
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
