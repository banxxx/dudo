import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderLocation', () {
    test('clamps chapter and offset to safe bounds', () {
      const location = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 99,
        offset: -12,
      );

      final clamped = location.clamp(chapterCount: 3, maxOffset: 120);

      expect(clamped.chapterIndex, 2);
      expect(clamped.offset, 0);
    });

    test('compares locations inside the same book', () {
      const first = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 1,
        offset: 20,
      );
      const second = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 2,
        offset: 0,
      );

      expect(first.compareTo(second), lessThan(0));
    });
  });

  group('ReaderRange', () {
    test('normalizes reversed locations', () {
      const later = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 2,
        offset: 0,
      );
      const earlier = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 1,
        offset: 20,
      );

      final range = ReaderRange.normalized(first: later, second: earlier);

      expect(range.start, earlier);
      expect(range.end, later);
      expect(range.isWithinSingleChapter, isFalse);
    });

    test('checks containment across chapters', () {
      final range = ReaderRange.normalized(
        first: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 20,
        ),
        second: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 2,
          offset: 8,
        ),
      );

      expect(
        range.contains(
          const ReaderLocation(
            bookId: 'book-1',
            chapterIndex: 2,
            offset: 3,
          ),
        ),
        isTrue,
      );
      expect(
        range.contains(
          const ReaderLocation(
            bookId: 'book-1',
            chapterIndex: 2,
            offset: 9,
          ),
        ),
        isFalse,
      );
    });
  });
}
