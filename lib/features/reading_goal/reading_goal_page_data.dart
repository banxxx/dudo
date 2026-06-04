import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/theme/app_tokens.dart';
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
    required this.helper,
    required this.metric,
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
  final String helper;
  final String metric;
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
  String get helper => content.helper;
  String get metric => content.metric;
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

  static const title = '五月阅读目标';
  static const editTitle = '编辑目标';
  static const progressTitle = '本月目标进度';
  static const currentProgress = '15h 36m';
  static const progressSummary = '目标 20 小时 · 已完成 78%';
  static const progressPercent = 0.78;
  static const progressPercentText = '78%';
  static const progressPercentLabel = '完成';
  static const weeklyTitle = '本周节奏';
  static const weeklyAverage = '日均 42 分钟';
  static const settingsTitle = '目标设置';
  static const suggestionTitle = '每天再读 33 分钟即可达成';
  static const suggestionDescription = '建议把睡前阅读提醒提前到 21:00。';
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
      helper: '阅读时长统计 · 每天约 39 分钟',
      metric: '78%',
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
      helper: '完成章节统计 · 每周约 6 章',
      metric: '12',
      metricLabel: '已完成',
      hint: '章节目标按完成章节数推进，适合章节清晰的小说',
      ruleTexts: [
        '章节阅读进度达到 90% 视为完成',
        '重复阅读同一章节不重复计数',
        '无章节书籍会按段落自动估算',
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
      helper: '阅读页数统计 · 每天约 12 页',
      metric: '210',
      metricLabel: '已读',
      hint: '页数目标会随排版校准，适合想看明确读量的人',
      ruleTexts: [
        '按当前字号、行高和屏幕尺寸估算页数',
        '切换排版后会重新校准虚拟页',
        'PDF 固定页数会直接使用原始页码',
      ],
      note: '阅读页数会随字体和排版变化；保存后将重新校准当前进度。',
    ),
  };

  static const heroBadges = [
    ReadingGoalHeroBadgeData(
      icon: LucideIcons.timer,
      text: '差 4h24m',
      iconColor: DudoColors.secondaryContainer,
      textColor: DudoColors.secondaryContainer,
      fill: Color(0x1FFFF8EA),
    ),
    ReadingGoalHeroBadgeData(
      icon: LucideIcons.trendingUp,
      text: '节奏正常',
      iconColor: DudoColors.primaryContainer,
      textColor: DudoColors.primaryContainer,
      fill: Color(0x2BDDE8D4),
    ),
  ];

  static const metrics = [
    ReadingGoalMetricData(
      value: '23/31',
      label: '已记录天数',
      fill: DudoColors.surface,
      stroke: DudoColors.outlineVariant,
    ),
    ReadingGoalMetricData(
      value: '6天',
      label: '连续阅读',
      fill: DudoColors.primaryContainer,
      stroke: DudoColors.primaryContainer,
    ),
  ];

  static const weeklyBars = [
    ReadingGoalWeekBarData(
        label: '一', height: 34, color: DudoColors.primaryContainer),
    ReadingGoalWeekBarData(
        label: '二', height: 44, color: DudoColors.primaryContainer),
    ReadingGoalWeekBarData(
        label: '三', height: 26, color: DudoColors.surfaceLow),
    ReadingGoalWeekBarData(label: '四', height: 52, color: DudoColors.primary),
    ReadingGoalWeekBarData(
        label: '五', height: 40, color: DudoColors.primaryContainer),
    ReadingGoalWeekBarData(label: '六', height: 48, color: DudoColors.primary),
    ReadingGoalWeekBarData(
        label: '日', height: 22, color: DudoColors.surfaceLow),
  ];

  static const settings = [
    ReadingGoalSettingLineData(
      icon: LucideIcons.target,
      label: '月度时长',
      value: '20 小时',
    ),
    ReadingGoalSettingLineData(
      icon: LucideIcons.bell,
      label: '阅读提醒',
      value: '21:30',
    ),
    ReadingGoalSettingLineData(
      icon: LucideIcons.calendarCheck,
      label: '统计口径',
      value: '阅读时长',
    ),
  ];
}
