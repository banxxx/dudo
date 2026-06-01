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

class AppMessageRequest {
  const AppMessageRequest({
    required this.title,
    this.description,
    this.kind = AppMessageKind.info,
    this.position = AppMessagePosition.bottom,
    this.size = AppMessageSize.compact,
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
