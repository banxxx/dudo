import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/bookmarks_repository.dart';
import '../domain/bookmark_entry.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) {
  return BookmarksRepository(ref.watch(appDatabaseProvider));
});

final bookmarkEntriesProvider = StreamProvider<List<BookmarkEntry>>((ref) {
  return ref.watch(bookmarksRepositoryProvider).watchEntries();
});
