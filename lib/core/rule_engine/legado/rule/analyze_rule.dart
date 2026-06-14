import 'dart:convert';

import '../../models/rule_chain.dart';
import '../../parsers/parser.dart';
import 'rule_ast.dart';
import 'rule_context.dart';
import 'rule_value.dart';

class AnalyzeRule {
  AnalyzeRule({
    required this.registry,
    this.astParser = const LegadoRuleAstParser(),
  });

  final ParserRegistry registry;
  final LegadoRuleAstParser astParser;

  RuleValue parse(String rawRule, RuleContext context) {
    final ast = astParser.parse(_replaceDynamicRule(rawRule, context));
    return evaluate(ast, context, context.input.rawText);
  }

  String? string(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return null;
    final value = evaluate(
      astParser.parse(_replaceDynamicRule(rawRule, context, source: source)),
      context,
      source,
    );
    return _firstString(value);
  }

  List<Object> elements(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return const <Object>[];
    final value = evaluate(
      astParser.parse(_replaceDynamicRule(rawRule, context, source: source)),
      context,
      source,
      wantsElements: true,
    );
    return _objects(value);
  }

  String? absoluteUrl(String? rawUrl, String baseUrl) {
    final normalized = normalizeField(rawUrl);
    if (normalized == null || normalized.trim().isEmpty) return normalized;
    final uri = Uri.tryParse(normalized.trim());
    if (uri == null) return rawUrl;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
  }

  String? fieldString(Object source, String? rawRule, RuleContext context) {
    return normalizeField(string(source, rawRule, context));
  }

  String? normalizeField(String? value) {
    if (value == null) return null;
    return _htmlUnescape(value).replaceAll('\u00A0', ' ').trim();
  }

  String _replaceDynamicRule(
    String rawRule,
    RuleContext context, {
    Object? source,
  }) {
    return rawRule.replaceAllMapped(RegExp(r'\{\{([\s\S]+?)\}\}'), (match) {
      final expression = match.group(1)?.trim() ?? '';
      final value = _dynamicValue(expression, context, source: source);
      return value?.toString() ?? '';
    });
  }

  Object? _dynamicValue(
    String expression,
    RuleContext context, {
    Object? source,
  }) {
    final key = _unquote(expression);
    return switch (key) {
      'key' => context.keyword,
      'page' => context.page,
      'baseUrl' || 'baseUri' => context.baseUri.toString(),
      'redirectUrl' || 'redirectUri' => context.redirectUri.toString(),
      'result' => source ?? context.input.rawText,
      _ => context.getVariable(key),
    };
  }

  String _htmlUnescape(String input) {
    return input.replaceAllMapped(RegExp(r'&(#x?[0-9A-Fa-f]+|\w+);'), (match) {
      final entity = match.group(1)!;
      if (entity.startsWith('#x') || entity.startsWith('#X')) {
        final codePoint = int.tryParse(entity.substring(2), radix: 16);
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      }
      if (entity.startsWith('#')) {
        final codePoint = int.tryParse(entity.substring(1));
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      }
      return _namedHtmlEntities[entity] ?? match.group(0)!;
    });
  }

  RuleValue evaluate(
    LegadoRuleAst ast,
    RuleContext context,
    Object source, {
    bool wantsElements = false,
  }) {
    context.trace?.add('evaluate:${ast.runtimeType}');
    return switch (ast) {
      LegadoFallbackRule(:final alternatives) => _evaluateFallback(
          alternatives,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoAppendRule(:final parts) => _evaluateAppend(
          parts,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoInterleaveRule(:final parts) => _evaluateInterleave(
          parts,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoPipelineRule(:final steps) => _evaluatePipeline(
          steps,
          context,
          source,
          wantsElements: wantsElements,
        ),
    };
  }

  RuleValue _evaluateFallback(
    List<LegadoRuleAst> alternatives,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) {
    for (final alternative in alternatives) {
      final value = evaluate(
        alternative,
        context,
        source,
        wantsElements: wantsElements,
      );
      if (!value.isEmpty) return value;
    }
    return const RuleListValue([]);
  }

  RuleValue _evaluateAppend(
    List<LegadoRuleAst> parts,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) {
    return RuleListValue(
      parts
          .expand(
            (part) => _flatValues(
              evaluate(
                part,
                context,
                source,
                wantsElements: wantsElements,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  RuleValue _evaluateInterleave(
    List<LegadoRuleAst> parts,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) {
    final values = parts
        .map(
          (part) => _flatValues(
            evaluate(
              part,
              context,
              source,
              wantsElements: wantsElements,
            ),
          ).toList(growable: false),
        )
        .toList(growable: false);
    final maxLength = values.fold<int>(
      0,
      (max, list) => list.length > max ? list.length : max,
    );
    final interleaved = <RuleValue>[];
    for (var i = 0; i < maxLength; i++) {
      for (final list in values) {
        if (i < list.length) interleaved.add(list[i]);
      }
    }
    return RuleListValue(interleaved);
  }

  RuleValue _evaluatePipeline(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) {
    if (steps.isEmpty) return const RuleListValue([]);
    final variableValue = _evaluateVariableCommand(
      steps,
      context,
      source,
      wantsElements: wantsElements,
    );
    if (variableValue != null) return variableValue;

    final mode = steps.first.mode;
    final parserType = _parserTypeFor(mode, source);
    final parser = registry.forType(parserType);
    if (parser == null) return const RuleListValue([]);

    final rule = RuleChain.parse(_rawRuleForParser(steps));
    if (wantsElements) {
      return RuleNodeSetValue(parser.parseElements(source, rule));
    }
    return RuleListValue(
      parser
          .parseList(source, rule)
          .map(RuleStringValue.new)
          .toList(growable: false),
    );
  }

  RuleValue? _evaluateVariableCommand(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) {
    if (steps.length != 1) return null;
    final raw = steps.single.raw.trim();
    if (_isPut(raw)) {
      final payload = _commandPayload(raw, 'put');
      if (payload == null) return const RuleListValue([]);
      for (final entry in _parsePutPayload(payload, source).entries) {
        context.putVariable(entry.key, entry.value);
      }
      return const RuleListValue([]);
    }
    if (_isGet(raw)) {
      final key = _commandPayload(raw, 'get');
      if (key == null || key.trim().isEmpty) return const RuleListValue([]);
      return _valueFromObject(
        context.getVariable(_stripBraces(key).trim()),
        wantsElements: wantsElements,
      );
    }
    return null;
  }

  RuleType _parserTypeFor(LegadoRuleMode mode, Object source) {
    return switch (mode) {
      LegadoRuleMode.css => RuleType.explicitCss,
      LegadoRuleMode.jsonPath => RuleType.jsonPath,
      LegadoRuleMode.xpath => RuleType.xpath,
      LegadoRuleMode.regex => RuleType.regex,
      LegadoRuleMode.js => RuleType.js,
      LegadoRuleMode.defaultHtml =>
        source is Map || source is List ? RuleType.jsonPath : RuleType.css,
    };
  }

  String _rawRuleForParser(List<LegadoRuleStep> steps) {
    final raw = steps.map((step) => step.raw).join('@');
    return switch (steps.first.mode) {
      LegadoRuleMode.css => '@CSS:$raw',
      LegadoRuleMode.jsonPath => raw,
      LegadoRuleMode.xpath => '@XPath:$raw',
      LegadoRuleMode.regex => raw,
      LegadoRuleMode.js => raw,
      LegadoRuleMode.defaultHtml => raw,
    };
  }

  bool _isPut(String raw) =>
      RegExp(r'^@?put\s*:', caseSensitive: false).hasMatch(raw);

  bool _isGet(String raw) =>
      RegExp(r'^@?get\s*:', caseSensitive: false).hasMatch(raw);

  String? _commandPayload(String raw, String command) {
    final match = RegExp(
      '^@?$command\\s*:\\s*([\\s\\S]*)\$',
      caseSensitive: false,
    ).firstMatch(raw);
    return match?.group(1)?.trim();
  }

  Map<String, Object?> _parsePutPayload(String payload, Object source) {
    final body = _stripBraces(payload).trim();
    if (body.isEmpty) return const {};

    final decoded = _tryDecodeJson(payload) ?? _tryDecodeJson('{$body}');
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (!body.contains(':')) return {body: source};

    final out = <String, Object?>{};
    for (final part in body.split(',')) {
      final separator = part.indexOf(':');
      if (separator <= 0) continue;
      final key = part.substring(0, separator).trim();
      final value = part.substring(separator + 1).trim();
      if (key.isEmpty) continue;
      out[_unquote(key)] = _unquote(value);
    }
    return out;
  }

  Object? _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  String _stripBraces(String raw) {
    final text = raw.trim();
    if (text.startsWith('{') && text.endsWith('}')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  String _unquote(String raw) {
    final text = raw.trim();
    if (text.length >= 2) {
      final first = text[0];
      final last = text[text.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        return text.substring(1, text.length - 1);
      }
    }
    return text;
  }

  RuleValue _valueFromObject(Object? value, {required bool wantsElements}) {
    if (value == null) return const RuleListValue([]);
    if (wantsElements) {
      if (value is Iterable) {
        return RuleNodeSetValue(value.whereType<Object>().toList());
      }
      return RuleNodeSetValue([value]);
    }
    if (value is Iterable) {
      return RuleListValue(
        value
            .whereType<Object?>()
            .map((item) => RuleStringValue(item.toString()))
            .toList(growable: false),
      );
    }
    return RuleStringValue(value.toString());
  }

  String? _firstString(RuleValue value) {
    return switch (value) {
      RuleStringValue(:final value) => value,
      RuleListValue(:final values) => _firstStringIn(values),
      RuleNodeSetValue(:final nodes) =>
        nodes.isEmpty ? null : nodes.first.toString(),
      RuleJsonValue(:final value) => value?.toString(),
      RuleRegexCapturesValue(:final captures) =>
        captures.isEmpty ? null : captures.first,
      RuleJsValue(:final value) => value?.toString(),
    };
  }

  String? _firstStringIn(List<RuleValue> values) {
    for (final value in values) {
      final text = _firstString(value);
      if (text != null) return text;
    }
    return null;
  }

  List<Object> _objects(RuleValue value) {
    return switch (value) {
      RuleNodeSetValue(:final nodes) => nodes,
      RuleListValue(:final values) =>
        values.expand(_objects).toList(growable: false),
      RuleStringValue(:final value) => value.isEmpty ? const [] : [value],
      RuleJsonValue(:final value) => value == null ? const [] : [value],
      RuleRegexCapturesValue(:final captures) => captures,
      RuleJsValue(:final value) => value == null ? const [] : [value],
    };
  }

  Iterable<RuleValue> _flatValues(RuleValue value) sync* {
    switch (value) {
      case RuleListValue(:final values):
        for (final item in values) {
          yield* _flatValues(item);
        }
      default:
        if (!value.isEmpty) yield value;
    }
  }
}

const _namedHtmlEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'copy': '(c)',
  'reg': '(r)',
};
