/// The state of a book that is being cached for offline reading.
enum OfflineCacheTaskStatus { queued, downloading, paused, failed }

/// A single book-level cache task.
///
/// [downloadedChapters] and [totalChapters] are optional on purpose: some
/// books expose a usable overall progress without a reliable chapter list. In
/// that case the task UI shows only the percentage instead of inventing a
/// chapter count.
class OfflineCacheTask {
  const OfflineCacheTask({
    required this.bookId,
    required this.title,
    this.author,
    required this.status,
    this.progress,
    this.downloadedChapters,
    this.totalChapters,
    this.message,
    required this.updatedAt,
  });

  final String bookId;
  final String title;
  final String? author;
  final OfflineCacheTaskStatus status;

  /// Overall progress from 0 to 1. Null means the task cannot report a total
  /// yet, so the UI renders an indeterminate bar.
  final double? progress;
  final int? downloadedChapters;
  final int? totalChapters;

  /// Human-readable failure or pause detail.
  final String? message;
  final DateTime updatedAt;

  bool get hasChapterProgress =>
      downloadedChapters != null && totalChapters != null && totalChapters! > 0;

  int? get percent {
    final value = progress;
    if (value == null) return null;
    return (value.clamp(0, 1) * 100).round();
  }

  String get statusLabel => switch (status) {
        OfflineCacheTaskStatus.queued => '等待中',
        OfflineCacheTaskStatus.downloading => '缓存中',
        OfflineCacheTaskStatus.paused => '已暂停',
        OfflineCacheTaskStatus.failed => '缓存失败',
      };

  OfflineCacheTask copyWith({
    OfflineCacheTaskStatus? status,
    double? progress,
    int? downloadedChapters,
    int? totalChapters,
    String? message,
    bool clearMessage = false,
    DateTime? updatedAt,
  }) {
    return OfflineCacheTask(
      bookId: bookId,
      title: title,
      author: author,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
      totalChapters: totalChapters ?? this.totalChapters,
      message: clearMessage ? null : (message ?? this.message),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
