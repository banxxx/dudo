import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/importers/legado_source_importer.dart';
import '../data/importers/source_importer.dart';
import '../data/source_import_service.dart';
import '../data/source_repository.dart';

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository(ref.watch(appDatabaseProvider));
});

final legadoSourceImporterProvider = Provider<LegadoSourceImporter>((ref) {
  return const LegadoSourceImporter();
});

final sourceImportersProvider = Provider<List<SourceImporter>>((ref) {
  return [
    ref.watch(legadoSourceImporterProvider),
    // Future dudo-native importers should be added here without changing
    // the Legado importer implementation.
  ];
});

final sourceImportServiceProvider = Provider<SourceImportService>((ref) {
  return SourceImportService(
    repository: ref.watch(sourceRepositoryProvider),
    importers: ref.watch(sourceImportersProvider),
  );
});

final sourcesProvider = StreamProvider<List<Source>>((ref) {
  return ref.watch(sourceRepositoryProvider).watchSources();
});
