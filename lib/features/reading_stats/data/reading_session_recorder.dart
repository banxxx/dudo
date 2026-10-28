import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Writes the reading sessions that power the stats screens and the home
/// reading-rhythm card.
class ReadingSessionRecorder {
  const ReadingSessionRecorder(this.database);

  final AppDatabase database;

  /// Stores a completed session. Sessions shorter than a second are ignored so
  /// opening and immediately closing the reader does not add noise.
  Future<void> record({
    required String bookId,
    required DateTime startedAt,
    required DateTime endedAt,
    int wordsRead = 0,
    int chaptersRead = 0,
  }) async {
    final seconds = endedAt.difference(startedAt).inSeconds;
    if (seconds <= 0) return;

    await database.into(database.readingSessions).insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            startedAt: startedAt,
            endedAt: Value(endedAt),
            durationSeconds: Value(seconds),
            wordsRead: Value(wordsRead),
            chaptersRead: Value(chaptersRead),
          ),
        );
  }
}
