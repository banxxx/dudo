import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/home/application/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 20, 12);

  group('currentReadingBookProvider', () {
    test('picks the most recently read book that has progress', () async {
      final container = ProviderContainer(
        overrides: [
          shelfBooksProvider.overrideWith(
            (ref) => Stream.value([
              _book(
                id: 'unread',
                title: '未读的书',
                updatedAt: now.add(const Duration(hours: 3)),
              ),
              _book(
                id: 'older',
                title: '较早读的书',
                chapterIndex: 2,
                updatedAt: now,
              ),
              _book(
                id: 'latest',
                title: '最近读的书',
                chapterIndex: 5,
                updatedAt: now.add(const Duration(hours: 1)),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shelfBooksProvider.future);

      expect(container.read(currentReadingBookProvider)?.id, 'latest');
    });

    test('returns null when the shelf has no started book', () async {
      final container = ProviderContainer(
        overrides: [
          shelfBooksProvider.overrideWith(
            (ref) => Stream.value([_book(id: 'unread', title: '未读的书')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shelfBooksProvider.future);

      expect(container.read(currentReadingBookProvider), isNull);
      expect(container.read(homeReadingSnapshotProvider), isNull);
    });
  });

  group('homeReadingSnapshotProvider', () {
    test('derives chapter, progress, and remaining time from stored data',
        () async {
      final book = _book(
        id: 'book-1',
        title: '三体',
        author: '刘慈欣',
        chapterIndex: 23,
        readPosition: 900,
        remoteChapterCount: 40,
      );
      final chapter = _chapter(
        bookId: book.id,
        chapterIndex: 23,
        title: '第24章 旧世界的回声',
        length: 1800,
      );
      final container = _snapshotContainer(book, chapter);
      addTearDown(container.dispose);

      await _awaitChapterData(container, book.id, 23);
      final snapshot = container.read(homeReadingSnapshotProvider)!;

      expect(snapshot.bookTitle, '三体');
      expect(snapshot.chapterLabel, '第 24 章');
      expect(snapshot.continueLabel, '继续阅读 · 第 24 章');
      expect(snapshot.subtitle, '旧世界的回声');
      expect(snapshot.progressPercent, 59);
      expect(snapshot.remainingMinutes, 2);
      expect(snapshot.remainingLabel, '剩余 2 分钟');
      expect(snapshot.coverLabel, '刘慈');
    });

    test('falls back to the book intro when the chapter has no title',
        () async {
      final book = _book(
        id: 'book-2',
        title: '长安的荔枝',
        intro: '一骑红尘妃子笑。',
        chapterIndex: 1,
        readPosition: 0,
        remoteChapterCount: 10,
      );
      final container = _snapshotContainer(book, null);
      addTearDown(container.dispose);

      await _awaitChapterData(container, book.id, 1);
      final snapshot = container.read(homeReadingSnapshotProvider)!;

      expect(snapshot.subtitle, '一骑红尘妃子笑。');
      expect(snapshot.remainingMinutes, isNull);
      expect(snapshot.remainingLabel, '继续上次进度');
      expect(snapshot.progressPercent, 10);
    });

    test('shows the book title alone when the chapter count is unknown',
        () async {
      final book = _book(
        id: 'book-3',
        title: '没有目录的书',
        chapterIndex: 0,
        readPosition: 0,
      );
      final container = _snapshotContainer(book, null);
      addTearDown(container.dispose);

      await _awaitChapterData(container, book.id, 0);
      final snapshot = container.read(homeReadingSnapshotProvider)!;

      expect(snapshot.chapterLabel, isEmpty);
      expect(snapshot.continueLabel, '继续阅读');
      expect(snapshot.progressPercent, 0);
      expect(snapshot.progressLabel, '在读');
    });
  });
}

ProviderContainer _snapshotContainer(Book book, Chapter? chapter) {
  return ProviderContainer(
    overrides: [
      currentReadingBookProvider.overrideWithValue(book),
      bookChapterCountProvider.overrideWith(
        (ref, bookId) => Stream.value(book.remoteChapterCount ?? 0),
      ),
      currentBookChapterMetaProvider.overrideWith(
        (ref, key) => Stream.value(
          chapter != null && chapter.chapterIndex == key.chapterIndex
              ? chapter
              : null,
        ),
      ),
    ],
  );
}

Future<void> _awaitChapterData(
  ProviderContainer container,
  String bookId,
  int chapterIndex,
) async {
  await container.read(bookChapterCountProvider(bookId).future);
  await container
      .read(
        currentBookChapterMetaProvider(
          CurrentBookChapterKey(bookId: bookId, chapterIndex: chapterIndex),
        ).future,
      );
}

Book _book({
  required String id,
  required String title,
  String? author,
  String? intro,
  int chapterIndex = 0,
  int readPosition = 0,
  int? remoteChapterCount,
  DateTime? updatedAt,
}) {
  final timestamp = updatedAt ?? DateTime(2026, 5, 20, 10);
  return Book(
    id: id,
    title: title,
    author: author,
    intro: intro,
    lastChapterIndex: chapterIndex,
    lastReadPosition: readPosition,
    createdAt: timestamp,
    updatedAt: timestamp,
    inShelf: true,
    sortOrder: 0,
    remoteChapterCount: remoteChapterCount,
  );
}

Chapter _chapter({
  required String bookId,
  required int chapterIndex,
  required String title,
  required int length,
}) {
  return Chapter(
    id: '$bookId-$chapterIndex',
    bookId: bookId,
    chapterIndex: chapterIndex,
    title: title,
    normalizedContentLength: length,
    isCached: true,
  );
}
