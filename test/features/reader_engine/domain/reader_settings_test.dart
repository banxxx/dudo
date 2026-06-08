import 'package:flutter_test/flutter_test.dart';

import 'package:dudo/features/reader_engine/domain/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('clamps font size to reader-supported range', () {
      expect(ReaderSettings.clampFontSize(8), 10);
      expect(ReaderSettings.clampFontSize(18), 18);
      expect(ReaderSettings.clampFontSize(48), 45);
    });
  });
}
