import 'package:dudo/core/rule_engine/models/rule_chain.dart';
import 'package:dudo/core/rule_engine/parsers/jsonpath_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonPathParser', () {
    test('extracts elements and fields from JSON strings', () {
      const json = '''
        {
          "books": [
            {"name": "三体", "author": "刘慈欣"},
            {"name": "球状闪电", "author": "刘慈欣"}
          ]
        }
      ''';
      final parser = JsonPathParser();

      final books = parser.parseElements(json, RuleChain.parse(r'$.books[*]'));

      expect(books, hasLength(2));
      expect(parser.parseString(books.first, RuleChain.parse(r'$.name')), '三体');
      expect(
          parser.parseString(books.first, RuleChain.parse(r'$.author')), '刘慈欣');
    });

    test('treats bare field names as JSONPath fields for JSON objects', () {
      final parser = JsonPathParser();
      final book = {'title': '三体', 'author': '刘慈欣'};

      expect(parser.parseString(book, RuleChain.parse('title')), '三体');
      expect(parser.parseString(book, RuleChain.parse('author')), '刘慈欣');
    });

    test('stringifies scalar matches', () {
      final parser = JsonPathParser();

      expect(
        parser.parseList('{"count":2,"ok":true}', RuleChain.parse(r'$.count')),
        ['2'],
      );
      expect(
        parser.parseList('{"count":2,"ok":true}', RuleChain.parse(r'$.ok')),
        ['true'],
      );
    });
  });
}
