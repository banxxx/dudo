import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../application/reading_stats_provider.dart';
import '../domain/reading_stats_models.dart';

class ReadingStatsPage extends ConsumerWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(readingStatsSummaryProvider);

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
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
                '本周节奏',
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
    final maxMinutes = summary.dailyStats
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
            children: [
              Expanded(
                child: Text(
                  '每日阅读分布',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                summary.hasData ? '峰值 ${maxMinutes}m' : '暂无数据',
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < summary.dailyStats.length; i++) ...[
                  Expanded(
                    child: _ChartBar(
                      stat: summary.dailyStats[i],
                      maxMinutes: maxMinutes,
                      highlighted: i == 2 || i == 4 || i == 6,
                    ),
                  ),
                  if (i != summary.dailyStats.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.stat,
    required this.maxMinutes,
    required this.highlighted,
  });

  final DailyReadingStat stat;
  final int maxMinutes;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final normalized = maxMinutes == 0 ? 0.0 : stat.minutes / maxMinutes;
    final height = 18 + normalized * 76;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          stat.minutes == 0 ? '' : '${stat.minutes}m',
          style: DudoTextStyles.numeric(
            color: DudoColors.secondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            color: stat.minutes == 0
                ? DudoColors.outlineVariant
                : highlighted
                    ? DudoColors.primary
                    : DudoColors.primaryContainerStrong,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stat.dayLabel,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

Future<void> _showRangeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RangeSheet(),
  );
}

class _RangeSheet extends ConsumerWidget {
  const _RangeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(readingStatsRangeProvider);
    final summary = ref.watch(readingStatsSummaryProvider);

    return Container(
      height: 574,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    range.preset == ReadingStatsPreset.custom
                        ? '自定义时间'
                        : '选择时间',
                    style: DudoTextStyles.serif(
                      color: DudoColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _RoundIconButton(
                  icon: LucideIcons.x,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PresetSwitch(selected: range.preset),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CalendarHeader(range: range),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _CalendarWeekdays(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CalendarGrid(range: range),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary.sheetSummary,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DudoColors.textPrimary,
                    foregroundColor: DudoColors.surfaceHigh,
                    minimumSize: const Size(88, 42),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.full),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确认'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetSwitch extends ConsumerWidget {
  const _PresetSwitch({required this.selected});

  final ReadingStatsPreset selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: AppRadius.full,
      ),
      child: Row(
        children: [
          _PresetButton(
            label: '本周',
            selected: selected == ReadingStatsPreset.week,
            onTap: () => ref.read(readingStatsRangeProvider.notifier).state =
                ReadingStatsRange.week(),
          ),
          _PresetButton(
            label: '本月',
            selected: selected == ReadingStatsPreset.month,
            onTap: () => ref.read(readingStatsRangeProvider.notifier).state =
                ReadingStatsRange.month(),
          ),
          _PresetButton(
            label: '自定义',
            selected: selected == ReadingStatsPreset.custom,
            onTap: () => ref.read(readingStatsRangeProvider.notifier).state =
                ReadingStatsRange.custom(),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: AppRadius.full,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.surfaceHigh : Colors.transparent,
            borderRadius: AppRadius.full,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1425251F),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.textPrimary : DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.range});

  final ReadingStatsRange range;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.chevronLeft,
            color: DudoColors.secondary, size: 19),
        Expanded(
          child: Center(
            child: Text(
              '2024年5月',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const Icon(LucideIcons.chevronRight,
            color: DudoColors.secondary, size: 19),
      ],
    );
  }
}

class _CalendarWeekdays extends StatelessWidget {
  const _CalendarWeekdays();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.range});

  final ReadingStatsRange range;

  @override
  Widget build(BuildContext context) {
    const cells = [
      0,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      0,
      0,
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 4,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final day = cells[index];
        if (day == 0) return const SizedBox.shrink();
        return _CalendarDay(day: day, preset: range.preset);
      },
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.day, required this.preset});

  final int day;
  final ReadingStatsPreset preset;

  @override
  Widget build(BuildContext context) {
    final selected = switch (preset) {
      ReadingStatsPreset.week => day == 22,
      ReadingStatsPreset.month => day == 22,
      ReadingStatsPreset.custom => day == 10 || day == 20,
    };
    final ranged = switch (preset) {
      ReadingStatsPreset.week => day >= 18 && day <= 24,
      ReadingStatsPreset.month => day >= 1 && day <= 31,
      ReadingStatsPreset.custom => day >= 10 && day <= 20,
    };

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? DudoColors.primary
            : ranged
                ? DudoColors.primaryContainer
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: DudoTextStyles.numeric(
          color: selected ? DudoColors.surfaceHigh : DudoColors.textPrimary,
          fontSize: 14,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
