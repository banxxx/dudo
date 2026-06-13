import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class RuleInput {
  RuleInput({
    required this.rawText,
    required this.baseUri,
    Uri? redirectUri,
    dom.Document? htmlDocument,
    Object? jsonDocument,
  })  : redirectUri = redirectUri ?? baseUri,
        _htmlDocument = htmlDocument,
        _jsonDocument = jsonDocument;

  final String rawText;
  final Uri baseUri;
  final Uri redirectUri;
  dom.Document? _htmlDocument;
  Object? _jsonDocument;

  dom.Document get htmlDocument {
    return _htmlDocument ??= html_parser.parse(rawText);
  }

  Object? get jsonDocument {
    if (_jsonDocument != null) return _jsonDocument;
    try {
      _jsonDocument = jsonDecode(rawText);
    } catch (_) {
      _jsonDocument = null;
    }
    return _jsonDocument;
  }
}

sealed class RuleValue {
  const RuleValue();

  bool get isEmpty;
}

class RuleStringValue extends RuleValue {
  const RuleStringValue(this.value);

  final String value;

  @override
  bool get isEmpty => value.isEmpty;
}

class RuleListValue extends RuleValue {
  const RuleListValue(this.values);

  final List<RuleValue> values;

  @override
  bool get isEmpty => values.isEmpty || values.every((value) => value.isEmpty);
}

class RuleNodeSetValue extends RuleValue {
  const RuleNodeSetValue(this.nodes);

  final List<Object> nodes;

  @override
  bool get isEmpty => nodes.isEmpty;
}

class RuleJsonValue extends RuleValue {
  const RuleJsonValue(this.value);

  final Object? value;

  @override
  bool get isEmpty => value == null;
}

class RuleRegexCapturesValue extends RuleValue {
  const RuleRegexCapturesValue(this.captures);

  final List<String> captures;

  @override
  bool get isEmpty => captures.isEmpty;
}

class RuleJsValue extends RuleValue {
  const RuleJsValue(this.value);

  final Object? value;

  @override
  bool get isEmpty => value == null || value == '';
}
