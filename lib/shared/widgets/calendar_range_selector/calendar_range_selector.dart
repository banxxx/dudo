import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import 'calendar_range_models.dart';

class CalendarRangeSelector extends StatefulWidget {
  const CalendarRangeSelector({
    super.key,
    required this.selection,
    required this.onSelectionChanged,
    this.today,
    this.minDate,
    this.maxDate,
    this.summaryText,
    this.onConfirm,
    this.onCancel,
  });

  final CalendarDateRangeSelection selection;
  final ValueChanged<CalendarDateRangeSelection> onSelectionChanged;
  final DateTime? today;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String? summaryText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  State<CalendarRangeSelector> createState() => _CalendarRangeSelectorState();
}

class _CalendarRangeSelectorState extends State<CalendarRangeSelector> {
  DateTime? _customStart;
  bool _selectingCustomEnd = false;

  DateTime get _today => DateUtils.dateOnly(widget.today ?? DateTime.now());

  @override
  void didUpdateWidget(CalendarRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.preset != widget.selection.preset &&
        widget.selection.preset != CalendarRangePreset.custom) {
      _customStart = null;
      _selectingCustomEnd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = widget.summaryText;

    return Column(
      children: [
        _PresetSwitch(
          selected: widget.selection.preset,
          onChanged: _handlePresetChanged,
        ),
        const SizedBox(height: 16),
        _CalendarHeader(
          visibleMonth: widget.selection.visibleMonth,
          onPrevious: () => _handleVisibleMonthChanged(-1),
          onNext: () => _handleVisibleMonthChanged(1),
        ),
        const SizedBox(height: 12),
        const _CalendarWeekdays(),
        const SizedBox(height: 8),
        Expanded(
          child: _CalendarGrid(
            selection: widget.selection,
            minDate: widget.minDate,
            maxDate: widget.maxDate,
            onDayTap: _handleDayTap,
          ),
        ),
        if (summaryText != null || widget.onConfirm != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (summaryText != null)
                Expanded(
                  child: Text(
                    summaryText,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (widget.onConfirm != null)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DudoColors.textPrimary,
                    foregroundColor: DudoColors.surfaceHigh,
                    minimumSize: const Size(88, 42),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.full,
                    ),
                  ),
                  onPressed: widget.onConfirm,
                  child: const Text('确认'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _handlePresetChanged(CalendarRangePreset preset) {
    final selection = switch (preset) {
      CalendarRangePreset.week => CalendarDateRangeSelection.weekOf(_today),
      CalendarRangePreset.month => CalendarDateRangeSelection.monthOf(_today),
      CalendarRangePreset.custom => CalendarDateRangeSelection.custom(
          start: widget.selection.start,
          end: widget.selection.end,
          visibleMonth: widget.selection.visibleMonth,
        ),
    };

    _customStart = null;
    _selectingCustomEnd = false;
    widget.onSelectionChanged(_clampSelection(selection));
  }

  void _handleVisibleMonthChanged(int delta) {
    final month = widget.selection.visibleMonth;
    widget.onSelectionChanged(
      widget.selection
          .withVisibleMonth(DateTime(month.year, month.month + delta)),
    );
  }

  void _handleDayTap(DateTime day) {
    if (_isDisabled(day)) return;

    final selectedDay = DateUtils.dateOnly(day);
    CalendarDateRangeSelection next;

    if (widget.selection.preset != CalendarRangePreset.custom) {
      next = CalendarDateRangeSelection.custom(
        start: selectedDay,
        end: selectedDay,
        visibleMonth: widget.selection.visibleMonth,
      );
      _customStart = selectedDay;
      _selectingCustomEnd = true;
    } else if (!_selectingCustomEnd || _customStart == null) {
      next = CalendarDateRangeSelection.custom(
        start: selectedDay,
        end: selectedDay,
        visibleMonth: widget.selection.visibleMonth,
      );
      _customStart = selectedDay;
      _selectingCustomEnd = true;
    } else {
      next = CalendarDateRangeSelection.custom(
        start: _customStart!,
        end: selectedDay,
        visibleMonth: widget.selection.visibleMonth,
      );
      _customStart = null;
      _selectingCustomEnd = false;
    }

    widget.onSelectionChanged(_clampSelection(next));
  }

  CalendarDateRangeSelection _clampSelection(
      CalendarDateRangeSelection selection) {
    var start = selection.start;
    var end = selection.end;
    final minDate =
        widget.minDate == null ? null : DateUtils.dateOnly(widget.minDate!);
    final maxDate =
        widget.maxDate == null ? null : DateUtils.dateOnly(widget.maxDate!);

    if (minDate != null) {
      if (start.isBefore(minDate)) start = minDate;
      if (end.isBefore(minDate)) end = minDate;
    }
    if (maxDate != null) {
      if (start.isAfter(maxDate)) start = maxDate;
      if (end.isAfter(maxDate)) end = maxDate;
    }

    return CalendarDateRangeSelection(
      preset: selection.preset,
      start: start,
      end: end,
      visibleMonth: selection.visibleMonth,
    );
  }

  bool _isDisabled(DateTime day) {
    final date = DateUtils.dateOnly(day);
    final minDate =
        widget.minDate == null ? null : DateUtils.dateOnly(widget.minDate!);
    final maxDate =
        widget.maxDate == null ? null : DateUtils.dateOnly(widget.maxDate!);
    return (minDate != null && date.isBefore(minDate)) ||
        (maxDate != null && date.isAfter(maxDate));
  }
}

class _PresetSwitch extends StatelessWidget {
  const _PresetSwitch({required this.selected, required this.onChanged});

  final CalendarRangePreset selected;
  final ValueChanged<CalendarRangePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: AppRadius.full,
      ),
      child: Row(
        children: [
          for (final preset in CalendarRangePreset.values)
            _PresetButton(
              label: preset.presetLabel,
              selected: selected == preset,
              onTap: () => onChanged(preset),
            ),
        ],
      ),
    );
  }
}

extension on CalendarRangePreset {
  String get presetLabel {
    switch (this) {
      case CalendarRangePreset.week:
        return '本周';
      case CalendarRangePreset.month:
        return '本月';
      case CalendarRangePreset.custom:
        return '自定义';
    }
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: AppRadius.full,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.surfaceHigh : Colors.transparent,
            borderRadius: AppRadius.full,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1425251F),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.textPrimary : DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.visibleMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime visibleMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CalendarArrowButton(
          key: const ValueKey('calendar-previous-month'),
          icon: LucideIcons.chevronLeft,
          onTap: onPrevious,
        ),
        Expanded(
          child: Center(
            child: Text(
              formatCalendarMonthTitle(visibleMonth),
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        _CalendarArrowButton(
          key: const ValueKey('calendar-next-month'),
          icon: LucideIcons.chevronRight,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: DudoColors.secondary, size: 19),
      ),
    );
  }
}

class _CalendarWeekdays extends StatelessWidget {
  const _CalendarWeekdays();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.selection,
    required this.onDayTap,
    this.minDate,
    this.maxDate,
  });

  final CalendarDateRangeSelection selection;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? minDate;
  final DateTime? maxDate;

  @override
  Widget build(BuildContext context) {
    final days = buildCalendarMonthGrid(selection.visibleMonth);
    final rows = <Widget>[];

    for (var row = 0; row < days.length / DateTime.daysPerWeek; row++) {
      final rowDays =
          days.skip(row * DateTime.daysPerWeek).take(DateTime.daysPerWeek);
      rows.add(
        Expanded(
          child: Row(
            children: [
              for (final day in rowDays)
                Expanded(
                  child: day == null
                      ? const SizedBox.shrink()
                      : _CalendarDay(
                          day: day,
                          selected: selection.isBoundary(day),
                          ranged: selection.contains(day),
                          disabled: _isDisabled(day),
                          onTap: () => onDayTap(day),
                        ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  bool _isDisabled(DateTime day) {
    final date = DateUtils.dateOnly(day);
    final min = minDate == null ? null : DateUtils.dateOnly(minDate!);
    final max = maxDate == null ? null : DateUtils.dateOnly(maxDate!);
    return (min != null && date.isBefore(min)) ||
        (max != null && date.isAfter(max));
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.selected,
    required this.ranged,
    required this.disabled,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool ranged;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fillColor = disabled
        ? Colors.transparent
        : selected
            ? DudoColors.primary
            : ranged
                ? DudoColors.primaryContainer
                : Colors.transparent;
    final Color textColor = disabled
        ? DudoColors.outline
        : selected
            ? DudoColors.surfaceHigh
            : ranged
                ? DudoColors.primaryDark
                : DudoColors.textPrimary;

    return Center(
      child: InkWell(
        key: ValueKey('calendar-day-${day.year}-${day.month}-${day.day}'),
        borderRadius: BorderRadius.circular(18),
        onTap: disabled ? null : onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${day.day}',
            style: DudoTextStyles.numeric(
              color: textColor,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
