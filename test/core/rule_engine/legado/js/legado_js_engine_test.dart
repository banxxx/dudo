import 'package:dudo/core/rule_engine/legado/js/legado_js_engine.dart';
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
      expect(engine.eval('cookie.getKey("sid")', context: context), 'abc');
      expect(engine.eval('cookie.getKey("missing")', context: context), isNull);
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
  });
}
