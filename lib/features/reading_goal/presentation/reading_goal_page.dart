import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../domain/reading_goal_method.dart';
import '../reading_goal_page_data.dart';
import 'widgets/reading_goal_edit_view.dart';
import 'widgets/reading_goal_overview_view.dart';

class ReadingGoalPage extends StatefulWidget {
  const ReadingGoalPage({super.key});

  @override
  State<ReadingGoalPage> createState() => _ReadingGoalPageState();
}

class _ReadingGoalPageState extends State<ReadingGoalPage> {
  bool _isEditing = false;
  GoalMethod _method = GoalMethod.duration;
  int _goalValue = GoalMethod.duration.defaultValue;
  bool _reminderEnabled = true;
  Set<int> _repeatDays = Set<int>.from(ReadingGoalPageData.defaultRepeatDays);
  List<bool> _rules = List<bool>.from(ReadingGoalPageData.defaultRules);

  void _openEdit() => setState(() => _isEditing = true);

  void _closeEdit() => setState(() => _isEditing = false);

  void _resetEdit() {
    setState(() {
      _method = GoalMethod.duration;
      _goalValue = _method.defaultValue;
      _reminderEnabled = true;
      _repeatDays = Set<int>.from(ReadingGoalPageData.defaultRepeatDays);
      _rules = List<bool>.from(ReadingGoalPageData.defaultRules);
    });
  }

  void _changeMethod(GoalMethod method) {
    setState(() {
      _method = method;
      _goalValue = method.defaultValue;
      _rules = List<bool>.from(ReadingGoalPageData.defaultRules);
    });
  }

  void _changeGoal(int value) {
    setState(() => _goalValue = value.clamp(_method.minValue, 999));
  }

  void _toggleRepeatDay(int index) {
    setState(() {
      final days = Set<int>.from(_repeatDays);
      days.contains(index) ? days.remove(index) : days.add(index);
      _repeatDays = days;
    });
  }

  void _toggleRule(int index) {
    setState(() => _rules[index] = !_rules[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: _isEditing
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _closeEdit();
              },
              child: ReadingGoalEditView(
                method: _method,
                goalValue: _goalValue,
                reminderEnabled: _reminderEnabled,
                repeatDays: _repeatDays,
                rules: _rules,
                onCancel: _closeEdit,
                onSave: _closeEdit,
                onReset: _resetEdit,
                onMethodChanged: _changeMethod,
                onGoalChanged: _changeGoal,
                onReminderChanged: (value) {
                  setState(() => _reminderEnabled = value);
                },
                onRepeatDayToggled: _toggleRepeatDay,
                onRuleToggled: _toggleRule,
              ),
            )
          : ReadingGoalOverviewView(onEdit: _openEdit),
    );
  }
}
