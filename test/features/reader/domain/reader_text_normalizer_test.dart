import 'package:dudo/features/reader/domain/reader_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildReaderParagraphSpans', () {
    test('returns empty spans for empty content', () {
      expect(buildReaderParagraphSpans(''), isEmpty);
    });

    test('maps a single paragraph to the full normalized text range', () {
      final spans = buildReaderParagraphSpans('  第一段  ');

      expect(spans, hasLength(1));
      expect(spans.single.index, 0);
      expect(spans.single.text, '第一段');
      expect(spans.single.startOffset, 0);
      expect(spans.single.endOffset, 3);
    });

    test('accounts for blank line separators in normalized text offsets', () {
      final spans = buildReaderParagraphSpans('A\nBCD');

      expect(normalizeReaderText('A\nBCD'), 'A\n\nBCD');
      expect(spans, hasLength(2));
      expect(spans[0].startOffset, 0);
      expect(spans[0].endOffset, 1);
      expect(spans[1].startOffset, 3);
      expect(spans[1].endOffset, 6);
    });

    test('normalizes CRLF and ignores blank lines consistently', () {
      final spans = buildReaderParagraphSpans('甲\r\n\r\n乙\n\n 丙 ');

      expect(normalizeReaderText('甲\r\n\r\n乙\n\n 丙 '), '甲\n\n乙\n\n丙');
      expect(spans.map((span) => span.text), ['甲', '乙', '丙']);
      expect(spans.map((span) => span.startOffset), [0, 3, 6]);
      expect(spans.map((span) => span.endOffset), [1, 4, 7]);
    });
  });
}
