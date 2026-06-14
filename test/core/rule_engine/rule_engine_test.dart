import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleEngine.validate', () {
    test('keeps legacy issues for blocking validation errors', () {
      final report = RuleEngine.create().validate(
        const SourceRule(
          id: 'empty',
          name: 'Empty',
          url: '',
        ),
      );

      expect(report.ok, isFalse);
      expect(report.issues, contains('source url is empty'));
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(['source-url-empty', 'search-url-missing']),
      );
      expect(
        report.diagnostics
            .where((diagnostic) =>
                diagnostic.severity == SourceCompatibilitySeverity.error)
            .map((diagnostic) => diagnostic.path),
        containsAll(['bookSourceUrl', 'searchUrl']),
      );
    });

    test('reports source compatibility diagnostics beyond structural parsing',
        () {
      final report = RuleEngine.create().validate(
        const SourceRule(
          id: 'source',
          name: 'Compatibility Source',
          url: 'source.example.com',
          search: SearchRule(
            searchUrl:
                'https://source.example/search?q={{key}},{"webView":true,"bodyJs":"x"}',
            bookList: '@XPath://div[@class="book"]',
            name: '<js>result</js>',
          ),
        ),
      );

      expect(report.ok, isTrue);
      expect(report.issues, isEmpty);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          'source-url-not-absolute',
          'url-body-js-unsupported',
          'url-web-view-unsupported',
          'search-book-url-missing',
          'book-info-missing',
          'toc-missing',
          'content-missing',
        ]),
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('rule-xpath-unsupported')),
      );
    });
  });
}
