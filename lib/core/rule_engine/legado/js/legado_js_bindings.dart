import 'dart:convert';

import '../../models/source_rule.dart';
import 'legado_js_context.dart';

class LegadoJsBindings {
  const LegadoJsBindings();

  String contextJson(LegadoJsContext context) {
    return jsonEncode(<String, Object?>{
      'key': context.key,
      'keyword': context.key,
      'page': context.page,
      'baseUrl': context.baseUrl,
      'src': context.src,
      'result': context.result,
      'source': _sourceToJson(context.source),
      'book': context.book,
      'chapter': context.chapter,
      'nextChapterUrl': context.nextChapterUrl,
      'variables': context.variables,
      'cookie': context.cookie,
    });
  }

  String globals({
    required bool allowAsync,
    required bool hasAjax,
    String? ajaxContextId,
  }) {
    return '''
  var key = __ctx.key;
  var keyword = __ctx.keyword;
  var page = __ctx.page;
  var baseUrl = __ctx.baseUrl;
  var src = __ctx.src;
  var result = __ctx.result;
  var source = __ctx.source;
  var book = __ctx.book;
  var chapter = __ctx.chapter;
  var nextChapterUrl = __ctx.nextChapterUrl;
${_jsonPathHelpers()}
${_javaBinding(allowAsync: allowAsync, hasAjax: hasAjax, ajaxContextId: ajaxContextId)}
${_cookieBinding()}
${_cacheBinding()}
''';
  }

  String _jsonPathHelpers() {
    return r'''
  function __parseMaybeJson(value) {
    if (typeof value !== "string") return value;
    var text = value.trim();
    if (!text) return value;
    if (text[0] !== "{" && text[0] !== "[") return value;
    try { return JSON.parse(text); } catch (e) { return value; }
  }
  function __readPath(root, path) {
    if (root == null || typeof path !== "string") return null;
    if (path === "$") return root;
    if (path.indexOf("$.") !== 0) return null;
    var current = __parseMaybeJson(root);
    var parts = path.substring(2).split(".");
    for (var i = 0; i < parts.length; i++) {
      if (current == null) return null;
      var part = parts[i];
      var bracket = part.match(/^([^\[]+)\[(\d+)\]$/);
      if (bracket) {
        current = current[bracket[1]];
        current = current == null ? null : current[Number(bracket[2])];
      } else {
        current = current[part];
      }
    }
    return current == null ? null : current;
  }
  function __ruleValue(path) {
    var fromResult = __readPath(result, path);
    if (fromResult != null) return fromResult;
    return __readPath(src, path);
  }
''';
  }

  String _javaBinding({
    required bool allowAsync,
    required bool hasAjax,
    String? ajaxContextId,
  }) {
    final ajaxFunction = allowAsync && hasAjax
        ? '''
    ajax: function(rawUrl) {
      return sendMessage(
        "LegadoJavaAjax",
        JSON.stringify({"id": ${jsonEncode(ajaxContextId)}, "url": String(rawUrl)})
      );
    }
'''
        : '''
    ajax: function() {
      throw new Error("java.ajax is not configured");
    }
''';
    return '''
  var java = {
    getString: function(value) {
      if (typeof value === "string" && value.indexOf("\$") === 0) {
        var ruleValue = __ruleValue(value);
        return ruleValue == null ? "" : String(ruleValue);
      }
      return value == null ? "" : String(value);
    },
    put: function(name, value) {
      __ctx.variables[String(name)] = value;
      return value;
    },
    get: function(name) { return __ctx.variables[String(name)]; },
    setContent: function(value) {
      src = value;
      result = value;
      __ctx.src = value;
      __ctx.result = value;
      return value;
    },
    log: function(value) { return value; },
$ajaxFunction
  };
''';
  }

  String _cookieBinding() {
    return '''
  var cookie = {
    getKey: function(domainOrName, maybeName) {
      var name = maybeName == null ? domainOrName : maybeName;
      if (!__ctx.cookie) return null;
      var parts = String(__ctx.cookie).split(';');
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i].trim();
        var index = part.indexOf('=');
        if (index <= 0) continue;
        if (part.substring(0, index).trim() === String(name)) {
          return part.substring(index + 1).trim();
        }
      }
      return null;
    }
  };
''';
  }

  String _cacheBinding() {
    return '''
  var cache = {
    get: function(name) {
      __ctx.variables.__cache = __ctx.variables.__cache || {};
      return __ctx.variables.__cache[String(name)];
    },
    put: function(name, value) {
      __ctx.variables.__cache = __ctx.variables.__cache || {};
      __ctx.variables.__cache[String(name)] = value;
      return value;
    }
  };
''';
  }

  Object? _sourceToJson(Object? source) {
    if (source == null) return null;
    if (source is String || source is num || source is bool || source is Map) {
      return source;
    }
    if (source is Iterable) return source.toList(growable: false);
    if (source is SourceRule) {
      return {
        'id': source.id,
        'name': source.name,
        'url': source.url,
        'headers': source.headers,
      };
    }
    return source.toString();
  }
}
