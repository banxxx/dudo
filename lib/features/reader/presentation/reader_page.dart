import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../features/bookshelf/application/bookshelf_providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../domain/reader_chapter_view.dart';
import '../domain/reader_overlay_mode.dart';
import 'layout/reader_page_layout.dart';
import 'layout/reader_page_metrics.dart';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _saveProgressTimer;

  ReaderOverlayMode _overlayMode = ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _brightness = 0.72;
  String _pageTurnMode = '滑动';
  bool _isListening = false;
  int _pageIndex = 0;
  int _currentReadPosition = 0;
  int? _restoredChapterIndex;
  int? _lastSavedChapterIndex;
  int? _lastSavedReadPosition;
  late int _currentChapterIndex;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _syncSystemUiMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUiMode());
  }

  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _scrollController.dispose();
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
      _pageIndex = 0;
      _currentReadPosition = 0;
      _restoredChapterIndex = null;
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
    final chaptersValue = ref.watch(bookChaptersProvider(widget.bookId));

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
              chaptersValue: chaptersValue,
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
    required AsyncValue<List<Chapter>> chaptersValue,
  }) {
    if (bookValue.hasError || chaptersValue.hasError) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '打开失败',
        message: '无法加载书籍或章节',
        actionLabel: '重试',
        onAction: () {
          ref.invalidate(bookByIdProvider(widget.bookId));
          ref.invalidate(bookChaptersProvider(widget.bookId));
        },
      );
    }
    if (bookValue.isLoading || chaptersValue.isLoading) {
      return ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '正在打开书籍…',
        message: '正在读取本地章节内容',
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

    final chapters = chaptersValue.valueOrNull ?? const <Chapter>[];
    if (chapters.isEmpty) {
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

    final localPath = book.localPath;
    final firstChapterContentLength = chapters.first.content?.length ?? 0;
    if (localPath != null &&
        chapters.length == 1 &&
        firstChapterContentLength > 60000) {
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

    final view = ReaderChapterView.fromBook(
      book: book,
      chapters: chapters,
      requestedChapterIndex: _currentChapterIndex,
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
    final pages = ReaderPageLayout.paginate(
      text: view.text,
      metrics: metrics,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      availableHeight: articleHeight,
    );
    final restoredPosition = _restoreReadPositionIfNeeded(
      book: book,
      view: view,
      pages: pages,
    );
    final readPosition = restoredPosition ??
        _currentReadPosition.clamp(0, view.text.length).toInt();
    final pageIndex = ReaderPageLayout.pageIndexForPosition(
      pages: pages,
      readPosition: readPosition,
    );
    if (pageIndex != _pageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pageIndex = pageIndex);
      });
    }
    final chapterProgress = view.chapterProgressForPosition(readPosition);
    final bookProgress = view.bookProgressForPosition(readPosition);

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
        ReadingArticle(
          metrics: metrics,
          palette: _palette,
          chapter: view,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          top: articleTop,
          height: articleHeight,
          pageIndex: pageIndex,
          pages: pages,
          scrollController: _scrollController,
          scrollable: _pageTurnMode == '滚动',
          interactive:
              _pageTurnMode == '滚动' && _overlayMode == ReaderOverlayMode.hidden,
          preview: _overlayMode != ReaderOverlayMode.hidden &&
              _overlayMode != ReaderOverlayMode.controls,
          onScrollPositionChanged: (position) => _updateReadPosition(
            chapterIndex: view.currentChapterIndex,
            readPosition: position,
            contentLength: view.text.length,
          ),
          onTap: _toggleOverlay,
        ),
        ReaderProgress(
          metrics: metrics,
          palette: _palette,
          pageLabel: '${view.chapterLabel} · ${pageIndex + 1}/${pages.length}',
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
          catalogItems: view.catalogItems,
          onBack: () {
            _saveCurrentProgressNow(view);
            context.pop();
          },
          onClose: () => _setOverlayMode(ReaderOverlayMode.controls),
          onModeChanged: _setOverlayMode,
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
          }),
          onLineHeightChanged: (lineHeight) => setState(() {
            _lineHeight = lineHeight;
            _restoredChapterIndex = null;
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

  void _toggleOverlay() {
    _setOverlayMode(
      _overlayMode == ReaderOverlayMode.hidden
          ? ReaderOverlayMode.controls
          : ReaderOverlayMode.hidden,
    );
  }

  void _setOverlayMode(ReaderOverlayMode mode) {
    if (_overlayMode == mode) return;
    setState(() => _overlayMode = mode);
    _syncSystemUiMode(mode);
  }

  void _turnPage({
    required List<ReaderPageSlice> pages,
    required ReaderChapterView view,
    required int direction,
  }) {
    if (_pageTurnMode == '滚动') {
      _scrollPage(view: view, direction: direction);
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
      );
      return;
    }
    if (direction < 0 && view.previousChapterIndex != null) {
      _turnChapter(view.previousChapterIndex!, initialReadPosition: 0);
      return;
    }
    if (direction > 0 && view.nextChapterIndex != null) {
      _turnChapter(view.nextChapterIndex!, initialReadPosition: 0);
    }
  }

  void _scrollPage({
    required ReaderChapterView view,
    required int direction,
  }) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final pageDelta = position.viewportDimension * 0.92 * direction;
    final target = (position.pixels + pageDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (target == position.pixels) {
      if (direction < 0 && view.previousChapterIndex != null) {
        _turnChapter(view.previousChapterIndex!, initialReadPosition: 0);
      } else if (direction > 0 && view.nextChapterIndex != null) {
        _turnChapter(view.nextChapterIndex!, initialReadPosition: 0);
      }
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _turnChapter(int chapterIndex, {required int initialReadPosition}) {
    if (_currentChapterIndex == chapterIndex) return;
    setState(() {
      _currentChapterIndex = chapterIndex;
      _pageIndex = 0;
      _currentReadPosition = initialReadPosition;
      _restoredChapterIndex = null;
      _overlayMode = ReaderOverlayMode.hidden;
    });
    _saveReadingProgress(
      chapterIndex: chapterIndex,
      readPosition: initialReadPosition,
      force: true,
    );
    _syncSystemUiMode(ReaderOverlayMode.hidden);
  }

  void _selectChapter(int chapterIndex) {
    if (_currentChapterIndex == chapterIndex) {
      _setOverlayMode(ReaderOverlayMode.controls);
      return;
    }
    setState(() {
      _currentChapterIndex = chapterIndex;
      _pageIndex = 0;
      _currentReadPosition = 0;
      _restoredChapterIndex = null;
      _overlayMode = ReaderOverlayMode.controls;
    });
    _saveReadingProgress(
      chapterIndex: chapterIndex,
      readPosition: 0,
      force: true,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final offset = view.text.isEmpty
          ? 0.0
          : maxScrollExtent * (readPosition / view.text.length);
      _scrollController.jumpTo(offset.clamp(0.0, maxScrollExtent));
    });
    return readPosition;
  }

  void _updateReadPosition({
    required int chapterIndex,
    required int readPosition,
    required int contentLength,
  }) {
    final normalized = readPosition.clamp(0, contentLength).toInt();
    if (_currentReadPosition == normalized) return;
    setState(() => _currentReadPosition = normalized);
    _saveReadingProgress(
      chapterIndex: chapterIndex,
      readPosition: normalized,
    );
  }

  void _saveCurrentProgressNow(ReaderChapterView view) {
    _saveReadingProgress(
      chapterIndex: view.currentChapterIndex,
      readPosition: _currentReadPosition.clamp(0, view.text.length).toInt(),
      force: true,
    );
  }

  void _saveReadingProgress({
    required int chapterIndex,
    required int readPosition,
    bool force = false,
  }) {
    if (_lastSavedChapterIndex == chapterIndex &&
        _lastSavedReadPosition == readPosition) {
      return;
    }
    _saveProgressTimer?.cancel();
    void save() {
      _lastSavedChapterIndex = chapterIndex;
      _lastSavedReadPosition = readPosition;
      ref.read(bookshelfRepositoryProvider).updateReadingProgress(
            bookId: widget.bookId,
            chapterIndex: chapterIndex,
            readPosition: readPosition,
          );
    }

    if (force) {
      save();
    } else {
      _saveProgressTimer = Timer(const Duration(milliseconds: 450), save);
    }
  }

  void _syncSystemUiMode([ReaderOverlayMode? mode]) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
