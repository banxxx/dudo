import 'reader_location.dart';

class ReaderRange {
  const ReaderRange({
    required this.start,
    required this.end,
  });

  factory ReaderRange.normalized({
    required ReaderLocation first,
    required ReaderLocation second,
  }) {
    if (first.bookId != second.bookId) {
      throw ArgumentError('ReaderRange cannot cross books.');
    }
    return first.compareTo(second) <= 0
        ? ReaderRange(start: first, end: second)
        : ReaderRange(start: second, end: first);
  }

  final ReaderLocation start;
  final ReaderLocation end;

  bool get isCollapsed => start == end;
  bool get isWithinSingleChapter => start.isSameChapter(end);

  bool contains(ReaderLocation location) {
    if (location.bookId != start.bookId) return false;
    return start.compareTo(location) <= 0 && end.compareTo(location) >= 0;
  }
}
