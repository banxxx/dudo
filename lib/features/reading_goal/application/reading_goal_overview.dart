import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../reading_stats/domain/reading_stats_models.dart';
import '../domain/reading_goal.dart';
import '../domain/reading_goal_method.dart';
import '../reading_goal_page_data.dart';

/// A virtual page for the page-based goal. The reader lays out roughly 800
/// characters per page at the default typography.
const int _charactersPerPage = 800;

/// Everything the reading goal overview and the profile goal card render,
/// derived from the saved goal and this month's sessions.
class ReadingGoalOverview {
  const ReadingGoalOverview({
    required this.title,
    required this.currentProgress,
    required this.progressSummary,
    required this.progressPercent,
    required this.progressPercentText,
    required this.remainingDescription,
    required this.methodProgress,
    required this.heroBadges,
    required this.metrics,
    required this.weeklyAverage,
    required this.weeklyBars,
    required this.settings,
    required this.suggestionTitle,
    required this.suggestionDescription,
  });

  factory ReadingGoalOverview.build({
    required ReadingGoal goal,
    required ReadingMonthStats stats,
    required List<ReadingRhythmStat> weekRhythm,
    required DateTime now,
  }) {
    final currentValue = _currentValue(goal, stats);
    final targetValue = _targetValue(goal);
    final remainingValue = math.max(0, targetValue - currentValue);
    final ratio = targetValue <= 0
        ? 0.0
        : (currentValue / targetValue).clamp(0.0, 1.0).toDouble();
    final percentText = '${(ratio * 100).round()}%';

    final daysLeft = math.max(1, stats.daysInMonth - now.day + 1);
    final expectedRatio =
        stats.daysInMonth == 0 ? 0.0 : now.day / stats.daysInMonth;

    return ReadingGoalOverview(
      title: ReadingGoalPageData.titleFor(now),
      currentProgress: _currentLabel(goal, stats, currentValue),
      progressSummary: '目标 ${_targetLabel(goal)} · 已完成 $percentText',
      progressPercent: ratio,
      progressPercentText: percentText,
      remainingDescription: _remainingDescription(goal, remainingValue),
      methodProgress: {
        GoalMethod.duration: formatCompactDuration(stats.totalMinutes),
        GoalMethod.chapters: '${stats.chaptersRead}',
        GoalMethod.pages:
            '${(stats.charactersRead / _charactersPerPage).round()}',
      },
      heroBadges: [
        ReadingGoalHeroBadgeData(
          icon: LucideIcons.timer,
          text: remainingValue <= 0
              ? '已达成'
              : '差 ${_remainingLabel(goal, remainingValue)}',
          iconColor: DudoColors.secondaryContainer,
          textColor: DudoColors.secondaryContainer,
          fill: const Color(0x1FFFF8EA),
        ),
        ReadingGoalHeroBadgeData(
          icon: LucideIcons.trendingUp,
          text: _paceLabel(ratio, expectedRatio),
          iconColor: DudoColors.primaryContainer,
          textColor: DudoColors.primaryContainer,
          fill: const Color(0x2BDDE8D4),
        ),
      ],
      metrics: [
        ReadingGoalMetricData(
          value: '${stats.recordedDays}/${stats.daysInMonth}',
          label: '已记录天数',
          fill: DudoColors.surface,
          stroke: DudoColors.outlineVariant,
        ),
        ReadingGoalMetricData(
          value: '${stats.streakDays}天',
          label: '连续阅读',
          fill: DudoColors.primaryContainer,
          stroke: DudoColors.primaryContainer,
        ),
      ],
      weeklyAverage: _weeklyAverageLabel(weekRhythm),
      weeklyBars: _weeklyBars(weekRhythm),
      settings: [
        ReadingGoalSettingLineData(
          icon: LucideIcons.target,
          label: '月度目标',
          value: _targetLabel(goal),
        ),
        ReadingGoalSettingLineData(
          icon: LucideIcons.bell,
          label: '阅读提醒',
          value: goal.reminderEnabled ? '已开启' : '已关闭',
        ),
        ReadingGoalSettingLineData(
          icon: LucideIcons.calendarCheck,
          label: '统计口径',
          value: goal.method.label,
        ),
      ],
      suggestionTitle: _suggestionTitle(goal, remainingValue, daysLeft, ratio),
      suggestionDescription: _suggestionDescription(
        hasData: stats.hasData,
        onPace: ratio >= expectedRatio,
      ),
    );
  }

  final String title;
  final String currentProgress;
  final String progressSummary;
  final double progressPercent;
  final String progressPercentText;

  /// Sentence for the profile goal card, e.g.
  /// "距离 20 小时目标还差 4 小时 24 分钟。"
  final String remainingDescription;

  /// This month's progress per goal method, for the edit preview.
  final Map<GoalMethod, String> methodProgress;
  final List<ReadingGoalHeroBadgeData> heroBadges;
  final List<ReadingGoalMetricData> metrics;
  final String weeklyAverage;
  final List<ReadingGoalWeekBarData> weeklyBars;
  final List<ReadingGoalSettingLineData> settings;
  final String suggestionTitle;
  final String suggestionDescription;
}

int _targetValue(ReadingGoal goal) {
  return switch (goal.method) {
    GoalMethod.duration => goal.value * 60,
    GoalMethod.chapters || GoalMethod.pages => goal.value,
  };
}

int _currentValue(ReadingGoal goal, ReadingMonthStats stats) {
  return switch (goal.method) {
    GoalMethod.duration => stats.totalMinutes,
    GoalMethod.chapters => stats.chaptersRead,
    GoalMethod.pages => (stats.charactersRead / _charactersPerPage).round(),
  };
}

String _targetLabel(ReadingGoal goal) {
  return switch (goal.method) {
    GoalMethod.duration => '${goal.value} 小时',
    GoalMethod.chapters => '${goal.value} 章',
    GoalMethod.pages => '${goal.value} 页',
  };
}

String _currentLabel(
  ReadingGoal goal,
  ReadingMonthStats stats,
  int currentValue,
) {
  return switch (goal.method) {
    GoalMethod.duration => formatCompactDuration(stats.totalMinutes),
    GoalMethod.chapters => '$currentValue 章',
    GoalMethod.pages => '$currentValue 页',
  };
}

String _remainingLabel(ReadingGoal goal, int remainingValue) {
  return switch (goal.method) {
    GoalMethod.duration => formatCompactDuration(remainingValue),
    GoalMethod.chapters => '$remainingValue 章',
    GoalMethod.pages => '$remainingValue 页',
  };
}

String _remainingDescription(ReadingGoal goal, int remainingValue) {
  if (remainingValue <= 0) return '本月目标已达成，继续保持这份节奏。';
  return switch (goal.method) {
    GoalMethod.duration =>
      '距离 ${goal.value} 小时目标还差 ${formatProseDuration(remainingValue)}。',
    GoalMethod.chapters => '距离 ${goal.value} 章目标还差 $remainingValue 章。',
    GoalMethod.pages => '距离 ${goal.value} 页目标还差 $remainingValue 页。',
  };
}

String _paceLabel(double ratio, double expectedRatio) {
  if (ratio >= 1) return '目标达成';
  if (ratio >= expectedRatio) return '节奏正常';
  return '稍落后';
}

String _suggestionTitle(
  ReadingGoal goal,
  int remainingValue,
  int daysLeft,
  double ratio,
) {
  if (ratio >= 1) return '本月目标已达成，保持就好';
  final perDay = math.max(1, (remainingValue / daysLeft).ceil());
  return switch (goal.method) {
    GoalMethod.duration => '每天再读 $perDay 分钟即可达成',
    GoalMethod.chapters => '每天再读 $perDay 章即可达成',
    GoalMethod.pages => '每天再读 $perDay 页即可达成',
  };
}

String _suggestionDescription({
  required bool hasData,
  required bool onPace,
}) {
  if (!hasData) return '今天读一点，本月的目标就开始推进了。';
  if (onPace) return '保持当前节奏，本月底即可达成目标。';
  return '把阅读拆成两段，更容易补上进度。';
}

String _weeklyAverageLabel(List<ReadingRhythmStat> weekRhythm) {
  if (weekRhythm.isEmpty) return '日均 0 分钟';
  final total = weekRhythm.fold<int>(0, (sum, stat) => sum + stat.minutes);
  return '日均 ${(total / weekRhythm.length).round()} 分钟';
}

List<ReadingGoalWeekBarData> _weeklyBars(
  List<ReadingRhythmStat> weekRhythm,
) {
  final maxMinutes = weekRhythm.isEmpty
      ? 0
      : weekRhythm.fold<int>(0, (max, stat) => math.max(max, stat.minutes));

  return [
    for (final stat in weekRhythm)
      ReadingGoalWeekBarData(
        label: stat.label,
        height: maxMinutes <= 0 ? 22.0 : 22 + (stat.minutes / maxMinutes) * 30,
        color: stat.minutes <= 0
            ? DudoColors.surfaceLow
            : stat.minutes == maxMinutes
                ? DudoColors.primary
                : DudoColors.primaryContainer,
      ),
  ];
}
