import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_session_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReaderLocation at(int chapter, int offset) {
    return ReaderLocation(
      bookId: 'book-1',
      chapterIndex: chapter,
      offset: offset,
    );
  }

  test('page turns add the skipped characters but complete no chapter', () {
    final tracker = ReadingSessionTracker();

    tracker.onLocationChanged(at(0, 0), 1000);
    tracker.onLocationChanged(at(0, 400), 1000);
    tracker.onLocationChanged(at(0, 800), 1000);

    final delta = tracker.takeDelta();
    expect(delta.characters, 800);
    expect(delta.chapters, 0);
  });

  test('moving backwards does not subtract characters', () {
    final tracker = ReadingSessionTracker();

    tracker.onLocationChanged(at(0, 400), 1000);
    tracker.onLocationChanged(at(0, 100), 1000);

    expect(tracker.takeDelta().characters, 0);
  });

  test('leaving a chapter completes it and adds the rest plus the new offset',
      () {
    final tracker = ReadingSessionTracker();

    tracker.onLocationChanged(at(2, 700), 1000);
    tracker.onLocationChanged(at(3, 200), 1200);

    final delta = tracker.takeDelta();
    expect(delta.characters, 300 + 200);
    expect(delta.chapters, 1);
  });

  test('jumps add no characters and complete no chapter', () {
    final tracker = ReadingSessionTracker();

    tracker.onLocationChanged(at(0, 0), 1000);
    tracker.onLocationChanged(at(10, 0), 1000);

    final delta = tracker.takeDelta();
    expect(delta.characters, 0);
    expect(delta.chapters, 0);
  });

  test('takeDelta only reports each increment once', () {
    final tracker = ReadingSessionTracker();

    tracker.onLocationChanged(at(0, 0), 1000);
    tracker.onLocationChanged(at(1, 0), 1000);
    expect(tracker.takeDelta().chapters, 1);

    tracker.onLocationChanged(at(1, 300), 1000);
    final second = tracker.takeDelta();
    expect(second.characters, 300);
    expect(second.chapters, 0);
  });
}
