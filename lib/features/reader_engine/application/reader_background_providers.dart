import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/reader_background_repository.dart';
import '../domain/reader_background.dart';

final readerBackgroundRepositoryProvider =
    Provider<ReaderBackgroundRepository>((ref) {
  return DriftReaderBackgroundRepository(ref.watch(appDatabaseProvider));
});

final readerBackgroundControllerProvider = StateNotifierProvider<
    ReaderBackgroundController, AsyncValue<ReaderBackgroundPreference>>((ref) {
  return ReaderBackgroundController(
    repository: ref.watch(readerBackgroundRepositoryProvider),
  );
});

class ReaderBackgroundController
    extends StateNotifier<AsyncValue<ReaderBackgroundPreference>> {
  ReaderBackgroundController({
    required ReaderBackgroundRepository repository,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    reload();
  }

  final ReaderBackgroundRepository _repository;

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.readPreference);
  }

  Future<void> select(ReaderBackgroundPreference preference) async {
    final previous = state;
    state = AsyncValue.data(preference);
    try {
      await _repository.savePreference(preference);
    } catch (error, stackTrace) {
      state = previous;
      return Future<void>.error(error, stackTrace);
    }
  }
}
