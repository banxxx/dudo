import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/reader_background_repository.dart';
import '../domain/reader_background.dart';

final readerBackgroundRepositoryProvider =
    Provider<ReaderBackgroundRepository>((ref) {
  return DriftReaderBackgroundRepository(ref.watch(appDatabaseProvider));
});

final readerBackgroundControllerProvider = StateNotifierProvider<
    ReaderBackgroundController, AsyncValue<ReaderBackgroundState>>((ref) {
  return ReaderBackgroundController(
    repository: ref.watch(readerBackgroundRepositoryProvider),
  );
});

class ReaderBackgroundState {
  const ReaderBackgroundState({
    required this.current,
    required this.custom,
  });

  factory ReaderBackgroundState.defaults() {
    return ReaderBackgroundState(
      current: ReaderBackgroundPreference.defaults(),
      custom: null,
    );
  }

  final ReaderBackgroundPreference current;
  final ReaderBackgroundPreference? custom;
}

class ReaderBackgroundController
    extends StateNotifier<AsyncValue<ReaderBackgroundState>> {
  ReaderBackgroundController({
    required ReaderBackgroundRepository repository,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    reload();
  }

  final ReaderBackgroundRepository _repository;
  int _requestVersion = 0;

  Future<void> reload() async {
    final requestVersion = ++_requestVersion;
    state = const AsyncValue.loading();
    final next = await AsyncValue.guard(() async {
      return ReaderBackgroundState(
        current: await _repository.readPreference(),
        custom: await _repository.readCustomPreference(),
      );
    });
    if (requestVersion == _requestVersion) {
      state = next;
    }
  }

  Future<void> select(ReaderBackgroundPreference preference) async {
    final requestVersion = ++_requestVersion;
    final previous = state;
    final previousValue =
        previous.valueOrNull ?? ReaderBackgroundState.defaults();
    final custom = preference.type == ReaderBackgroundType.customImage
        ? preference
        : previousValue.custom;
    state = AsyncValue.data(
      ReaderBackgroundState(current: preference, custom: custom),
    );
    try {
      await _repository.savePreference(preference);
    } catch (error, stackTrace) {
      if (requestVersion == _requestVersion) {
        state = previous;
      }
      return Future<void>.error(error, stackTrace);
    }
  }

  Future<ReaderBackgroundPreference?> importCustom() async {
    final requestVersion = ++_requestVersion;
    final previous = state;
    try {
      final preference = await _repository.pickAndImportBackground();
      if (preference != null) {
        state = AsyncValue.data(
          ReaderBackgroundState(
            current: preference,
            custom: preference,
          ),
        );
      }
      return preference;
    } catch (error, stackTrace) {
      if (requestVersion == _requestVersion) {
        state = previous;
      }
      return Future<ReaderBackgroundPreference?>.error(error, stackTrace);
    }
  }
}
