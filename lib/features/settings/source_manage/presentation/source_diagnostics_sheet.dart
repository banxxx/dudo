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
        backgroundColor: DudoColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '删除失效书源？',
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '将删除 ${broken.length} 个无法使用的书源，此操作不可撤销。',
          style: DudoTextStyles.sans(
            color: DudoColors.secondaryDark,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '删除',
              style: DudoTextStyles.sans(
                color: _dangerText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3325251F),
            offset: Offset(0, -18),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: DudoColors.outline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
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
                      const SizedBox(height: 4),
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
                const SizedBox(width: 8),
                _SheetCloseButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 14),
            Text(
              '正在检查书源规则…',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12.5,
              ),
            ),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _dangerFill,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  LucideIcons.circleAlert,
                  color: _dangerText,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _SheetActionButton(
                label: '重新检查',
                icon: LucideIcons.refreshCw,
                background: DudoColors.surfaceLow,
                foreground: DudoColors.textPrimary,
                onTap: _diagnose,
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DudoColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: '书源',
                    value: '${report.totalCount}',
                    color: DudoColors.primary,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatColumn(
                    label: '失效',
                    value: '${report.brokenCount}',
                    color: report.brokenCount > 0
                        ? _dangerText
                        : DudoColors.primary,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatColumn(
                    label: '需注意',
                    value: '${report.attentionCount}',
                    color: DudoColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(
                  '问题明细',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${issues.length} 项',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: issues.isEmpty
              ? _EmptyDiagnostics(healthyCount: report.healthyCount)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _DiagnosticCard(entry: issues[index]),
                ),
        ),
        if (report.brokenCount > 0)
          _DeleteBrokenFooter(
            brokenCount: report.brokenCount,
            deleting: _deleting,
            onTap: _deleteBrokenSources,
          ),
      ],
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Icon(
            LucideIcons.x,
            color: DudoColors.secondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: DudoColors.outlineVariant,
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: DudoTextStyles.numeric(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeleteBrokenFooter extends StatelessWidget {
  const _DeleteBrokenFooter({
    required this.brokenCount,
    required this.deleting,
    required this.onTap,
  });

  final int brokenCount;
  final bool deleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        border: Border(top: BorderSide(color: DudoColors.outlineVariant)),
      ),
      child: _SheetActionButton(
        label: '删除 $brokenCount 个失效书源',
        icon: LucideIcons.trash2,
        background: _dangerText,
        foreground: DudoColors.surfaceHigh,
        loading: deleting,
        onTap: onTap,
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else
                Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
              decoration:  BoxDecoration(
                color: DudoColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child:  Icon(
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
    final icon = entry.isBroken
        ? LucideIcons.circleAlert
        : searchlessOnly || entry.warningCount > 0
            ? LucideIcons.triangleAlert
            : LucideIcons.info;

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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.source.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: DudoTextStyles.sans(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
