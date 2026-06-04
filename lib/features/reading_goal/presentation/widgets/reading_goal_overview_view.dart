import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_fixed_page_frame.dart';
import '../../../../shared/widgets/dudo_page_header.dart';
import '../../reading_goal_page_data.dart';

class ReadingGoalOverviewView extends StatelessWidget {
  const ReadingGoalOverviewView({super.key, required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DudoFixedPageFrame(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      constrainWidth: false,
      header: _GoalHeader(onEdit: onEdit),
      children: const [
        SizedBox(height: 10),
        _GoalHeroCard(),
        SizedBox(height: 10),
        _QuickMetrics(),
        SizedBox(height: 10),
        _WeeklyPaceCard(),
        SizedBox(height: 10),
        _GoalSettingsCard(),
        SizedBox(height: 10),
        _SuggestionCard(),
      ],
    );
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: ReadingGoalPageData.title,
      leading: DudoCircleIconButton(
        icon: LucideIcons.chevronLeft,
        onTap: () => context.pop(),
      ),
      trailing: DudoCircleIconButton(icon: LucideIcons.pencil, onTap: onEdit),
    );
  }
}

class _GoalHeroCard extends StatelessWidget {
  const _GoalHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2625251F),
            offset: Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReadingGoalPageData.progressTitle,
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ReadingGoalPageData.currentProgress,
                      style: DudoTextStyles.numeric(
                        color: DudoColors.surfaceHigh,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ReadingGoalPageData.progressSummary,
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (final badge in ReadingGoalPageData.heroBadges) ...[
                      _HeroBadge(badge),
                      if (badge != ReadingGoalPageData.heroBadges.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _ProgressDonut(),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge(this.badge);

  final ReadingGoalHeroBadgeData badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: badge.fill, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(badge.icon, color: badge.iconColor, size: 13),
          const SizedBox(width: 5),
          Text(
            badge.text,
            style: DudoTextStyles.sans(
              color: badge.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDonut extends StatelessWidget {
  const _ProgressDonut();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              color: DudoColors.surfaceHigh.withValues(alpha: 0.13),
            ),
          ),
          const SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: ReadingGoalPageData.progressPercent,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              color: DudoColors.primaryContainer,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: DudoColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ReadingGoalPageData.progressPercentText,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.surfaceHigh,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ReadingGoalPageData.progressPercentLabel,
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (final metric in ReadingGoalPageData.metrics) ...[
            Expanded(child: _MetricCard(metric)),
            if (metric != ReadingGoalPageData.metrics.last)
              const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final ReadingGoalMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: metric.fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: metric.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.value,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 24,
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
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPaceCard extends StatelessWidget {
  const _WeeklyPaceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ReadingGoalPageData.weeklyTitle,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ReadingGoalPageData.weeklyAverage,
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in ReadingGoalPageData.weeklyBars) ...[
                  Expanded(child: _WeekBarColumn(bar)),
                  if (bar != ReadingGoalPageData.weeklyBars.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBarColumn extends StatelessWidget {
  const _WeekBarColumn(this.bar);

  final ReadingGoalWeekBarData bar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: bar.height,
          decoration: BoxDecoration(
            color: bar.color,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          bar.label,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _GoalSettingsCard extends StatelessWidget {
  const _GoalSettingsCard();

  @override
  Widget build(BuildContext context) {
    return const _PlainCard(
      height: 170,
      children: [
        _CardTitle(ReadingGoalPageData.settingsTitle),
        SizedBox(height: 6),
        _SettingsLines(),
      ],
    );
  }
}

class _SettingsLines extends StatelessWidget {
  const _SettingsLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final setting in ReadingGoalPageData.settings) ...[
          _SettingLine(setting),
          if (setting != ReadingGoalPageData.settings.last)
            const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine(this.setting);

  final ReadingGoalSettingLineData setting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(setting.icon, color: DudoColors.secondary, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            setting.label,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            setting.value,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: DudoColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.leaf,
                color: DudoColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReadingGoalPageData.suggestionTitle,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ReadingGoalPageData.suggestionDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
