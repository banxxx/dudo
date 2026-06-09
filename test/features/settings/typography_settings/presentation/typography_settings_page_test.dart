import 'package:dudo/features/settings/typography_settings/presentation/typography_settings_page.dart';
import 'package:dudo/features/settings/typography_settings/application/reader_font_providers.dart';
import 'package:dudo/features/settings/typography_settings/data/reader_font_repository.dart';
import 'package:dudo/features/settings/typography_settings/domain/reader_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders and switches the font management design', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerFontRepositoryProvider.overrideWithValue(
            _FakeReaderFontRepository(),
          ),
        ],
        child: const MaterialApp(
          home: TypographySettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('阅读体验'), findsOneWidget);
    expect(find.text('字体管理'), findsNWidgets(2));
    expect(find.text('字体预览'), findsOneWidget);
    expect(find.text('内置字体和导入字体统一在这里选择'), findsOneWidget);
    expect(find.text('添加本地字体'), findsOneWidget);
    expect(find.text('霞鹜文楷'), findsOneWidget);
    expect(find.text('LXGWWenKai-Regular.ttf · 11.8MB'), findsOneWidget);

    await tester.tap(find.text('内置字体'));
    await tester.pumpAndSettle();

    expect(find.text('添加本地字体'), findsNothing);
    expect(find.text('Noto Serif SC'), findsOneWidget);
    expect(find.text('Noto Sans SC'), findsOneWidget);

    await tester.tap(find.text('我的字体'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pumpAndSettle();

    expect(find.text('删除“方正书宋”？'), findsOneWidget);
    expect(find.text('FZShuSong.otf · 本地字体'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });
}

class _FakeReaderFontRepository implements ReaderFontRepository {
  String _selectedFamilyKey = 'DudoImportedFont_demo_wenkai';
  final List<ReaderFont> _importedFonts = [
    ReaderFont(
      id: 'imported-wenkai',
      displayName: '霞鹜文楷',
      familyKey: 'DudoImportedFont_demo_wenkai',
      source: ReaderFontSource.imported,
      originalFileName: 'LXGWWenKai-Regular.ttf',
      fileSize: 12373196,
      relativePath: 'fonts/imported/imported-wenkai/font.ttf',
      importedAt: DateTime(2026),
    ),
    ReaderFont(
      id: 'imported-shusong',
      displayName: '方正书宋',
      familyKey: 'DudoImportedFont_demo_shusong',
      source: ReaderFontSource.imported,
      originalFileName: 'FZShuSong.otf',
      fileSize: 8273912,
      relativePath: 'fonts/imported/imported-shusong/font.otf',
      importedAt: DateTime(2026),
    ),
  ];

  @override
  Future<ReaderFontLibrary> loadLibrary() async {
    return ReaderFontLibrary(
      fonts: [...ReaderBuiltinFonts.values, ..._importedFonts],
      selectedFamilyKey: _selectedFamilyKey,
    );
  }

  @override
  Future<ReaderFont?> pickAndImportFont() async => null;

  @override
  Future<void> selectFont(String familyKey) async {
    _selectedFamilyKey = familyKey;
  }

  @override
  Future<void> deleteImportedFont(String id) async {
    _importedFonts.removeWhere((font) => font.id == id);
    if (_selectedFamilyKey.startsWith('DudoImportedFont_')) {
      _selectedFamilyKey = ReaderBuiltinFonts.serifSc.familyKey;
    }
  }

  @override
  Future<String> readSelectedFontFamily() async => _selectedFamilyKey;

  @override
  Future<void> loadImportedFonts() async {}
}
