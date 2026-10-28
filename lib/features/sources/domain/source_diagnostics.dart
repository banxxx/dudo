import '../../../core/database/app_database.dart';
import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';

/// A single source plus the result of parsing and validating its rules.
class SourceDiagnosticEntry {
  const SourceDiagnosticEntry({
    required this.source,
    this.rule,
    this.diagnostics = const [],
    this.parseError,
  });

  final Source source;
  final SourceRule? rule;
  final List<SourceCompatibilityDiagnostic> diagnostics;

  /// Set when `rulesJson` cannot be parsed into a [SourceRule].
  final String? parseError;

  /// A source that cannot be used at all. Missing `searchUrl` is intentionally
  /// excluded: such a source may still be opened from a book URL.
  bool get isBroken =>
      parseError != null ||
      diagnostics.any(
        (diagnostic) =>
            diagnostic.severity.isError &&
            diagnostic.code != 'search-url-missing',
      );

  bool get hasIssues => parseError != null || diagnostics.isNotEmpty;

  int get errorCount =>
      (parseError == null ? 0 : 1) +
      diagnostics.where((diagnostic) => diagnostic.severity.isError).length;

  int get warningCount => diagnostics
      .where((diagnostic) =>
          diagnostic.severity == SourceCompatibilitySeverity.warning)
      .length;

  int get infoCount => diagnostics
      .where((diagnostic) =>
          diagnostic.severity == SourceCompatibilitySeverity.info)
      .length;

  /// Localized, user-facing message for the first problem.
  String get summaryMessage {
    if (parseError != null) return parseError!;
    if (diagnostics.isEmpty) return '规则结构正常';
    return sourceDiagnosticMessage(diagnostics.first);
  }
}

class SourceDiagnosticsReport {
  const SourceDiagnosticsReport({required this.entries});

  final List<SourceDiagnosticEntry> entries;

  int get totalCount => entries.length;

  int get brokenCount => entries.where((entry) => entry.isBroken).length;

  /// Sources that are usable but have warnings/info worth showing.
  int get attentionCount =>
      entries.where((entry) => !entry.isBroken && entry.hasIssues).length;

  int get healthyCount => totalCount - brokenCount - attentionCount;

  List<SourceDiagnosticEntry> get sortedEntries {
    final sorted = [...entries]..sort((a, b) {
        if (a.isBroken != b.isBroken) return a.isBroken ? -1 : 1;
        if (a.hasIssues != b.hasIssues) return a.hasIssues ? -1 : 1;
        return a.source.name.compareTo(b.source.name);
      });
    return List.unmodifiable(sorted);
  }
}

/// Maps validation diagnostics to short Chinese labels for the UI.
String sourceDiagnosticMessage(SourceCompatibilityDiagnostic diagnostic) {
  return switch (diagnostic.code) {
    'source-url-empty' => '书源地址为空',
    'source-url-invalid' => '书源地址不是有效的 URL',
    'source-url-invalid-scheme' => '书源地址必须使用 http/https',
    'source-url-not-absolute' => '书源地址不是绝对地址，相对规则可能无法解析',
    'source-type-not-text' => '非文本书源，当前版本不会用于搜索',
    'search-url-missing' => '缺少搜索地址，无法参与搜索',
    'search-book-list-missing' => '搜索规则缺少书籍列表规则',
    'search-name-missing' => '搜索规则缺少书名规则',
    'search-book-url-missing' => '搜索规则缺少书籍地址规则',
    'book-info-missing' => '缺少详情规则，无法加载书籍信息',
    'toc-missing' => '缺少目录规则，无法加载章节',
    'content-missing' => '缺少正文规则，无法加载正文',
    'url-web-js-unsupported' => '该源使用 WebJs，当前版本不支持',
    'url-web-view-unsupported' => '该源使用 WebView 请求，当前版本不支持',
    'rule-web-js-unsupported' => '规则包含 WebJs，当前版本不支持',
    'rule-regex-partial' => '正则规则支持不完整',
    'rule-regex-capture-reference-unsupported' => '正则捕获引用暂不支持',
    _ => diagnostic.message,
  };
}
