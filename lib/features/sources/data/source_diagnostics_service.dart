import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/rule_engine/legado/js/legado_js_engine.dart';
import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../domain/source_diagnostics.dart';

/// Validates stored source rules without touching the network.
///
/// The validation engine only parses rule strings, so it is safe to run on
/// the UI isolate. Work is yielded every [_yieldEvery] sources to keep large
/// source packs from blocking a frame.
class SourceDiagnosticsService {
  SourceDiagnosticsService({RuleEngine? engine})
      : _engine =
            engine ?? RuleEngine.create(jsEngine: const SimpleLegadoJsEngine());

  static const _yieldEvery = 100;

  final RuleEngine _engine;

  Future<SourceDiagnosticsReport> diagnose(Iterable<Source> sources) async {
    final entries = <SourceDiagnosticEntry>[];
    var index = 0;
    for (final source in sources) {
      entries.add(_diagnoseOne(source));
      index += 1;
      if (index % _yieldEvery == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return SourceDiagnosticsReport(entries: entries);
  }

  SourceDiagnosticEntry _diagnoseOne(Source source) {
    try {
      final decoded = jsonDecode(source.rulesJson);
      if (decoded is! Map) {
        return SourceDiagnosticEntry(
          source: source,
          parseError: '书源规则不是 JSON 对象',
        );
      }
      final rule = SourceRule.fromJson(decoded.cast<String, dynamic>());
      final report = _engine.validate(rule);
      return SourceDiagnosticEntry(
        source: source,
        rule: rule,
        diagnostics: report.diagnostics,
      );
    } catch (_) {
      return SourceDiagnosticEntry(
        source: source,
        parseError: '书源规则解析失败',
      );
    }
  }
}
