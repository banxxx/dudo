import 'package:dudo/shared/widgets/calendar_range_selector/calendar_range_models.dart';
import 'package:dudo/shared/widgets/calendar_range_selector/calendar_range_selector.dart';
import 'package:dudo/shared/widgets/calendar_range_selector/calendar_range_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDateRangeSelection', () {
    test('builds a Monday based week range from an anchor date', () {
      final selection =
          CalendarDateRangeSelection.weekOf(DateTime(2024, 5, 22));

      expect(selection.preset, CalendarRangePreset.week);
      expect(selection.start, DateTime(2024, 5, 20));
      expect(selection.end, DateTime(2024, 5, 26));
      expect(selection.visibleMonth, DateTime(2024, 5));
      expect(selection.dayCount, 7);
    });

    test('builds a full month range', () {
      final selection =
          CalendarDateRangeSelection.monthOf(DateTime(2024, 2, 12));

      expect(selection.preset, CalendarRangePreset.month);
      expect(selection.start, DateTime(2024, 2));
      expect(selection.end, DateTime(2024, 2, 29));
      expect(selection.dayCount, 29);
    });

    test('normalizes custom ranges and detects contained dates', () {
      final selection = CalendarDateRangeSelection.custom(
        start: DateTime(2024, 5, 20, 18),
        end: DateTime(2024, 5, 10, 9),
      );

      expect(selection.start, DateTime(2024, 5, 10));
      expect(selection.end, DateTime(2024, 5, 20));
      expect(selection.contains(DateTime(2024, 5, 15)), isTrue);
      expect(selection.isBoundary(DateTime(2024, 5, 20)), isTrue);
      expect(selection.contains(DateTime(2024, 5, 21)), isFalse);
    });

    test('builds a Monday-first calendar grid', () {
      final grid = buildCalendarMonthGrid(DateTime(2024, 5));

      expect(grid.length, 35);
      expect(grid.first, isNull);
      expect(grid[2], DateTime(2024, 5));
      expect(grid[32], DateTime(2024, 5, 31));
      expect(grid.last, isNull);
    });
  });

  testWidgets('renders selector and navigates months', (tester) async {
    var selection = CalendarDateRangeSelection.weekOf(DateTime(2024, 5, 22));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 420,
                child: CalendarRangeSelector(
                  selection: selection,
                  today: DateTime(2024, 5, 22),
                  onSelectionChanged: (next) =>
                      setState(() => selection = next),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('2024年5月'), findsOneWidget);
    expect(find.text('一'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2024年6月'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-previous-month')));
    await tester.pumpAndSettle();
    expect(find.text('2024年5月'), findsOneWidget);
  });

  testWidgets('switches presets and selects a custom range', (tester) async {
    var selection = CalendarDateRangeSelection.weekOf(DateTime(2024, 5, 22));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 420,
                child: CalendarRangeSelector(
                  selection: selection,
                  today: DateTime(2024, 5, 22),
                  onSelectionChanged: (next) =>
                      setState(() => selection = next),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('本月'));
    await tester.pumpAndSettle();
    expect(selection.preset, CalendarRangePreset.month);
    expect(selection.start, DateTime(2024, 5));
    expect(selection.end, DateTime(2024, 5, 31));

    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-2024-5-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-2024-5-20')));
    await tester.pumpAndSettle();

    expect(selection.preset, CalendarRangePreset.custom);
    expect(selection.start, DateTime(2024, 5, 10));
    expect(selection.end, DateTime(2024, 5, 20));
  });

  testWidgets('sheet returns confirmed selection', (tester) async {
    CalendarDateRangeSelection? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showCalendarRangeSelectorSheet(
                      context: context,
                      initialSelection: CalendarDateRangeSelection.weekOf(
                        DateTime(2024, 5, 22),
                      ),
                      today: DateTime(2024, 5, 22),
                      summaryText: '本周阅读 6h 40m · 连续 5 天',
                    );
                  },
                  child: const Text('打开'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('选择时间'), findsOneWidget);
    expect(find.text('2024年5月'), findsOneWidget);
    expect(find.text('本周阅读 6h 40m · 连续 5 天'), findsOneWidget);

    await tester.tap(find.text('本月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(confirmed?.preset, CalendarRangePreset.month);
    expect(confirmed?.start, DateTime(2024, 5));
    expect(confirmed?.end, DateTime(2024, 5, 31));
  });
}
