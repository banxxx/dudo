import '../../../../core/rule_engine/legado/js/legado_js_engine.dart';
import '../../../../core/rule_engine/models/source_rule.dart';
import '../../../../core/rule_engine/rule_engine.dart';
import '../../domain/source_import_format.dart';
import '../../domain/source_import_models.dart';
import '../source_url_normalizer.dart';
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

    // Validation only parses rule strings; the simple JS engine avoids
    // touching the QuickJS plugin during import.
    final validator = RuleEngine.create(jsEngine: const SimpleLegadoJsEngine());

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
      SourceRule rule;
      try {
        rule = SourceRule.fromJson(rawJson);
      } catch (_) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '书源规则字段类型不兼容',
            url: _stringValue(rawJson['bookSourceUrl'] ?? rawJson['url']),
            name: _stringValue(rawJson['bookSourceName'] ?? rawJson['name']),
          ),
        );
        continue;
      }

      final name = rule.name.trim();
      final rawUrl = rule.url.trim();
      if (name.isEmpty) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '缺少 bookSourceName',
            url: rawUrl.isEmpty ? null : rawUrl,
          ),
        );
        continue;
      }

      final normalizedUrl = normalizeSourceUrl(rawUrl);
      if (normalizedUrl == null) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '书源地址无效',
            url: rawUrl.isEmpty ? null : rawUrl,
            name: name,
          ),
        );
        continue;
      }

      // Persist the normalized identity fields so the runtime never sees
      // whitespace / scheme-less URLs that only the DB row was cleaning up.
      rawJson['bookSourceUrl'] = normalizedUrl;
      rawJson['bookSourceName'] = name;
      final group = rule.group;
      if (group != null) rawJson['bookSourceGroup'] = group;
      final comment = rule.comment;
      if (comment != null) rawJson['bookSourceComment'] = comment;

      try {
        rule = SourceRule.fromJson(rawJson);
      } catch (_) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: '书源规则字段类型不兼容',
            url: normalizedUrl,
            name: name,
          ),
        );
        continue;
      }

      final report = validator.validate(rule);
      final fatal = report.diagnostics.where(
        (diagnostic) =>
            diagnostic.severity.isError &&
            // A source without searchUrl may still be used for detail-page
            // URL import; keep it and report it as searchless instead.
            diagnostic.code != 'search-url-missing',
      );
      if (fatal.isNotEmpty) {
        invalidItems.add(
          SourceImportInvalidItem(
            index: i,
            reason: fatal.first.message,
            url: normalizedUrl,
            name: name,
          ),
        );
        continue;
      }

      if (byUrl.containsKey(normalizedUrl)) {
        duplicateInFileCount += 1;
      }

      byUrl[normalizedUrl] = SourceImportCandidate(
        id: normalizedUrl,
        name: name,
        url: normalizedUrl,
        groupName: rule.group,
        comment: rule.comment,
        sortOrder: _intValue(rawJson['customOrder']),
        enabled: rule.enabled,
        sourceType: rule.sourceType,
        remoteUpdatedAt: rule.lastUpdateTime,
        hasSearch: rule.hasSearchUrl,
        hasExplore: rule.explore?.exploreUrl?.trim().isNotEmpty ?? false,
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
