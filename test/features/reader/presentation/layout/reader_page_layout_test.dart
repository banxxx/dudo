import 'package:dudo/features/reader/presentation/layout/reader_page_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderPageLayout.pageIndexForPosition', () {
    const pages = [
      ReaderPageSlice(startOffset: 0, endOffset: 10, text: '0'),
      ReaderPageSlice(startOffset: 10, endOffset: 25, text: '1'),
      ReaderPageSlice(startOffset: 30, endOffset: 45, text: '2'),
    ];

    test('returns 0 for an empty page list', () {
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: const [],
          readPosition: 12,
        ),
        0,
      );
    });

    test('maps start and negative positions to the first page', () {
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: -4,
        ),
        0,
      );
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 0,
        ),
        0,
      );
    });

    test('maps exact page starts and page interiors', () {
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 10,
        ),
        1,
      );
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 24,
        ),
        1,
      );
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 30,
        ),
        2,
      );
    });

    test('maps end and oversized positions to the last page', () {
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 45,
        ),
        2,
      );
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 999,
        ),
        2,
      );
    });

    test('maps offset gaps to the nearest previous page', () {
      expect(
        ReaderPageLayout.pageIndexForPosition(
          pages: pages,
          readPosition: 27,
        ),
        1,
      );
    });
  });
}
