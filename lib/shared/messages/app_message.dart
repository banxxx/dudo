enum AppMessageKind {
  info,
  success,
  warning,
  error,
  loading,
}

enum AppMessagePosition {
  top,
  center,
  bottom,
}

enum AppMessageSize {
  compact,
  dialog,
}

enum AppMessageVisualStyle {
  paper,
  filled,
}

class AppMessageRequest {
  const AppMessageRequest({
    required this.title,
    this.description,
    this.kind = AppMessageKind.info,
    this.position = AppMessagePosition.bottom,
    this.size = AppMessageSize.compact,
    this.visualStyle = AppMessageVisualStyle.paper,
    this.actionLabel,
    this.onAction,
    this.duration,
    this.dedupeKey,
    this.replaceExisting = false,
    this.dismissible = true,
  });

  final String title;
  final String? description;
  final AppMessageKind kind;
  final AppMessagePosition position;
  final AppMessageSize size;
  final AppMessageVisualStyle visualStyle;
  final String? actionLabel;
  final void Function()? onAction;
  final Duration? duration;
  final String? dedupeKey;
  final bool replaceExisting;
  final bool dismissible;

  String get effectiveKey =>
      dedupeKey ??
      [
        kind.name,
        position.name,
        size.name,
        visualStyle.name,
        actionLabel ?? '',
        title,
        description ?? '',
      ].join('|');

  Duration? get effectiveDuration {
    if (duration != null) return duration;
    return switch (kind) {
      AppMessageKind.loading => null,
      AppMessageKind.error => const Duration(seconds: 5),
      _ => const Duration(seconds: 3),
    };
  }
}
