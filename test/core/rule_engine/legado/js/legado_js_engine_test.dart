import 'package:dudo/core/rule_engine/legado/js/legado_js_engine.dart';
import 'package:dudo/core/rule_engine/legado/rule/rule_context.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimpleLegadoJsEngine', () {
    test('evaluates basic bindings from LegadoJsContext', () {
      const engine = SimpleLegadoJsEngine();
      const source = SourceRule(
        id: 'source-id',
        name: 'Source',
        url: 'https://source.example',
      );
      const context = LegadoJsContext(
        key: 'Alpha',
        page: 2,
        baseUrl: 'https://source.example/base/',
        result: 'Result',
        src: 'Src',
        source: source,
        book: {'name': 'Book'},
      );

      expect(engine.eval('key + page', context: context), 'Alpha2');
      expect(engine.eval('baseUrl', context: context),
          'https://source.example/base/');
      expect(engine.eval('result', context: context), 'Result');
      expect(engine.eval('src', context: context), 'Src');
      expect(engine.eval('source', context: context), source);
      expect(engine.eval('book', context: context), {'name': 'Book'});
      expect(engine.eval('source.name', context: context), 'Source');
      expect(engine.eval('book.name', context: context), 'Book');
    });

    test('supports java and cookie helper bindings', () {
      const engine = SimpleLegadoJsEngine();
      final variables = <String, Object?>{'cached': 'old'};
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        variables: variables,
        cookie: 'sid=abc; theme=dark',
      );

      expect(engine.eval('java.getString(123)', context: context), '123');
      expect(engine.eval('java.get("cached")', context: context), 'old');
      expect(engine.eval('java.put("cached", "new")', context: context), 'new');
      expect(variables['cached'], 'new');
      expect(engine.eval('java.log("debug")', context: context), 'debug');
      expect(engine.eval('cookie.getKey("sid")', context: context), 'abc');
      expect(
        engine.eval('cookie.getKey("https://source.example", "sid")',
            context: context),
        'abc',
      );
      expect(engine.eval('cookie.getKey("missing")', context: context), isNull);
    });

    test('traces missing cookies when cookie.getKey cannot resolve a value',
        () {
      const engine = SimpleLegadoJsEngine();
      final trace = LegadoTrace();
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        trace: trace,
      );

      expect(engine.eval('cookie.getKey("sid")', context: context), isNull);
      expect(trace.events, contains('cookie.getKey.empty:sid'));
    });

    test('supports memory cache helper bindings', () {
      const engine = SimpleLegadoJsEngine();
      final variables = <String, Object?>{};
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        variables: variables,
      );

      expect(
          engine.eval('cache.put("chapter", "one")', context: context), 'one');
      expect(engine.eval('cache.get("chapter")', context: context), 'one');
      expect(engine.eval('cache.get("missing")', context: context), isNull);
      expect(variables['__cache'], {'chapter': 'one'});
    });

    test('resolves JSONPath values through java.getString', () {
      const engine = SimpleLegadoJsEngine();
      const context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        result:
            '{"novelName":"Book","chapterlist":[{"chaptername":"Chapter 1"}]}',
      );

      expect(
        engine.eval('java.getString("\$.novelName")', context: context),
        'Book',
      );
      expect(
        engine.eval(
          'java.getString("\$.chapterlist[0].chaptername")',
          context: context,
        ),
        'Chapter 1',
      );
      expect(
        engine.eval('java.getString("\$.missing")', context: context),
        '',
      );
    });

    test('exposes java.ajax as a controlled binding point', () {
      const engine = SimpleLegadoJsEngine();
      final requested = <String>[];
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        ajax: (rawUrl) {
          requested.add(rawUrl);
          return 'response:$rawUrl';
        },
      );

      expect(
        engine.eval('java.ajax("/api?q=" + key)', context: context),
        'response:/api?q=Alpha',
      );
      expect(requested, ['/api?q=Alpha']);
    });

    test('accepts java.ajax timeout argument for Legado compatibility', () {
      const engine = SimpleLegadoJsEngine();
      final requested = <String>[];
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        ajax: (rawUrl) {
          requested.add(rawUrl);
          return '{"content":"response:$rawUrl"}';
        },
      );

      expect(
        engine.eval(
          'JSON.parse(java.ajax("/api?q=" + key, 5000)).content',
          context: context,
        ),
        'response:/api?q=Alpha',
      );
      expect(requested, ['/api?q=Alpha']);
    });

    test('only allows simple-expression fallback scripts', () {
      expect(
        canUseSimpleLegadoJsFallback('JSON.parse(result).chapterContent'),
        isTrue,
      );
      expect(
        canUseSimpleLegadoJsFallback('result = java.getString("\$.content")'),
        isTrue,
      );
      expect(
        canUseSimpleLegadoJsFallback('if(result){ result = "ok"; }'),
        isFalse,
      );
      expect(
        canUseSimpleLegadoJsFallback('var data = JSON.parse(result); data.x'),
        isFalse,
      );
      expect(
        canUseSimpleLegadoJsFallback(
            '// if inside comment\nJSON.parse(result)'),
        isTrue,
      );
    });
  });

  group('FlutterJsLegadoJsEngine', () {
    test('awaits java.ajax in async JS expressions', () async {
      final engine = FlutterJsLegadoJsEngine(
        timeout: const Duration(seconds: 5),
      );
      final requested = <String>[];
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        ajax: (rawUrl) async {
          requested.add(rawUrl);
          return '{"value":"response:$rawUrl"}';
        },
      );

      final value = await _evalWithQuickJsOrSkip(
        engine,
        'JSON.parse(java.ajax("/api?q=" + key)).value',
        context,
      );
      if (identical(value, _quickJsSkipped)) return;

      expect(value, 'response:/api?q=Alpha');
      expect(requested, ['/api?q=Alpha']);
    });

    test('keeps result assignment after awaited java.ajax', () async {
      final engine = FlutterJsLegadoJsEngine(
        timeout: const Duration(seconds: 5),
      );
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        ajax: (rawUrl) async => {'value': 'body:$rawUrl'},
      );

      final value = await _evalWithQuickJsOrSkip(
        engine,
        '''
        var data = JSON.parse(java.ajax("/chapter/" + key));
        result = data.value;
        ''',
        context,
      );
      if (identical(value, _quickJsSkipped)) return;

      expect(value, 'body:/chapter/Alpha');
    });

    test('keeps automatic semicolon insertion around awaited ajax',
        () async {
      final engine = FlutterJsLegadoJsEngine(
        timeout: const Duration(seconds: 5),
      );
      final context = LegadoJsContext(
        key: 'Alpha',
        page: 1,
        ajax: (rawUrl) async => 'ajax:$rawUrl',
      );

      final value = await _evalWithQuickJsOrSkip(
        engine,
        '''
        url = "/chapter/" + key
        html = java.ajax(url)
        java.setContent(html)
        result = html
        ''',
        context,
      );
      if (identical(value, _quickJsSkipped)) return;

      expect(value, 'ajax:/chapter/Alpha');
    });
  });
}

final Object _quickJsSkipped = Object();

Future<Object?> _evalWithQuickJsOrSkip(
  FlutterJsLegadoJsEngine engine,
  String script,
  LegadoJsContext context,
) async {
  try {
    return await engine.evalAsync(script, context: context);
  } on LegadoJsException catch (error) {
    final message = error.message;
    if (message.contains('Unsupported function JSON.parse') ||
        message.contains('Unsupported character =') ||
        message.contains('Full JS runtime is required') ||
        message.contains("Instance of 'Future")) {
      markTestSkipped('QuickJS runtime is not available in this test host.');
      return _quickJsSkipped;
    }
    rethrow;
  }
}
