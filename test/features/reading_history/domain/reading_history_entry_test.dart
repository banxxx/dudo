import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_history/domain/reading_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Thursday, 21 May 2026; the current week starts on Monday the 18th.
  final now = DateTime(2026, 5, 21, 9, 30);

  test('labels today and yesterday by name', () {
    expect(_entryAt(DateTime(2026, 5, 21, 8)).timeLabel(now), '今天');
    expect(_entryAt(DateTime(2026, 5, 20, 23)).timeLabel(now), '昨天');
  });

  test('uses weekdays for the rest of the current week', () {
    expect(_entryAt(DateTime(2026, 5, 19)).timeLabel(now), '周二');
    expect(_entryAt(DateTime(2026, 5, 18, 7)).timeLabel(now), '周一');
  });

  test('falls back to the date once the week has passed', () {
    expect(_entryAt(DateTime(2026, 5, 17)).timeLabel(now), '5月17日');
    expect(_entryAt(DateTime(2026, 4, 30)).timeLabel(now), '4月30日');
  });

  test('only today counts as the pine-tinted day', () {
    expect(_entryAt(DateTime(2026, 5, 21, 0, 5)).openedToday(now), isTrue);
    expect(_entryAt(DateTime(2026, 5, 20, 23, 55)).openedToday(now), isFalse);
    expect(_entryAt(DateTime(2026, 5, 19)).openedToday(now), isFalse);
  });
}

ReadingHistoryEntry _entryAt(DateTime openedAt) {
  return ReadingHistoryEntry(
    book: Book(
      id: 'book',
      title: '云边有个小卖部',
      author: '张嘉佳',
      lastChapterIndex: 11,
      lastReadPosition: 120,
      createdAt: openedAt,
      updatedAt: openedAt,
      inShelf: true,
      sortOrder: 0,
      coverShowText: true,
    ),
    chapterCount: 24,
    chapterTitle: '海边的风',
    percent: 36,
  );
}
