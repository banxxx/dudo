import 'dart:async';

import 'package:dudo/features/settings/typography_settings/presentation/typography_settings_page.dart';
import 'package:dudo/features/settings/typography_settings/application/reader_font_providers.dart';
import 'package:dudo/features/settings/typography_settings/data/reader_font_repository.dart';
import 'package:dudo/features/settings/typography_settings/domain/reader_font.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
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
          appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
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

  testWidgets('keeps the font list visible while importing', (tester) async {
    final importCompleter = Completer<ReaderFont?>();
    final repository = _FakeReaderFontRepository(
      importCompleter: importCompleter,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerFontRepositoryProvider.overrideWithValue(repository),
          appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
        ],
        child: const MaterialApp(
          home: TypographySettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加本地字体'));
    await tester.pump();

    expect(find.text('霞鹜文楷'), findsOneWidget);
    expect(find.text('方正书宋'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    importCompleter.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the font list visible while deleting', (tester) async {
    final deleteCompleter = Completer<void>();
    final repository = _FakeReaderFontRepository(
      deleteCompleter: deleteCompleter,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerFontRepositoryProvider.overrideWithValue(repository),
          appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
        ],
        child: const MaterialApp(
          home: TypographySettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('霞鹜文楷'), findsOneWidget);
    expect(find.text('方正书宋'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    deleteCompleter.complete();
    await tester.pumpAndSettle();

    expect(find.text('方正书宋'), findsNothing);
  });

  testWidgets('dismisses font snack when page is disposed', (tester) async {
    final messageService = _FakeAppMessageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerFontRepositoryProvider.overrideWithValue(
            _FakeReaderFontRepository(),
          ),
          appMessageServiceProvider.overrideWithValue(messageService),
        ],
        child: const MaterialApp(
          home: TypographySettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerFontRepositoryProvider.overrideWithValue(
            _FakeReaderFontRepository(),
          ),
          appMessageServiceProvider.overrideWithValue(messageService),
        ],
        child: const MaterialApp(
          home: SizedBox.shrink(),
        ),
      ),
    );

    expect(messageService.dismissedKeys, contains('typography-settings-snack'));
  });
}

class _FakeAppMessageService implements AppMessageService {
  final dismissedKeys = <String>[];
  final shownRequests = <AppMessageRequest>[];

  @override
  void dismiss(String dedupeKey) {
    dismissedKeys.add(dedupeKey);
  }

  @override
  void dismissAll() {}

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void show(AppMessageRequest request) {
    shownRequests.add(request);
  }

  @override
  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
  }) {}

  @override
  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}
}

class _FakeReaderFontRepository implements ReaderFontRepository {
  _FakeReaderFontRepository({
    this.importCompleter,
    this.deleteCompleter,
  });

  final Completer<ReaderFont?>? importCompleter;
  final Completer<void>? deleteCompleter;
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
  Future<ReaderFont?> pickAndImportFont() async {
    final font = await (importCompleter?.future ?? Future<ReaderFont?>.value());
    if (font != null) _importedFonts.add(font);
    return font;
  }

  @override
  Future<void> selectFont(String familyKey) async {
    _selectedFamilyKey = familyKey;
  }

  @override
  Future<void> deleteImportedFont(String id) async {
    await (deleteCompleter?.future ?? Future<void>.value());
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
