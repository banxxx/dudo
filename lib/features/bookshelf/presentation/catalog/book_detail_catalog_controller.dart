import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../application/bookshelf_providers.dart';
import 'local_book_detail_catalog_controller.dart';
import 'remote_book_detail_catalog_controller.dart';

typedef BookDetailCatalogSetState = void Function(void Function() update);
typedef BookDetailCatalogCallback = void Function();

const int chapterCatalogPageSize = 80;
const double chapterCatalogPrefetchExtent = 900.0;

/// 书籍详情页目录协调器。
///
/// 页面只关心“展示哪些章节、是否正在加载、是否还有更多”等 UI 状态；
/// 这里负责从数据库分页读取章节，并在在线书籍滚动到底部时触发下一页网络目录。
class BookDetailCatalogController {
  BookDetailCatalogController({
    required this.bookId,
    required this.ref,
    required this.setState,
    required this.isMounted,
    this.onPageChanged,
  })  : remote = RemoteBookDetailCatalogController(ref: ref),
        local = LocalBookDetailCatalogController(ref: ref);

  final String bookId;
  final WidgetRef ref;
  final BookDetailCatalogSetState setState;
  final bool Function() isMounted;
  final BookDetailCatalogCallback? onPageChanged;
  final RemoteBookDetailCatalogController remote;
  final LocalBookDetailCatalogController local;

  final List<Chapter> _chapters = [];
  bool _isLoadingPage = false;
  bool _isRefreshingRemote = false;
  bool _hasMorePages = true;
  String? _remoteError;

  List<Chapter> get chapters => _chapters;
  bool get isLoadingPage => _isLoadingPage;
  bool get isRefreshingRemote => _isRefreshingRemote;
  bool get hasMorePages => _hasMorePages;
  String? get remoteError => _remoteError;

  int loadedChapterCount(AsyncValue<int> chapterCountValue) {
    return chapterCountValue.valueOrNull ?? _chapters.length;
  }

  int displayChapterCount(Book book, int loadedChapterCount) {
    return remote.displayChapterCount(book, loadedChapterCount);
  }

  bool chaptersLoading({
    required Book book,
    required AsyncValue<int> chapterCountValue,
  }) {
    return _chapters.isEmpty &&
        (_isLoadingPage ||
            chapterCountValue.isLoading ||
            (remote.isRemoteBook(book) && _isRefreshingRemote));
  }

  void resetAndLoad() {
    _chapters.clear();
    _hasMorePages = true;
    _isLoadingPage = false;
    unawaited(loadNextPage());
  }

  Future<void> loadNextPage() async {
    if (_isLoadingPage || !_hasMorePages || !isMounted()) return;
    setState(() => _isLoadingPage = true);
    try {
      var page =
          await ref.read(bookshelfRepositoryProvider).fetchChapterMetasPage(
                bookId: bookId,
                offset: _chapters.length,
                limit: chapterCatalogPageSize,
              );

      if (page.isEmpty) {
        final remoteResult = await remote.loadNextPageIfNeeded(bookId);
        if (remoteResult.errorMessage != null && isMounted()) {
          setState(() => _remoteError = remoteResult.errorMessage);
        }
        if (remoteResult.loaded) {
          page =
              await ref.read(bookshelfRepositoryProvider).fetchChapterMetasPage(
                    bookId: bookId,
                    offset: _chapters.length,
                    limit: chapterCatalogPageSize,
                  );
        }
      }

      final book = await ref.read(bookshelfRepositoryProvider).findBookById(
            bookId,
          );
      if (!isMounted()) return;
      setState(() {
        _chapters.addAll(page);
        _hasMorePages =
            page.length == chapterCatalogPageSize || remote.hasMore(book);
        _isLoadingPage = false;
      });
      onPageChanged?.call();
    } catch (_) {
      if (isMounted()) setState(() => _isLoadingPage = false);
    }
  }

  Future<void> refreshRemote(Book book) async {
    if (_isRefreshingRemote) return;

    setState(() {
      _isRefreshingRemote = true;
      _remoteError = null;
      _chapters.clear();
      _hasMorePages = true;
      _isLoadingPage = false;
    });

    try {
      final errorMessage = await remote.refresh(book);
      if (!isMounted()) return;
      if (errorMessage != null) {
        setState(() => _remoteError = errorMessage);
        return;
      }
      await loadNextPage();
    } finally {
      if (isMounted()) {
        setState(() => _isRefreshingRemote = false);
      }
    }
  }
}
