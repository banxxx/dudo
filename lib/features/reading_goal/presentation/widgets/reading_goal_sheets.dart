import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../domain/reading_goal_method.dart';
import '../../reading_goal_page_data.dart';

/// The reminder values edited in the F10-5 sheet.
class ReadingGoalReminderDraft {
  const ReadingGoalReminderDraft({
    required this.enabled,
    required this.minutes,
    required this.repeatDays,
  });

  final bool enabled;
  final int minutes;
  final Set<int> repeatDays;
}

Future<int?> showReadingGoalValueSheet(
  BuildContext context, {
  required GoalMethod method,
  required int initialValue,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ValueSheet(
      method: method,
      initialValue: initialValue,
    ),
  );
}

Future<ReadingGoalReminderDraft?> showReadingGoalReminderSheet(
  BuildContext context, {
  required bool enabled,
  required int minutes,
  required Set<int> repeatDays,
}) {
  return showModalBottomSheet<ReadingGoalReminderDraft>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    isScrollControlled: true,
    useSafeArea: true,
    // The time wheel consumes vertical drags itself.
    enableDrag: false,
    builder: (context) => _ReminderSheet(
      enabled: enabled,
      minutes: minutes,
      repeatDays: repeatDays,
    ),
  );
}

Future<List<bool>?> showReadingGoalRulesSheet(
  BuildContext context, {
  required GoalMethod method,
  required List<bool> rules,
}) {
  return showModalBottomSheet<List<bool>>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _RulesSheet(method: method, rules: rules),
  );
}

Future<bool?> showReadingGoalCloseSheet(
  BuildContext context, {
  required String targetLabel,
  required String progressText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CloseGoalSheet(
      targetLabel: targetLabel,
      progressText: progressText,
    ),
  );
}

/// Paper sheet shared by the value, reminder and rules overlays: handle,
/// title row with a close button, then the caller's sections.
class _GoalSheetFrame extends StatelessWidget {
  const _GoalSheetFrame({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: DudoColors.outlineVariant)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, -10),
            blurRadius: 28,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 12),
            _SheetTitleRow(title: title),
            for (final child in children) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Center(
        child: Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: DudoColors.outline,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _SheetTitleRow extends StatelessWidget {
  const _SheetTitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  LucideIcons.x,
                  color: DudoColors.secondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.fill,
    this.foreground,
    this.radius = 28,
    this.height = 56,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final Color? fill;
  final Color? foreground;
  final double radius;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final background = fill ?? DudoColors.textPrimary;
    final color = foreground ?? DudoColors.onInk;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: DudoTextStyles.sans(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// F10-4 — custom goal value
// ---------------------------------------------------------------------------

class _ValueSheet extends StatefulWidget {
  const _ValueSheet({required this.method, required this.initialValue});

  final GoalMethod method;
  final int initialValue;

  @override
  State<_ValueSheet> createState() => _ValueSheetState();
}

class _ValueSheetState extends State<_ValueSheet> {
  static const List<List<String>> _keypadRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['clear', '0', 'back'],
  ];

  late String _digits = '${widget.initialValue}';

  int? get _value {
    final parsed = int.tryParse(_digits);
    if (parsed == null) return null;
    if (parsed < widget.method.minValue ||
        parsed > ReadingGoalPageData.maxValue) {
      return null;
    }
    return parsed;
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_digits.length >= 3) return;
      if (_digits == '0') {
        _digits = digit;
      } else {
        _digits += digit;
      }
    });
  }

  void _clear() => setState(() => _digits = '');

  void _backspace() {
    setState(() {
      if (_digits.isEmpty) return;
      _digits = _digits.substring(0, _digits.length - 1);
    });
  }

  void _setQuick(int value) => setState(() => _digits = '$value');

  void _submit() {
    final value = _value;
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final value = _value;
    final display = _digits.isEmpty ? '0' : _digits;
    final unit = method.unit;
    return _GoalSheetFrame(
      title: '自定义目标数值',
      children: [
        Container(
          height: 104,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    display,
                    key: const ValueKey('reading-goal-value-display'),
                    style: DudoTextStyles.numeric(
                      color: DudoColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$unit / 月',
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '推荐 ${method.recommendedRange} · 按最近 7 天读速估算',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              for (final quick in method.quickValues) ...[
                Expanded(
                  child: _QuickValueChip(
                    key: ValueKey('reading-goal-quick-$quick'),
                    label: '$quick $unit',
                    selected: _digits == '$quick',
                    onTap: () => _setQuick(quick),
                  ),
                ),
                if (quick != method.quickValues.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Column(
          children: [
            for (var row = 0; row < _keypadRows.length; row++) ...[
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    for (var column = 0;
                        column < _keypadRows[row].length;
                        column++) ...[
                      Expanded(
                        child: _keypadKey(_keypadRows[row][column]),
                      ),
                      if (column != _keypadRows[row].length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              if (row != _keypadRows.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
        _SheetActionButton(
          key: const ValueKey('reading-goal-value-apply'),
          label: '应用 ${value ?? 0} $unit',
          icon: LucideIcons.check,
          enabled: value != null,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _keypadKey(String key) {
    return switch (key) {
      'clear' => _KeypadKey(
          key: const ValueKey('reading-goal-keypad-clear'),
          onTap: _clear,
          child: Text(
            '清空',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      'back' => _KeypadKey(
          key: const ValueKey('reading-goal-keypad-delete'),
          onTap: _backspace,
          child: Icon(
            LucideIcons.delete,
            color: DudoColors.secondaryDark,
            size: 22,
          ),
        ),
      _ => _KeypadKey(
          key: ValueKey('reading-goal-keypad-$key'),
          onTap: () => _appendDigit(key),
          child: Text(
            key,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    };
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(child: child),
      ),
    );
  }
}

class _QuickValueChip extends StatelessWidget {
  const _QuickValueChip({
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

// ---------------------------------------------------------------------------
// F10-5 — reminder time
// ---------------------------------------------------------------------------

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({
    required this.enabled,
    required this.minutes,
    required this.repeatDays,
  });

  final bool enabled;
  final int minutes;
  final Set<int> repeatDays;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late bool _enabled = widget.enabled;
  late int _minutes = widget.minutes;
  late Set<int> _repeatDays = Set<int>.from(widget.repeatDays);

  int get _hour => _minutes ~/ 60;
  int get _minute => _minutes % 60;

  void _changeHour(int hour) => setState(() {
        _minutes = (hour % 24) * 60 + _minute;
      });

  void _changeMinute(int minute) => setState(() {
        _minutes = _hour * 60 + (minute % 60);
      });

  void _toggleDay(int index) {
    setState(() {
      final days = Set<int>.from(_repeatDays);
      days.contains(index) ? days.remove(index) : days.add(index);
      _repeatDays = days;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      ReadingGoalReminderDraft(
        enabled: _enabled,
        minutes: _minutes,
        repeatDays: Set<int>.from(_repeatDays),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _GoalSheetFrame(
      title: '设置阅读提醒',
      children: [
        _ReminderStatusCard(
          enabled: _enabled,
          title: _enabled
              ? '每日 ${ReadingGoalPageData.formatReminderTime(_minutes)} 提醒'
              : '提醒已关闭',
          subtitle: '${ReadingGoalPageData.repeatDaysLabel(_repeatDays)} · '
              '${ReadingGoalPageData.sceneLabelFor(_minutes)}',
          onToggle: () => setState(() => _enabled = !_enabled),
        ),
        _TimeWheel(
          hour: _hour,
          minute: _minute,
          onHourChanged: _changeHour,
          onMinuteChanged: _changeMinute,
        ),
        Column(
          children: [
            SizedBox(
              height: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '重复日期',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '点按切换',
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  for (var index = 0;
                      index < ReadingGoalPageData.weekdays.length;
                      index++) ...[
                    Expanded(
                      child: _RepeatDayChip(
                        label: ReadingGoalPageData.weekdays[index],
                        selected: _repeatDays.contains(index),
                        onTap: () => _toggleDay(index),
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
        SizedBox(
          height: 44,
          child: Row(
            children: [
              for (final scene in ReadingGoalPageData.reminderScenes) ...[
                Expanded(
                  child: _SceneChip(
                    label: scene.label,
                    selected: _minutes == scene.minutes,
                    onTap: () => setState(() => _minutes = scene.minutes),
                  ),
                ),
                if (scene != ReadingGoalPageData.reminderScenes.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        _SheetActionButton(
          key: const ValueKey('reading-goal-reminder-save'),
          label: '保存提醒',
          icon: LucideIcons.check,
          onTap: _save,
        ),
      ],
    );
  }
}

class _ReminderStatusCard extends StatelessWidget {
  const _ReminderStatusCard({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onToggle,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              LucideIcons.bellRing,
              color: DudoColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    color: DudoColors.secondaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppMotion.short,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: enabled ? DudoColors.primary : DudoColors.surfaceLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: enabled ? DudoColors.primary : DudoColors.outline,
                ),
              ),
              child: AnimatedAlign(
                duration: AppMotion.short,
                curve: AppMotion.emphasized,
                alignment:
                    enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: enabled ? DudoColors.onInk : DudoColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DudoColors.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1425251F),
                  offset: Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _WheelColumn(
                  value: hour,
                  min: 0,
                  max: 23,
                  onChanged: onHourChanged,
                ),
              ),
              SizedBox(
                width: 20,
                child: Center(
                  child: Text(
                    ':',
                    style: DudoTextStyles.numeric(
                      color: const Color(0xFFB9A78D),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _WheelColumn(
                  value: minute,
                  min: 0,
                  max: 59,
                  onChanged: onMinuteChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  static const double _stepDistance = 26;

  double _accumulated = 0;

  int _wrap(int value) {
    final span = widget.max - widget.min + 1;
    return widget.min + ((value - widget.min) % span + span) % span;
  }

  void _step(int direction) {
    widget.onChanged(_wrap(widget.value + direction));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _accumulated += details.delta.dy;
    while (_accumulated >= _stepDistance) {
      _accumulated -= _stepDistance;
      _step(-1);
    }
    while (_accumulated <= -_stepDistance) {
      _accumulated += _stepDistance;
      _step(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      child: Column(
        children: [
          Expanded(
            child: _WheelCell(
              value: _wrap(widget.value - 1),
              muted: true,
              onTap: () => _step(-1),
            ),
          ),
          Expanded(
            child: _WheelCell(
              value: widget.value,
              muted: false,
              onTap: null,
            ),
          ),
          Expanded(
            child: _WheelCell(
              value: _wrap(widget.value + 1),
              muted: true,
              onTap: () => _step(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelCell extends StatelessWidget {
  const _WheelCell({
    required this.value,
    required this.muted,
    required this.onTap,
  });

  final int value;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = value.toString().padLeft(2, '0');
    final text = Text(
      label,
      style: DudoTextStyles.numeric(
        color: muted ? DudoColors.secondary : DudoColors.textPrimary,
        fontSize: muted ? 22 : 32,
        fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: muted ? Opacity(opacity: 0.32, child: text) : text,
      ),
    );
  }
}

class _RepeatDayChip extends StatelessWidget {
  const _RepeatDayChip({
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
              color: selected ? DudoColors.onInk : DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({
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

// ---------------------------------------------------------------------------
// F10-6 — counting rules
// ---------------------------------------------------------------------------

class _RulesSheet extends StatefulWidget {
  const _RulesSheet({required this.method, required this.rules});

  final GoalMethod method;
  final List<bool> rules;

  @override
  State<_RulesSheet> createState() => _RulesSheetState();
}

class _RulesSheetState extends State<_RulesSheet> {
  late final List<bool> _rules = List<bool>.from(widget.rules);

  void _toggle(int index) {
    setState(() => _rules[index] = !_rules[index]);
  }

  @override
  Widget build(BuildContext context) {
    final texts = widget.method.ruleTexts;
    return _GoalSheetFrame(
      title: '计入规则',
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DudoColors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: DudoColors.surface,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  LucideIcons.listChecks,
                  color: DudoColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '决定哪些阅读行为计入本月目标',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '关闭后该项不再计入目标',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            for (var index = 0; index < texts.length; index++) ...[
              _RuleRow(
                key: ValueKey('reading-goal-rule-$index'),
                text: texts[index],
                selected: _rules[index],
                onTap: () => _toggle(index),
              ),
              if (index != texts.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
        _SheetActionButton(
          key: const ValueKey('reading-goal-rules-save'),
          label: '保存规则',
          icon: LucideIcons.check,
          onTap: () => Navigator.of(context).pop(List<bool>.from(_rules)),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
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
      color: DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? DudoColors.textPrimary
                        : DudoColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? DudoColors.textPrimary
                          : DudoColors.outline,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          color: DudoColors.onInk,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// F10-7 — close goal confirmation
// ---------------------------------------------------------------------------

class _CloseGoalSheet extends StatelessWidget {
  const _CloseGoalSheet({
    required this.targetLabel,
    required this.progressText,
  });

  final String targetLabel;
  final String progressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: DudoColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 12,
              child: Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DudoColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E5C9),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    LucideIcons.power,
                    color: Color(0xFFA0612B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '关闭阅读目标？',
                        style: DudoTextStyles.sans(
                          color: DudoColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '关闭后不再显示目标进度，目标设置与阅读进度会保留。',
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DudoColors.paperBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DudoColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.flag,
                    color: DudoColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '当前目标：每月 $targetLabel · 已完成 $progressText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: _SheetActionButton(
                      label: '取消',
                      fill: DudoColors.surfaceLow,
                      foreground: DudoColors.secondary,
                      radius: 24,
                      height: 48,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetActionButton(
                      key: const ValueKey('reading-goal-close-confirm'),
                      label: '关闭目标',
                      fill: const Color(0xFFA0612B),
                      foreground: DudoColors.onInk,
                      radius: 24,
                      height: 48,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
