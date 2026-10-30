import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/settings/shelf_update_settings/application/shelf_update_settings_provider.dart';
import 'package:dudo/features/settings/shelf_update_settings/data/shelf_update_settings_repository.dart';
import 'package:dudo/features/settings/shelf_update_settings/domain/shelf_update_settings.dart';
import 'package:dudo/features/settings/shelf_update_settings/presentation/shelf_update_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page is taller than the default 800x600 test surface.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the saved schedule and the online book count',
      (tester) async {
    _useTallViewport(tester);
    final repository =
        _FakeShelfUpdateSettingsRepository(ShelfUpdateSettings.defaults());

    await tester.pumpWidget(_wrap(repository, onlineBooks: 2));
    await tester.pumpAndSettle();

    expect(find.text('书架更新'), findsOneWidget);
    expect(find.text('更新计划'), findsOneWidget);
    // Once in the hero, once on the selected frequency card.
    expect(find.text('每天'), findsNWidgets(2));
    expect(find.textContaining('2 本在线书籍'), findsOneWidget);
    expect(find.text('自动更新书架'), findsOneWidget);
    expect(find.text('每周'), findsOneWidget);
    expect(find.text('仅 Wi-Fi 更新'), findsOneWidget);
    expect(find.text('章节更新提醒'), findsOneWidget);
    expect(find.textContaining('本地导入的书籍不会联网'), findsOneWidget);
  });

  testWidgets('turning auto update off is saved and shown as closed',
      (tester) async {
    _useTallViewport(tester);
    final repository =
        _FakeShelfUpdateSettingsRepository(ShelfUpdateSettings.defaults());

    await tester.pumpWidget(_wrap(repository, onlineBooks: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('shelf-update-auto-switch')));
    await tester.pump();

    expect(repository.saved.last.enabled, isFalse);
    expect(find.text('已关闭'), findsOneWidget);
    expect(find.text('书架不会自动获取在线书源的新章节'), findsOneWidget);
  });

  testWidgets('picking another frequency saves it immediately', (tester) async {
    _useTallViewport(tester);
    final repository =
        _FakeShelfUpdateSettingsRepository(ShelfUpdateSettings.defaults());

    await tester.pumpWidget(_wrap(repository, onlineBooks: 2));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('shelf-update-frequency-everyThreeDays')),
    );
    await tester.pump();

    expect(repository.saved.last.frequency, ShelfUpdateFrequency.everyThreeDays);
    expect(find.text('每 3 天'), findsNWidgets(2));
  });

  testWidgets('network and reminder switches are persisted', (tester) async {
    _useTallViewport(tester);
    final repository =
        _FakeShelfUpdateSettingsRepository(ShelfUpdateSettings.defaults());

    await tester.pumpWidget(_wrap(repository, onlineBooks: 0));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('shelf-update-wifi-switch')));
    await tester.pump();
    expect(repository.saved.last.wifiOnly, isFalse);

    await tester.tap(find.byKey(const ValueKey('shelf-update-alerts-switch')));
    await tester.pump();
    expect(repository.saved.last.chapterAlerts, isFalse);
    expect(find.textContaining('暂无在线书籍'), findsOneWidget);
  });
}

Widget _wrap(
  ShelfUpdateSettingsRepository repository, {
  required int onlineBooks,
}) {
  return ProviderScope(
    overrides: [
      shelfUpdateSettingsRepositoryProvider.overrideWithValue(repository),
      shelfBooksProvider.overrideWith(
        (ref) => Stream.value(_books(onlineBooks)),
      ),
    ],
    child: const MaterialApp(home: ShelfUpdateSettingsPage()),
  );
}

List<Book> _books(int onlineCount) {
  final now = DateTime(2026, 6, 2);
  return [
    for (var index = 0; index < onlineCount; index++)
      Book(
        id: 'online-$index',
        title: '在线书 $index',
        author: '作者',
        sourceId: 'source-1',
        sourceBookUrl: 'https://example.com/book/$index',
        lastChapterIndex: 0,
        lastReadPosition: 0,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: index,
      ),
    Book(
      id: 'local-1',
      title: '本地书',
      author: '作者',
      localPath: '/books/local.txt',
      lastChapterIndex: 0,
      lastReadPosition: 0,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: onlineCount,
    ),
  ];
}

class _FakeShelfUpdateSettingsRepository
    implements ShelfUpdateSettingsRepository {
  _FakeShelfUpdateSettingsRepository(this._settings);

  ShelfUpdateSettings _settings;
  final List<ShelfUpdateSettings> saved = [];

  @override
  Future<ShelfUpdateSettings> load() async => _settings;

  @override
  Future<void> save(ShelfUpdateSettings settings) async {
    _settings = settings;
    saved.add(settings);
  }

  @override
  Stream<ShelfUpdateSettings> watch() => Stream.value(_settings);
}
