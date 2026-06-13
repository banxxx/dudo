import 'package:flutter_test/flutter_test.dart';
import 'package:dudo/core/rule_engine/models/source_rule.dart';

void main() {
  group('SourceRule search rule parsing', () {
    test('accepts map ruleSearch', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'searchUrl': 'https://example.com/search?q={{key}}',
        'ruleSearch': {
          'bookList': '.book',
          'name': '.name@text',
        },
      });

      expect(rule.search?.searchUrl, 'https://example.com/search?q={{key}}');
      expect(rule.search?.bookList, '.book');
      expect(rule.search?.name, '.name@text');
    });

    test('accepts stringified JSON ruleSearch', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'searchUrl': 'https://example.com/search?q={{key}}',
        'ruleSearch': '{"bookList":".book","name":".name@text"}',
      });

      expect(rule.search?.searchUrl, 'https://example.com/search?q={{key}}');
      expect(rule.search?.bookList, '.book');
      expect(rule.search?.name, '.name@text');
    });

    test('ignores invalid string ruleSearch without throwing', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'searchUrl': 'https://example.com/search?q={{key}}',
        'ruleSearch': 'not json',
      });

      expect(rule.search, isNull);
    });
  });

  group('SourceRule nested rule block parsing', () {
    test('accepts stringified JSON ruleBookInfo', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'ruleBookInfo': r'{"name":"$.name","author":"$.author"}',
      });

      expect(rule.bookInfo?.name, r'$.name');
      expect(rule.bookInfo?.author, r'$.author');
    });

    test('accepts stringified JSON ruleToc', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'ruleToc': r'{"chapterList":"$.chapters[*]","chapterName":"$.name"}',
      });

      expect(rule.toc?.chapterList, r'$.chapters[*]');
      expect(rule.toc?.chapterName, r'$.name');
    });

    test('accepts stringified JSON ruleContent', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'ruleContent': r'{"content":"$.content","title":"$.title"}',
      });

      expect(rule.content?.content, r'$.content');
      expect(rule.content?.title, r'$.title');
    });

    test('accepts stringified JSON ruleExplore', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'exploreUrl': 'https://example.com/explore',
        'ruleExplore': r'{"bookList":"$.books[*]","name":"$.name"}',
      });

      expect(rule.explore?.exploreUrl, 'https://example.com/explore');
      expect(rule.explore?.bookList, r'$.books[*]');
      expect(rule.explore?.name, r'$.name');
    });
  });

  group('SourceRule header parsing', () {
    test('accepts map headers', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header': {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://example.com',
          'Null-Value': null,
        },
      });

      expect(rule.headers, {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://example.com',
      });
    });

    test('accepts standard JSON string headers', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header':
            '{"User-Agent":"Mozilla/5.0","Referer":"https://example.com"}',
      });

      expect(rule.headers['User-Agent'], 'Mozilla/5.0');
      expect(rule.headers['Referer'], 'https://example.com');
    });

    test('accepts Legado single-quoted string headers', () {
      final rule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header':
            "{'User-Agent': 'Mozilla/5.0', 'Referer': 'https://example.com'}",
      });

      expect(rule.headers['User-Agent'], 'Mozilla/5.0');
      expect(rule.headers['Referer'], 'https://example.com');
    });

    test('ignores invalid header shapes without throwing', () {
      final invalidStringRule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header': 'not a header map',
      });
      final listRule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header': ['User-Agent', 'Mozilla/5.0'],
      });
      final nullRule = SourceRule.fromJson({
        'bookSourceName': '测试源',
        'bookSourceUrl': 'https://example.com',
        'header': null,
      });

      expect(invalidStringRule.headers, isEmpty);
      expect(listRule.headers, isEmpty);
      expect(nullRule.headers, isEmpty);
    });
  });
}
