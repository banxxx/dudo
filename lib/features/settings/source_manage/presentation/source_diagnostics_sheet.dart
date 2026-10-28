import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/rule_engine/rule_engine.dart';
import '../../../../shared/messages/app_message.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../sources/application/source_providers.dart';
import '../../../sources/domain/source_diagnostics.dart';

const _diagnosticsMessageKey = 'source-diagnostics';
const _dangerFill = Color(0xFFF4DDD2);
const _dangerText = Color(0xFFA8553A);

Future<void> showSourceDiagnosticsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SourceDiagnosticsSheet(),
  );
}

class SourceDiagnosticsSheet extends ConsumerStatefulWidget {
  const SourceDiagnosticsSheet({super.key});

  @override
  ConsumerState<SourceDiagnosticsSheet> createState() =>
      _SourceDiagnosticsSheetState();
}

class _SourceDiagnosticsSheetState
    extends ConsumerState<SourceDiagnosticsSheet> {
  SourceDiagnosticsReport? _report;
  String? _error;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _diagnose(showLoading: false);
  }

  Future<void> _diagnose({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final sources = await ref.read(sourceRepositoryProvider).listSources();
      final report =
          await ref.read(sourceDiagnosticsServiceProvider).diagnose(sources);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '书源规则检查失败，请稍后重试。';
        _loading = false;
      });
    }
  }

  Future<void> _deleteBrokenSources() async {
    final broken =
        _report?.entries.where((entry) => entry.isBroken).toList() ?? const [];
    if (broken.isEmpty || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除失效书源？'),
        content: Text('将删除 ${broken.length} 个无法使用的书源，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(sourceRepositoryProvider)
          .deleteSources(broken.map((entry) => entry.source.id));
      ref.invalidate(sourcesProvider);
      if (!mounted) return;
      ref.read(appMessageServiceProvider).success(
            '已删除 ${broken.length} 个失效书源',
            title: '清理完成',
            dedupeKey: _diagnosticsMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
      await _diagnose();
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '删除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _diagnosticsMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: DudoColors.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: DudoColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '规则诊断',
                        style: DudoTextStyles.serif(
                          color: DudoColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '检查书源规则结构，不会发起网络请求',
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: DudoColors.secondary,
                  tooltip: '关闭',
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('正在检查书源规则…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                color: _dangerText,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _diagnose,
                child: const Text('重新检查'),
              ),
            ],
          ),
        ),
      );
    }

    final report = _report;
    if (report == null) return const SizedBox.shrink();
    final issues = report.sortedEntries
        .where((entry) => entry.hasIssues)
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '书源',
                  value: '${report.totalCount}',
                  color: DudoColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: '失效',
                  value: '${report.brokenCount}',
                  color:
                      report.brokenCount > 0 ? _dangerText : DudoColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: '需注意',
                  value: '${report.attentionCount}',
                  color: DudoColors.accent,
                ),
              ),
            ],
          ),
        ),
        if (report.brokenCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _deleting ? null : _deleteBrokenSources,
                style: FilledButton.styleFrom(
                  backgroundColor: _dangerFill,
                  foregroundColor: _dangerText,
                ),
                icon: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.trash2, size: 16),
                label: Text('删除 ${report.brokenCount} 个失效书源'),
              ),
            ),
          ),
        Expanded(
          child: issues.isEmpty
              ? _EmptyDiagnostics(healthyCount: report.healthyCount)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _DiagnosticCard(entry: issues[index]),
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: DudoTextStyles.numeric(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiagnostics extends StatelessWidget {
  const _EmptyDiagnostics({required this.healthyCount});

  final int healthyCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: DudoColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: DudoColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$healthyCount 个书源规则结构正常',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '没有发现需要处理的问题',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.entry});

  final SourceDiagnosticEntry entry;

  @override
  Widget build(BuildContext context) {
    // The only non-fatal error is `search-url-missing`; such a source can
    // still be opened from a book URL, so it is shown as a warning rather
    // than as a broken source.
    final searchlessOnly = !entry.isBroken && entry.errorCount > 0;
    final color = entry.isBroken
        ? _dangerText
        : searchlessOnly || entry.warningCount > 0
            ? DudoColors.accent
            : DudoColors.secondary;
    final badge = entry.isBroken
        ? '失效'
        : searchlessOnly
            ? '无搜索'
            : entry.warningCount > 0
                ? '警告'
                : '提示';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: DudoTextStyles.sans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.source.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (entry.parseError != null)
            _DiagnosticLine(
              color: _dangerText,
              message: entry.parseError!,
            )
          else ...[
            for (final diagnostic in entry.diagnostics.take(3))
              _DiagnosticLine(
                color: _severityColor(diagnostic.severity),
                message: sourceDiagnosticMessage(diagnostic),
              ),
            if (entry.diagnostics.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '另有 ${entry.diagnostics.length - 3} 条问题',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(SourceCompatibilitySeverity severity) {
    return switch (severity) {
      SourceCompatibilitySeverity.error => _dangerText,
      SourceCompatibilitySeverity.warning => DudoColors.accent,
      SourceCompatibilitySeverity.info => DudoColors.secondary,
    };
  }
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
