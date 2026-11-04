import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../reading_stats/application/reading_stats_provider.dart';
import '../application/reading_goal_overview.dart';
import '../application/reading_goal_providers.dart';
import '../domain/reading_goal.dart';
import '../domain/reading_goal_method.dart';
import '../reading_goal_page_data.dart';
import 'widgets/reading_goal_edit_view.dart';
import 'widgets/reading_goal_overview_view.dart';
import 'widgets/reading_goal_sheets.dart';

class ReadingGoalPage extends ConsumerStatefulWidget {
  const ReadingGoalPage({super.key});

  @override
  ConsumerState<ReadingGoalPage> createState() => _ReadingGoalPageState();
}

class _ReadingGoalPageState extends ConsumerState<ReadingGoalPage> {
  /// The saved goal, or `null` before the user has set one. A missing goal
  /// opens the page straight in the edit flow.
  ReadingGoal? _goal;
  bool _isEditing = false;

  // Draft state for the edit view; committed to [_goal] on save.
  GoalMethod _method = GoalMethod.duration;
  int _goalValue = GoalMethod.duration.defaultValue;
  bool _reminderEnabled = true;
  int _reminderMinutes = ReadingGoal.defaults().reminderMinutes;
  Set<int> _repeatDays = Set<int>.from(ReadingGoalPageData.defaultRepeatDays);
  List<bool> _rules = List<bool>.from(ReadingGoalPageData.defaultRules);

  @override
  void initState() {
    super.initState();
    _loadSavedGoal();
  }

  Future<void> _loadSavedGoal() async {
    final goal = await ref.read(readingGoalProvider.future);
    if (!mounted) return;
    setState(() {
      _goal = goal;
      // Keep a draft the user has already started untouched.
      if (_isEditing) return;
      if (goal == null) {
        _applyGoal(ReadingGoal.defaults());
        _isEditing = true;
      } else {
        _applyGoal(goal);
        // A closed goal keeps its plan, so open the edit view seeded with the
        // saved settings and let the footer re-open it.
        _isEditing = !goal.enabled;
      }
    });
  }

  void _applyGoal(ReadingGoal goal) {
    _method = goal.method;
    _goalValue = goal.value;
    _reminderEnabled = goal.reminderEnabled;
    _reminderMinutes = goal.reminderMinutes;
    _repeatDays = Set<int>.from(goal.repeatDays);
    _rules = List<bool>.from(goal.rules);
  }

  Future<void> _openEdit() async {
    // The overview can paint from its cached value before the goal stream has
    // emitted, so wait for the saved goal before seeding the draft.
    final saved = _goal ?? await ref.read(readingGoalProvider.future);
    if (!mounted) return;
    setState(() {
      _applyGoal(saved ?? ReadingGoal.defaults());
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    final goal = _goal;
    if (goal == null || !goal.enabled) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _applyGoal(goal);
      _isEditing = false;
    });
  }

  Future<void> _saveEdit() async {
    final goal = ReadingGoal(
      method: _method,
      value: _goalValue,
      reminderEnabled: _reminderEnabled,
      reminderMinutes: _reminderMinutes,
      repeatDays: Set<int>.from(_repeatDays),
      rules: List<bool>.from(_rules),
      enabled: true,
    );
    try {
      await ref.read(readingGoalRepositoryProvider).saveGoal(goal);
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
      return;
    }

    // Saving makes the goal stream emit, which reloads the overview. Wait for
    // the refreshed overview before leaving the edit view so the hand-over
    // never lands on the loading placeholder and flashes a blank page.
    try {
      await ref.read(readingGoalOverviewProvider.future);
    } catch (_) {
      // A failed overview load renders its own error view.
    }

    if (!mounted) return;
    setState(() {
      _goal = goal;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('阅读目标已保存')),
    );
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
    setState(() => _goalValue =
        value.clamp(_method.minValue, ReadingGoalPageData.maxValue));
  }

  void _changeReminder(ReadingGoalReminderDraft draft) {
    setState(() {
      _reminderEnabled = draft.enabled;
      _reminderMinutes = draft.minutes;
      _repeatDays = Set<int>.from(draft.repeatDays);
    });
  }

  void _changeRules(List<bool> rules) {
    setState(() => _rules = List<bool>.from(rules));
  }

  /// The preview disc mirrors the saved method's progress: a percentage for
  /// time, the counted chapters or pages otherwise.
  String _previewProgress(ReadingGoalOverview? overview) {
    if (_method == GoalMethod.duration) {
      return overview?.progressPercentText ?? '0%';
    }
    return overview?.methodProgress[_method] ?? '0';
  }

  Future<void> _requestCloseGoal() async {
    final goal = _goal;
    if (goal == null) return;
    final overview = ref.read(readingGoalOverviewProvider).valueOrNull;
    final confirmed = await showReadingGoalCloseSheet(
      context,
      targetLabel: '${goal.value} ${goal.method.unit}',
      progressText: overview?.progressPercentText ?? '0%',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(readingGoalRepositoryProvider).setEnabled(false);
    } catch (error, stackTrace) {
      log.w(
        '[reading-goal] failed to close goal',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('关闭目标失败，请稍后重试')),
      );
      return;
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(readingGoalOverviewProvider);
    final overview = overviewAsync.valueOrNull;
    final today = ref.watch(readingStatsTodayProvider);

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: _isEditing
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _cancelEdit();
              },
              child: ReadingGoalEditView(
                title: ReadingGoalPageData.titleFor(today),
                method: _method,
                goalValue: _goalValue,
                progressText: _previewProgress(overview),
                daysInMonth: ReadingGoalPageData.daysInMonth(today),
                reminderEnabled: _reminderEnabled,
                reminderMinutes: _reminderMinutes,
                repeatDays: _repeatDays,
                rules: _rules,
                onCancel: _cancelEdit,
                onSave: _saveEdit,
                onReset: _resetEdit,
                onGoalAction: _goal == null
                    ? null
                    : _goal!.enabled
                        ? _requestCloseGoal
                        : _saveEdit,
                goalActionLabel:
                    _goal != null && !_goal!.enabled ? '开启目标' : '关闭目标',
                onMethodChanged: _changeMethod,
                onGoalChanged: _changeGoal,
                onReminderChanged: _changeReminder,
                onRulesChanged: _changeRules,
              ),
            )
          : overviewAsync.when(
              // A save reloads the overview through the goal stream. Keeping
              // the last overview on screen during that reload avoids a blank
              // loading frame between the edit view and the overview.
              skipLoadingOnReload: true,
              data: (overview) => overview == null
                  ? const _GoalLoadingView()
                  : ReadingGoalOverviewView(
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
