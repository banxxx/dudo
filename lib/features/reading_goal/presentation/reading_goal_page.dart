import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../reading_stats/application/reading_stats_provider.dart';
import '../application/reading_goal_providers.dart';
import '../domain/reading_goal.dart';
import '../domain/reading_goal_method.dart';
import '../reading_goal_page_data.dart';
import 'widgets/reading_goal_edit_view.dart';
import 'widgets/reading_goal_overview_view.dart';

class ReadingGoalPage extends ConsumerStatefulWidget {
  const ReadingGoalPage({super.key});

  @override
  ConsumerState<ReadingGoalPage> createState() => _ReadingGoalPageState();
}

class _ReadingGoalPageState extends ConsumerState<ReadingGoalPage> {
  bool _isEditing = false;
  ReadingGoal _goal = ReadingGoal.defaults();

  // Draft state for the edit view; committed to [_goal] on save.
  GoalMethod _method = GoalMethod.duration;
  int _goalValue = GoalMethod.duration.defaultValue;
  bool _reminderEnabled = true;
  Set<int> _repeatDays = Set<int>.from(ReadingGoalPageData.defaultRepeatDays);
  List<bool> _rules = List<bool>.from(ReadingGoalPageData.defaultRules);

  @override
  void initState() {
    super.initState();
    _applyGoal(_goal);
    _loadSavedGoal();
  }

  Future<void> _loadSavedGoal() async {
    final goal = await ref.read(readingGoalProvider.future);
    if (!mounted || _isEditing) return;
    setState(() => _applyGoal(goal));
  }

  void _applyGoal(ReadingGoal goal) {
    _goal = goal;
    _method = goal.method;
    _goalValue = goal.value;
    _reminderEnabled = goal.reminderEnabled;
    _repeatDays = Set<int>.from(goal.repeatDays);
    _rules = List<bool>.from(goal.rules);
  }

  void _openEdit() => setState(() => _isEditing = true);

  void _closeEdit() => setState(() => _isEditing = false);

  Future<void> _saveEdit() async {
    final goal = ReadingGoal(
      method: _method,
      value: _goalValue,
      reminderEnabled: _reminderEnabled,
      repeatDays: Set<int>.from(_repeatDays),
      rules: List<bool>.from(_rules),
    );
    setState(() {
      _goal = goal;
      _isEditing = false;
    });

    try {
      await ref.read(readingGoalRepositoryProvider).saveGoal(goal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('阅读目标已保存')),
      );
    } catch (error, stackTrace) {
      log.w(
        '[reading-goal] failed to save goal',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('阅读目标保存失败，请稍后重试')),
      );
    }
  }

  void _resetEdit() {
    setState(() => _applyGoal(ReadingGoal.defaults()));
  }

  void _changeMethod(GoalMethod method) {
    setState(() {
      _method = method;
      _goalValue = method.defaultValue;
      _rules = List<bool>.from(ReadingGoalPageData.defaultRules);
    });
  }

  void _changeGoal(int value) {
    setState(() =>
        _goalValue = value.clamp(_method.minValue, ReadingGoalPageData.maxValue));
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
    final overviewAsync = ref.watch(readingGoalOverviewProvider);
    final overview = overviewAsync.valueOrNull;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: _isEditing
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _closeEdit();
              },
              child: ReadingGoalEditView(
                title: ReadingGoalPageData.titleFor(
                  ref.watch(readingStatsTodayProvider),
                ),
                method: _method,
                goalValue: _goalValue,
                methodProgress: overview?.methodProgress ?? const {},
                reminderEnabled: _reminderEnabled,
                repeatDays: _repeatDays,
                rules: _rules,
                onCancel: _closeEdit,
                onSave: _saveEdit,
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
          : overviewAsync.when(
              data: (overview) => ReadingGoalOverviewView(
                overview: overview,
                onEdit: _openEdit,
              ),
              loading: () => const _GoalLoadingView(),
              error: (error, stackTrace) => _GoalErrorView(
                onRetry: () => ref.invalidate(readingGoalOverviewProvider),
              ),
            ),
    );
  }
}

class _GoalLoadingView extends StatelessWidget {
  const _GoalLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _GoalErrorView extends StatelessWidget {
  const _GoalErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorStateView(
      title: '阅读目标加载失败',
      message: '请稍后重试',
      action: TextButton(
        onPressed: onRetry,
        child: const Text('重新加载'),
      ),
    );
  }
}
