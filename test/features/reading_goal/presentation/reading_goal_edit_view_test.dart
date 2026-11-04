import 'package:dudo/features/reading_goal/domain/reading_goal_method.dart';
import 'package:dudo/features/reading_goal/presentation/widgets/reading_goal_edit_view.dart';
import 'package:dudo/features/reading_goal/presentation/widgets/reading_goal_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the F10-1 edit design', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('编辑目标'), findsOneWidget);
    expect(find.text('关闭目标'), findsOneWidget);
    expect(find.text('十一月阅读目标'), findsOneWidget);
    expect(find.text('20 小时 / 月'), findsOneWidget);
    expect(find.text('阅读时长统计 · 每天约 39 分钟'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('统计方式'), findsOneWidget);
    expect(find.text('目标数值'), findsOneWidget);
    expect(find.text('阅读时长 · 月度'), findsOneWidget);
    expect(find.text('阅读提醒'), findsOneWidget);
    expect(find.text('每日 21:30 · 周一至周六'), findsOneWidget);
    expect(find.text('计入规则'), findsOneWidget);
    expect(find.text('3 项已开启'), findsOneWidget);
    expect(find.text('恢复默认'), findsOneWidget);
    expect(find.text('保存目标'), findsOneWidget);
  });

  testWidgets('applies a custom goal from the keypad sheet', (tester) async {
    _useTallViewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(_app(onGoalChanged: changes.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();

    expect(find.text('自定义目标数值'), findsOneWidget);
    expect(find.text('推荐 15–30 小时 · 按最近 7 天读速估算'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-keypad-clear')));
    await tester.tap(find.byKey(const ValueKey('reading-goal-keypad-3')));
    await tester.tap(find.byKey(const ValueKey('reading-goal-keypad-6')));
    await tester.pump();

    expect(find.text('应用 36 小时'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-value-apply')));
    await tester.pumpAndSettle();

    expect(changes, [36]);
    expect(find.text('自定义目标数值'), findsNothing);
  });

  testWidgets('a quick value fills the keypad sheet', (tester) async {
    _useTallViewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(_app(onGoalChanged: changes.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reading-goal-quick-30')));
    await tester.pump();

    expect(find.text('应用 30 小时'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reading-goal-value-apply')));
    await tester.pumpAndSettle();

    expect(changes, [30]);
  });

  testWidgets('does not apply an out-of-range value', (tester) async {
    _useTallViewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(_app(onGoalChanged: changes.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reading-goal-keypad-clear')));
    await tester.tap(find.byKey(const ValueKey('reading-goal-keypad-0')));
    await tester.pump();

    expect(find.text('应用 0 小时'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reading-goal-value-apply')));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.text('自定义目标数值'), findsOneWidget);
  });

  testWidgets('edits the reminder in the F10-5 sheet', (tester) async {
    _useTallViewport(tester);
    final reminders = <ReadingGoalReminderDraft>[];
    await tester.pumpWidget(_app(onReminderChanged: reminders.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-reminder-row')));
    await tester.pumpAndSettle();

    expect(find.text('设置阅读提醒'), findsOneWidget);
    expect(find.text('每日 21:30 提醒'), findsOneWidget);
    expect(find.text('周一至周六 · 睡前轻读'), findsOneWidget);

    await tester.tap(find.text('午休'));
    await tester.pumpAndSettle();
    expect(find.text('每日 12:40 提醒'), findsOneWidget);

    await tester.tap(find.text('日'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-reminder-save')));
    await tester.pumpAndSettle();

    expect(reminders, hasLength(1));
    expect(reminders.single.enabled, isTrue);
    expect(reminders.single.minutes, 12 * 60 + 40);
    expect(reminders.single.repeatDays, {0, 1, 2, 3, 4, 5, 6});
  });

  testWidgets('edits the counting rules in the F10-6 sheet', (tester) async {
    _useTallViewport(tester);
    final rules = <List<bool>>[];
    await tester.pumpWidget(_app(onRulesChanged: rules.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-rules-row')));
    await tester.pumpAndSettle();

    expect(find.text('决定哪些阅读行为计入本月目标'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-rule-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reading-goal-rules-save')));
    await tester.pumpAndSettle();

    expect(rules, [
      [true, false, true],
    ]);
  });

  testWidgets('the header close action requests closing the goal',
      (tester) async {
    _useTallViewport(tester);
    var closeRequests = 0;
    await tester.pumpWidget(_app(onGoalAction: () => closeRequests++));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-close-action')));
    await tester.pump();

    expect(closeRequests, 1);
  });

  testWidgets('the header action re-opens a closed goal', (tester) async {
    _useTallViewport(tester);
    var openRequests = 0;
    await tester.pumpWidget(
      _app(
        onGoalAction: () => openRequests++,
        goalActionLabel: '开启目标',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('开启目标'), findsOneWidget);
    expect(find.text('关闭目标'), findsNothing);
    // Re-opening uses the header action; the footer stays the normal save.
    expect(find.text('保存目标'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-close-action')));
    await tester.pump();

    expect(openRequests, 1);
  });
}

Widget _app({
  ValueChanged<int>? onGoalChanged,
  ValueChanged<ReadingGoalReminderDraft>? onReminderChanged,
  ValueChanged<List<bool>>? onRulesChanged,
  VoidCallback? onGoalAction,
  String goalActionLabel = '关闭目标',
}) {
  return MaterialApp(
    home: Scaffold(
      body: ReadingGoalEditView(
        title: '十一月阅读目标',
        method: GoalMethod.duration,
        goalValue: 20,
        progressText: '78%',
        daysInMonth: 31,
        reminderEnabled: true,
        reminderMinutes: 21 * 60 + 30,
        repeatDays: const {0, 1, 2, 3, 4, 5},
        rules: const [true, true, true],
        onCancel: () {},
        onSave: () {},
        onReset: () {},
        onGoalAction: onGoalAction ?? () {},
        goalActionLabel: goalActionLabel,
        onMethodChanged: (_) {},
        onGoalChanged: onGoalChanged ?? (_) {},
        onReminderChanged: onReminderChanged ?? (_) {},
        onRulesChanged: onRulesChanged ?? (_) {},
      ),
    ),
  );
}
