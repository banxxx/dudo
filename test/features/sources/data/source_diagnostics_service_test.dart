import 'dart:convert';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/sources/data/source_diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SourceDiagnosticsService();

  test('reports a structurally valid source as healthy', () async {
    final report = await service.diagnose([
      _source(id: 'valid', name: '正常源', rules: _validRules()),
    ]);

    final entry = report.entries.single;
    expect(entry.isBroken, isFalse);
    expect(entry.hasIssues, isFalse);
    expect(entry.summaryMessage, '规则结构正常');
    expect(report.healthyCount, 1);
    expect(report.brokenCount, 0);
    expect(report.attentionCount, 0);
  });

  test('treats unparsable rules as broken', () async {
    final report = await service.diagnose([
      _source(id: 'broken-json', name: '坏 JSON', rules: 'not-json'),
    ]);

    final entry = report.entries.single;
    expect(entry.isBroken, isTrue);
    expect(entry.parseError, '书源规则解析失败');
    expect(entry.summaryMessage, '书源规则解析失败');
    expect(report.brokenCount, 1);
  });

  test('treats a non-object rules payload as broken', () async {
    final report = await service.diagnose([
      _source(id: 'array', name: '数组规则', rules: '[]'),
    ]);

    final entry = report.entries.single;
    expect(entry.isBroken, isTrue);
    expect(entry.parseError, '书源规则不是 JSON 对象');
  });

  test('keeps searchless sources usable but flags them', () async {
    final report = await service.diagnose([
      _source(
        id: 'searchless',
        name: '无搜索源',
        rules: {
          'bookSourceName': '无搜索源',
          'bookSourceUrl': 'https://searchless.example.com',
          'ruleSearch': {
            'bookList': r'$.items',
            'name': r'$.name',
            'bookUrl': r'$.url',
          },
          'ruleBookInfo': {'name': r'$.name'},
          'ruleToc': {'chapterList': r'$.chapters'},
          'ruleContent': {'content': r'$.content'},
        },
      ),
    ]);

    final entry = report.entries.single;
    expect(entry.isBroken, isFalse);
    expect(entry.hasIssues, isTrue);
    expect(entry.errorCount, 1);
    expect(
      entry.diagnostics.map((diagnostic) => diagnostic.code),
      contains('search-url-missing'),
    );
    expect(report.attentionCount, 1);
  });

  test('flags non-text sources as informational', () async {
    final report = await service.diagnose([
      _source(
        id: 'audio',
        name: '音频源',
        rules: {
          ..._validRules(),
          'bookSourceType': 1,
        },
      ),
    ]);

    final entry = report.entries.single;
    expect(entry.isBroken, isFalse);
    expect(entry.infoCount, 1);
    expect(entry.summaryMessage, '非文本书源，当前版本不会用于搜索');
    expect(report.attentionCount, 1);
  });

  test('sorts broken sources before sources with only warnings', () async {
    final report = await service.diagnose([
      _source(id: 'healthy', name: '正常源', rules: _validRules()),
      _source(
        id: 'searchless',
        name: '无搜索源',
        rules: {
          ..._validRules(),
          'searchUrl': null,
        },
      ),
      _source(id: 'broken', name: '坏源', rules: 'not-json'),
    ]);

    expect(
      report.sortedEntries.map((entry) => entry.source.id),
      ['broken', 'searchless', 'healthy'],
    );
  });
}

Map<String, Object?> _validRules() {
  return {
    'bookSourceName': '正常源',
    'bookSourceUrl': 'https://valid.example.com',
    'searchUrl': 'https://valid.example.com/search?q={{key}}',
    'ruleSearch': {
      'bookList': r'$.items',
      'name': r'$.name',
      'bookUrl': r'$.url',
    },
    'ruleBookInfo': {'name': r'$.name'},
    'ruleToc': {'chapterList': r'$.chapters'},
    'ruleContent': {'content': r'$.content'},
  };
}

Source _source({
  required String id,
  required String name,
  required Object rules,
}) {
  final now = DateTime(2026, 6, 13);
  return Source(
    id: id,
    name: name,
    url: 'https://$id.example.com',
    enabled: true,
    sourceType: 0,
    rulesJson: rules is String ? rules : jsonEncode(rules),
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}
