import 'package:flutter/material.dart';

import 'domain/reading_goal_method.dart';

class ReadingGoalMethodContent {
  const ReadingGoalMethodContent({
    required this.label,
    required this.unit,
    required this.compactUnit,
    required this.defaultValue,
    required this.step,
    required this.minValue,
    required this.presets,
    required this.metricLabel,
    required this.hint,
    required this.ruleTexts,
    required this.note,
  });

  final String label;
  final String unit;
  final String compactUnit;
  final int defaultValue;
  final int step;
  final int minValue;
  final List<int> presets;
  final String metricLabel;
  final String hint;
  final List<String> ruleTexts;
  final String note;

  String get unitTitle => '$label · 月度';
}

extension GoalMethodData on GoalMethod {
  ReadingGoalMethodContent get content =>
      ReadingGoalPageData.methodContents[this]!;

  String get label => content.label;
  String get unit => content.unit;
  String get compactUnit => content.compactUnit;
  String get unitTitle => content.unitTitle;
  int get defaultValue => content.defaultValue;
  int get step => content.step;
  int get minValue => content.minValue;
  List<int> get presets => content.presets;
  String get metricLabel => content.metricLabel;
  String get hint => content.hint;
  List<String> get ruleTexts => content.ruleTexts;
  String get note => content.note;
}

class ReadingGoalHeroBadgeData {
  const ReadingGoalHeroBadgeData({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.fill,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final Color fill;
}

class ReadingGoalMetricData {
  const ReadingGoalMetricData({
    required this.value,
    required this.label,
    required this.fill,
    required this.stroke,
  });

  final String value;
  final String label;
  final Color fill;
  final Color stroke;
}

class ReadingGoalWeekBarData {
  const ReadingGoalWeekBarData({
    required this.label,
    required this.height,
    required this.color,
  });

  final String label;
  final double height;
  final Color color;
}

class ReadingGoalSettingLineData {
  const ReadingGoalSettingLineData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class ReadingGoalPageData {
  const ReadingGoalPageData._();

  static const _monthNames = [
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '七',
    '八',
    '九',
    '十',
    '十一',
    '十二',
  ];

  static String titleFor(DateTime date) =>
      '${_monthNames[date.month - 1]}月阅读目标';

  static const editTitle = '编辑目标';

  /// Upper bound for a custom goal value; the stepper and the custom dialog
  /// both clamp to it.
  static const maxValue = 999;

  static const progressTitle = '本月目标进度';
  static const progressPercentLabel = '完成';
  static const weeklyTitle = '本周节奏';
  static const settingsTitle = '目标设置';
  static const reminderTime = '每日 21:30';
  static const reminderLabel = '睡前轻读';
  static const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  static const defaultRepeatDays = {0, 1, 2, 3, 4, 5};
  static const defaultRules = [true, true, true];

  static const methodContents = {
    GoalMethod.duration: ReadingGoalMethodContent(
      label: '阅读时长',
      unit: '小时',
      compactUnit: 'h',
      defaultValue: 20,
      step: 1,
      minValue: 1,
      presets: [10, 20, 30],
      metricLabel: '当前',
      hint: '选择方式后，下方目标数值自动切换单位和推荐预设',
      ruleTexts: [
        '打开阅读器并停留阅读时计入',
        '听书时长同步计入目标',
        '离开阅读页后自动暂停计时',
      ],
      note: '阅读时长适合养成稳定习惯；本页保存后，历史进度不会清空。',
    ),
    GoalMethod.chapters: ReadingGoalMethodContent(
      label: '完成章节',
      unit: '章',
      compactUnit: '章',
      defaultValue: 24,
      step: 1,
      minValue: 1,
      presets: [12, 24, 40],
      metricLabel: '已完成',
      hint: '章节目标按完成章节数推进，适合章节清晰的小说',
      ruleTexts: [
        '读完并进入下一章后计为完成',
        '同一次阅读中重复翻看不重复计数',
        '通过目录或书签跳读不会计入完成章节',
      ],
      note: '完成章节适合章节标题明确的 TXT / EPUB；保存后按新方式统计。',
    ),
    GoalMethod.pages: ReadingGoalMethodContent(
      label: '阅读页数',
      unit: '页',
      compactUnit: '页',
      defaultValue: 360,
      step: 10,
      minValue: 10,
      presets: [180, 360, 600],
      metricLabel: '已读',
      hint: '页数目标会随排版校准，适合想看明确读量的人',
      ruleTexts: [
        '按阅读字数估算页数（约 800 字/页）',
        '翻回已读位置不会重复计数',
        '通过目录或书签跳读不会计入页数',
      ],
      note: '阅读页数按阅读字数估算；保存后继续沿用同一口径累计。',
    ),
  };
}
