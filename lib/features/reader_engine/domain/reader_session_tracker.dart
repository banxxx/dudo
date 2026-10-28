import 'reader_location.dart';

/// How much was read since the last [ReadingSessionTracker.takeDelta] call.
class ReadingSessionDelta {
  const ReadingSessionDelta({
    required this.chapters,
    required this.characters,
  });

  final int chapters;
  final int characters;
}

/// Tracks how much of a book was read during one reader visit so the reading
/// session can report chapters and characters.
///
/// Only forward movement counts: page turns add the skipped characters, a
/// chapter change adds the rest of the chapter being left plus the part read
/// in the next one, and jumps (catalog, bookmarks) add nothing. A chapter
/// counts as completed only once the reader moves on to the next one, so
/// opening a chapter and leaving does not inflate the goal.
class ReadingSessionTracker {
  final Set<int> _completedChapters = <int>{};
  final Set<int> _recordedChapters = <int>{};
  int _characters = 0;
  int _recordedCharacters = 0;
  ReaderLocation? _lastLocation;
  int _lastChapterLength = 0;

  void onLocationChanged(ReaderLocation location, int chapterLength) {
    final last = _lastLocation;

    if (last != null) {
      if (location.chapterIndex == last.chapterIndex) {
        final delta = location.offset - last.offset;
        if (delta > 0) _characters += delta;
      } else if (location.chapterIndex == last.chapterIndex + 1) {
        _completedChapters.add(last.chapterIndex);
        final remaining = _lastChapterLength - last.offset;
        if (remaining > 0) _characters += remaining;
        final offset = location.offset.clamp(0, chapterLength);
        if (offset > 0) _characters += offset;
      }
    }

    _lastLocation = location;
    _lastChapterLength = chapterLength;
  }

  /// Returns the progress since the previous call and marks it as recorded so
  /// pausing and resuming does not count the same chapter twice.
  ReadingSessionDelta takeDelta() {
    final chapters =
        _completedChapters.difference(_recordedChapters).length;
    _recordedChapters.addAll(_completedChapters);

    final characters = _characters - _recordedCharacters;
    _recordedCharacters = _characters;

    return ReadingSessionDelta(chapters: chapters, characters: characters);
  }
}
