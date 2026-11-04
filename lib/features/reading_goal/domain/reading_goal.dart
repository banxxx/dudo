import 'reading_goal_method.dart';

/// The user's monthly reading goal, persisted in the `app_preferences` table.
class ReadingGoal {
  const ReadingGoal({
    required this.method,
    required this.value,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.repeatDays,
    required this.rules,
    this.enabled = true,
  });

  factory ReadingGoal.defaults() {
    return const ReadingGoal(
      method: GoalMethod.duration,
      value: 20,
      reminderEnabled: true,
      reminderMinutes: 21 * 60 + 30,
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
    final reminderMinutes = json['reminderMinutes'];
    final repeatDays = json['repeatDays'];
    final rules = json['rules'];

    return ReadingGoal(
      method: method,
      value: value is int && value > 0 ? value : defaults.value,
      reminderEnabled: json['reminderEnabled'] is bool
          ? json['reminderEnabled'] as bool
          : defaults.reminderEnabled,
      reminderMinutes: reminderMinutes is int &&
              reminderMinutes >= 0 &&
              reminderMinutes < 24 * 60
          ? reminderMinutes
          : defaults.reminderMinutes,
      repeatDays: repeatDays is List
          ? repeatDays
              .whereType<int>()
              .where((day) => day >= 0 && day < 7)
              .toSet()
          : defaults.repeatDays,
      rules: rules is List
          ? rules.map((rule) => rule == true).toList()
          : defaults.rules,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
    );
  }

  static const String preferenceKey = 'reading.goal';

  final GoalMethod method;

  /// Target in [method]'s unit: hours, chapters or pages.
  final int value;
  final bool reminderEnabled;

  /// Reminder time as minutes since midnight (0–1439).
  final int reminderMinutes;

  /// Weekdays the reminder repeats on, 0 = Monday.
  final Set<int> repeatDays;
  final List<bool> rules;

  /// Whether the goal is currently active. Closing a goal only flips this
  /// flag: the plan, reminder and rules stay saved so re-opening restores the
  /// user's setup instead of starting from the defaults.
  final bool enabled;

  ReadingGoal copyWith({
    GoalMethod? method,
    int? value,
    bool? reminderEnabled,
    int? reminderMinutes,
    Set<int>? repeatDays,
    List<bool>? rules,
    bool? enabled,
  }) {
    return ReadingGoal(
      method: method ?? this.method,
      value: value ?? this.value,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
      rules: rules ?? this.rules,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() {
    final days = repeatDays.toList()..sort();
    return {
      'method': method.name,
      'value': value,
      'reminderEnabled': reminderEnabled,
      'reminderMinutes': reminderMinutes,
      'repeatDays': days,
      'rules': rules,
      'enabled': enabled,
    };
  }
}
