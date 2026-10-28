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
  var source = __ctx.source || {};
  var book = __ctx.book || {};
  var chapter = __ctx.chapter;
  if (typeof source.getVariable !== "function") {
    source.getVariable = function() {
      return __ctx.variables["__source_variable"] || "";
    };
    source.putVariable = function(value) {
      __ctx.variables["__source_variable"] = value;
      return value;
    };
  }
  if (typeof source.getKey !== "function") {
    source.getKey = function() { return source.id || source.url || ""; };
    source.getName = function() { return source.name || ""; };
    source.getUrl = function() { return source.url || ""; };
  }
  if (typeof book.getVariable !== "function") {
    book.getVariable = function(name) {
      var variables = __bookVariables(book);
      var value = variables[String(name)];
      return value == null ? "" : String(value);
    };
    book.putVariable = function(name, value) {
      var variables = __bookVariables(book);
      variables[String(name)] = value;
      book.variable = JSON.stringify(variables);
      return value;
    };
    book.getName = function() { return book.name || ""; };
    book.getAuthor = function() { return book.author || ""; };
    book.getUrl = function() { return book.bookUrl || book.url || ""; };
    book.getOrigin = function() { return book.origin || ""; };
    book.getOriginName = function() { return book.originName || ""; };
  }
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
    var current = __parseMaybeJson(root);
    if (path.indexOf("$..") === 0) {
      var recursiveParts = path.substring(3).split(".");
      var found = __findKey(current, recursiveParts[0]);
      for (var r = 1; r < recursiveParts.length; r++) {
        if (found == null) return null;
        found = __readPath(found, "$." + recursiveParts[r]);
      }
      return found == null ? null : found;
    }
    if (path.indexOf("$.") !== 0) return null;
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
  function __findKey(value, key) {
    if (value == null) return null;
    if (Array.isArray(value)) {
      for (var i = 0; i < value.length; i++) {
        var found = __findKey(value[i], key);
        if (found != null) return found;
      }
      return null;
    }
    if (typeof value === "object") {
      if (Object.prototype.hasOwnProperty.call(value, key)) return value[key];
      for (var name in value) {
        if (!Object.prototype.hasOwnProperty.call(value, name)) continue;
        var nested = __findKey(value[name], key);
        if (nested != null) return nested;
      }
    }
    return null;
  }
  function __bookVariables(book) {
    var variables = book.variable;
    if (typeof variables === "string") {
      try { variables = JSON.parse(variables); } catch (e) { variables = {}; }
    }
    if (variables == null || typeof variables !== "object") variables = {};
    return variables;
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
    get: function(name) {
      var value = __ctx.variables[String(name)];
      return value == null ? "" : value;
    },
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
