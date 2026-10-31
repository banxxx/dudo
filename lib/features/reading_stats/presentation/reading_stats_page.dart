import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/calendar_range_selector/calendar_range_sheet.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../../shared/widgets/dudo_page_header.dart';
import '../application/reading_stats_provider.dart';
import '../data/reading_stats_repository.dart';
import '../domain/reading_stats_models.dart';

const _dangerFill = Color(0xFFF4DDD2);
const _dangerText = Color(0xFFA8553A);

class ReadingStatsPage extends ConsumerWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(readingStatsRangeProvider);
    final summary = ref.watch(readingStatsSummaryProvider);

    Widget frame(ReadingStatsRange headerRange, Widget child) {
      return DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        children: [
          _StatsHeader(
            range: headerRange,
            onRangeTap: () => _showRangeSheet(context, ref),
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
    }

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: summary.when(
        data: (summary) => DudoPageFrame(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          children: [
            _StatsHeader(
              range: summary.range,
              onRangeTap: () => _showRangeSheet(context, ref),
            ),
            const SizedBox(height: 12),
            _StatsHero(summary: summary),
            const SizedBox(height: 10),
            _QuickMetrics(summary: summary),
            const SizedBox(height: 12),
            _RhythmChart(summary: summary),
            const SizedBox(height: 12),
            if (summary.hasData) ...[
              _ReadingDetailCard(summary: summary),
              const SizedBox(height: 12),
              _BookContributionCard(summary: summary),
            ] else
              _EmptyRhythmCard(
                onRead: () => context.go(AppRoutes.bookshelf),
              ),
          ],
        ),
        loading: () => frame(range, const _ReadingStatsLoadingCard()),
        error: (_, __) => frame(
          range,
          _ReadingStatsErrorCard(
            onRetry: () => ref.invalidate(readingStatsSummaryProvider),
          ),
        ),
      ),
    );
  }
}

class _ReadingStatsLoadingCard extends StatelessWidget {
  const _ReadingStatsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      alignment: Alignment.center,
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
            '正在整理阅读记录…',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingStatsErrorCard extends StatelessWidget {
  const _ReadingStatsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          Text(
            '阅读记录加载失败',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '统计暂时不可用，请稍后重试。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: DudoColors.primary,
              textStyle: DudoTextStyles.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.range, required this.onRangeTap});

  final ReadingStatsRange range;
  final VoidCallback onRangeTap;

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: range.title,
      height: 60,
      titleAlignment: Alignment.centerLeft,
      reserveTrailingSpace: false,
      leading: DudoCircleIconButton(
        icon: LucideIcons.chevronLeft,
        iconSize: 21,
        borderColor: DudoColors.outlineVariant,
        onTap: () => context.pop(),
      ),
      titleWidget: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '阅读记录',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              range.title,
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
      trailing: _StatsRangeButton(label: range.label, onTap: onRangeTap),
    );
  }
}

class _StatsRangeButton extends StatelessWidget {
  const _StatsRangeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.full,
      child: InkWell(
        key: const ValueKey('reading-stats-range-button'),
        borderRadius: AppRadius.full,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: AppRadius.full,
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.calendarDays,
                color: DudoColors.secondary,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 13,
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

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;

    return Container(
      height: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(28),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2625251F),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.description,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  summary.totalLabel,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.onInk,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.range.dayCount} 天中读了 ${summary.readingDays} 天 · '
                  '共 ${summary.sessionCount} 次',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ReadingDayDonut(summary: summary),
        ],
      ),
    );
  }
}

class _ReadingDayDonut extends StatelessWidget {
  const _ReadingDayDonut({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 11,
              strokeCap: StrokeCap.round,
              color: DudoColors.onInk.withValues(alpha: 0.13),
            ),
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: summary.readingDayRatio.clamp(0.0, 1.0),
              strokeWidth: 11,
              strokeCap: StrokeCap.round,
              color: dark ? DudoColors.primary : DudoColors.primaryContainer,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                summary.readingDayRatioLabel,
                style: DudoTextStyles.numeric(
                  color: DudoColors.onInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '阅读天',
                style: DudoTextStyles.sans(
                  color: DudoColors.onInkMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (var i = 0; i < summary.stats.length; i++) ...[
            Expanded(
              child: _QuickMetricCard(
                metric: summary.stats[i],
                highlighted: i == 0,
              ),
            ),
            if (i != summary.stats.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _QuickMetricCard extends StatelessWidget {
  const _QuickMetricCard({required this.metric, required this.highlighted});

  final ReadingStatMetric metric;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? DudoColors.primaryContainer : DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? DudoColors.primaryContainerStrong
              : DudoColors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.value,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmChart extends StatelessWidget {
  const _RhythmChart({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = summary.rhythmStats
        .map((stat) => stat.minutes)
        .fold<int>(0, (max, minutes) => minutes > max ? minutes : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '阅读节奏',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.rhythmSubtitle,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                summary.hasData
                    ? '峰值 ${_formatPeak(maxMinutes, summary.rhythmGranularity)}'
                    : '暂无数据',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 138,
            child: _ReadingRhythmBarChart(
              rhythmStats: summary.rhythmStats,
              granularity: summary.rhythmGranularity,
              maxMinutes: maxMinutes,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPeak(
    int minutes,
    ReadingStatsRhythmGranularity granularity,
  ) {
    if (granularity == ReadingStatsRhythmGranularity.day || minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}

class _ReadingRhythmBarChart extends StatefulWidget {
  const _ReadingRhythmBarChart({
    required this.rhythmStats,
    required this.granularity,
    required this.maxMinutes,
  });

  final List<ReadingRhythmStat> rhythmStats;
  final ReadingStatsRhythmGranularity granularity;
  final int maxMinutes;

  @override
  State<_ReadingRhythmBarChart> createState() => _ReadingRhythmBarChartState();
}

class _ReadingRhythmBarChartState extends State<_ReadingRhythmBarChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _jumpToLatestIfScrollable();
  }

  @override
  void didUpdateWidget(_ReadingRhythmBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rhythmStats.length != widget.rhythmStats.length ||
        oldWidget.granularity != widget.granularity) {
      _jumpToLatestIfScrollable();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartMaxY =
        widget.maxMinutes <= 0 ? 60.0 : (widget.maxMinutes * 1.28).toDouble();
    final chartWidth = _chartWidthFor(widget.rhythmStats.length);
    final shouldScroll = chartWidth > 330;
    final chart = SizedBox(
      width: shouldScroll ? chartWidth : null,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= widget.rhythmStats.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.rhythmStats[index].label,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: widget.rhythmStats.length > 16 ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipColor: (_) => DudoColors.textPrimary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = widget.rhythmStats[group.x.toInt()];
                return BarTooltipItem(
                  '${_tooltipDateRange(stat)}\n${stat.minutes == 0 ? '未阅读' : '${stat.minutes} 分钟'}',
                  DudoTextStyles.sans(
                    color: DudoColors.surfaceHigh,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < widget.rhythmStats.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: widget.rhythmStats[i].minutes == 0
                        ? chartMaxY * 0.08
                        : widget.rhythmStats[i].minutes.toDouble(),
                    width: _barWidthFor(widget.rhythmStats.length),
                    borderRadius: BorderRadius.circular(9),
                    color: widget.rhythmStats[i].minutes == 0
                        ? DudoColors.outlineVariant
                        : _barColorFor(widget.rhythmStats[i].minutes),
                  ),
                ],
              ),
          ],
        ),
        duration: AppMotion.long,
        curve: AppMotion.emphasizedDecelerate,
      ),
    );

    if (!shouldScroll) return chart;

    return SingleChildScrollView(
      key: const ValueKey('reading-stats-rhythm-scroll'),
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: chart,
    );
  }

  void _jumpToLatestIfScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  double _chartWidthFor(int count) {
    if (count <= 7) return 0;
    final slotWidth =
        widget.granularity == ReadingStatsRhythmGranularity.day ? 42.0 : 54.0;
    return count * slotWidth;
  }

  double _barWidthFor(int count) {
    if (count <= 7) return 18;
    if (count <= 18) return 14;
    return 10;
  }

  Color _barColorFor(int minutes) {
    if (widget.maxMinutes > 0 && minutes == widget.maxMinutes) {
      return DudoColors.primary;
    }
    return DudoColors.primaryContainerStrong;
  }

  String _tooltipDateRange(ReadingRhythmStat stat) {
    if (DateUtils.isSameDay(stat.start, stat.end)) {
      return '${stat.start.month}月${stat.start.day}日';
    }
    if (stat.start.year == stat.end.year) {
      return '${stat.start.month}月${stat.start.day}日-${stat.end.month}月${stat.end.day}日';
    }
    return '${stat.start.year}年${stat.start.month}月${stat.start.day}日-'
        '${stat.end.year}年${stat.end.month}月${stat.end.day}日';
  }
}

class _ReadingDetailCard extends StatelessWidget {
  const _ReadingDetailCard({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final bestDayLabel = summary.bestDayLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读明细',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _DetailRow(
            icon: LucideIcons.bookOpen,
            label: '累计章节',
            value: '${summary.chaptersRead} 章',
          ),
          const _DetailDivider(),
          _DetailRow(
            icon: LucideIcons.type,
            label: '累计字数',
            value: formatReadingWords(summary.wordsRead),
          ),
          const _DetailDivider(),
          _DetailRow(
            icon: LucideIcons.history,
            label: '阅读次数',
            value:
                '${summary.sessionCount} 次 · 平均 ${formatCompactDuration(summary.averageSessionMinutes)}',
          ),
          const _DetailDivider(),
          _DetailRow(
            icon: LucideIcons.timer,
            label: '最长单次',
            value: formatCompactDuration(summary.longestSessionMinutes),
          ),
          const _DetailDivider(),
          _DetailRow(
            icon: LucideIcons.calendarHeart,
            label: '最活跃的一天',
            value: bestDayLabel == null
                ? '—'
                : '$bestDayLabel · ${formatCompactDuration(summary.bestDayMinutes)}',
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: DudoColors.outlineVariant);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: DudoColors.secondary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookContributionCard extends StatelessWidget {
  const _BookContributionCard({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '书籍贡献',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Top ${summary.contributions.length}',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < summary.contributions.length; i++) ...[
            _ContributionRow(rank: i + 1, item: summary.contributions[i]),
            if (i != summary.contributions.length - 1)
              const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.rank, required this.item});

  final int rank;
  final BookReadingContribution item;

  @override
  Widget build(BuildContext context) {
    final ratio = item.ratio.clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$rank',
            style: DudoTextStyles.numeric(
              color: DudoColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.full,
                child: Container(
                  height: 6,
                  color: DudoColors.surfaceLow,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DudoColors.primary,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.durationLabel,
              style: DudoTextStyles.numeric(
                color: DudoColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(ratio * 100).round()}%',
              style: DudoTextStyles.numeric(
                color: DudoColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyRhythmCard extends StatelessWidget {
  const _EmptyRhythmCard({required this.onRead});

  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DudoColors.primaryContainer,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              LucideIcons.bookOpen,
              color: DudoColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '开始阅读后生成节奏',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '读完一章、停留片刻，dudo 会帮你记录每天的阅读呼吸。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRead,
            style: TextButton.styleFrom(
              foregroundColor: DudoColors.primary,
              textStyle: DudoTextStyles.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('去书架看看'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showRangeSheet(BuildContext context, WidgetRef ref) async {
  final range = ref.read(readingStatsRangeProvider);
  final today = ref.read(readingStatsTodayProvider);
  final selection = await showCalendarRangeSelectorSheet(
    context: context,
    initialSelection: range.toCalendarSelection(),
    today: today,
    summaryTextBuilder: (selection) => readingStatsRangePreviewText(
      ReadingStatsRange.fromCalendarSelection(selection),
    ),
  );

  if (selection != null) {
    final nextRange = ReadingStatsRange.fromCalendarSelection(selection);
    if (!context.mounted) return;
    if (!nextRange.isSupportedForRhythm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('一次最多查看 366 天的阅读节奏，请重新选择时间范围'),
        ),
      );
      return;
    }
    ref.read(readingStatsRangeProvider.notifier).state = nextRange;
  }
}
