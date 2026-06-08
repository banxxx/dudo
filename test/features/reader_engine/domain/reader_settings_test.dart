import 'package:flutter_test/flutter_test.dart';

import 'package:dudo/features/reader_engine/domain/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('clamps font size to reader-supported range', () {
      expect(ReaderSettings.clampFontSize(8), 10);
      expect(ReaderSettings.clampFontSize(18), 18);
      expect(ReaderSettings.clampFontSize(48), 45);
    });

    test('clamps paragraph spacing to reader-supported range', () {
      expect(ReaderSettings.clampParagraphSpacing(-4), 0);
      expect(ReaderSettings.clampParagraphSpacing(15), 15);
      expect(ReaderSettings.clampParagraphSpacing(48), 36);
    });

    test('clamps page horizontal margin to reader-supported range', () {
      expect(ReaderSettings.clampPageHorizontalMargin(12), 18);
      expect(ReaderSettings.clampPageHorizontalMargin(30), 30);
      expect(ReaderSettings.clampPageHorizontalMargin(60), 52);
    });
  });
}
