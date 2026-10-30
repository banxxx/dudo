import 'package:dudo/features/settings/typography_settings/domain/reader_font.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats font file sizes with the units the page shows', () {
    expect(formatReaderFontSize(null), '本地字体');
    expect(formatReaderFontSize(0), '本地字体');
    expect(formatReaderFontSize(512 * 1024), '512.0KB');
    expect(formatReaderFontSize(12373196), '11.8MB');
  });

  test('the file label combines the original name and size', () {
    const font = ReaderFont(
      id: 'font-1',
      displayName: '方正书宋',
      familyKey: 'DudoImportedFont_demo',
      source: ReaderFontSource.imported,
      originalFileName: 'FZShuSong.otf',
      fileSize: 8273912,
      relativePath: 'fonts/imported/font-1/font.otf',
    );

    expect(font.fileLabel, 'FZShuSong.otf · 7.9MB');
  });

  test('the file label falls back to the display name', () {
    const font = ReaderFont(
      id: 'font-2',
      displayName: '某字体',
      familyKey: 'DudoImportedFont_demo_2',
      source: ReaderFontSource.imported,
    );

    expect(font.fileLabel, '某字体 · 本地字体');
  });
}
