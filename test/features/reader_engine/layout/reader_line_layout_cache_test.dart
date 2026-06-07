import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderLineLayoutCacheKey', () {
    test('changes when advanced typography settings change', () {
      final settings = ReaderLayoutSettings.fromReaderSettings(
        ReaderSettings.defaults(),
      );

      final baseKey = ReaderLineLayoutCacheKey.fromSettings(
        bookId: 'book-1',
        chapterIndex: 0,
        contentHash: 1,
        viewportWidth: 320,
        viewportHeight: 640,
        settings: settings,
      );
      final changedKey = ReaderLineLayoutCacheKey.fromSettings(
        bookId: 'book-1',
        chapterIndex: 0,
        contentHash: 1,
        viewportWidth: 320,
        viewportHeight: 640,
        settings: settings.copyWith(enableJustify: true),
      );

      expect(changedKey, isNot(baseKey));
    });
  });
}
