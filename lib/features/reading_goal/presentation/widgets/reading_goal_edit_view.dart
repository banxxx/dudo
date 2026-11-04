import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_fixed_page_frame.dart';
import '../../../../shared/widgets/dudo_page_header.dart';
import '../../domain/reading_goal_method.dart';
import '../../reading_goal_page_data.dart';
import 'reading_goal_sheets.dart';

class ReadingGoalEditView extends StatelessWidget {
  const ReadingGoalEditView({
    super.key,
    required this.title,
    required this.method,
    required this.goalValue,
    required this.progressText,
    required this.daysInMonth,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.repeatDays,
    required this.rules,
    required this.onCancel,
    required this.onSave,
    required this.onReset,
    this.onGoalAction,
    this.goalActionLabel = '关闭目标',
    required this.onMethodChanged,
    required this.onGoalChanged,
    required this.onReminderChanged,
    required this.onRulesChanged,
  });

  final String title;
  final GoalMethod method;
  final int goalValue;

  /// This month's completion percentage, shown in the preview disc.
  final String progressText;
  final int daysInMonth;
  final bool reminderEnabled;
  final int reminderMinutes;
  final Set<int> repeatDays;
  final List<bool> rules;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onReset;

  /// The header action: closes an active goal or re-opens a closed one.
  /// `null` while no goal has been saved yet.
  final VoidCallback? onGoalAction;

  /// `关闭目标` for an active goal, `开启目标` for a closed one.
  final String goalActionLabel;
  final ValueChanged<GoalMethod> onMethodChanged;
  final ValueChanged<int> onGoalChanged;
  final ValueChanged<ReadingGoalReminderDraft> onReminderChanged;
  final ValueChanged<List<bool>> onRulesChanged;

  String get _reminderSummary => reminderEnabled
      ? '每日 ${ReadingGoalPageData.formatReminderTime(reminderMinutes)} · '
          '${ReadingGoalPageData.repeatDaysLabel(repeatDays)}'
      : '已关闭';

  String get _rulesSummary => '${rules.where((rule) => rule).length} 项已开启';

  Future<void> _editValue(BuildContext context) async {
    final value = await showReadingGoalValueSheet(
      context,
      method: method,
      initialValue: goalValue,
    );
    if (value == null || !context.mounted) return;
    onGoalChanged(value);
  }

  Future<void> _editReminder(BuildContext context) async {
    final draft = await showReadingGoalReminderSheet(
      context,
      enabled: reminderEnabled,
      minutes: reminderMinutes,
      repeatDays: repeatDays,
    );
    if (draft == null || !context.mounted) return;
    onReminderChanged(draft);
  }

  Future<void> _editRules(BuildContext context) async {
    final updated = await showReadingGoalRulesSheet(
      context,
      method: method,
      rules: rules,
    );
    if (updated == null || !context.mounted) return;
    onRulesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return DudoFixedPageFrame(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      headerGap: 10,
      constrainWidth: false,
      header: _GoalEditHeader(
        onCancel: onCancel,
        onGoalAction: onGoalAction,
        goalActionLabel: goalActionLabel,
      ),
      footer: _GoalEditActions(onReset: onReset, onSave: onSave),
      children: [
        _GoalEditPreview(
          title: title,
          method: method,
          goalValue: goalValue,
          progressText: progressText,
          daysInMonth: daysInMonth,
        ),
        const SizedBox(height: 10),
        _GoalMethodCard(method: method, onChanged: onMethodChanged),
        const SizedBox(height: 10),
        _GoalValueCard(
          method: method,
          goalValue: goalValue,
          onChanged: onGoalChanged,
          onCustomTap: () => _editValue(context),
        ),
        const SizedBox(height: 10),
        _GoalSettingEntry(
          key: const ValueKey('reading-goal-reminder-row'),
          icon: LucideIcons.bell,
          title: '阅读提醒',
          subtitle: _reminderSummary,
          onTap: () => _editReminder(context),
        ),
        const SizedBox(height: 10),
        _GoalSettingEntry(
          key: const ValueKey('reading-goal-rules-row'),
          icon: LucideIcons.listChecks,
          title: '计入规则',
          subtitle: _rulesSummary,
          onTap: () => _editRules(context),
        ),
      ],
    );
  }
}

class _GoalEditHeader extends StatelessWidget {
  const _GoalEditHeader({
    required this.onCancel,
    required this.onGoalAction,
    required this.goalActionLabel,
  });

  final VoidCallback onCancel;
  final VoidCallback? onGoalAction;
  final String goalActionLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DudoCircleIconButton(
            key: const ValueKey('reading-goal-edit-cancel'),
            icon: LucideIcons.x,
            iconSize: 20,
            onTap: onCancel,
          ),
          Text(
            ReadingGoalPageData.editTitle,
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onGoalAction != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onGoalAction,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 44,
                  child: Center(
                    child: Text(
                      goalActionLabel,
                      key: const ValueKey('reading-goal-close-action'),
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _GoalEditPreview extends StatelessWidget {
  const _GoalEditPreview({
    required this.title,
    required this.method,
    required this.goalValue,
    required this.progressText,
    required this.daysInMonth,
  });

  final String title;
  final GoalMethod method;
  final int goalValue;
  final String progressText;
  final int daysInMonth;

  /// A per-day or per-week pace derived from the chosen value so the helper
  /// line stays correct when the goal is not the default.
  String get _helperText {
    final days = daysInMonth <= 0 ? 30 : daysInMonth;
    return switch (method) {
      GoalMethod.duration =>
        '阅读时长统计 · 每天约 ${(goalValue * 60 / days).round()} 分钟',
      GoalMethod.chapters => '完成章节统计 · 每周约 ${(goalValue / 4).round()} 章',
      GoalMethod.pages => '阅读页数统计 · 每天约 ${(goalValue / days).round()} 页',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(28),
        border: dark ? Border.all(color: DudoColors.outline) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$goalValue ${method.unit} / 月',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.serif(
                    color: DudoColors.onInk,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                Text(
                  _helperText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DudoColors.primaryContainer,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  progressText,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method.metricLabel,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
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

class _GoalMethodCard extends StatelessWidget {
  const _GoalMethodCard({required this.method, required this.onChanged});

  final GoalMethod method;
  final ValueChanged<GoalMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('统计方式'),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                for (final option in GoalMethod.values) ...[
                  Expanded(
                    child: _MethodOptionPill(
                      option: option,
                      selected: option == method,
                      onTap: () => onChanged(option),
                    ),
                  ),
                  if (option != GoalMethod.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: DudoColors.secondary,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    method.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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

class _MethodOptionPill extends StatelessWidget {
  const _MethodOptionPill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final GoalMethod option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? DudoColors.onInk : DudoColors.secondaryDark;
    return Material(
      color: selected ? DudoColors.textPrimary : DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              color: selected ? DudoColors.onInk : DudoColors.secondary,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              option.label,
              style: DudoTextStyles.sans(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalValueCard extends StatelessWidget {
  const _GoalValueCard({
    required this.method,
    required this.goalValue,
    required this.onChanged,
    required this.onCustomTap,
  });

  final GoalMethod method;
  final int goalValue;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _CardTitle('目标数值'),
              Text(
                method.unitTitle,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepperButton(
                  icon: LucideIcons.minus,
                  fill: DudoColors.surfaceLow,
                  iconColor: DudoColors.secondaryDark,
                  onTap: () => onChanged(goalValue - method.step),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$goalValue',
                      style: DudoTextStyles.numeric(
                        color: DudoColors.textPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '${method.unit} / 月',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _StepperButton(
                  icon: LucideIcons.plus,
                  fill: DudoColors.primaryContainer,
                  iconColor: DudoColors.primary,
                  onTap: () => onChanged(goalValue + method.step),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                for (final preset in method.presets) ...[
                  Expanded(
                    child: _PresetPill(
                      label: '$preset${method.compactUnit}',
                      selected: goalValue == preset,
                      onTap: () => onChanged(preset),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: _PresetPill(
                    key: const ValueKey('reading-goal-custom-pill'),
                    label: '自定义',
                    selected: !method.presets.contains(goalValue),
                    onTap: onCustomTap,
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

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.fill,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DudoColors.textPrimary : DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.onInk : DudoColors.secondaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSettingEntry extends StatelessWidget {
  const _GoalSettingEntry({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: DudoColors.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                color: DudoColors.secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalEditActions extends StatelessWidget {
  const _GoalEditActions({required this.onReset, required this.onSave});

  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: _EditActionButton(
              label: '恢复默认',
              fill: DudoColors.surface,
              foreground: DudoColors.secondary,
              border: DudoColors.outline,
              onTap: onReset,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EditActionButton(
              key: const ValueKey('reading-goal-save'),
              label: '保存目标',
              icon: LucideIcons.check,
              fill: DudoColors.textPrimary,
              foreground: DudoColors.onInk,
              onTap: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditActionButton extends StatelessWidget {
  const _EditActionButton({
    super.key,
    required this.label,
    required this.fill,
    required this.foreground,
    required this.onTap,
    this.icon,
    this.border,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: icon == null ? 14 : 15,
                  fontWeight: icon == null ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: child,
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
