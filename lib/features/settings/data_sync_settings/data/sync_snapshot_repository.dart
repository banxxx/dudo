import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../reader_engine/domain/reader_preferences.dart';
import '../../theme_settings/domain/theme_settings.dart';
import '../domain/sync_snapshot.dart';

/// Reads local data into a snapshot and applies what the server sends back.
abstract interface class SyncSnapshotStore {
  Future<SyncSnapshot> build({
    required bool includeBooks,
    required bool includeAnnotations,
    required bool includeSettings,
  });

  Future<void> apply(SyncSnapshot snapshot);
}

/// Builds the outgoing snapshot from the local database and applies the merged
/// snapshot returned by the server.
///
/// The apply step is deliberately additive: it upserts books, bookmarks, notes
/// and allow-listed preferences, but never deletes anything. A malformed or
/// incomplete server response therefore cannot wipe a device.
class SyncSnapshotRepository implements SyncSnapshotStore {
  const SyncSnapshotRepository(this.database);

  final AppDatabase database;

  /// Preference rows that may travel between devices. Credentials, cookies,
  /// recent searches and device-local paths are intentionally excluded.
  static const allowedPreferenceKeys = {
    ThemeSettings.preferenceKey,
    ReaderPreferences.preferenceKey,
  };

  @override
  Future<SyncSnapshot> build({
    required bool includeBooks,
    required bool includeAnnotations,
    required bool includeSettings,
  }) async {
    final now = DateTime.now();

    List<SyncBook>? books;
    if (includeBooks) {
      final rows = await (database.select(database.books)
            ..where((book) => book.inShelf.equals(true)))
          .get();
      books = [
        for (final book in rows)
          SyncBook(
            id: book.id,
            title: book.title,
            author: book.author,
            coverUrl: book.coverUrl,
            intro: book.intro,
            sourceId: book.sourceId,
            sourceBookUrl: book.sourceBookUrl,
            lastChapterIndex: book.lastChapterIndex,
            lastReadPosition: book.lastReadPosition,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt,
            inShelf: book.inShelf,
            sortOrder: book.sortOrder,
            remoteChapterCount: book.remoteChapterCount,
            remoteNextTocUrl: book.remoteNextTocUrl,
          ),
      ];
    }

    List<SyncBookmark>? bookmarks;
    List<SyncNote>? notes;
    if (includeAnnotations) {
      final bookmarkRows = await database.select(database.bookmarks).get();
      final noteRows = await database.select(database.notes).get();
      final bookIds = {
        for (final row in bookmarkRows) row.bookId,
        for (final row in noteRows) row.bookId,
      };
      final chapters = bookIds.isEmpty
          ? const <Chapter>[]
          : await (database.select(database.chapters)
                ..where((chapter) => chapter.bookId.isIn(bookIds)))
              .get();
      final chapterIndexById = {
        for (final chapter in chapters) chapter.id: chapter.chapterIndex,
      };

      bookmarks = [
        for (final row in bookmarkRows)
          if (chapterIndexById[row.chapterId] case final index?)
            SyncBookmark(
              id: row.id,
              bookId: row.bookId,
              chapterId: row.chapterId,
              chapterIndex: index,
              position: row.position,
              preview: row.preview,
              createdAt: row.createdAt,
            ),
      ];
      notes = [
        for (final row in noteRows)
          if (chapterIndexById[row.chapterId] case final index?)
            SyncNote(
              id: row.id,
              bookId: row.bookId,
              chapterId: row.chapterId,
              chapterIndex: index,
              startOffset: row.startOffset,
              endOffset: row.endOffset,
              content: row.content,
              note: row.note,
              color: row.color,
              createdAt: row.createdAt,
            ),
      ];
    }

    Map<String, String>? preferences;
    if (includeSettings) {
      final rows = await (database.select(database.appPreferences)
            ..where((row) => row.key.isIn(allowedPreferenceKeys)))
          .get();
      preferences = {for (final row in rows) row.key: row.value};
    }

    return SyncSnapshot(
      books: books,
      bookmarks: bookmarks,
      notes: notes,
      preferences: preferences,
      generatedAt: now,
    );
  }

  @override
  Future<void> apply(SyncSnapshot snapshot) async {
    await database.transaction(() async {
      if (snapshot.books != null) {
        await _applyBooks(snapshot.books!);
      }
      if (snapshot.bookmarks != null || snapshot.notes != null) {
        await _applyAnnotations(snapshot.bookmarks, snapshot.notes);
      }
      if (snapshot.preferences != null) {
        await _applyPreferences(snapshot.preferences!);
      }
    });
  }

  Future<void> _applyBooks(List<SyncBook> books) async {
    for (final book in books) {
      final existing = await (database.select(database.books)
            ..where((row) => row.id.equals(book.id)))
          .getSingleOrNull();

      if (existing == null) {
        // A local-file book from another device has no readable file here, so
        // only remote source-backed books are recreated.
        if (book.sourceId == null) continue;
        await database.into(database.books).insert(
              BooksCompanion.insert(
                id: book.id,
                title: book.title,
                author: Value(book.author),
                coverUrl: Value(book.coverUrl),
                intro: Value(book.intro),
                sourceId: Value(book.sourceId),
                sourceBookUrl: Value(book.sourceBookUrl),
                lastChapterIndex: Value(book.lastChapterIndex),
                lastReadPosition: Value(book.lastReadPosition),
                createdAt: Value(book.createdAt),
                updatedAt: Value(book.updatedAt),
                inShelf: Value(book.inShelf),
                sortOrder: Value(book.sortOrder),
                remoteChapterCount: Value(book.remoteChapterCount),
                remoteNextTocUrl: Value(book.remoteNextTocUrl),
              ),
            );
        continue;
      }

      // The server is expected to merge by `updatedAt`; this guard keeps a
      // stale server from rolling back newer local reading progress.
      if (!book.updatedAt.isAfter(existing.updatedAt)) continue;

      await (database.update(database.books)
            ..where((row) => row.id.equals(book.id)))
          .write(
        BooksCompanion(
          title: Value(book.title),
          author: Value(book.author),
          coverUrl: Value(book.coverUrl),
          intro: Value(book.intro),
          sourceId: Value(book.sourceId),
          sourceBookUrl: Value(book.sourceBookUrl),
          lastChapterIndex: Value(book.lastChapterIndex),
          lastReadPosition: Value(book.lastReadPosition),
          updatedAt: Value(book.updatedAt),
          inShelf: Value(book.inShelf),
          sortOrder: Value(book.sortOrder),
          remoteChapterCount: Value(book.remoteChapterCount),
          remoteNextTocUrl: Value(book.remoteNextTocUrl),
        ),
      );
    }
  }

  Future<void> _applyAnnotations(
    List<SyncBookmark>? bookmarks,
    List<SyncNote>? notes,
  ) async {
    final bookIds = {
      for (final bookmark in bookmarks ?? const <SyncBookmark>[])
        bookmark.bookId,
      for (final note in notes ?? const <SyncNote>[]) note.bookId,
    };
    if (bookIds.isEmpty) return;

    final localBooks = await (database.select(database.books)
          ..where((book) => book.id.isIn(bookIds)))
        .get();
    final localBookIds = {for (final book in localBooks) book.id};
    if (localBookIds.isEmpty) return;

    final chapters = await (database.select(database.chapters)
          ..where((chapter) => chapter.bookId.isIn(localBookIds)))
        .get();
    final chapterById = {for (final chapter in chapters) chapter.id: chapter};
    final chapterIdByKey = {
      for (final chapter in chapters)
        _chapterKey(chapter.bookId, chapter.chapterIndex): chapter.id,
    };

    for (final bookmark in bookmarks ?? const <SyncBookmark>[]) {
      if (!localBookIds.contains(bookmark.bookId)) continue;
      final chapterId = _resolveChapterId(
        bookId: bookmark.bookId,
        chapterId: bookmark.chapterId,
        chapterIndex: bookmark.chapterIndex,
        chapterById: chapterById,
        chapterIdByKey: chapterIdByKey,
      );
      if (chapterId == null) continue;
      await database.into(database.bookmarks).insertOnConflictUpdate(
            BookmarksCompanion(
              id: Value(bookmark.id),
              bookId: Value(bookmark.bookId),
              chapterId: Value(chapterId),
              position: Value(bookmark.position),
              preview: Value(bookmark.preview),
              createdAt: Value(bookmark.createdAt),
            ),
          );
    }

    for (final note in notes ?? const <SyncNote>[]) {
      if (!localBookIds.contains(note.bookId)) continue;
      final chapterId = _resolveChapterId(
        bookId: note.bookId,
        chapterId: note.chapterId,
        chapterIndex: note.chapterIndex,
        chapterById: chapterById,
        chapterIdByKey: chapterIdByKey,
      );
      if (chapterId == null) continue;
      await database.into(database.notes).insertOnConflictUpdate(
            NotesCompanion(
              id: Value(note.id),
              bookId: Value(note.bookId),
              chapterId: Value(chapterId),
              startOffset: Value(note.startOffset),
              endOffset: Value(note.endOffset),
              content: Value(note.content),
              note: Value(note.note),
              color: Value(note.color),
              createdAt: Value(note.createdAt),
            ),
          );
    }
  }

  Future<void> _applyPreferences(Map<String, String> preferences) async {
    for (final entry in preferences.entries) {
      if (!allowedPreferenceKeys.contains(entry.key)) continue;
      // Reject anything that the local repositories cannot decode, so a broken
      // server cannot replace the theme with a malformed blob.
      try {
        if (jsonDecode(entry.value) is! Map) continue;
      } catch (_) {
        continue;
      }
      await database.into(database.appPreferences).insertOnConflictUpdate(
            AppPreferencesCompanion(
              key: Value(entry.key),
              value: Value(entry.value),
              updatedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  String? _resolveChapterId({
    required String bookId,
    required String chapterId,
    required int chapterIndex,
    required Map<String, Chapter> chapterById,
    required Map<String, String> chapterIdByKey,
  }) {
    final direct = chapterById[chapterId];
    if (direct != null && direct.bookId == bookId) return direct.id;
    return chapterIdByKey[_chapterKey(bookId, chapterIndex)];
  }

  String _chapterKey(String bookId, int chapterIndex) {
    return '$bookId\u0000$chapterIndex';
  }
}
