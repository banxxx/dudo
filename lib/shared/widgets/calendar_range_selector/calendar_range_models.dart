import 'package:flutter/material.dart';

enum CalendarRangePreset { week, month, custom }

@immutable
class CalendarDateRangeSelection {
  CalendarDateRangeSelection({
    required this.preset,
    required DateTime start,
    required DateTime end,
    required DateTime visibleMonth,
  })  : start = DateUtils.dateOnly(start.isAfter(end) ? end : start),
        end = DateUtils.dateOnly(start.isAfter(end) ? start : end),
        visibleMonth = DateTime(visibleMonth.year, visibleMonth.month);

  factory CalendarDateRangeSelection.weekOf(
    DateTime anchor, {
    int firstDayOfWeek = DateTime.monday,
  }) {
    final date = DateUtils.dateOnly(anchor);
    final offset = (date.weekday - firstDayOfWeek) % DateTime.daysPerWeek;
    final start = date.subtract(Duration(days: offset));
    final end = start.add(const Duration(days: DateTime.daysPerWeek - 1));

    return CalendarDateRangeSelection(
      preset: CalendarRangePreset.week,
      start: start,
      end: end,
      visibleMonth: date,
    );
  }

  factory CalendarDateRangeSelection.monthOf(DateTime anchor) {
    final month = DateTime(anchor.year, anchor.month);

    return CalendarDateRangeSelection(
      preset: CalendarRangePreset.month,
      start: month,
      end: DateTime(
        month.year,
        month.month,
        DateUtils.getDaysInMonth(month.year, month.month),
      ),
      visibleMonth: month,
    );
  }

  factory CalendarDateRangeSelection.custom({
    required DateTime start,
    required DateTime end,
    DateTime? visibleMonth,
  }) {
    return CalendarDateRangeSelection(
      preset: CalendarRangePreset.custom,
      start: start,
      end: end,
      visibleMonth: visibleMonth ?? start,
    );
  }

  final CalendarRangePreset preset;
  final DateTime start;
  final DateTime end;
  final DateTime visibleMonth;

  int get dayCount => end.difference(start).inDays + 1;

  String get presetLabel {
    switch (preset) {
      case CalendarRangePreset.week:
        return '本周';
      case CalendarRangePreset.month:
        return '本月';
      case CalendarRangePreset.custom:
        return '自定义';
    }
  }

  bool contains(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool isBoundary(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return DateUtils.isSameDay(day, start) || DateUtils.isSameDay(day, end);
  }

  CalendarDateRangeSelection copyWith({
    CalendarRangePreset? preset,
    DateTime? start,
    DateTime? end,
    DateTime? visibleMonth,
  }) {
    return CalendarDateRangeSelection(
      preset: preset ?? this.preset,
      start: start ?? this.start,
      end: end ?? this.end,
      visibleMonth: visibleMonth ?? this.visibleMonth,
    );
  }

  CalendarDateRangeSelection withVisibleMonth(DateTime month) {
    return copyWith(visibleMonth: DateTime(month.year, month.month));
  }
}

List<DateTime?> buildCalendarMonthGrid(
  DateTime visibleMonth, {
  int firstDayOfWeek = DateTime.monday,
}) {
  final month = DateTime(visibleMonth.year, visibleMonth.month);
  final offset = (month.weekday - firstDayOfWeek) % DateTime.daysPerWeek;
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;

  return List<DateTime?>.generate(totalCells, (index) {
    final day = index - offset + 1;
    if (day < 1 || day > daysInMonth) return null;
    return DateTime(month.year, month.month, day);
  });
}

String formatCalendarMonthTitle(DateTime month) =>
    '${month.year}年${month.month}月';
