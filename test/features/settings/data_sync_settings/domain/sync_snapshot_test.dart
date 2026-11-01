import 'dart:convert';

import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON round trip keeps every snapshot field', () {
    final snapshot = SyncSnapshot(
      books: [
        SyncBook(
          id: 'book-1',
          title: '云边有个小卖部',
          author: '张嘉佳',
          coverUrl: 'https://img.example.com/cover.jpg',
          intro: '小镇故事',
          sourceId: 'source-1',
          sourceBookUrl: 'https://books.example.com/1',
          lastChapterIndex: 3,
          lastReadPosition: 1200,
          createdAt: DateTime(2026, 5, 1, 8),
          updatedAt: DateTime(2026, 6, 2, 9, 30),
          inShelf: true,
          sortOrder: 2,
          remoteChapterCount: 42,
          remoteNextTocUrl: 'https://books.example.com/1/toc?page=2',
        ),
      ],
      bookmarks: [
        SyncBookmark(
          id: 'bm-1',
          bookId: 'book-1',
          chapterId: 'book-1:1',
          chapterIndex: 1,
          position: 88,
          preview: '云边',
          createdAt: DateTime(2026, 5, 2),
        ),
      ],
      notes: [
        SyncNote(
          id: 'note-1',
          bookId: 'book-1',
          chapterId: 'book-1:1',
          chapterIndex: 1,
          startOffset: 4,
          endOffset: 18,
          content: '这里写得很好',
          note: '想起故乡',
          color: 'yellow',
          createdAt: DateTime(2026, 5, 3),
        ),
      ],
      preferences: const {'reader.preferences': '{"fontSize":18}'},
      generatedAt: DateTime(2026, 6, 2, 14, 32),
    );

    final decoded = SyncSnapshot.fromJson(
      jsonDecode(jsonEncode(snapshot.toJson())),
    );

    expect(decoded.toJson(), snapshot.toJson());
    expect(decoded.books!.single.lastChapterIndex, 3);
    expect(decoded.bookmarks!.single.chapterIndex, 1);
    expect(decoded.notes!.single.startOffset, 4);
    expect(decoded.preferences, snapshot.preferences);
  });

  test('a missing scope stays null while an empty scope stays empty', () {
    final decoded = SyncSnapshot.fromJson(const {
      'schemaVersion': 1,
      'books': <Object?>[],
      'generatedAt': '2026-06-02T06:32:00.000Z',
    });

    expect(decoded.books, isEmpty);
    expect(decoded.bookmarks, isNull);
    expect(decoded.notes, isNull);
    expect(decoded.preferences, isNull);
  });

  test('fromResponse accepts both a bare snapshot and a wrapper', () {
    const payload = {
      'schemaVersion': 1,
      'notes': [
        {
          'id': 'note-1',
          'bookId': 'book-1',
          'chapterId': 'book-1:1',
          'chapterIndex': 1,
          'startOffset': 0,
          'endOffset': 4,
          'content': '摘录',
          'createdAt': '2026-05-03T00:00:00.000Z',
        },
      ],
      'generatedAt': '2026-06-02T06:32:00.000Z',
    };

    expect(SyncSnapshot.fromResponse(payload).notes, hasLength(1));
    expect(
      SyncSnapshot.fromResponse(const {'snapshot': payload}).notes,
      hasLength(1),
    );
  });

  test('a newer schema version is rejected', () {
    expect(
      () => SyncSnapshot.fromJson(const {'schemaVersion': 2}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('协议版本过新'),
        ),
      ),
    );
  });

  test('a book without an id or title is rejected', () {
    expect(
      () => SyncSnapshot.fromJson(const {
        'books': [
          {'id': 'book-1'},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SyncSnapshot.fromJson(const {
        'books': [
          {'title': '没有 id'},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('malformed list fields are rejected instead of skipped', () {
    expect(
      () => SyncSnapshot.fromJson(const {'bookmarks': 'nope'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SyncSnapshot.fromJson(const {
        'notes': [42]
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('book defaults are tolerant of a minimal payload', () {
    final book = SyncBook.fromJson(const {
      'id': 'book-1',
      'title': '书',
      'updatedAt': '2026-06-02T06:32:00.000Z',
    });

    expect(book.lastChapterIndex, 0);
    expect(book.lastReadPosition, 0);
    expect(book.inShelf, isTrue);
    expect(book.sortOrder, 0);
    expect(book.remoteChapterCount, isNull);
    expect(book.createdAt, book.updatedAt);
  });

  test('preferences keep only string values', () {
    final decoded = SyncSnapshot.fromJson(const {
      'preferences': {
        'reader.preferences': '{"fontSize":18}',
        'bad': 42,
      },
    });

    expect(
        decoded.preferences, const {'reader.preferences': '{"fontSize":18}'});
  });
}
