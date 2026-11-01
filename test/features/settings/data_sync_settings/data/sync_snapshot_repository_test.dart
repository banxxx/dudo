import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reader_engine/domain/reader_preferences.dart';
import 'package:dudo/features/settings/data_sync_settings/data/sync_snapshot_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:dudo/features/settings/theme_settings/domain/theme_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

void main() {
  // Windows ships SQLite as winsqlite3.dll; the test runner does not have
  // sqlite3.dll on PATH like a built Flutter app does.
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }

  late AppDatabase database;
  late SyncSnapshotRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SyncSnapshotRepository(database);
  });

  tearDown(() => database.close());

  group('build', () {
    test('includes only shelf books and scoped data', () async {
      await _insertBook(database, id: 'book-1', inShelf: true);
      await _insertBook(database, id: 'book-2', inShelf: false);
      await _insertChapter(database, bookId: 'book-1', index: 0);
      await _insertChapter(database, bookId: 'book-1', index: 1);
      await _insertBookmark(
        database,
        id: 'bm-1',
        bookId: 'book-1',
        chapterId: 'book-1:1',
      );
      await _insertBookmark(
        database,
        id: 'bm-orphan',
        bookId: 'book-1',
        chapterId: 'missing',
      );
      await _insertNote(
        database,
        id: 'note-1',
        bookId: 'book-1',
        chapterId: 'book-1:0',
      );
      await _insertPreference(
        database,
        ThemeSettings.preferenceKey,
        '{"mode":"dark"}',
      );
      await _insertPreference(
        database,
        ReaderPreferences.preferenceKey,
        '{"fontSize":18}',
      );
      await _insertPreference(database, 'reader.lastSearch', '{"q":"云"}');

      final snapshot = await repository.build(
        includeBooks: true,
        includeAnnotations: true,
        includeSettings: true,
      );

      expect(snapshot.books, hasLength(1));
      expect(snapshot.books!.single.id, 'book-1');
      expect(snapshot.bookmarks, hasLength(1));
      expect(snapshot.bookmarks!.single.id, 'bm-1');
      expect(snapshot.bookmarks!.single.chapterIndex, 1);
      expect(snapshot.notes, hasLength(1));
      expect(snapshot.notes!.single.chapterIndex, 0);
      expect(
        snapshot.preferences,
        {
          ThemeSettings.preferenceKey: '{"mode":"dark"}',
          ReaderPreferences.preferenceKey: '{"fontSize":18}',
        },
      );
    });

    test('leaves an unselected scope null', () async {
      final snapshot = await repository.build(
        includeBooks: false,
        includeAnnotations: false,
        includeSettings: false,
      );

      expect(snapshot.books, isNull);
      expect(snapshot.bookmarks, isNull);
      expect(snapshot.notes, isNull);
      expect(snapshot.preferences, isNull);
    });
  });

  group('apply books', () {
    test('updates a newer remote book and keeps the local path', () async {
      await _insertBook(
        database,
        id: 'book-1',
        updatedAt: DateTime(2026, 6, 1),
        localPath: '/books/local.txt',
      );

      await repository.apply(
        SyncSnapshot(
          books: [
            _book(
              id: 'book-1',
              updatedAt: DateTime(2026, 6, 2),
              lastChapterIndex: 5,
              lastReadPosition: 900,
            ),
          ],
          generatedAt: DateTime.now(),
        ),
      );

      final book = await _bookRow(database, 'book-1');
      expect(book.lastChapterIndex, 5);
      expect(book.lastReadPosition, 900);
      expect(book.localPath, '/books/local.txt');
    });

    test('ignores a stale remote book', () async {
      await _insertBook(
        database,
        id: 'book-1',
        updatedAt: DateTime(2026, 6, 3),
        lastReadPosition: 100,
      );

      await repository.apply(
        SyncSnapshot(
          books: [
            _book(
              id: 'book-1',
              updatedAt: DateTime(2026, 6, 2),
              lastReadPosition: 900,
            ),
          ],
          generatedAt: DateTime.now(),
        ),
      );

      expect((await _bookRow(database, 'book-1')).lastReadPosition, 100);
    });

    test('recreates source-backed books but not local-file books', () async {
      await repository.apply(
        SyncSnapshot(
          books: [
            _book(
              id: 'remote-book',
              updatedAt: DateTime(2026, 6, 2),
              sourceId: 'source-1',
            ),
            _book(
              id: 'local-only-book',
              updatedAt: DateTime(2026, 6, 2),
            ),
          ],
          generatedAt: DateTime.now(),
        ),
      );

      final ids = [
        for (final row in await database.select(database.books).get()) row.id
      ];
      expect(ids, contains('remote-book'));
      expect(ids, isNot(contains('local-only-book')));
    });
  });

  group('apply annotations', () {
    test('resolves chapters by id or by chapter index and upserts', () async {
      await _insertBook(database, id: 'book-1');
      await _insertChapter(database, bookId: 'book-1', index: 0);
      await _insertChapter(database, bookId: 'book-1', index: 1);
      await _insertBookmark(
        database,
        id: 'bm-1',
        bookId: 'book-1',
        chapterId: 'book-1:0',
        position: 1,
      );

      await repository.apply(
        SyncSnapshot(
          bookmarks: [
            SyncBookmark(
              id: 'bm-1',
              bookId: 'book-1',
              chapterId: 'book-1:0',
              chapterIndex: 0,
              position: 42,
              preview: '更新后的书签',
              createdAt: DateTime(2026, 6, 2),
            ),
            SyncBookmark(
              id: 'bm-2',
              bookId: 'book-1',
              // The chapter id is unknown, but the index resolves locally.
              chapterId: 'remote-chapter-id',
              chapterIndex: 1,
              position: 7,
              createdAt: DateTime(2026, 6, 2),
            ),
            SyncBookmark(
              id: 'bm-unknown-book',
              bookId: 'missing-book',
              chapterId: 'missing-chapter',
              chapterIndex: 0,
              position: 0,
              createdAt: DateTime(2026, 6, 2),
            ),
            SyncBookmark(
              id: 'bm-unknown-chapter',
              bookId: 'book-1',
              chapterId: 'missing-chapter',
              chapterIndex: 9,
              position: 0,
              createdAt: DateTime(2026, 6, 2),
            ),
          ],
          notes: [
            SyncNote(
              id: 'note-1',
              bookId: 'book-1',
              chapterId: 'book-1:1',
              chapterIndex: 1,
              startOffset: 0,
              endOffset: 4,
              content: '摘录',
              note: '想法',
              createdAt: DateTime(2026, 6, 2),
            ),
          ],
          generatedAt: DateTime.now(),
        ),
      );

      final bookmarks = await database.select(database.bookmarks).get();
      final updated = bookmarks.singleWhere((row) => row.id == 'bm-1');
      expect(updated.position, 42);
      expect(updated.preview, '更新后的书签');
      final resolved = bookmarks.singleWhere((row) => row.id == 'bm-2');
      expect(resolved.chapterId, 'book-1:1');
      expect(
          bookmarks.map((row) => row.id), isNot(contains('bm-unknown-book')));
      expect(
        bookmarks.map((row) => row.id),
        isNot(contains('bm-unknown-chapter')),
      );

      final note = (await database.select(database.notes).get()).single;
      expect(note.id, 'note-1');
      expect(note.chapterId, 'book-1:1');
      expect(note.content, '摘录');
    });
  });

  group('apply preferences', () {
    test('only accepts allow-listed keys with a JSON object value', () async {
      await _insertPreference(
        database,
        ThemeSettings.preferenceKey,
        '{"mode":"dark"}',
      );
      await _insertPreference(
        database,
        ReaderPreferences.preferenceKey,
        '{"fontSize":18}',
      );
      await _insertPreference(database, 'reader.lastSearch', '{"q":"云"}');

      await repository.apply(
        SyncSnapshot(
          preferences: {
            ThemeSettings.preferenceKey: '{"mode":"light"}',
            ReaderPreferences.preferenceKey: 'not json',
            'reader.lastSearch': '{"q":"远程"}',
          },
          generatedAt: DateTime.now(),
        ),
      );

      final values = {
        for (final row in await database.select(database.appPreferences).get())
          row.key: row.value,
      };
      expect(values[ThemeSettings.preferenceKey], '{"mode":"light"}');
      expect(values[ReaderPreferences.preferenceKey], '{"fontSize":18}');
      expect(values['reader.lastSearch'], '{"q":"云"}');
    });
  });

  test('applying an empty snapshot deletes nothing', () async {
    await _insertBook(database, id: 'book-1');
    await _insertChapter(database, bookId: 'book-1', index: 0);
    await _insertBookmark(
      database,
      id: 'bm-1',
      bookId: 'book-1',
      chapterId: 'book-1:0',
    );

    await repository.apply(
      SyncSnapshot(
        books: const [],
        bookmarks: const [],
        notes: const [],
        preferences: const {},
        generatedAt: DateTime.now(),
      ),
    );

    expect(await database.select(database.books).get(), hasLength(1));
    expect(await database.select(database.bookmarks).get(), hasLength(1));
  });
}

Future<void> _insertBook(
  AppDatabase database, {
  required String id,
  bool inShelf = true,
  DateTime? updatedAt,
  String? localPath,
  int lastReadPosition = 0,
}) {
  return database.into(database.books).insert(
        BooksCompanion.insert(
          id: id,
          title: '书籍 $id',
          localPath: Value(localPath),
          lastReadPosition: Value(lastReadPosition),
          inShelf: Value(inShelf),
          updatedAt: Value(updatedAt ?? DateTime(2026, 6, 1)),
        ),
      );
}

Future<void> _insertChapter(
  AppDatabase database, {
  required String bookId,
  required int index,
}) {
  return database.into(database.chapters).insert(
        ChaptersCompanion.insert(
          id: '$bookId:$index',
          bookId: bookId,
          chapterIndex: index,
          title: '第 $index 章',
        ),
      );
}

Future<void> _insertBookmark(
  AppDatabase database, {
  required String id,
  required String bookId,
  required String chapterId,
  int position = 0,
}) {
  return database.into(database.bookmarks).insert(
        BookmarksCompanion.insert(
          id: id,
          bookId: bookId,
          chapterId: chapterId,
          position: position,
        ),
      );
}

Future<void> _insertNote(
  AppDatabase database, {
  required String id,
  required String bookId,
  required String chapterId,
}) {
  return database.into(database.notes).insert(
        NotesCompanion.insert(
          id: id,
          bookId: bookId,
          chapterId: chapterId,
          startOffset: 0,
          endOffset: 4,
          content: '摘录',
        ),
      );
}

Future<void> _insertPreference(
  AppDatabase database,
  String key,
  String value,
) {
  return database.into(database.appPreferences).insertOnConflictUpdate(
        AppPreferencesCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime(2026, 6, 1),
        ),
      );
}

SyncBook _book({
  required String id,
  required DateTime updatedAt,
  String? sourceId,
  int lastChapterIndex = 0,
  int lastReadPosition = 0,
}) {
  return SyncBook(
    id: id,
    title: '书籍 $id',
    sourceId: sourceId,
    lastChapterIndex: lastChapterIndex,
    lastReadPosition: lastReadPosition,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: updatedAt,
  );
}

Future<Book> _bookRow(AppDatabase database, String id) {
  return (database.select(database.books)..where((row) => row.id.equals(id)))
      .getSingle();
}
