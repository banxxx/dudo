import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_fixed_page_frame.dart';
import '../../../../shared/widgets/dudo_page_header.dart';
import '../../domain/reading_goal_method.dart';
import '../../reading_goal_page_data.dart';

class ReadingGoalEditView extends StatelessWidget {
  const ReadingGoalEditView({
    super.key,
    required this.method,
    required this.goalValue,
    required this.reminderEnabled,
    required this.repeatDays,
    required this.rules,
    required this.onCancel,
    required this.onSave,
    required this.onReset,
    required this.onMethodChanged,
    required this.onGoalChanged,
    required this.onReminderChanged,
    required this.onRepeatDayToggled,
    required this.onRuleToggled,
  });

  final GoalMethod method;
  final int goalValue;
  final bool reminderEnabled;
  final Set<int> repeatDays;
  final List<bool> rules;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final ValueChanged<GoalMethod> onMethodChanged;
  final ValueChanged<int> onGoalChanged;
  final ValueChanged<bool> onReminderChanged;
  final ValueChanged<int> onRepeatDayToggled;
  final ValueChanged<int> onRuleToggled;

  @override
  Widget build(BuildContext context) {
    return DudoFixedPageFrame(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      constrainWidth: false,
      header: _GoalEditHeader(onCancel: onCancel, onSave: onSave),
      footer: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _GoalEditActions(onReset: onReset, onSave: onSave),
      ),
      children: [
        const SizedBox(height: 10),
        _GoalEditPreview(method: method, goalValue: goalValue),
        const SizedBox(height: 10),
        _GoalMethodCard(method: method, onChanged: onMethodChanged),
        const SizedBox(height: 10),
        _GoalValueCard(
          method: method,
          goalValue: goalValue,
          onChanged: onGoalChanged,
        ),
        const SizedBox(height: 10),
        _GoalReminderCard(
          enabled: reminderEnabled,
          repeatDays: repeatDays,
          onEnabledChanged: onReminderChanged,
          onRepeatDayToggled: onRepeatDayToggled,
        ),
        const SizedBox(height: 10),
        _GoalRulesCard(
          method: method,
          rules: rules,
          onRuleToggled: onRuleToggled,
        ),
        const SizedBox(height: 10),
        _GoalEditNote(method: method),
      ],
    );
  }
}

class _GoalEditHeader extends StatelessWidget {
  const _GoalEditHeader({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: ReadingGoalPageData.editTitle,
      leading: DudoCircleIconButton(icon: LucideIcons.x, onTap: onCancel),
      trailing: _SmallDarkButton(text: '保存', onTap: onSave),
    );
  }
}

class _SmallDarkButton extends StatelessWidget {
  const _SmallDarkButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DudoColors.textPrimary,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Text(
            text,
            style: DudoTextStyles.sans(
              color: DudoColors.surfaceHigh,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalEditPreview extends StatelessWidget {
  const _GoalEditPreview({required this.method, required this.goalValue});

  final GoalMethod method;
  final int goalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, 12),
            blurRadius: 28,
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
                Text(
                  ReadingGoalPageData.title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$goalValue ${method.unit} / 月',
                  style: DudoTextStyles.serif(
                    color: DudoColors.surfaceHigh,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                Text(
                  method.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
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
                  method.metric,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  method.metricLabel,
                  style: DudoTextStyles.sans(
                    color: DudoColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
            height: 48,
            child: Row(
              children: [
                for (final option in GoalMethod.values) ...[
                  Expanded(
                    child: _MethodOptionPill(
                      label: option.label,
                      selected: option == method,
                      onTap: () => onChanged(option),
                    ),
                  ),
                  if (option != GoalMethod.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles,
                    color: DudoColors.secondary, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    method.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? DudoColors.textPrimary : DudoColors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color:
                  selected ? DudoColors.surfaceHigh : DudoColors.secondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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
  });

  final GoalMethod method;
  final int goalValue;
  final ValueChanged<int> onChanged;

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
                    const SizedBox(height: 3),
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
                  onTap: () => onChanged(goalValue + method.step),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
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
                    label: '自定义',
                    selected: !method.presets.contains(goalValue),
                    onTap: () {},
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
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Icon(icon, color: DudoColors.secondaryDark, size: 20),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color:
                  selected ? DudoColors.surfaceHigh : DudoColors.secondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalReminderCard extends StatelessWidget {
  const _GoalReminderCard({
    required this.enabled,
    required this.repeatDays,
    required this.onEnabledChanged,
    required this.onRepeatDayToggled,
  });

  final bool enabled;
  final Set<int> repeatDays;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onRepeatDayToggled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _CardTitle('阅读提醒'),
              _DudoSwitch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock3,
                    color: DudoColors.secondary, size: 16),
                const SizedBox(width: 10),
                Text(
                  ReadingGoalPageData.reminderTime,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  ReadingGoalPageData.reminderLabel,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Row(
              children: [
                for (var index = 0;
                    index < ReadingGoalPageData.weekdays.length;
                    index++) ...[
                  Expanded(
                    child: _DayChip(
                      label: ReadingGoalPageData.weekdays[index],
                      selected: repeatDays.contains(index),
                      onTap: () => onRepeatDayToggled(index),
                    ),
                  ),
                  if (index != ReadingGoalPageData.weekdays.length - 1)
                    const SizedBox(width: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DudoSwitch extends StatelessWidget {
  const _DudoSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.short,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? DudoColors.textPrimary : DudoColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? DudoColors.textPrimary : DudoColors.outline,
          ),
        ),
        child: AnimatedAlign(
          duration: AppMotion.short,
          curve: AppMotion.emphasized,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: DudoColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.surfaceHigh : DudoColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalRulesCard extends StatelessWidget {
  const _GoalRulesCard({
    required this.method,
    required this.rules,
    required this.onRuleToggled,
  });

  final GoalMethod method;
  final List<bool> rules;
  final ValueChanged<int> onRuleToggled;

  @override
  Widget build(BuildContext context) {
    final texts = method.ruleTexts;
    return _EditCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('计入规则'),
          const SizedBox(height: 8),
          for (var index = 0; index < texts.length; index++) ...[
            _RuleRow(
              text: texts[index],
              selected: rules[index],
              onTap: () => onRuleToggled(index),
            ),
            if (index != texts.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 24,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color:
                      selected ? DudoColors.textPrimary : DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        selected ? DudoColors.textPrimary : DudoColors.outline,
                  ),
                ),
                child: selected
                    ? const Icon(LucideIcons.check,
                        color: DudoColors.surfaceHigh, size: 13)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalEditNote extends StatelessWidget {
  const _GoalEditNote({required this.method});

  final GoalMethod method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: DudoColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              method.note,
              style: DudoTextStyles.sans(
                color: DudoColors.secondaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ),
        ],
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
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: _ActionButton(
              text: '恢复默认',
              fill: DudoColors.surface,
              textColor: DudoColors.secondaryDark,
              border: DudoColors.outlineVariant,
              onTap: onReset,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              text: '保存目标',
              icon: LucideIcons.check,
              fill: DudoColors.textPrimary,
              textColor: DudoColors.surfaceHigh,
              onTap: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.fill,
    required this.textColor,
    required this.onTap,
    this.icon,
    this.border,
  });

  final String text;
  final Color fill;
  final Color textColor;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(25),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: DudoTextStyles.sans(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
