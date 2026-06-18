import 'dart:convert';

import '../../models/rule_chain.dart';
import '../../parsers/parser.dart';
import '../js/legado_js_engine.dart';
import 'rule_ast.dart';
import 'rule_context.dart';
import 'rule_value.dart';

class AnalyzeRule {
  AnalyzeRule({
    required this.registry,
    this.astParser = const LegadoRuleAstParser(),
    this.jsEngine = const SimpleLegadoJsEngine(),
  });

  final ParserRegistry registry;
  final LegadoRuleAstParser astParser;
  final LegadoJsEngine jsEngine;

  RuleValue parse(String rawRule, RuleContext context) {
    final ast = astParser.parse(_replaceDynamicRule(rawRule, context));
    return evaluate(ast, context, context.input.rawText);
  }

  String? string(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return null;
    context.trace?.add('rule.stage:string');
    final preparedRule = _replaceDynamicRule(rawRule, context, source: source);
    if (preparedRule != rawRule &&
        _looksLikeLiteral(preparedRule) &&
        !_hasEmbeddedJs(preparedRule)) {
      return preparedRule;
    }
    final embedded = _evaluateEmbeddedJsRule(
      source,
      preparedRule,
      context,
      wantsElements: false,
    );
    if (embedded != null) return _firstString(embedded);
    final value = evaluate(
      astParser.parse(preparedRule),
      context,
      source,
    );
    return _firstString(value);
  }

  Future<String?> stringAsync(
    Object source,
    String? rawRule,
    RuleContext context,
  ) async {
    if (rawRule == null || rawRule.trim().isEmpty) return null;
    context.trace?.add('rule.stage:string');
    final preparedRule = _replaceDynamicRule(rawRule, context, source: source);
    if (preparedRule != rawRule &&
        _looksLikeLiteral(preparedRule) &&
        !_hasEmbeddedJs(preparedRule)) {
      return preparedRule;
    }
    final embedded = await _evaluateEmbeddedJsRuleAsync(
      source,
      preparedRule,
      context,
      wantsElements: false,
    );
    if (embedded != null) return _firstString(embedded);
    final value = await evaluateAsync(
      astParser.parse(preparedRule),
      context,
      source,
    );
    return _firstString(value);
  }

  List<Object> elements(Object source, String? rawRule, RuleContext context) {
    if (rawRule == null || rawRule.trim().isEmpty) return const <Object>[];
    context.trace?.add('rule.stage:elements');
    final embedded = _evaluateEmbeddedJsRule(
      source,
      rawRule,
      context,
      wantsElements: true,
    );
    if (embedded != null) return _objects(embedded);
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

  Future<String?> fieldStringAsync(
    Object source,
    String? rawRule,
    RuleContext context,
  ) async {
    return normalizeField(await stringAsync(source, rawRule, context));
  }

  List<String> fieldStrings(
    Object source,
    String? rawRule,
    RuleContext context,
  ) {
    if (rawRule == null || rawRule.trim().isEmpty) return const [];
    context.trace?.add('rule.stage:fieldStrings');
    final preparedRule = _replaceDynamicRule(rawRule, context, source: source);
    final embedded = _evaluateEmbeddedJsRule(
      source,
      preparedRule,
      context,
      wantsElements: false,
    );
    if (embedded != null) {
      return _strings(embedded)
          .map(normalizeField)
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    final value = evaluate(
      astParser.parse(preparedRule),
      context,
      source,
    );
    return _strings(value)
        .map(normalizeField)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fieldStringsAsync(
    Object source,
    String? rawRule,
    RuleContext context,
  ) async {
    if (rawRule == null || rawRule.trim().isEmpty) return const [];
    context.trace?.add('rule.stage:fieldStrings');
    final preparedRule = _replaceDynamicRule(rawRule, context, source: source);
    final embedded = await _evaluateEmbeddedJsRuleAsync(
      source,
      preparedRule,
      context,
      wantsElements: false,
    );
    if (embedded != null) return _normalizedStrings(embedded);
    final value = await evaluateAsync(
      astParser.parse(preparedRule),
      context,
      source,
    );
    return _normalizedStrings(value);
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
      return _stringifyDynamicValue(value);
    });
  }

  String _stringifyDynamicValue(Object? value) {
    if (value == null) return '';
    if (value is double && value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  Object? _dynamicValue(
    String expression,
    RuleContext context, {
    Object? source,
  }) {
    final key = _unquote(expression);
    final direct = switch (key) {
      'key' => context.keyword,
      'page' => context.page,
      'baseUrl' || 'baseUri' => context.currentUrl,
      'redirectUrl' || 'redirectUri' => context.redirectUri.toString(),
      'result' => source ?? context.input.rawText,
      _ => context.getVariable(key),
    };
    if (direct != null) return direct;

    if (_looksLikeRule(key)) {
      try {
        final value = evaluate(
          astParser.parse(_replaceDynamicRule(key, context, source: source)),
          context,
          source ?? context.input.rawText,
        );
        return _firstString(value);
      } on Exception {
        return null;
      }
    }

    try {
      return jsEngine.eval(
        expression,
        context: LegadoJsContext(
          key: context.keyword ?? '',
          page: context.page,
          baseUrl: context.currentUrl,
          src: source,
          result: source ?? context.input.rawText,
          source: context.source,
          book: context.book,
          variables: context.variables,
          cookie: context.cookie,
          ajax: context.ajax,
          trace: context.trace,
        ),
      );
    } on Exception {
      return null;
    }
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

  Future<RuleValue> evaluateAsync(
    LegadoRuleAst ast,
    RuleContext context,
    Object source, {
    bool wantsElements = false,
  }) async {
    context.trace?.add('evaluate:${ast.runtimeType}');
    return switch (ast) {
      LegadoFallbackRule(:final alternatives) => _evaluateFallbackAsync(
          alternatives,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoAppendRule(:final parts) => _evaluateAppendAsync(
          parts,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoInterleaveRule(:final parts) => _evaluateInterleaveAsync(
          parts,
          context,
          source,
          wantsElements: wantsElements,
        ),
      LegadoPipelineRule(:final steps) => _evaluatePipelineAsync(
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

  Future<RuleValue> _evaluateFallbackAsync(
    List<LegadoRuleAst> alternatives,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) async {
    for (final alternative in alternatives) {
      final value = await evaluateAsync(
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

  Future<RuleValue> _evaluateAppendAsync(
    List<LegadoRuleAst> parts,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) async {
    final values = <RuleValue>[];
    for (final part in parts) {
      final value = await evaluateAsync(
        part,
        context,
        source,
        wantsElements: wantsElements,
      );
      values.addAll(_flatValues(value));
    }
    return RuleListValue(values);
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

  Future<RuleValue> _evaluateInterleaveAsync(
    List<LegadoRuleAst> parts,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) async {
    final values = <List<RuleValue>>[];
    for (final part in parts) {
      final value = await evaluateAsync(
        part,
        context,
        source,
        wantsElements: wantsElements,
      );
      values.add(_flatValues(value).toList(growable: false));
    }
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
    final normalizedSteps = _applyPutSteps(steps, context, source);
    if (normalizedSteps.isEmpty) return const RuleListValue([]);
    final variableValue = _evaluateVariableCommand(
      normalizedSteps,
      context,
      source,
      wantsElements: wantsElements,
    );
    if (variableValue != null) return variableValue;

    final mode = normalizedSteps.first.mode;
    if (mode == LegadoRuleMode.js) {
      final value = _evaluateJsSteps(normalizedSteps, context, source);
      return _valueFromObject(value, wantsElements: wantsElements);
    }
    if (mode == LegadoRuleMode.webJs) {
      context.trace?.add('rule.webJs:unsupported');
      return const RuleListValue([]);
    }

    final parserType = _parserTypeFor(mode, source);
    context.trace?.add('rule.parserMode:${mode.name}');
    final parser = registry.forType(parserType);
    if (parser == null) {
      context.trace?.add('rule.parser.unsupported:${parserType.name}');
      return const RuleListValue([]);
    }

    final rule = RuleChain.parse(_rawRuleForParser(normalizedSteps));
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

  Future<RuleValue> _evaluatePipelineAsync(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source, {
    required bool wantsElements,
  }) async {
    if (steps.isEmpty) return const RuleListValue([]);
    final normalizedSteps = _applyPutSteps(steps, context, source);
    if (normalizedSteps.isEmpty) return const RuleListValue([]);
    final variableValue = _evaluateVariableCommand(
      normalizedSteps,
      context,
      source,
      wantsElements: wantsElements,
    );
    if (variableValue != null) return variableValue;

    final mode = normalizedSteps.first.mode;
    if (mode == LegadoRuleMode.js) {
      final value =
          await _evaluateJsStepsAsync(normalizedSteps, context, source);
      return _valueFromObject(value, wantsElements: wantsElements);
    }
    if (mode == LegadoRuleMode.webJs) {
      context.trace?.add('rule.webJs:unsupported');
      return const RuleListValue([]);
    }

    final parserType = _parserTypeFor(mode, source);
    context.trace?.add('rule.parserMode:${mode.name}');
    final parser = registry.forType(parserType);
    if (parser == null) {
      context.trace?.add('rule.parser.unsupported:${parserType.name}');
      return const RuleListValue([]);
    }

    final rule = RuleChain.parse(_rawRuleForParser(normalizedSteps));
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

  RuleValue? _evaluateEmbeddedJsRule(
    Object source,
    String rawRule,
    RuleContext context, {
    required bool wantsElements,
  }) {
    final parts = _splitEmbeddedJs(rawRule);
    if (parts == null) return null;

    Object? current = source;
    var sawJs = false;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.text.trim().isEmpty) continue;
      if (part.isJs) {
        sawJs = true;
        current = jsEngine.eval(
          _stripJsWrapper(part.text),
          context: LegadoJsContext(
            key: context.keyword ?? '',
            page: context.page,
            baseUrl: context.currentUrl,
            src: source,
            result: current,
            source: context.source,
            book: context.book,
            variables: context.variables,
            cookie: context.cookie,
            ajax: context.ajax,
            trace: context.trace,
          ),
        );
        continue;
      }

      final isLast = i == parts.length - 1;
      final preparedPart =
          _replaceDynamicRule(part.text, context, source: current).trim();
      if (_looksLikeLiteral(preparedPart)) {
        current = preparedPart;
        continue;
      }
      final value = evaluate(
        astParser.parse(preparedPart),
        context,
        current ?? '',
        wantsElements: wantsElements && isLast,
      );
      if (wantsElements && isLast) return value;
      current = _objectFromValue(value);
    }

    return sawJs
        ? _valueFromObject(current, wantsElements: wantsElements)
        : null;
  }

  Future<RuleValue?> _evaluateEmbeddedJsRuleAsync(
    Object source,
    String rawRule,
    RuleContext context, {
    required bool wantsElements,
  }) async {
    final parts = _splitEmbeddedJs(rawRule);
    if (parts == null) return null;

    Object? current = source;
    var sawJs = false;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.text.trim().isEmpty) continue;
      if (part.isJs) {
        sawJs = true;
        current = await jsEngine.evalAsync(
          _stripJsWrapper(part.text),
          context: LegadoJsContext(
            key: context.keyword ?? '',
            page: context.page,
            baseUrl: context.currentUrl,
            src: source,
            result: current,
            source: context.source,
            book: context.book,
            variables: context.variables,
            cookie: context.cookie,
            ajax: context.ajax,
            trace: context.trace,
          ),
        );
        continue;
      }

      final isLast = i == parts.length - 1;
      final preparedPart =
          _replaceDynamicRule(part.text, context, source: current).trim();
      if (_looksLikeLiteral(preparedPart)) {
        current = preparedPart;
        continue;
      }
      final value = await evaluateAsync(
        astParser.parse(preparedPart),
        context,
        current ?? '',
        wantsElements: wantsElements && isLast,
      );
      if (wantsElements && isLast) return value;
      current = _objectFromValue(value);
    }

    return sawJs
        ? _valueFromObject(current, wantsElements: wantsElements)
        : null;
  }

  List<_EmbeddedRulePart>? _splitEmbeddedJs(String rawRule) {
    final parts = <_EmbeddedRulePart>[];
    final textBuffer = StringBuffer();
    var foundJs = false;
    var index = 0;

    while (index < rawRule.length) {
      if (_startsWithIgnoreCase(rawRule, index, '<js>')) {
        _flushEmbeddedText(parts, textBuffer);
        final end = _findJsBlockEnd(rawRule, index + 4);
        if (end == -1) {
          if (parts.isEmpty) {
            // 部分历史书源会只写起始 <js>，Legado 在多个入口也按整段脚本处理。
            // 这里将剩余内容视为 JS，避免把 '<js>' 交给 JS 引擎造成语法错误。
            parts.add(_EmbeddedRulePart(rawRule.substring(index + 4), true));
            foundJs = true;
            index = rawRule.length;
            continue;
          }
          textBuffer.write(rawRule.substring(index));
          break;
        }
        parts.add(_EmbeddedRulePart(rawRule.substring(index + 4, end), true));
        foundJs = true;
        index = end + 5;
        continue;
      }

      if (_startsWithIgnoreCase(rawRule, index, '@js:')) {
        _flushEmbeddedText(parts, textBuffer);
        parts.add(_EmbeddedRulePart(rawRule.substring(index + 4), true));
        foundJs = true;
        index = rawRule.length;
        continue;
      }

      textBuffer.write(rawRule[index]);
      index += 1;
    }

    _flushEmbeddedText(parts, textBuffer);
    return foundJs ? parts : null;
  }

  void _flushEmbeddedText(
    List<_EmbeddedRulePart> parts,
    StringBuffer buffer,
  ) {
    if (buffer.isEmpty) return;
    parts.add(_EmbeddedRulePart(buffer.toString(), false));
    buffer.clear();
  }

  int _findJsBlockEnd(String rawRule, int start) {
    var quote = '';
    var escaped = false;
    for (var index = start; index < rawRule.length; index++) {
      final char = rawRule[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == quote) quote = '';
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        continue;
      }
      if (_startsWithIgnoreCase(rawRule, index, '</js>')) return index;
    }
    return -1;
  }

  bool _startsWithIgnoreCase(String input, int index, String pattern) {
    if (index + pattern.length > input.length) return false;
    return input.substring(index, index + pattern.length).toLowerCase() ==
        pattern.toLowerCase();
  }

  List<LegadoRuleStep> _applyPutSteps(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source,
  ) {
    final out = <LegadoRuleStep>[];
    for (final step in steps) {
      if (_isPut(step.raw)) {
        final payload = _commandPayload(step.raw, 'put');
        if (payload != null) {
          for (final entry in _parsePutPayload(payload, source).entries) {
            final rawValue = entry.value;
            final value = rawValue is String && _looksLikeRule(rawValue)
                ? string(source, rawValue, context)
                : rawValue;
            context.putVariable(entry.key, value);
          }
        }
      } else {
        out.add(step);
      }
    }
    return out;
  }

  bool _looksLikeRule(String rule) {
    final text = rule.trim();
    return text.startsWith('@') ||
        text.startsWith(r'$.') ||
        text.startsWith(r'$[') ||
        text.startsWith(r'$..') ||
        text.startsWith('//');
  }

  bool _looksLikeLiteral(String rule) {
    final text = rule.trim();
    return RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false)
        .hasMatch(text);
  }

  bool _hasEmbeddedJs(String rule) {
    return RegExp(r'<js>[\s\S]*?</js>|@js:', caseSensitive: false)
        .hasMatch(rule);
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
      LegadoRuleMode.webJs => RuleType.js,
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
      LegadoRuleMode.webJs => raw,
      LegadoRuleMode.defaultHtml => raw,
    };
  }

  Object? _evaluateJsSteps(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source,
  ) {
    Object? current = source;
    for (final step in steps) {
      current = jsEngine.eval(
        _stripJsWrapper(step.raw),
        context: LegadoJsContext(
          key: context.keyword ?? '',
          page: context.page,
          baseUrl: context.currentUrl,
          src: source,
          result: current,
          source: context.source,
          book: context.book,
          variables: context.variables,
          cookie: context.cookie,
          ajax: context.ajax,
          trace: context.trace,
        ),
      );
    }
    return current;
  }

  Future<Object?> _evaluateJsStepsAsync(
    List<LegadoRuleStep> steps,
    RuleContext context,
    Object source,
  ) async {
    Object? current = source;
    for (final step in steps) {
      current = await jsEngine.evalAsync(
        _stripJsWrapper(step.raw),
        context: LegadoJsContext(
          key: context.keyword ?? '',
          page: context.page,
          baseUrl: context.currentUrl,
          src: source,
          result: current,
          source: context.source,
          book: context.book,
          variables: context.variables,
          cookie: context.cookie,
          ajax: context.ajax,
          trace: context.trace,
        ),
      );
    }
    return current;
  }

  String _stripJsWrapper(String raw) {
    final text = raw.trim();
    final match = RegExp(
      r'^<js>([\s\S]*)</js>$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return match.group(1)?.trim() ?? '';
    if (_startsWithIgnoreCase(text, 0, '<js>')) {
      final body = text.substring(4).trim();
      if (body.toLowerCase().endsWith('</js>')) {
        return body.substring(0, body.length - 5).trim();
      }
      // 容错处理缺少闭合标签的整段 JS 规则，保持兼容层集中在规则引擎内。
      return body;
    }
    return text;
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

  Object? _objectFromValue(RuleValue value) {
    return switch (value) {
      RuleStringValue(:final value) => value,
      RuleListValue(:final values) => values.length == 1
          ? _objectFromValue(values.single)
          : [
              for (final item in values) _objectFromValue(item),
            ],
      RuleNodeSetValue(:final nodes) => nodes,
      RuleJsonValue(:final value) => value,
      RuleRegexCapturesValue(:final captures) => captures,
      RuleJsValue(:final value) => value,
    };
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

  List<String> _strings(RuleValue value) {
    return switch (value) {
      RuleStringValue(:final value) => value.isEmpty ? const [] : [value],
      RuleListValue(:final values) =>
        values.expand(_strings).toList(growable: false),
      RuleNodeSetValue(:final nodes) => [
          for (final node in nodes)
            if (node.toString().isNotEmpty) node.toString(),
        ],
      RuleJsonValue(:final value) =>
        value == null ? const [] : [value.toString()],
      RuleRegexCapturesValue(:final captures) => captures,
      RuleJsValue(:final value) =>
        value == null ? const [] : [value.toString()],
    };
  }

  List<String> _normalizedStrings(RuleValue value) {
    return _strings(value)
        .map(normalizeField)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
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

class _EmbeddedRulePart {
  const _EmbeddedRulePart(this.text, this.isJs);

  final String text;
  final bool isJs;
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
