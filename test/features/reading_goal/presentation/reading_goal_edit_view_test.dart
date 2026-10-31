import 'package:dudo/features/reading_goal/domain/reading_goal_method.dart';
import 'package:dudo/features/reading_goal/presentation/widgets/reading_goal_edit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The value card sits below the preview and method cards.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('applies a custom goal from the dialog', (tester) async {
    _useTallViewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(_app(onGoalChanged: changes.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();

    expect(find.text('自定义目标'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('reading-goal-custom-field')),
    );
    expect(field.controller?.text, '20');
    expect(find.text('保存后目标为 20 小时 / 月'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reading-goal-custom-field')),
      '36',
    );
    await tester.pump();

    expect(find.text('保存后目标为 36 小时 / 月'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-confirm')));
    await tester.pumpAndSettle();

    expect(changes, [36]);
    expect(find.text('自定义目标'), findsNothing);
  });

  testWidgets('disables confirm for an out-of-range value', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reading-goal-custom-field')),
      '0',
    );
    await tester.pump();

    expect(find.text('可设置 1–999 小时'), findsOneWidget);
    final confirm = tester.widget<TextButton>(
      find.byKey(const ValueKey('reading-goal-custom-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('cancelling leaves the goal unchanged', (tester) async {
    _useTallViewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(_app(onGoalChanged: changes.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-goal-custom-pill')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reading-goal-custom-field')),
      '36',
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.text('自定义目标'), findsNothing);
  });
}

Widget _app({ValueChanged<int>? onGoalChanged}) {
  return MaterialApp(
    home: Scaffold(
      body: ReadingGoalEditView(
        title: '十一月阅读目标',
        method: GoalMethod.duration,
        goalValue: 20,
        methodProgress: const {},
        reminderEnabled: true,
        repeatDays: const {0, 1},
        rules: const [true, true, true],
        onCancel: () {},
        onSave: () {},
        onReset: () {},
        onMethodChanged: (_) {},
        onGoalChanged: onGoalChanged ?? (_) {},
        onReminderChanged: (_) {},
        onRepeatDayToggled: (_) {},
        onRuleToggled: (_) {},
      ),
    ),
  );
}
