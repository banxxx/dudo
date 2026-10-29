import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../reading_stats/domain/reading_stats_models.dart';
import '../application/home_providers.dart';
import 'widgets/home_reading_top_section.dart';
import 'widgets/home_starter_top_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homeReadingSnapshotProvider);

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        bottomSafeArea: false,
        children: [
          if (snapshot != null)
            HomeReadingTopSection(
              snapshot: snapshot,
              // No chapter parameter: the reader restores the saved position,
              // so continuing never restarts the chapter.
              onContinue: () =>
                  context.push('${AppRoutes.reader}/${snapshot.bookId}'),
            )
          else
            const HomeStarterTopSection(),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 12),
          const _RecommendationSection(),
          const SizedBox(height: 12),
          const _ReadingRhythmCard(),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.search,
              label: '找书',
              onTap: () => context.go(AppRoutes.search),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.bookmark,
              label: '书签',
              onTap: () => context.push(AppRoutes.bookmarks),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.chartNoAxesColumn,
              label: '统计',
              onTap: () => context.push(AppRoutes.readingStats),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DudoColors.secondary, size: 18),
            const SizedBox(height: 5),
            Text(
              label,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '为你精选',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '全部',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
         Row(
          children: [
            Expanded(
              child: _RecommendedBookCard(
                title: '云边有个小卖部',
                subtitle: '温柔乡土',
                label: 'ZHANG',
                gradient: [DudoColors.accent, DudoColors.secondaryContainer],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RecommendedBookCard(
                title: '明朝那些事儿',
                subtitle: '历史叙事',
                label: 'MING',
                gradient: [DudoColors.primary, DudoColors.primaryContainer],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RecommendedBookCard(
                title: '长安的荔枝',
                subtitle: '古代职场',
                label: 'CHANG',
                gradient: [DudoColors.secondary, DudoColors.outlineVariant],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.68,
          child: ClipRRect(
            borderRadius: AppRadius.large,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  label,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.surfaceHigh,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ReadingRhythmCard extends ConsumerWidget {
  const _ReadingRhythmCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeWeeklyRhythmProvider);
    final days = stats.valueOrNull ?? const <ReadingRhythmStat>[];
    final labels = days.isEmpty
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : [for (final day in days) day.label];
    final minutes = days.isEmpty
        ? const [0, 0, 0, 0, 0, 0, 0]
        : [for (final day in days) day.minutes];
    final totalMinutes = minutes.fold<int>(0, (sum, value) => sum + value);
    final maxMinutes = minutes.fold<int>(0, math.max);

    final summary = days.isEmpty
        ? '暂无记录'
        : totalMinutes <= 0
            ? '本周还没有阅读记录'
            : '共 ${_durationLabel(totalMinutes)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周节奏',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                summary,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  Expanded(
                    child: _RhythmBar(
                      label: labels[i],
                      minutes: minutes[i],
                      maxMinutes: maxMinutes,
                    ),
                  ),
                  if (i != labels.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmBar extends StatelessWidget {
  const _RhythmBar({
    required this.label,
    required this.minutes,
    required this.maxMinutes,
  });

  final String label;
  final int minutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final hasReading = minutes > 0;
    final height = hasReading && maxMinutes > 0
        ? 6.0 + (minutes / maxMinutes) * 34.0
        : 6.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            color: hasReading ? DudoColors.primary : DudoColors.outline,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

String _durationLabel(int minutes) {
  if (minutes <= 0) return '0 分钟';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$remaining 分钟';
  if (remaining == 0) return '$hours 小时';
  return '$hours 小时 $remaining 分钟';
}
