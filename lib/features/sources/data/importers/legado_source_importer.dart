import '../../../../core/rule_engine/models/source_rule.dart';
import '../../domain/source_import_format.dart';
import '../../domain/source_import_models.dart';
import 'source_importer.dart';

class LegadoSourceImporter extends SourceImporter {
  const LegadoSourceImporter();

  @override
  SourceImportFormat get format => SourceImportFormat.legado;

  @override
  bool canHandleJson(Object? json) {
    if (json is List) {
      return json.any(_looksLikeLegadoSource);
    }
    return _looksLikeLegadoSource(json);
  }

  @override
  Future<SourceImportParseResult> parseJson(Object? json) async {
    final entries = switch (json) {
      final List list => list,
      final Map map => [map],
      _ => const <Object?>[],
    };

    final byUrl = <String, SourceImportCandidate>{};
    final invalidItems = <SourceImportInvalidItem>[];
    var duplicateInFileCount = 0;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry is! Map) {
        invalidItems.add(
          SourceImportInvalidItem(index: i, reason: '第 ${i + 1} 项不是书源对象'),
        );
        continue;
      }

      final rawJson = entry.cast<String, dynamic>();
      final url = _stringValue(rawJson['bookSourceUrl'] ?? rawJson['url']);
      final name = _stringValue(rawJson['bookSourceName'] ?? rawJson['name']);

      if (url == null || url.isEmpty) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '缺少 bookSourceUrl',
            name: name,
          ),
        );
        continue;
      }
      if (name == null || name.isEmpty) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '缺少 bookSourceName',
            url: url,
          ),
        );
        continue;
      }

      final SourceRule rule;
      try {
        rule = SourceRule.fromJson(rawJson);
      } catch (_) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '书源规则字段类型不兼容',
            url: url,
            name: name,
          ),
        );
        continue;
      }
      if (rule.url.trim().isEmpty || rule.name.trim().isEmpty) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '书源基础字段无法解析',
            url: url,
            name: name,
          ),
        );
        continue;
      }

      if (byUrl.containsKey(url)) {
        duplicateInFileCount += 1;
      }

      byUrl[url] = SourceImportCandidate(
        id: url,
        name: name,
        url: url,
        groupName: _stringValue(rawJson['bookSourceGroup']),
        comment: _stringValue(rawJson['bookSourceComment']),
        sortOrder: _intValue(rawJson['customOrder']),
        rawJson: rawJson,
      );
    }

    return SourceImportParseResult(
      format: SourceImportFormat.legado,
      candidates: byUrl.values.toList(growable: false),
      invalidItems: invalidItems,
      duplicateInFileCount: duplicateInFileCount,
      totalInputCount: entries.length,
    );
  }

  bool _looksLikeLegadoSource(Object? json) {
    if (json is! Map) return false;
    return json.containsKey('bookSourceUrl') ||
        json.containsKey('bookSourceName') ||
        json.containsKey('ruleSearch') ||
        json.containsKey('ruleBookInfo') ||
        json.containsKey('ruleToc') ||
        json.containsKey('ruleContent');
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}
