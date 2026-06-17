import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookshelf/application/bookshelf_providers.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../search/application/search_providers.dart';
import '../../sources/application/source_providers.dart';
import '../data/bookshelf_reader_annotation_repository.dart';
import '../data/bookshelf_reader_progress_repository.dart';
import '../data/reader_annotation_repository.dart';
import '../data/reader_document_source.dart';
import '../data/reader_progress_repository.dart';
import '../data/remote_reader_content_loader.dart';
import '../data/text_reader_book_repository.dart';
import '../data/text_reader_document_source.dart';

final readerDocumentSourceProvider = Provider<ReaderDocumentSource>((ref) {
  final repository = ref.watch(bookshelfRepositoryProvider);
  final textRepository = BookshelfTextReaderBookRepository(repository);
  final cookieStore = ref.watch(legadoCookieStoreProvider).valueOrNull;
  return TextReaderDocumentSource(
    textRepository,
    remoteContentLoader: RemoteReaderContentLoader.fromRepositories(
      repository: textRepository,
      sourceRepository: ref.watch(sourceRepositoryProvider),
      ruleEngine: RuleEngine.create(cookieStore: cookieStore),
    ),
  );
});

final readerProgressRepositoryProvider =
    Provider<ReaderProgressRepository>((ref) {
  return BookshelfReaderProgressRepository(
    ref.watch(bookshelfRepositoryProvider),
  );
});

final readerAnnotationRepositoryProvider =
    Provider<ReaderAnnotationRepository>((ref) {
  return BookshelfReaderAnnotationRepository(ref.watch(appDatabaseProvider));
});
