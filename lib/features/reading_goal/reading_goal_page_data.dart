import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    required this.quickValues,
    required this.recommendedRange,
    required this.metricLabel,
    required this.hint,
    required this.ruleTexts,
  });

  final String label;
  final String unit;
  final String compactUnit;
  final int defaultValue;
  final int step;
  final int minValue;
  final List<int> presets;

  /// Suggested values inside the custom-value keypad sheet.
  final List<int> quickValues;

  /// Recommended band shown above the keypad, e.g. `300–450 页`.
  final String recommendedRange;
  final String metricLabel;
  final String hint;
  final List<String> ruleTexts;

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
  List<int> get quickValues => content.quickValues;
  String get recommendedRange => content.recommendedRange;
  String get metricLabel => content.metricLabel;
  String get hint => content.hint;
  List<String> get ruleTexts => content.ruleTexts;

  IconData get icon => switch (this) {
        GoalMethod.duration => LucideIcons.clock3,
        GoalMethod.chapters => LucideIcons.bookOpen,
        GoalMethod.pages => LucideIcons.fileText,
      };
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

/// A one-tap reminder time suggestion in the reminder sheet.
class ReadingGoalReminderScene {
  const ReadingGoalReminderScene(this.label, this.minutes);

  final String label;
  final int minutes;
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
  static const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  static const defaultRepeatDays = {0, 1, 2, 3, 4, 5};
  static const defaultRules = [true, true, true];

  static const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static const reminderScenes = [
    ReadingGoalReminderScene('通勤前', 7 * 60 + 30),
    ReadingGoalReminderScene('午休', 12 * 60 + 40),
    ReadingGoalReminderScene('睡前轻读', 21 * 60 + 30),
  ];

  /// Formats minutes since midnight as `21:30`.
  static String formatReminderTime(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    final hour = (clamped ~/ 60).toString().padLeft(2, '0');
    final minute = (clamped % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// `周一至周六` for a contiguous run, `每天` for all seven, otherwise a list.
  static String repeatDaysLabel(Set<int> days) {
    if (days.isEmpty) return '不重复';
    final sorted = days.toList()..sort();
    if (sorted.length == 7) return '每天';
    final contiguous = sorted.length > 1 &&
        sorted.last - sorted.first == sorted.length - 1;
    if (contiguous) {
      return '${_weekdayNames[sorted.first]}至${_weekdayNames[sorted.last]}';
    }
    return sorted.map((day) => _weekdayNames[day]).join('、');
  }

  /// The scene whose preset matches [minutes], or `自定义时间`.
  static String sceneLabelFor(int minutes) {
    for (final scene in reminderScenes) {
      if (scene.minutes == minutes) return scene.label;
    }
    return '自定义时间';
  }

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static const methodContents = {
    GoalMethod.duration: ReadingGoalMethodContent(
      label: '阅读时长',
      unit: '小时',
      compactUnit: 'h',
      defaultValue: 20,
      step: 1,
      minValue: 1,
      presets: [10, 20, 30],
      quickValues: [10, 20, 30],
      recommendedRange: '15–30 小时',
      metricLabel: '完成',
      hint: '选择方式后，下方目标数值自动切换单位和推荐预设',
      ruleTexts: [
        '打开阅读器并停留阅读时计入',
        '听书时长同步计入目标',
        '离开阅读页后自动暂停计时',
      ],
    ),
    GoalMethod.chapters: ReadingGoalMethodContent(
      label: '完成章节',
      unit: '章',
      compactUnit: '章',
      defaultValue: 24,
      step: 1,
      minValue: 1,
      presets: [12, 24, 40],
      quickValues: [12, 24, 40],
      recommendedRange: '18–30 章',
      metricLabel: '已完成',
      hint: '章节目标按完成章节数推进，适合章节清晰的小说',
      ruleTexts: [
        '读完并进入下一章后计为完成',
        '同一次阅读中重复翻看不重复计数',
        '通过目录或书签跳读不会计入完成章节',
      ],
    ),
    GoalMethod.pages: ReadingGoalMethodContent(
      label: '阅读页数',
      unit: '页',
      compactUnit: '页',
      defaultValue: 360,
      step: 10,
      minValue: 10,
      presets: [180, 360, 600],
      quickValues: [300, 420, 600],
      recommendedRange: '300–450 页',
      metricLabel: '已读',
      hint: '页数目标会随排版校准，适合想看明确读量的人',
      ruleTexts: [
        '按阅读字数估算页数（约 800 字/页）',
        '翻回已读位置不会重复计数',
        '通过目录或书签跳读不会计入页数',
      ],
    ),
  };
}
