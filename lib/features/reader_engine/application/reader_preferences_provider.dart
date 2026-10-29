import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/reader_preferences_repository.dart';
import '../domain/reader_preferences.dart';

final readerPreferencesRepositoryProvider =
    Provider<ReaderPreferencesRepository>((ref) {
  return DriftReaderPreferencesRepository(ref.watch(appDatabaseProvider));
});

/// The persisted reader settings, watched by screens that only display them.
final readerPreferencesProvider = StreamProvider<ReaderPreferences>((ref) {
  return ref.watch(readerPreferencesRepositoryProvider).watch();
});
