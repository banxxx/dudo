import '../data/reader_progress_repository.dart';
import '../domain/reader_location.dart';

class ReaderProgressController {
  ReaderProgressController(this.repository);

  final ReaderProgressRepository repository;
  var _suppressSave = false;

  Future<T> runWithoutSaving<T>(Future<T> Function() action) async {
    final previous = _suppressSave;
    _suppressSave = true;
    try {
      return await action();
    } finally {
      _suppressSave = previous;
    }
  }

  Future<void> saveIfAllowed({
    required ReaderLocation location,
    required bool isProgrammaticChange,
  }) async {
    if (_suppressSave || isProgrammaticChange) return;
    await repository.saveProgress(location);
  }
}
