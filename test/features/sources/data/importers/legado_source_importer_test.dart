import 'package:flutter_test/flutter_test.dart';
import 'package:dudo/features/sources/data/importers/legado_source_importer.dart';

void main() {
  group('LegadoSourceImporter', () {
    const importer = LegadoSourceImporter();

    test('parses sources with Legado string headers', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '测试源',
          'bookSourceUrl': 'https://example.com',
          'customOrder': -20,
          'header': "{'User-Agent': 'Mozilla/5.0'}",
        },
      ]);

      expect(result.totalInputCount, 1);
      expect(result.invalidCount, 0);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '测试源');
      expect(result.candidates.single.url, 'https://example.com');
      expect(result.candidates.single.sortOrder, -20);
    });

    test('keeps valid sources when one item has an invalid url', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '有效源',
          'bookSourceUrl': 'https://valid.example.com',
        },
        {
          'bookSourceName': '坏地址源',
          'bookSourceUrl': 'not a url',
        },
      ]);

      expect(result.totalInputCount, 2);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '有效源');
      expect(result.invalidCount, 1);
      expect(result.invalidItems.single.url, 'not a url');
      expect(result.invalidItems.single.reason, '书源地址无效');
    });

    test('normalizes source urls and persists the normalized identity',
        () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '空格源',
          'bookSourceUrl': '  https://space.example.com  ',
        },
        {
          'bookSourceName': '裸域名源',
          'bookSourceUrl': 'www.bare.example.com/path',
        },
        {
          'bookSourceName': '缺斜杠源',
          'bookSourceUrl': 'http:slash.example.com',
        },
        {
          'bookSourceName': '带选项源',
          'bookSourceUrl': 'https://opt.example.com,{"method":"GET"}',
        },
        {
          'bookSourceName': '空格选项源',
          'bookSourceUrl': 'https://opt-space.example.com, {"method":"GET"}',
        },
      ]);

      expect(result.invalidCount, 0);
      final urls = result.candidates.map((candidate) => candidate.url).toSet();
      expect(urls, {
        'https://space.example.com',
        'https://www.bare.example.com/path',
        'http://slash.example.com',
        'https://opt.example.com',
        'https://opt-space.example.com',
      });
      for (final candidate in result.candidates) {
        expect(candidate.rawJson['bookSourceUrl'], candidate.url);
      }
    });

    test('parses enabled, sourceType and lastUpdateTime', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '禁用音频源',
          'bookSourceUrl': 'https://audio.example.com',
          'enabled': false,
          'bookSourceType': 1,
          'lastUpdateTime': 1700000000000,
          'searchUrl': 'https://audio.example.com/search',
          'ruleSearch': {'bookList': r'$.items'},
          'exploreUrl': 'https://audio.example.com/explore',
          'ruleExplore': {'bookList': r'$.items'},
        },
      ]);

      expect(result.candidates, hasLength(1));
      final candidate = result.candidates.single;
      expect(candidate.enabled, isFalse);
      expect(candidate.sourceType, 1);
      expect(candidate.remoteUpdatedAt, 1700000000000);
      expect(candidate.hasSearch, isTrue);
      expect(candidate.hasExplore, isTrue);
    });

    test('coerces numeric rule fields like Legado Gson', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '数字规则源',
          'bookSourceUrl': 'https://numeric.example.com',
          'ruleBookInfo': {'init': 123, 'name': 456},
        },
      ]);

      expect(result.invalidCount, 0);
      expect(result.candidates.single.rawJson['ruleBookInfo'], {
        'init': 123,
        'name': 456,
      });
    });

    test('keeps sources without searchUrl but reports them as searchless',
        () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '详情源',
          'bookSourceUrl': 'https://detail.example.com',
          'ruleBookInfo': {'name': r'$.name'},
        },
      ]);

      expect(result.invalidCount, 0);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.hasSearch, isFalse);
    });

    test('deduplicates sources by url and keeps the last one', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '旧源',
          'bookSourceUrl': 'https://same.example.com',
        },
        {
          'bookSourceName': '新源',
          'bookSourceUrl': ' https://same.example.com ',
        },
      ]);

      expect(result.duplicateInFileCount, 1);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '新源');
    });
  });
}
