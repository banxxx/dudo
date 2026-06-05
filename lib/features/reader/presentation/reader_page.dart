import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../features/bookshelf/application/bookshelf_providers.dart';
import '../../../features/bookshelf/data/bookshelf_repository.dart';
import '../../../shared/theme/app_theme.dart';
import '../domain/reader_catalog_item.dart';
import '../domain/reader_chapter_view.dart';
import '../domain/reader_overlay_mode.dart';
import 'layout/reader_page_layout.dart';
import 'layout/reader_page_metrics.dart';
import 'modes/reader_turn_mode.dart';
import 'modes/scroll/reader_scroll_block.dart';
import 'modes/scroll/reader_scroll_chapter_entry.dart';
import 'modes/scroll/reader_scroll_mode_view.dart';
import 'reader_controls.dart';
import 'widgets/reader_background.dart';
import 'widgets/reader_gesture_layer.dart';
import 'widgets/reader_progress.dart';
import 'widgets/reader_state_message.dart';
import 'widgets/reading_article.dart';

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({
    super.key,
    required this.bookId,
    this.initialChapterIndex = 0,
  });

  final String bookId;
  final int initialChapterIndex;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  static const int _catalogPageSize = 30;

  Timer? _saveProgressTimer;

  ReaderOverlayMode _overlayMode = ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _brightness = 0.72;
  ReaderTurnMode _pageTurnMode = ReaderTurnMode.slide;
  bool _isListening = false;
  int _pageIndex = 0;
  int _currentReadPosition = 0;
  int? _restoredChapterIndex;
  int? _currentScrollChapterIndex;
  int? _currentScrollContentLength;
  String? _currentScrollChapterTitle;
  int? _lastSavedChapterIndex;
  int? _lastSavedReadPosition;
  int? _pendingSaveChapterIndex;
  int? _pendingSaveReadPosition;
  bool _pendingSaveBumpRecency = false;
  _ReaderPaginationKey? _cachedPaginationKey;
  List<ReaderPageSlice>? _cachedPages;
  final List<Chapter> _catalogMetas = [];
  bool _catalogIsLoadingMore = false;
  bool _catalogHasMore = true;
  int _catalogLoadedCount = 0;
  int? _providerChapterIndex;
  late BookshelfRepository _repository;
  late int _currentChapterIndex;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(bookshelfRepositoryProvider);
    _currentChapterIndex = widget.initialChapterIndex;
    _syncSystemUiMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUiMode());
  }

  @override
  void dispose() {
    _flushPendingProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    });
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.initialChapterIndex != widget.initialChapterIndex) {
      _currentChapterIndex = widget.initialChapterIndex;
      _providerChapterIndex = null;
      _pageIndex = 0;
      _currentReadPosition = 0;
      _restoredChapterIndex = null;
      _resetCatalogPaging();
    }
    _syncSystemUiMode();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _palette.foreground;
    final statusStyle = foreground.computeLuminance() > 0.5
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final bookValue = ref.watch(bookByIdProvider(widget.bookId));
    final chapterCountValue =
        ref.watch(bookChapterCountProvider(widget.bookId));
    final effectiveChapterIndex = _effectiveChapterIndex(
      chapterCountValue.valueOrNull,
      preferredChapterIndex: _pageTurnMode == ReaderTurnMode.scroll
          ? _providerChapterIndex ?? _currentChapterIndex
          : _currentChapterIndex,
    );
    final currentChapterKey = CurrentBookChapterKey(
      bookId: widget.bookId,
      chapterIndex: effectiveChapterIndex,
    );
    final currentChapterMetaValue =
        ref.watch(currentBookChapterMetaProvider(currentChapterKey));
    final currentChapterValue =
        ref.watch(currentBookChapterContentProvider(currentChapterKey));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusStyle.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        key: const ValueKey('reader-page'),
        extendBodyBehindAppBar: true,
        backgroundColor: _palette.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = ReaderPageMetrics.fromSize(constraints.biggest);
            final content = _buildReaderContent(
              context: context,
              metrics: metrics,
              bookValue: bookValue,
              chapterCountValue: chapterCountValue,
              currentChapterMetaValue: currentChapterMetaValue,
              currentChapterValue: currentChapterValue,
              currentChapterKey: currentChapterKey,
            );
            return Stack(
              children: [
                ReaderPaperBackground(palette: _palette),
                ReaderSoftPageEdge(metrics: metrics),
                content,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReaderContent({
    required BuildContext context,
    required ReaderPageMetrics metrics,
    required AsyncValue<Book?> bookValue,
    required AsyncValue<int> chapterCountValue,
    required AsyncValue<Chapter?> currentChapterMetaValue,
    required AsyncValue<Chapter?> currentChapterValue,
    required CurrentBookChapterKey currentChapterKey,
  }) {
    if (bookValue.hasError ||
        chapterCountValue.hasError ||
        currentChapterMetaValue.hasError ||
        currentChapterValue.hasError) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '打开失败',
        message: '无法加载书籍或章节',
        actionLabel: '重试',
        onAction: () {
          ref.invalidate(bookByIdProvider(widget.bookId));
          ref.invalidate(bookChapterCountProvider(widget.bookId));
          ref.invalidate(currentBookChapterMetaProvider(currentChapterKey));
          ref.invalidate(currentBookChapterContentProvider(currentChapterKey));
        },
      );
    }
    if (bookValue.isLoading || chapterCountValue.isLoading) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '正在打开书籍…',
        message: '正在读取章节目录',
      );
    }

    final book = bookValue.valueOrNull;
    if (book == null) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '书籍不存在',
        message: '这本书可能已被删除',
        actionLabel: '返回',
        onAction: () => context.pop(),
      );
    }

    final chapterCount = chapterCountValue.valueOrNull ?? 0;
    if (chapterCount == 0) {
      final localPath = book.localPath;
      if (localPath != null) {
        ref.read(localBookChapterAnalysisServiceProvider).analyzeInBackground(
              bookId: book.id,
              localPath: localPath,
            );
      }
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '章节计算中',
        message: '正在分析本地目录，请稍后再试',
      );
    }

    if (currentChapterMetaValue.isLoading || currentChapterValue.isLoading) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '正在打开章节…',
        message: '正在读取当前章节内容',
      );
    }

    final currentChapterMeta = currentChapterMetaValue.valueOrNull;
    final currentChapter = currentChapterValue.valueOrNull;
    if (currentChapterMeta == null || currentChapter == null) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '章节不存在',
        message: '这章内容可能已被删除或尚未缓存',
      );
    }

    final localPath = book.localPath;
    final currentChapterContentLength = currentChapter.content?.length ?? 0;
    if (localPath != null &&
        chapterCount == 1 &&
        currentChapterContentLength > 60000) {
      ref.read(localBookChapterAnalysisServiceProvider).analyzeInBackground(
            bookId: book.id,
            localPath: localPath,
          );
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '章节计算中',
        message: '正在重新分析本地目录，请稍后再试',
      );
    }

    final view = ReaderChapterView.fromChapter(
      book: book,
      chapterMeta: currentChapterMeta,
      currentChapter: currentChapter,
      chapterCount: chapterCount,
    );
    final isScrollMode = _pageTurnMode == ReaderTurnMode.scroll;
    _providerChapterIndex ??= view.currentChapterIndex;
    _syncCurrentChapterIndex(
      view.currentChapterIndex,
      syncProvider: !isScrollMode,
    );
    if (view.contentMissing) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '暂无正文内容',
        message: '该章节内容尚未缓存',
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final articleTop = topInset + metrics.s(18);
    final footerTop = metrics.height - bottomInset - metrics.s(44);
    final articleHeight = (footerTop - articleTop - metrics.s(18))
        .clamp(metrics.s(520), metrics.height)
        .toDouble();
    final pages = isScrollMode
        ? const <ReaderPageSlice>[]
        : _pagesFor(
            view: view,
            metrics: metrics,
            articleHeight: articleHeight,
          );
    final restoredPosition = isScrollMode
        ? _restoreScrollReadPositionIfNeeded(book: book, view: view)
        : _restoreReadPositionIfNeeded(
            book: book,
            view: view,
            pages: pages,
          );
    final readPosition = restoredPosition ??
        _currentReadPosition.clamp(0, view.text.length).toInt();
    final pageIndex = isScrollMode
        ? 0
        : ReaderPageLayout.pageIndexForPosition(
            pages: pages,
            readPosition: readPosition,
          );
    if (!isScrollMode && pageIndex != _pageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _pageIndex = pageIndex);
        }
      });
    }
    final progressChapterIndex = isScrollMode
        ? _currentScrollChapterIndex ?? view.currentChapterIndex
        : view.currentChapterIndex;
    final progressContentLength = isScrollMode
        ? _currentScrollContentLength ?? view.text.length
        : view.text.length;
    final progressChapterTitle = isScrollMode
        ? _currentScrollChapterTitle ?? view.chapterLabel
        : view.chapterLabel;
    final progressReadPosition = isScrollMode
        ? _currentReadPosition.clamp(0, progressContentLength).toInt()
        : readPosition;
    final chapterProgress = progressContentLength <= 0
        ? 0.0
        : (progressReadPosition.clamp(0, progressContentLength).toDouble() /
                progressContentLength)
            .clamp(0.0, 1.0)
            .toDouble();
    final bookProgress =
        ((progressChapterIndex + chapterProgress) / view.chapterCount)
            .clamp(0.0, 1.0)
            .toDouble();
    final catalogItems = _overlayMode == ReaderOverlayMode.catalog
        ? _catalogItemsFor(
            chapterMetas: _catalogMetas,
            currentChapterIndex: view.currentChapterIndex,
          )
        : const <ReaderCatalogItem>[];

    return Stack(
      children: [
        Positioned.fill(
          child: ReaderGestureLayer(
            overlayMode: _overlayMode,
            pageTurnMode: _pageTurnMode,
            onToggleOverlay: _toggleOverlay,
            onPreviousPage: () => _turnPage(
              pages: pages,
              view: view,
              direction: -1,
            ),
            onNextPage: () => _turnPage(
              pages: pages,
              view: view,
              direction: 1,
            ),
          ),
        ),
        if (isScrollMode)
          ReaderScrollModeView(
            bookId: widget.bookId,
            chapterCount: view.chapterCount,
            initialChapterIndex: view.currentChapterIndex,
            initialReadPosition: readPosition,
            initialChapter: ReaderScrollChapterEntry(
              chapterIndex: view.currentChapterIndex,
              title: view.chapterTitle,
              text: view.text,
              paragraphSpans: view.paragraphSpans,
            ),
            repository: _repository,
            metrics: metrics,
            palette: _palette,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            top: articleTop,
            height: articleHeight,
            interactive: _overlayMode == ReaderOverlayMode.hidden,
            preview: _overlayMode != ReaderOverlayMode.hidden &&
                _overlayMode != ReaderOverlayMode.controls,
            onProgressChanged: _updateScrollProgress,
            onTap: _toggleOverlay,
          )
        else
          ReadingArticle(
            metrics: metrics,
            palette: _palette,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            top: articleTop,
            height: articleHeight,
            pageIndex: pageIndex,
            pages: pages,
            interactive: false,
            preview: _overlayMode != ReaderOverlayMode.hidden &&
                _overlayMode != ReaderOverlayMode.controls,
          ),
        ReaderProgress(
          metrics: metrics,
          palette: _palette,
          pageLabel: isScrollMode
              ? progressChapterTitle
              : '${view.chapterLabel} · ${pageIndex + 1}/${pages.length}',
          progress: chapterProgress,
        ),
        ReaderControls(
          mode: _overlayMode,
          bookTitle: view.bookTitle,
          chapterLabel: view.chapterLabel,
          chapterTitle: view.chapterTitle,
          progress: bookProgress,
          remainingText: view.remainingText,
          palette: _palette,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          brightness: _brightness,
          pageTurnMode: _pageTurnMode,
          isListening: _isListening,
          currentChapterIndex: view.currentChapterIndex,
          chapterCount: view.chapterCount,
          catalogItems: catalogItems,
          catalogHasMore: _catalogHasMore,
          catalogIsLoadingMore: _catalogIsLoadingMore,
          onCatalogLoadMore: () => _loadMoreCatalog(chapterCount),
          onBack: () {
            _saveCurrentProgressNow(view);
            context.pop();
          },
          onClose: () => _setOverlayMode(ReaderOverlayMode.controls),
          onModeChanged: (mode) =>
              _setOverlayMode(mode, chapterCount: chapterCount),
          onChapterSelected: _selectChapter,
          onPreviousChapter: view.previousChapterIndex == null
              ? null
              : () => _selectChapter(view.previousChapterIndex!),
          onNextChapter: view.nextChapterIndex == null
              ? null
              : () => _selectChapter(view.nextChapterIndex!),
          onPaletteChanged: (palette) => setState(() => _palette = palette),
          onFontSizeChanged: (fontSize) => setState(() {
            _fontSize = fontSize;
            _restoredChapterIndex = null;
            _currentScrollChapterIndex = null;
            _currentScrollContentLength = null;
            _currentScrollChapterTitle = null;
          }),
          onLineHeightChanged: (lineHeight) => setState(() {
            _lineHeight = lineHeight;
            _restoredChapterIndex = null;
            _currentScrollChapterIndex = null;
            _currentScrollContentLength = null;
            _currentScrollChapterTitle = null;
          }),
          onBrightnessChanged: (brightness) =>
              setState(() => _brightness = brightness),
          onPageTurnModeChanged: (mode) => setState(() => _pageTurnMode = mode),
          onListeningChanged: (listening) =>
              setState(() => _isListening = listening),
        ),
      ],
    );
  }

  List<ReaderCatalogItem> _catalogItemsFor({
    required List<Chapter> chapterMetas,
    required int currentChapterIndex,
  }) {
    return [
      for (var i = 0; i < chapterMetas.length; i++)
        ReaderCatalogItem(
          chapterIndex: chapterMetas[i].chapterIndex,
          title: chapterMetas[i].title,
          subtitle: chapterMetas[i].chapterIndex == currentChapterIndex
              ? '正在阅读'
              : '已缓存',
        ),
    ];
  }

  List<ReaderPageSlice> _pagesFor({
    required ReaderChapterView view,
    required ReaderPageMetrics metrics,
    required double articleHeight,
  }) {
    final key = _ReaderPaginationKey(
      bookId: widget.bookId,
      chapterIndex: view.currentChapterIndex,
      textLength: view.text.length,
      textHash: view.text.hashCode,
      metricsWidth: metrics.width,
      metricsHeight: metrics.height,
      articleHeight: articleHeight,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
    );
    final cachedPages = _cachedPages;
    if (_cachedPaginationKey == key && cachedPages != null) {
      return cachedPages;
    }
    final pages = ReaderPageLayout.paginate(
      text: view.text,
      metrics: metrics,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      availableHeight: articleHeight,
    );
    _cachedPaginationKey = key;
    _cachedPages = pages;
    return pages;
  }

  int _effectiveChapterIndex(
    int? chapterCount, {
    int? preferredChapterIndex,
  }) {
    final chapterIndex = preferredChapterIndex ?? _currentChapterIndex;
    if (chapterCount == null || chapterCount <= 0) return chapterIndex;
    return chapterIndex.clamp(0, chapterCount - 1).toInt();
  }

  void _syncCurrentChapterIndex(
    int chapterIndex, {
    bool syncProvider = true,
  }) {
    if (_currentChapterIndex == chapterIndex &&
        (!syncProvider || _providerChapterIndex == chapterIndex)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentChapterIndex = chapterIndex;
          if (syncProvider) _providerChapterIndex = chapterIndex;
        });
      }
    });
  }

  Future<void> _loadMoreCatalog(int chapterCount) async {
    if (_catalogIsLoadingMore || !_catalogHasMore) return;
    if (_catalogLoadedCount >= chapterCount) {
      setState(() => _catalogHasMore = false);
      return;
    }
    setState(() => _catalogIsLoadingMore = true);
    final offset = _catalogLoadedCount;
    final metas = await _repository.fetchChapterMetasPage(
      bookId: widget.bookId,
      offset: offset,
      limit: _catalogPageSize,
    );
    if (!mounted) return;
    setState(() {
      _catalogMetas.addAll(metas);
      _catalogLoadedCount += metas.length;
      _catalogHasMore = _catalogLoadedCount < chapterCount;
      _catalogIsLoadingMore = false;
    });
  }

  void _resetCatalogPaging() {
    _catalogMetas.clear();
    _catalogLoadedCount = 0;
    _catalogHasMore = true;
    _catalogIsLoadingMore = false;
  }

  void _toggleOverlay() {
    _setOverlayMode(
      _overlayMode == ReaderOverlayMode.hidden
          ? ReaderOverlayMode.controls
          : ReaderOverlayMode.hidden,
    );
  }

  void _setOverlayMode(ReaderOverlayMode mode, {int? chapterCount}) {
    if (_overlayMode == mode) return;
    setState(() => _overlayMode = mode);
    if (mode == ReaderOverlayMode.catalog && chapterCount != null) {
      _loadMoreCatalog(chapterCount);
    }
    _syncSystemUiMode(mode);
  }

  void _turnPage({
    required List<ReaderPageSlice> pages,
    required ReaderChapterView view,
    required int direction,
  }) {
    if (_pageTurnMode == ReaderTurnMode.scroll) {
      return;
    }
    final nextPageIndex = _pageIndex + direction;
    if (nextPageIndex >= 0 && nextPageIndex < pages.length) {
      final readPosition = pages[nextPageIndex].startOffset;
      setState(() {
        _pageIndex = nextPageIndex;
        _currentReadPosition = readPosition;
      });
      _saveReadingProgress(
        chapterIndex: view.currentChapterIndex,
        readPosition: readPosition,
        force: true,
        bumpRecency: true,
      );
      return;
    }
    if (direction < 0 && view.previousChapterIndex != null) {
      _turnChapter(view.previousChapterIndex!, initialReadPosition: 1 << 30);
      return;
    }
    if (direction > 0 && view.nextChapterIndex != null) {
      _turnChapter(view.nextChapterIndex!, initialReadPosition: 0);
    }
  }

  void _turnChapter(int chapterIndex, {required int initialReadPosition}) {
    if (_currentChapterIndex == chapterIndex) return;
    setState(() {
      _currentChapterIndex = chapterIndex;
      _providerChapterIndex = chapterIndex;
      _pageIndex = 0;
      _currentReadPosition = initialReadPosition;
      _restoredChapterIndex = null;
      _currentScrollChapterIndex = null;
      _currentScrollContentLength = null;
      _currentScrollChapterTitle = null;
      _overlayMode = ReaderOverlayMode.hidden;
    });
    if (initialReadPosition < 1 << 30) {
      _saveReadingProgress(
        chapterIndex: chapterIndex,
        readPosition: initialReadPosition,
        force: true,
        bumpRecency: true,
      );
    }
    _syncSystemUiMode(ReaderOverlayMode.hidden);
  }

  void _selectChapter(int chapterIndex) {
    if (_currentChapterIndex == chapterIndex) {
      _setOverlayMode(ReaderOverlayMode.controls);
      return;
    }
    setState(() {
      _currentChapterIndex = chapterIndex;
      _providerChapterIndex = chapterIndex;
      _pageIndex = 0;
      _currentReadPosition = 0;
      _restoredChapterIndex = null;
      _currentScrollChapterIndex = null;
      _currentScrollContentLength = null;
      _currentScrollChapterTitle = null;
      _overlayMode = ReaderOverlayMode.controls;
    });
    _saveReadingProgress(
      chapterIndex: chapterIndex,
      readPosition: 0,
      force: true,
      bumpRecency: true,
    );
    _syncSystemUiMode(ReaderOverlayMode.controls);
  }

  int? _restoreReadPositionIfNeeded({
    required Book book,
    required ReaderChapterView view,
    required List<ReaderPageSlice> pages,
  }) {
    if (_restoredChapterIndex == view.currentChapterIndex) return null;
    final readPosition = book.lastChapterIndex == view.currentChapterIndex
        ? book.lastReadPosition.clamp(0, view.text.length).toInt()
        : _currentReadPosition.clamp(0, view.text.length).toInt();
    _restoredChapterIndex = view.currentChapterIndex;
    _currentReadPosition = readPosition;
    _pageIndex = ReaderPageLayout.pageIndexForPosition(
      pages: pages,
      readPosition: readPosition,
    );
    return readPosition;
  }

  int? _restoreScrollReadPositionIfNeeded({
    required Book book,
    required ReaderChapterView view,
  }) {
    if (_restoredChapterIndex == view.currentChapterIndex) return null;
    final readPosition = book.lastChapterIndex == view.currentChapterIndex
        ? book.lastReadPosition.clamp(0, view.text.length).toInt()
        : _currentReadPosition.clamp(0, view.text.length).toInt();
    _restoredChapterIndex = view.currentChapterIndex;
    _currentScrollChapterIndex = view.currentChapterIndex;
    _currentScrollContentLength = view.text.length;
    _currentScrollChapterTitle = view.chapterLabel;
    _currentReadPosition = readPosition;
    return readPosition;
  }

  void _updateScrollProgress(ReaderScrollProgress progress) {
    if (_currentScrollChapterIndex == progress.chapterIndex &&
        _currentReadPosition == progress.readPosition) {
      return;
    }
    setState(() {
      _currentScrollChapterIndex = progress.chapterIndex;
      _currentScrollContentLength = progress.contentLength;
      _currentScrollChapterTitle = progress.chapterTitle;
      _currentReadPosition = progress.readPosition;
    });
    _saveReadingProgress(
      chapterIndex: progress.chapterIndex,
      readPosition: progress.readPosition,
    );
  }

  void _saveCurrentProgressNow(ReaderChapterView view) {
    _saveReadingProgress(
      chapterIndex: view.currentChapterIndex,
      readPosition: _currentReadPosition.clamp(0, view.text.length).toInt(),
      force: true,
      bumpRecency: true,
    );
  }

  void _saveReadingProgress({
    required int chapterIndex,
    required int readPosition,
    bool force = false,
    bool bumpRecency = false,
  }) {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = null;

    if (force) {
      _pendingSaveChapterIndex = null;
      _pendingSaveReadPosition = null;
      _pendingSaveBumpRecency = false;
      _persistReadingProgress(
        chapterIndex: chapterIndex,
        readPosition: readPosition,
        bumpRecency: bumpRecency,
      );
      return;
    }

    if (_lastSavedChapterIndex == chapterIndex &&
        _lastSavedReadPosition == readPosition) {
      _pendingSaveChapterIndex = null;
      _pendingSaveReadPosition = null;
      _pendingSaveBumpRecency = false;
      return;
    }

    _pendingSaveChapterIndex = chapterIndex;
    _pendingSaveReadPosition = readPosition;
    _pendingSaveBumpRecency = bumpRecency;
    _saveProgressTimer = Timer(const Duration(milliseconds: 450), () {
      final pendingChapterIndex = _pendingSaveChapterIndex;
      final pendingReadPosition = _pendingSaveReadPosition;
      final pendingBumpRecency = _pendingSaveBumpRecency;
      _pendingSaveChapterIndex = null;
      _pendingSaveReadPosition = null;
      _pendingSaveBumpRecency = false;
      if (pendingChapterIndex == null || pendingReadPosition == null) return;
      _persistReadingProgress(
        chapterIndex: pendingChapterIndex,
        readPosition: pendingReadPosition,
        bumpRecency: pendingBumpRecency,
      );
    });
  }

  void _flushPendingProgress() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = null;
    final pendingChapterIndex = _pendingSaveChapterIndex;
    final pendingReadPosition = _pendingSaveReadPosition;
    final pendingBumpRecency = _pendingSaveBumpRecency;
    _pendingSaveChapterIndex = null;
    _pendingSaveReadPosition = null;
    _pendingSaveBumpRecency = false;
    if (pendingChapterIndex == null || pendingReadPosition == null) return;
    _persistReadingProgress(
      chapterIndex: pendingChapterIndex,
      readPosition: pendingReadPosition,
      bumpRecency: pendingBumpRecency,
    );
  }

  void _persistReadingProgress({
    required int chapterIndex,
    required int readPosition,
    required bool bumpRecency,
  }) {
    if (_lastSavedChapterIndex == chapterIndex &&
        _lastSavedReadPosition == readPosition) {
      return;
    }
    _lastSavedChapterIndex = chapterIndex;
    _lastSavedReadPosition = readPosition;
    if (bumpRecency) {
      _repository.markBookRecentlyRead(
        bookId: widget.bookId,
        chapterIndex: chapterIndex,
        readPosition: readPosition,
      );
      return;
    }
    _repository.updateReadingProgress(
      bookId: widget.bookId,
      chapterIndex: chapterIndex,
      readPosition: readPosition,
    );
  }

  void _syncSystemUiMode([ReaderOverlayMode? mode]) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

class _ReaderPaginationKey {
  const _ReaderPaginationKey({
    required this.bookId,
    required this.chapterIndex,
    required this.textLength,
    required this.textHash,
    required this.metricsWidth,
    required this.metricsHeight,
    required this.articleHeight,
    required this.fontSize,
    required this.lineHeight,
  });

  final String bookId;
  final int chapterIndex;
  final int textLength;
  final int textHash;
  final double metricsWidth;
  final double metricsHeight;
  final double articleHeight;
  final double fontSize;
  final double lineHeight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ReaderPaginationKey &&
            other.bookId == bookId &&
            other.chapterIndex == chapterIndex &&
            other.textLength == textLength &&
            other.textHash == textHash &&
            other.metricsWidth == metricsWidth &&
            other.metricsHeight == metricsHeight &&
            other.articleHeight == articleHeight &&
            other.fontSize == fontSize &&
            other.lineHeight == lineHeight;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapterIndex,
        textLength,
        textHash,
        metricsWidth,
        metricsHeight,
        articleHeight,
        fontSize,
        lineHeight,
      );
}
