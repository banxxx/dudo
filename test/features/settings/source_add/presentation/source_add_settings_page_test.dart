import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/local_book_import_service.dart';
import 'package:dudo/features/settings/source_add/presentation/source_add_settings_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('duplicate local import shows resolution dialog', (tester) async {
    final duplicate = _book(
      id: 'local-1',
      title: '云边有个小卖部',
    );
    final importService = _FakeLocalBookImporter(
      candidate: const LocalBookImportCandidate(
        sourcePath: '/downloads/cloud.txt',
        fileName: '云边有个小卖部.txt',
        title: '云边有个小卖部',
      ),
    );

    await _pumpSourceAddSettings(
      tester,
      importService: importService,
      duplicate: duplicate,
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();

    expect(find.text('发现同名本地书'), findsOneWidget);
    expect(find.text('“云边有个小卖部” 已在书架中。你想如何处理？'), findsOneWidget);
    expect(find.text('跳过导入'), findsOneWidget);
    expect(find.text('覆盖'), findsOneWidget);
    expect(find.text('依旧导入'), findsOneWidget);
  });

  testWidgets('skip duplicate local import does not import', (tester) async {
    final duplicate = _book(
      id: 'local-1',
      title: '云边有个小卖部',
    );
    final importService = _FakeLocalBookImporter(
      candidate: const LocalBookImportCandidate(
        sourcePath: '/downloads/cloud.txt',
        fileName: '云边有个小卖部.txt',
        title: '云边有个小卖部',
      ),
    );

    await _pumpSourceAddSettings(
      tester,
      importService: importService,
      duplicate: duplicate,
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过导入'));
    await tester.pumpAndSettle();

    expect(importService.importedCandidates, isEmpty);
    expect(find.text('发现同名本地书'), findsNothing);
  });

  testWidgets('import anyway keeps duplicate local book', (tester) async {
    final duplicate = _book(
      id: 'local-1',
      title: '云边有个小卖部',
    );
    final importService = _FakeLocalBookImporter(
      candidate: const LocalBookImportCandidate(
        sourcePath: '/downloads/cloud.txt',
        fileName: '云边有个小卖部.txt',
        title: '云边有个小卖部',
      ),
    );

    await _pumpSourceAddSettings(
      tester,
      importService: importService,
      duplicate: duplicate,
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('依旧导入'));
    await tester.pumpAndSettle();

    expect(importService.importedCandidates.single.title, '云边有个小卖部');
    expect(importService.overwriteBooks.single, isNull);
  });

  testWidgets('overwrite duplicate local book passes existing book',
      (tester) async {
    final duplicate = _book(
      id: 'local-1',
      title: '云边有个小卖部',
    );
    final importService = _FakeLocalBookImporter(
      candidate: const LocalBookImportCandidate(
        sourcePath: '/downloads/cloud.txt',
        fileName: '云边有个小卖部.txt',
        title: '云边有个小卖部',
      ),
    );

    await _pumpSourceAddSettings(
      tester,
      importService: importService,
      duplicate: duplicate,
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('覆盖'));
    await tester.pumpAndSettle();

    expect(importService.importedCandidates.single.title, '云边有个小卖部');
    expect(importService.overwriteBooks.single, duplicate);
  });
}

Book _book({required String id, required String title}) {
  final now = DateTime(2026, 6, 2);
  return Book(
    id: id,
    title: title,
    author: '本地文件',
    localPath: '/books/$id/book.txt',
    lastChapterIndex: 0,
    lastReadPosition: 0,
    createdAt: now,
    updatedAt: now,
    inShelf: true,
    sortOrder: 0,
  );
}

Future<void> _pumpSourceAddSettings(
  WidgetTester tester, {
  required LocalBookImporter importService,
  required Book? duplicate,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SourceAddSettingsPage(),
      ),
      GoRoute(
        path: '/bookshelf',
        builder: (_, __) => const Scaffold(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shelfBooksProvider.overrideWith((ref) => Stream.value(const [])),
        localBookImportServiceProvider.overrideWithValue(importService),
        localBookDuplicateProvider
            .overrideWith((ref, title) async => duplicate),
        appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAppMessageService implements AppMessageService {
  @override
  void dismiss(String dedupeKey) {}

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
  void show(AppMessageRequest request) {}

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

class _FakeLocalBookImporter implements LocalBookImporter {
  _FakeLocalBookImporter({required this.candidate});

  final LocalBookImportCandidate? candidate;
  final importedCandidates = <LocalBookImportCandidate>[];
  final overwriteBooks = <Book?>[];

  @override
  Future<LocalBookImportCandidate?> pickTxtBook() async => candidate;

  @override
  Future<LocalBookImportResult?> importTxtBook() async {
    final picked = await pickTxtBook();
    if (picked == null) return null;
    return importTxtBookCandidate(picked);
  }

  @override
  Future<LocalBookImportResult> importTxtBookCandidate(
    LocalBookImportCandidate candidate, {
    Book? overwriteBook,
  }) async {
    importedCandidates.add(candidate);
    overwriteBooks.add(overwriteBook);
    return LocalBookImportResult(bookId: 'imported-1', title: candidate.title);
  }

  @override
  Future<int> deleteLocalBooksByIds(Set<String> ids) async => ids.length;
}
