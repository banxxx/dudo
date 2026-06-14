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
    final ast = astParser.parse(rawRule);
    return evaluate(ast, context, context.input.rawText);
  }

  String? string(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return null;
    final value = evaluate(astParser.parse(rawRule), context, source);
    return _firstString(value);
  }

  List<Object> elements(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return const <Object>[];
    final value = evaluate(
      astParser.parse(rawRule),
      context,
      source,
      wantsElements: true,
    );
    return _objects(value);
  }

  String? absoluteUrl(String? rawUrl, String baseUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return rawUrl;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return rawUrl;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
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
