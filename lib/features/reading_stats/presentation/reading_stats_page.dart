import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/calendar_range_selector/calendar_range_sheet.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../application/reading_stats_provider.dart';
import '../data/reading_stats_repository.dart';
import '../domain/reading_stats_models.dart';

class ReadingStatsPage extends ConsumerWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(readingStatsSummaryProvider);

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: summary.when(
        data: (summary) => DudoPageFrame(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          children: [
            _StatsHeader(summary: summary),
            const SizedBox(height: 12),
            _OverviewCard(summary: summary),
            const SizedBox(height: 12),
            _RhythmChart(summary: summary),
            const SizedBox(height: 12),
            if (summary.hasData)
              _BookContributionCard(summary: summary)
            else
              const _EmptyRhythmCard(),
          ],
        ),
        loading: () => const DudoPageFrame(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
          children: [
            _ReadingStatsLoadingCard(),
          ],
        ),
        error: (_, __) => DudoPageFrame(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          children: [
            _ReadingStatsErrorCard(
              onRetry: () => ref.invalidate(readingStatsSummaryProvider),
            ),
          ],
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
      height: 180,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: DudoColors.primary),
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '阅读统计加载失败',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: DudoColors.textPrimary,
              foregroundColor: DudoColors.surfaceHigh,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends ConsumerWidget {
  const _StatsHeader({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _RoundIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () => context.pop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '阅读统计',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                summary.range.title,
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
        Material(
          color: Colors.transparent,
          borderRadius: AppRadius.full,
          child: InkWell(
            key: const ValueKey('reading-stats-range-button'),
            borderRadius: AppRadius.full,
            onTap: () => _showRangeSheet(context, ref),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: DudoColors.surface,
                borderRadius: AppRadius.full,
                border: Border.all(color: DudoColors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.calendarDays,
                    color: DudoColors.secondary,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    summary.range.label,
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
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Icon(icon, color: DudoColors.secondary, size: 21),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summary});

  final ReadingStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: summary.hasData ? 154 : 142,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.totalLabel,
                style: DudoTextStyles.numeric(
                  color: DudoColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                summary.description,
                style: DudoTextStyles.sans(
                  color: DudoColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < summary.stats.length; i++) ...[
                Expanded(child: _MiniStat(metric: summary.stats[i])),
                if (i != summary.stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.metric});

  final ReadingStatMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0x55FFF8EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.value,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
                  fontWeight: FontWeight.w500,
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
          Text(
            '书籍贡献',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in summary.contributions) ...[
            _ContributionRow(item: item),
            if (item != summary.contributions.last) const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.item});

  final BookReadingContribution item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              item.durationLabel,
              style: DudoTextStyles.numeric(
                color: DudoColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.full,
          child: Container(
            height: 8,
            color: DudoColors.surfaceLow,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: item.ratio,
              child: Container(
                decoration: const BoxDecoration(
                  color: DudoColors.primary,
                  borderRadius: AppRadius.full,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRhythmCard extends StatelessWidget {
  const _EmptyRhythmCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DudoColors.primaryContainer,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
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
