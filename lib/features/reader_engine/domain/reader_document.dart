import 'reader_source_type.dart';

class ReaderDocument {
  const ReaderDocument({
    required this.bookId,
    required this.title,
    required this.sourceType,
    required this.chapterCount,
    this.metadata = const {},
  });

  final String bookId;
  final String title;
  final ReaderSourceType sourceType;
  final int chapterCount;
  final Map<String, Object?> metadata;

  ReaderDocument copyWith({
    String? bookId,
    String? title,
    ReaderSourceType? sourceType,
    int? chapterCount,
    Map<String, Object?>? metadata,
  }) {
    return ReaderDocument(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      chapterCount: chapterCount ?? this.chapterCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
