import 'package:dudo/features/reading_goal/application/reading_goal_overview.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal_method.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 20);

  ReadingMonthStats stats({
    int totalSeconds = 15 * 3600 + 36 * 60,
    int chaptersRead = 12,
    int charactersRead = 168000,
    int recordedDays = 23,
    int daysInMonth = 31,
    int streakDays = 6,
  }) {
    return ReadingMonthStats(
      month: DateTime(2026, 5),
      totalSeconds: totalSeconds,
      chaptersRead: chaptersRead,
      charactersRead: charactersRead,
      recordedDays: recordedDays,
      daysInMonth: daysInMonth,
      streakDays: streakDays,
    );
  }

  ReadingGoalOverview build({
    ReadingGoal? goal,
    ReadingMonthStats? monthStats,
    List<ReadingRhythmStat> weekRhythm = const [],
  }) {
    return ReadingGoalOverview.build(
      goal: goal ?? ReadingGoal.defaults(),
      stats: monthStats ?? stats(),
      weekRhythm: weekRhythm,
      now: now,
    );
  }

  test('duration goal reports the real monthly progress', () {
    final overview = build();

    expect(overview.title, '五月阅读目标');
    expect(overview.currentProgress, '15h 36m');
    expect(overview.progressSummary, '目标 20 小时 · 已完成 78%');
    expect(overview.progressPercent, closeTo(0.78, 0.001));
    expect(overview.progressPercentText, '78%');
    expect(overview.remainingDescription, '距离 20 小时目标还差 4 小时 24 分钟。');
    expect(overview.heroBadges.first.text, '差 4h 24m');
    expect(overview.heroBadges.last.text, '节奏正常');
    expect(overview.metrics.first.value, '23/31');
    expect(overview.metrics.last.value, '6天');
    expect(overview.settings[0].value, '20 小时');
    expect(overview.settings[2].value, '阅读时长');
    expect(overview.suggestionTitle, '每天再读 22 分钟即可达成');
  });

  test('chapter goal counts chapters instead of minutes', () {
    final overview = build(
      goal: ReadingGoal.defaults().copyWith(
        method: GoalMethod.chapters,
        value: 24,
      ),
    );

    expect(overview.currentProgress, '12 章');
    expect(overview.progressSummary, '目标 24 章 · 已完成 50%');
    expect(overview.remainingDescription, '距离 24 章目标还差 12 章。');
    expect(overview.heroBadges.first.text, '差 12 章');
    expect(overview.settings[0].value, '24 章');
    expect(overview.settings[2].value, '完成章节');
    expect(overview.methodProgress[GoalMethod.chapters], '12');
  });

  test('page goal derives pages from characters read', () {
    final overview = build(
      goal: ReadingGoal.defaults().copyWith(
        method: GoalMethod.pages,
        value: 360,
      ),
    );

    expect(overview.currentProgress, '210 页');
    expect(overview.progressPercentText, '58%');
    expect(overview.remainingDescription, '距离 360 页目标还差 150 页。');
    expect(overview.methodProgress[GoalMethod.pages], '210');
  });

  test('an exceeded goal is clamped to 100% and marked as reached', () {
    final overview = build(
      monthStats: stats(totalSeconds: 25 * 3600),
    );

    expect(overview.progressPercent, 1);
    expect(overview.progressPercentText, '100%');
    expect(overview.remainingDescription, '本月目标已达成，继续保持这份节奏。');
    expect(overview.heroBadges.first.text, '已达成');
    expect(overview.heroBadges.last.text, '目标达成');
    expect(overview.suggestionTitle, '本月目标已达成，保持就好');
  });

  test('an empty month suggests how much to read each day', () {
    final overview = build(
      monthStats: stats(
        totalSeconds: 0,
        chaptersRead: 0,
        charactersRead: 0,
        recordedDays: 0,
        streakDays: 0,
      ),
    );

    expect(overview.progressPercent, 0);
    expect(overview.progressPercentText, '0%');
    expect(overview.currentProgress, '0m');
    expect(overview.metrics.first.value, '0/31');
    expect(overview.suggestionTitle, '每天再读 100 分钟即可达成');
    expect(overview.suggestionDescription, '今天读一点，本月的目标就开始推进了。');
  });

  test('weekly bars scale to the busiest day', () {
    const minutes = [0, 30, 0, 60, 15, 0, 45];
    final overview = build(
      weekRhythm: [
        for (var i = 0; i < minutes.length; i++)
          ReadingRhythmStat(
            label: '一二三四五六日'[i],
            minutes: minutes[i],
            start: now,
            end: now,
          ),
      ],
    );

    expect(overview.weeklyAverage, '日均 21 分钟');
    expect(overview.weeklyBars, hasLength(7));
    expect(overview.weeklyBars[3].height, 52);
    expect(overview.weeklyBars[3].color, DudoColors.primary);
    expect(overview.weeklyBars[1].height, 37);
    expect(overview.weeklyBars[1].color, DudoColors.primaryContainer);
    expect(overview.weeklyBars[0].height, 22);
    expect(overview.weeklyBars[0].color, DudoColors.surfaceLow);
  });
}
