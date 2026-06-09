import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/reader_font_repository.dart';
import '../domain/reader_font.dart';

final readerFontRepositoryProvider = Provider<ReaderFontRepository>((ref) {
  return DriftReaderFontRepository(ref.watch(appDatabaseProvider));
});

final selectedReaderFontFamilyProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(readerFontRepositoryProvider);
  await repository.loadImportedFonts();
  return repository.readSelectedFontFamily();
});

final readerFontLibraryControllerProvider = StateNotifierProvider<
    ReaderFontLibraryController, AsyncValue<ReaderFontLibrary>>((ref) {
  return ReaderFontLibraryController(
    repository: ref.watch(readerFontRepositoryProvider),
    onSelectedChanged: () => ref.invalidate(selectedReaderFontFamilyProvider),
  );
});

class ReaderFontLibraryController
    extends StateNotifier<AsyncValue<ReaderFontLibrary>> {
  ReaderFontLibraryController({
    required ReaderFontRepository repository,
    required void Function() onSelectedChanged,
  })  : _repository = repository,
        _onSelectedChanged = onSelectedChanged,
        super(const AsyncValue.loading()) {
    reload();
  }

  final ReaderFontRepository _repository;
  final void Function() _onSelectedChanged;

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.loadLibrary);
  }

  Future<ReaderFont?> importFont() async {
    state = const AsyncValue.loading();
    try {
      final font = await _repository.pickAndImportFont();
      final library = await _repository.loadLibrary();
      state = AsyncValue.data(library);
      if (font != null) _onSelectedChanged();
      return font;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return Future<ReaderFont?>.error(error, stackTrace);
    }
  }

  Future<void> selectFont(String familyKey) async {
    final previous = state;
    state = const AsyncValue.loading();
    try {
      await _repository.selectFont(familyKey);
      state = AsyncValue.data(await _repository.loadLibrary());
      _onSelectedChanged();
    } catch (error, stackTrace) {
      state = previous;
      return Future<void>.error(error, stackTrace);
    }
  }

  Future<void> deleteFont(String id) async {
    final previous = state;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteImportedFont(id);
      state = AsyncValue.data(await _repository.loadLibrary());
      _onSelectedChanged();
    } catch (error, stackTrace) {
      state = previous;
      return Future<void>.error(error, stackTrace);
    }
  }
}
