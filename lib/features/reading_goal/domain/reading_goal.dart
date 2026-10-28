import 'reading_goal_method.dart';

/// The user's monthly reading goal, persisted in the `app_preferences` table.
class ReadingGoal {
  const ReadingGoal({
    required this.method,
    required this.value,
    required this.reminderEnabled,
    required this.repeatDays,
    required this.rules,
  });

  factory ReadingGoal.defaults() {
    return const ReadingGoal(
      method: GoalMethod.duration,
      value: 20,
      reminderEnabled: true,
      repeatDays: {0, 1, 2, 3, 4, 5},
      rules: [true, true, true],
    );
  }

  /// Restores a goal from its JSON form, falling back to the defaults for any
  /// field that is missing or malformed.
  factory ReadingGoal.fromJson(Object? json) {
    final defaults = ReadingGoal.defaults();
    if (json is! Map) return defaults;

    final method = GoalMethod.values.firstWhere(
      (value) => value.name == json['method'],
      orElse: () => defaults.method,
    );
    final value = json['value'];
    final repeatDays = json['repeatDays'];
    final rules = json['rules'];

    return ReadingGoal(
      method: method,
      value: value is int && value > 0 ? value : defaults.value,
      reminderEnabled: json['reminderEnabled'] is bool
          ? json['reminderEnabled'] as bool
          : defaults.reminderEnabled,
      repeatDays: repeatDays is List
          ? repeatDays
              .whereType<int>()
              .where((day) => day >= 0 && day < 7)
              .toSet()
          : defaults.repeatDays,
      rules: rules is List
          ? rules.map((rule) => rule == true).toList()
          : defaults.rules,
    );
  }

  static const String preferenceKey = 'reading.goal';

  final GoalMethod method;

  /// Target in [method]'s unit: hours, chapters or pages.
  final int value;
  final bool reminderEnabled;

  /// Weekdays the reminder repeats on, 0 = Monday.
  final Set<int> repeatDays;
  final List<bool> rules;

  ReadingGoal copyWith({
    GoalMethod? method,
    int? value,
    bool? reminderEnabled,
    Set<int>? repeatDays,
    List<bool>? rules,
  }) {
    return ReadingGoal(
      method: method ?? this.method,
      value: value ?? this.value,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      rules: rules ?? this.rules,
    );
  }

  Map<String, Object?> toJson() {
    final days = repeatDays.toList()..sort();
    return {
      'method': method.name,
      'value': value,
      'reminderEnabled': reminderEnabled,
      'repeatDays': days,
      'rules': rules,
    };
  }
}
