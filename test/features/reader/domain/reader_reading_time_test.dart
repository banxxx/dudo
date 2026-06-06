import 'package:dudo/features/reader/domain/reader_reading_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateReaderReadingTimeText', () {
    test('returns blank text for empty readable content', () {
      expect(estimateReaderReadingTimeText(''), '');
      expect(estimateReaderReadingTimeText(' \n\t'), '');
    });

    test('estimates reading time by non-whitespace character count', () {
      expect(estimateReaderReadingTimeText('字'), '约 1 分钟');
      expect(estimateReaderReadingTimeText('字' * 450), '约 1 分钟');
      expect(estimateReaderReadingTimeText('字' * 451), '约 2 分钟');
      expect(estimateReaderReadingTimeText('字 ' * 451), '约 2 分钟');
    });
  });
}
