import 'reader_range.dart';

enum ReaderAnnotationType {
  bookmark,
  highlight,
  note,
}

class ReaderAnnotation {
  const ReaderAnnotation({
    required this.id,
    required this.bookId,
    required this.range,
    required this.type,
    required this.preview,
    required this.createdAt,
    this.note,
    this.color,
  });

  final String id;
  final String bookId;
  final ReaderRange range;
  final ReaderAnnotationType type;
  final String preview;
  final DateTime createdAt;
  final String? note;
  final String? color;
}
