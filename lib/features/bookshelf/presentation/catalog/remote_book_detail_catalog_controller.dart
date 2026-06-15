import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../application/bookshelf_providers.dart';

class RemoteCatalogPageLoadResult {
  const RemoteCatalogPageLoadResult({
    required this.loaded,
    this.errorMessage,
  });

  final bool loaded;
  final String? errorMessage;
}

/// 在线书籍目录控制器。
///
/// 这里不直接解析任何书源规则，只负责详情页的“是否为在线书籍、是否还有下一页、
/// 触发下一页/刷新目录”等编排逻辑。具体每个书源如何请求和解析目录，仍由
/// RemoteBookImportService -> RuleEngine 负责，方便后续扩展不同书源。
class RemoteBookDetailCatalogController {
  const RemoteBookDetailCatalogController({required this.ref});

  final WidgetRef ref;

  bool isRemoteBook(Book book) {
    return book.localPath == null &&
        (book.sourceId?.trim().isNotEmpty ?? false) &&
        (book.sourceBookUrl?.trim().isNotEmpty ?? false);
  }

  int displayChapterCount(Book book, int loadedChapterCount) {
    if (!isRemoteBook(book)) return loadedChapterCount;
    return math.max(book.remoteChapterCount ?? 0, loadedChapterCount);
  }

  bool hasMore(Book? book) {
    return book != null &&
        isRemoteBook(book) &&
        (book.remoteNextTocUrl?.trim().isNotEmpty ?? false);
  }

  Future<RemoteCatalogPageLoadResult> loadNextPageIfNeeded(
    String bookId,
  ) async {
    final book = await ref.read(bookshelfRepositoryProvider).findBookById(
          bookId,
        );
    if (!hasMore(book)) {
      return const RemoteCatalogPageLoadResult(loaded: false);
    }

    try {
      final loaded = await ref
          .read(remoteBookImportServiceProvider)
          .loadNextRemoteCatalogPage(bookId);
      if (loaded) invalidateCatalogProviders(bookId);
      return RemoteCatalogPageLoadResult(loaded: loaded);
    } catch (_) {
      return const RemoteCatalogPageLoadResult(
        loaded: false,
        errorMessage: '在线目录加载失败',
      );
    }
  }

  /// 在线目录刷新会重新走书源规则管线，并覆盖本地缓存的在线目录。
  /// 它和本地 TXT 目录分析完全独立，避免两类书籍互相影响。
  Future<String?> refresh(Book book) async {
    final sourceId = book.sourceId?.trim();
    final bookUrl = book.sourceBookUrl?.trim();
    if (sourceId == null ||
        sourceId.isEmpty ||
        bookUrl == null ||
        bookUrl.isEmpty) {
      return null;
    }

    try {
      await ref.read(remoteBookImportServiceProvider).importRemoteBook(
            sourceId: sourceId,
            bookUrl: bookUrl,
            fallbackName: book.title,
            fallbackAuthor: book.author,
            fallbackCoverUrl: book.coverUrl,
            fallbackIntro: book.intro,
            addToShelf: book.inShelf,
          );
      invalidateCatalogProviders(book.id);
      return null;
    } catch (_) {
      return '在线目录获取失败';
    }
  }

  void invalidateCatalogProviders(String bookId) {
    ref
      ..invalidate(bookByIdProvider(bookId))
      ..invalidate(bookChapterCountProvider(bookId))
      ..invalidate(bookChapterMetasProvider(bookId))
      ..invalidate(initialBookChapterMetasProvider(bookId));
  }
}
