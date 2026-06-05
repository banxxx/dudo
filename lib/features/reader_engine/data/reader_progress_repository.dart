import '../domain/reader_location.dart';

abstract interface class ReaderProgressRepository {
  Future<ReaderLocation?> loadProgress(String bookId);

  Future<void> saveProgress(ReaderLocation location);
}
