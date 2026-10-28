import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookmarks/data/bookmarks_repository.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
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
  late BookmarksRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BookmarksRepository(database);

    await database.into(database.books).insert(
          BooksCompanion.insert(id: 'book-1', title: '三体'),
        );
    await database.into(database.chapters).insert(
          ChaptersCompanion.insert(
            id: 'chapter-1',
            bookId: 'book-1',
            chapterIndex: 2,
            title: '第3章 黎明',
          ),
        );
    await database.into(database.bookmarks).insert(
          BookmarksCompanion.insert(
            id: 'bookmark-1',
            bookId: 'book-1',
            chapterId: 'chapter-1',
            position: 42,
            preview: const Value('向宇宙深处望去。'),
            createdAt: Value(DateTime(2026, 5, 20, 9, 30)),
          ),
        );
    await database.into(database.notes).insert(
          NotesCompanion.insert(
            id: 'note-1',
            bookId: 'book-1',
            chapterId: 'chapter-1',
            startOffset: 10,
            endOffset: 30,
            content: '黑暗森林法则',
            note: const Value('值得回看'),
            createdAt: Value(DateTime(2026, 5, 21, 8)),
          ),
        );
    await database.into(database.notes).insert(
          NotesCompanion.insert(
            id: 'highlight-1',
            bookId: 'book-1',
            chapterId: 'chapter-1',
            startOffset: 50,
            endOffset: 70,
            content: '给岁月以文明',
            createdAt: Value(DateTime(2026, 5, 19, 7)),
          ),
        );
  });

  tearDown(() => database.close());

  test('lists bookmarks, notes, and highlights newest first', () async {
    final entries = await repository.watchEntries().first;

    expect(entries.map((entry) => entry.id), [
      'note-1',
      'bookmark-1',
      'highlight-1',
    ]);
    expect(entries[0].type, BookmarkEntryType.note);
    expect(entries[1].type, BookmarkEntryType.bookmark);
    expect(entries[2].type, BookmarkEntryType.highlight);

    final bookmark = entries[1];
    expect(bookmark.bookTitle, '三体');
    expect(bookmark.chapterIndex, 2);
    expect(bookmark.chapterTitle, '第3章 黎明');
    expect(bookmark.preview, '向宇宙深处望去。');
    expect(bookmark.offset, 42);
    expect(bookmark.createdAt, DateTime(2026, 5, 20, 9, 30));

    final note = entries[0];
    expect(note.excerpt, '黑暗森林法则');
    expect(note.note, '值得回看');
    expect(note.offset, 10);

    final highlight = entries[2];
    expect(highlight.note, isNull);
    expect(highlight.type.label, '高亮');
  });

  test('falls back to the chapter number when the title is empty', () async {
    await database.into(database.chapters).insert(
          ChaptersCompanion.insert(
            id: 'chapter-2',
            bookId: 'book-1',
            chapterIndex: 4,
            title: '',
          ),
        );
    await database.into(database.bookmarks).insert(
          BookmarksCompanion.insert(
            id: 'bookmark-2',
            bookId: 'book-1',
            chapterId: 'chapter-2',
            position: 0,
          ),
        );

    final entries = await repository.watchEntries().first;
    final entry = entries.firstWhere((item) => item.id == 'bookmark-2');

    expect(entry.chapterLabel, '第 5 章');
    expect(entry.preview, isEmpty);
  });

  test('deletes bookmarks and notes by entry type', () async {
    final entries = await repository.watchEntries().first;

    await repository.deleteEntry(
      entries.firstWhere((entry) => entry.id == 'bookmark-1'),
    );
    await repository.deleteEntry(
      entries.firstWhere((entry) => entry.id == 'note-1'),
    );

    final remaining = await repository.watchEntries().first;
    expect(remaining.map((entry) => entry.id), ['highlight-1']);
  });
}
