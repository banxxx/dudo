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
          'header': "{'User-Agent': 'Mozilla/5.0'}",
        },
      ]);

      expect(result.totalInputCount, 1);
      expect(result.invalidCount, 0);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '测试源');
      expect(result.candidates.single.url, 'https://example.com');
    });

    test('keeps valid sources when one item has incompatible rule fields',
        () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '有效源',
          'bookSourceUrl': 'https://valid.example.com',
        },
        {
          'bookSourceName': '坏字段源',
          'bookSourceUrl': 'https://bad.example.com',
          'ruleBookInfo': {'init': 123},
        },
      ]);

      expect(result.totalInputCount, 2);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '有效源');
      expect(result.invalidCount, 1);
      expect(result.invalidItems.single.url, 'https://bad.example.com');
      expect(result.invalidItems.single.reason, '书源规则字段类型不兼容');
    });

    test('deduplicates sources by url and keeps the last one', () async {
      final result = await importer.parseJson([
        {
          'bookSourceName': '旧源',
          'bookSourceUrl': 'https://same.example.com',
        },
        {
          'bookSourceName': '新源',
          'bookSourceUrl': 'https://same.example.com',
        },
      ]);

      expect(result.duplicateInFileCount, 1);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.name, '新源');
    });
  });
}
