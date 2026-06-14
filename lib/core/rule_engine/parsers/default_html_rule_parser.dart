import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/rule_chain.dart';
import 'parser.dart';

/// Default HTML selector parser for Legado-style rules, powered by package:html.
class DefaultHtmlRuleParser implements RuleParser {
  const DefaultHtmlRuleParser();

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
            final selected = _select(n, selector);
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
            final selected = _select(n, selector);
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
      'ownText',
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
    final bracketIndex = RegExp(r'^(.*)\[([^\]]+)\]$').firstMatch(s);
    if (bracketIndex != null && _isIndexList(bracketIndex.group(2)!)) {
      s = bracketIndex.group(1)!.trim();
      final indexSet = _parseIndexSet(bracketIndex.group(2)!);
      return _CssSelector(
        _normalizeSelectorValue(s),
        indexes: indexSet.indexes,
        excludeIndexes: indexSet.exclude,
      );
    }

    final legacyExclude = RegExp(r'^(.*)!(-?\d+(?::-?\d+)*)$').firstMatch(s);
    if (legacyExclude != null) {
      s = legacyExclude.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        indexes: _parseLegacyIndexes(legacyExclude.group(2)!),
        excludeIndexes: true,
      );
    }

    final legacyRange =
        RegExp(r'^(.*)\.(-?\d+:-?\d+(?::-?\d+)?)$').firstMatch(s);
    if (legacyRange != null) {
      s = legacyRange.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        indexes: _parseLegacyIndexes(legacyRange.group(2)!),
      );
    }

    final dotIndex = RegExp(r'^(.*)\.(-?\d+)$').firstMatch(s);
    if (dotIndex != null) {
      s = dotIndex.group(1)!.trim();
      return _CssSelector(
        _normalizeSelectorValue(s),
        indexes: [_IndexSpec.single(int.tryParse(dotIndex.group(2)!) ?? 0)],
      );
    }
    return _CssSelector(_normalizeSelectorValue(s));
  }

  bool _isIndexList(String raw) {
    return RegExp(
            r'^!?\s*-?\d*(?::\s*-?\d*){0,2}(\s*,\s*-?\d*(?::\s*-?\d*){0,2})*\s*$')
        .hasMatch(raw.trim());
  }

  String _normalizeSelectorValue(String s) {
    if (s.startsWith('class.')) return '.${s.substring(6)}';
    if (s.startsWith('id.')) return '#${s.substring(3)}';
    if (s.startsWith('tag.')) return s.substring(4);
    if (s.startsWith('text.')) return s;
    return s;
  }

  List<dom.Element> _select(dom.Element root, _CssSelector selector) {
    if (selector.textContains != null) {
      final needle = selector.textContains!;
      return root
          .querySelectorAll('*')
          .where((element) => _ownText(element).contains(needle))
          .toList();
    }
    return root.querySelectorAll(selector.value).toList();
  }

  List<dom.Element> _applySelectorIndex(
    List<dom.Element> nodes,
    _CssSelector selector,
  ) {
    if (nodes.isEmpty) return const [];
    if (selector.indexes.isEmpty) return nodes;

    final selected = <int>{};
    for (final spec in selector.indexes) {
      selected.addAll(spec.resolve(nodes.length));
    }
    if (selected.isEmpty) return selector.excludeIndexes ? nodes : const [];

    if (selector.excludeIndexes) {
      return [
        for (var i = 0; i < nodes.length; i++)
          if (!selected.contains(i)) nodes[i],
      ];
    }
    return [
      for (final index in selected)
        if (index >= 0 && index < nodes.length) nodes[index],
    ];
  }

  String _extractAttr(dom.Element n, String attr) {
    switch (attr) {
      case 'text':
        return _elementText(n).trim();
      case 'textNodes':
        return _textNodes(n);
      case 'ownText':
        return _ownText(n);
      case 'html':
      case 'innerHTML':
        return _cleanInnerHtml(n);
      case 'all':
        return n.outerHtml;
      default:
        return n.attributes[attr] ?? '';
    }
  }

  String _elementText(dom.Element element) {
    final buffer = StringBuffer();
    void visit(dom.Node node) {
      if (node is dom.Element &&
          (node.localName == 'script' || node.localName == 'style')) {
        return;
      }
      if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(text);
        }
        return;
      }
      for (final child in node.nodes) {
        visit(child);
      }
    }

    visit(element);
    return buffer.toString();
  }

  String _ownText(dom.Element element) {
    return element.nodes
        .whereType<dom.Text>()
        .map((node) => node.text.trim())
        .where((text) => text.isNotEmpty)
        .join(' ');
  }

  String _textNodes(dom.Element element) {
    return element.nodes
        .whereType<dom.Text>()
        .map((node) => node.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
  }

  String _cleanInnerHtml(dom.Element element) {
    final clone = html_parser.parse(element.outerHtml).body?.children.first;
    if (clone == null) return element.innerHtml;
    for (final node in clone.querySelectorAll('script, style')) {
      node.remove();
    }
    return clone.innerHtml;
  }

  _IndexSet _parseIndexSet(String raw) {
    final trimmed = raw.trim();
    final exclude = trimmed.startsWith('!');
    final body = exclude ? trimmed.substring(1).trim() : trimmed;
    return _IndexSet(
      exclude: exclude,
      indexes: [
        for (final part in body.split(','))
          if (part.trim().isNotEmpty) _parseIndexSpec(part.trim()),
      ],
    );
  }

  List<_IndexSpec> _parseLegacyIndexes(String raw) {
    return [_parseIndexSpec(raw)];
  }

  _IndexSpec _parseIndexSpec(String raw) {
    final parts = raw.split(':').map((part) => part.trim()).toList();
    if (parts.length == 1) {
      return _IndexSpec.single(int.tryParse(parts.single) ?? 0);
    }
    return _IndexSpec.range(
      start: parts[0].isEmpty ? null : int.tryParse(parts[0]),
      end: parts.length < 2 || parts[1].isEmpty ? null : int.tryParse(parts[1]),
      step: parts.length < 3 || parts[2].isEmpty ? 1 : int.tryParse(parts[2]),
    );
  }
}

class _CssSelector {
  const _CssSelector(
    this.value, {
    this.indexes = const [],
    this.excludeIndexes = false,
  });

  final String value;
  final List<_IndexSpec> indexes;
  final bool excludeIndexes;

  bool get isEmpty => value.isEmpty;
  String? get textContains =>
      value.startsWith('text.') ? value.substring(5) : null;
}

class _IndexSet {
  const _IndexSet({required this.exclude, required this.indexes});

  final bool exclude;
  final List<_IndexSpec> indexes;
}

class _IndexSpec {
  const _IndexSpec.single(int index)
      : start = index,
        end = index,
        step = 1,
        isRange = false;

  const _IndexSpec.range({this.start, this.end, int? step})
      : step = step ?? 1,
        isRange = true;

  final int? start;
  final int? end;
  final int step;
  final bool isRange;

  Iterable<int> resolve(int length) sync* {
    if (length <= 0) return;

    var normalizedStart = _normalize(start ?? 0, length);
    if (!isRange) {
      if (normalizedStart >= 0 && normalizedStart < length) {
        yield normalizedStart;
      }
      return;
    }

    var normalizedEnd = _normalize(end ?? length, length);
    normalizedStart = normalizedStart.clamp(0, length - 1);
    normalizedEnd = normalizedEnd.clamp(0, length);

    final stride = step == 0 ? 1 : step.abs();
    if (normalizedStart <= normalizedEnd) {
      for (var i = normalizedStart; i < normalizedEnd; i += stride) {
        yield i;
      }
    } else {
      for (var i = normalizedStart; i > normalizedEnd; i -= stride) {
        yield i;
      }
    }
  }

  int _normalize(int index, int length) {
    return index < 0 ? length + index : index;
  }
}
