import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../features/bookshelf/application/bookshelf_providers.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_tokens.dart';
import 'reader_controls.dart';

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
  }

  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        systemNavigationBarColor: _palette.backgroundEnd ?? _palette.background,
      ),
      child: Scaffold(
        key: const ValueKey('reader-page'),
        extendBodyBehindAppBar: true,
        backgroundColor: _palette.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ReaderPageMetrics.fromSize(constraints.biggest);
            final content = _buildReaderContent(
              context: context,
              metrics: metrics,
              bookValue: bookValue,
              chaptersValue: chaptersValue,
            );
            return Stack(
              children: [
                _ReaderPaperBackground(palette: _palette),
                _SoftPageEdge(metrics: metrics),
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
    required _ReaderPageMetrics metrics,
    required AsyncValue<Book?> bookValue,
    required AsyncValue<List<Chapter>> chaptersValue,
  }) {
    if (bookValue.hasError || chaptersValue.hasError) {
      return _ReaderStateMessage(
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
      return _ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '正在打开书籍…',
        message: '正在读取本地章节内容',
      );
    }

    final book = bookValue.valueOrNull;
    if (book == null) {
      return _ReaderStateMessage(
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
      return _ReaderStateMessage(
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
      return _ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '章节计算中',
        message: '正在重新分析本地目录，请稍后再试',
      );
    }

    final view = _ReaderChapterView.fromBook(
      book: book,
      chapters: chapters,
      requestedChapterIndex: _currentChapterIndex,
    );
    if (view.contentMissing) {
      return _ReaderStateMessage(
        metrics: metrics,
        palette: _palette,
        title: '暂无正文内容',
        message: '该章节内容尚未缓存',
      );
    }

    final pages = _ReaderPageLayout.paginate(
      text: view.text,
      metrics: metrics,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
    );
    final restoredPosition = _restoreReadPositionIfNeeded(
      book: book,
      view: view,
      pages: pages,
    );
    final readPosition = restoredPosition ??
        _currentReadPosition.clamp(0, view.text.length).toInt();
    final pageIndex = _ReaderPageLayout.pageIndexForPosition(
      pages: pages,
      readPosition: readPosition,
    );
    if (pageIndex != _pageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pageIndex = pageIndex);
      });
    }
    final pageCount = pages.length;
    final chapterProgress = view.progressForPosition(readPosition);

    return Stack(
      children: [
        Positioned.fill(
          child: _ReaderGestureLayer(
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
        _ReadingArticle(
          metrics: metrics,
          palette: _palette,
          chapter: view,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
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
        _ReaderProgress(
          metrics: metrics,
          palette: _palette,
          pageLabel: '${view.chapterLabel} · ${pageIndex + 1}/$pageCount',
          progress: chapterProgress,
        ),
        ReaderControls(
          mode: _overlayMode,
          bookTitle: view.bookTitle,
          chapterLabel: view.chapterLabel,
          chapterTitle: view.chapterTitle,
          progress: chapterProgress,
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
    required List<_ReaderPageSlice> pages,
    required _ReaderChapterView view,
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
    required _ReaderChapterView view,
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
    required _ReaderChapterView view,
    required List<_ReaderPageSlice> pages,
  }) {
    if (_restoredChapterIndex == view.currentChapterIndex) return null;
    final readPosition = book.lastChapterIndex == view.currentChapterIndex
        ? book.lastReadPosition.clamp(0, view.text.length).toInt()
        : _currentReadPosition.clamp(0, view.text.length).toInt();
    _restoredChapterIndex = view.currentChapterIndex;
    _currentReadPosition = readPosition;
    _pageIndex = _ReaderPageLayout.pageIndexForPosition(
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

  void _saveCurrentProgressNow(_ReaderChapterView view) {
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

class _ReaderPageMetrics {
  const _ReaderPageMetrics({
    required this.scale,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory _ReaderPageMetrics.fromSize(Size size) {
    final scale = (size.width / 390).clamp(0.92, 1.12).toDouble();
    final canvasWidth = 390 * scale;
    return _ReaderPageMetrics(
      scale: scale,
      left: (size.width - canvasWidth) / 2,
      top: 0,
      width: canvasWidth,
      height: size.height,
    );
  }

  final double scale;
  final double left;
  final double top;
  final double width;
  final double height;

  double x(double value) => left + value * scale;
  double y(double value) => top + value * scale;
  double s(double value) => value * scale;
}

class _ReaderPaperBackground extends StatelessWidget {
  const _ReaderPaperBackground({required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.background,
              palette.backgroundEnd ?? palette.background
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftPageEdge extends StatelessWidget {
  const _SoftPageEdge({required this.metrics});

  final _ReaderPageMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(18),
      top: metrics.y(100),
      width: metrics.s(1),
      height: metrics.s(610),
      child: const ColoredBox(color: Color(0x66D8CDBB)),
    );
  }
}

class _ReaderGestureLayer extends StatelessWidget {
  const _ReaderGestureLayer({
    required this.overlayMode,
    required this.pageTurnMode,
    required this.onToggleOverlay,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final ReaderOverlayMode overlayMode;
  final String pageTurnMode;
  final VoidCallback onToggleOverlay;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('reader-gesture-layer'),
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(context, details.localPosition),
      onHorizontalDragEnd: pageTurnMode == '滚动'
          ? null
          : (details) => _handleHorizontalDragEnd(details.primaryVelocity ?? 0),
    );
  }

  void _handleTap(BuildContext context, Offset position) {
    if (overlayMode != ReaderOverlayMode.hidden) {
      onToggleOverlay();
      return;
    }

    final width = context.size?.width ?? 0;
    if (width == 0) {
      onToggleOverlay();
      return;
    }

    if (pageTurnMode == '滚动') {
      onToggleOverlay();
      return;
    }

    if (position.dx < width * 0.33) {
      onPreviousPage();
      return;
    }
    if (position.dx > width * 0.67) {
      onNextPage();
      return;
    }
    onToggleOverlay();
  }

  void _handleHorizontalDragEnd(double velocity) {
    if (overlayMode != ReaderOverlayMode.hidden || velocity.abs() < 260) return;
    if (velocity < 0) {
      onNextPage();
    } else {
      onPreviousPage();
    }
  }
}

class _ReadingArticle extends StatelessWidget {
  const _ReadingArticle({
    required this.metrics,
    required this.palette,
    required this.chapter,
    required this.fontSize,
    required this.lineHeight,
    required this.pageIndex,
    required this.pages,
    required this.scrollController,
    required this.scrollable,
    required this.interactive,
    required this.preview,
    required this.onScrollPositionChanged,
    required this.onTap,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final _ReaderChapterView chapter;
  final double fontSize;
  final double lineHeight;
  final int pageIndex;
  final List<_ReaderPageSlice> pages;
  final ScrollController scrollController;
  final bool scrollable;
  final bool interactive;
  final bool preview;
  final ValueChanged<int> onScrollPositionChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = DudoTextStyles.serif(
      color: palette.foreground,
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );
    final currentPage = pages[pageIndex.clamp(0, pages.length - 1).toInt()];

    return Positioned(
      key: const ValueKey('reader-article'),
      left: metrics.x(30),
      top: metrics.y(92),
      width: metrics.s(330),
      height: metrics.s(642),
      child: IgnorePointer(
        ignoring: !interactive,
        child: Opacity(
          opacity: preview ? 0.42 : 1,
          child: scrollable
              ? NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    final maxScrollExtent =
                        notification.metrics.maxScrollExtent;
                    final ratio = maxScrollExtent <= 0
                        ? 0.0
                        : notification.metrics.pixels / maxScrollExtent;
                    onScrollPositionChanged(
                      (chapter.text.length * ratio.clamp(0.0, 1.0)).round(),
                    );
                    return false;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onTap,
                    child: SingleChildScrollView(
                      key: const ValueKey('reader-scroll-view'),
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: metrics.s(32)),
                        child: Text(chapter.text, style: style),
                      ),
                    ),
                  ),
                )
              : ClipRect(
                  child: Text(
                    currentPage.text,
                    key: ValueKey('reader-page-text-$pageIndex'),
                    overflow: TextOverflow.clip,
                    style: style,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReaderPageSlice {
  const _ReaderPageSlice({
    required this.startOffset,
    required this.endOffset,
    required this.text,
  });

  final int startOffset;
  final int endOffset;
  final String text;
}

class _ReaderPageLayout {
  static double pageHeight(_ReaderPageMetrics metrics) => metrics.s(642);

  static List<_ReaderPageSlice> paginate({
    required String text,
    required _ReaderPageMetrics metrics,
    required double fontSize,
    required double lineHeight,
  }) {
    if (text.isEmpty) {
      return const [_ReaderPageSlice(startOffset: 0, endOffset: 0, text: '')];
    }

    final style = DudoTextStyles.serif(
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );
    final width = metrics.s(330);
    final height = pageHeight(metrics);
    final pages = <_ReaderPageSlice>[];
    var start = 0;

    while (start < text.length) {
      final end = _findPageEnd(
        text: text,
        start: start,
        width: width,
        height: height,
        style: style,
      );
      final safeEnd = end <= start ? (start + 1).clamp(0, text.length) : end;
      pages.add(
        _ReaderPageSlice(
          startOffset: start,
          endOffset: safeEnd,
          text: text.substring(start, safeEnd).trimLeft(),
        ),
      );
      start = safeEnd;
      while (start < text.length && text.codeUnitAt(start) == 10) {
        start++;
      }
    }

    return pages.isEmpty
        ? const [_ReaderPageSlice(startOffset: 0, endOffset: 0, text: '')]
        : pages;
  }

  static int pageIndexForPosition({
    required List<_ReaderPageSlice> pages,
    required int readPosition,
  }) {
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (readPosition >= page.startOffset && readPosition < page.endOffset) {
        return i;
      }
    }
    return pages.length - 1;
  }

  static int _findPageEnd({
    required String text,
    required int start,
    required double width,
    required double height,
    required TextStyle style,
  }) {
    var low = start + 1;
    var high = text.length;
    var best = low;

    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      if (_fits(
        text: text.substring(start, mid),
        width: width,
        height: height,
        style: style,
      )) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (best >= text.length) return text.length;
    return _naturalBreak(text, start, best);
  }

  static bool _fits({
    required String text,
    required double width,
    required double height,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: width);
    return painter.height <= height;
  }

  static int _naturalBreak(String text, int start, int best) {
    final minimum = start + ((best - start) * 0.72).floor();
    for (var i = best; i > minimum; i--) {
      final char = text[i - 1];
      if (char == '\n' ||
          char == '。' ||
          char == '！' ||
          char == '？' ||
          char == '；' ||
          char == '，' ||
          char == ' ') {
        return i;
      }
    }
    return best;
  }
}

class _ReaderProgress extends StatelessWidget {
  const _ReaderProgress({
    required this.metrics,
    required this.palette,
    required this.pageLabel,
    required this.progress,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String pageLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-progress'),
      left: metrics.x(30),
      top: metrics.y(766),
      width: metrics.s(330),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pageLabel,
                style: DudoTextStyles.sans(
                  color: palette.mutedForeground ?? DudoColors.textSecondary,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: DudoTextStyles.numeric(
                  color: palette.mutedForeground ?? DudoColors.textSecondary,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(8)),
          Stack(
            children: [
              Container(
                height: metrics.s(4),
                decoration: BoxDecoration(
                  color: DudoColors.outline.withValues(alpha: 0.45),
                  borderRadius: AppRadius.full,
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: metrics.s(4),
                  decoration: BoxDecoration(
                    color: palette.accent ?? DudoColors.primary,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReaderChapterView {
  const _ReaderChapterView({
    required this.bookTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.remainingText,
    required this.chapterOrdinal,
    required this.text,
    required this.paragraphs,
    required this.currentChapterIndex,
    required this.chapterCount,
    required this.previousChapterIndex,
    required this.nextChapterIndex,
    required this.catalogItems,
    required this.contentMissing,
  });

  final String bookTitle;
  final String chapterLabel;
  final String chapterTitle;
  final String remainingText;
  final int chapterOrdinal;
  final String text;
  final List<String> paragraphs;
  final int currentChapterIndex;
  final int chapterCount;
  final int? previousChapterIndex;
  final int? nextChapterIndex;
  final List<ReaderCatalogItem> catalogItems;
  final bool contentMissing;

  bool get hasPrevious => previousChapterIndex != null;
  bool get hasNext => nextChapterIndex != null;

  double progressForPosition(int readPosition) {
    final chapterProgress = text.isEmpty
        ? 0.0
        : readPosition.clamp(0, text.length).toDouble() / text.length;
    return ((chapterOrdinal + chapterProgress) / chapterCount)
        .clamp(0, 1)
        .toDouble();
  }

  factory _ReaderChapterView.fromBook({
    required Book book,
    required List<Chapter> chapters,
    required int requestedChapterIndex,
  }) {
    final clampedPosition = requestedChapterIndex.clamp(0, chapters.length - 1);
    final exactIndex = chapters.indexWhere(
      (chapter) => chapter.chapterIndex == requestedChapterIndex,
    );
    final position = exactIndex >= 0 ? exactIndex : clampedPosition;
    final chapter = chapters[position];
    final content = chapter.content?.trim() ?? '';
    final paragraphs = _splitReaderParagraphs(content);
    final isSingleLocalChapter = book.localPath != null && chapters.length == 1;
    final chapterLabel = isSingleLocalChapter ? '全文' : chapter.title;

    return _ReaderChapterView(
      bookTitle: book.title,
      chapterLabel: chapterLabel,
      chapterTitle: chapter.title,
      remainingText: _estimateReadingTimeText(content),
      chapterOrdinal: position,
      text: paragraphs.join('\n\n'),
      paragraphs: paragraphs,
      currentChapterIndex: chapter.chapterIndex,
      chapterCount: chapters.length,
      previousChapterIndex:
          position > 0 ? chapters[position - 1].chapterIndex : null,
      nextChapterIndex: position + 1 < chapters.length
          ? chapters[position + 1].chapterIndex
          : null,
      catalogItems: [
        for (var i = 0; i < chapters.length; i++)
          ReaderCatalogItem(
            chapterIndex: chapters[i].chapterIndex,
            title: chapters[i].title,
            subtitle: i == position ? '正在阅读' : '已缓存',
          ),
      ],
      contentMissing: content.isEmpty,
    );
  }
}

List<String> _splitReaderParagraphs(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
}

String _estimateReadingTimeText(String content) {
  final readableLength = content.replaceAll(RegExp(r'\s+'), '').length;
  if (readableLength == 0) return '暂无进度';
  final minutes = (readableLength / 450).ceil().clamp(1, 9999);
  return '约 $minutes 分钟';
}

class _ReaderStateMessage extends StatelessWidget {
  const _ReaderStateMessage({
    required this.metrics,
    required this.palette,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(30),
      top: metrics.y(292),
      width: metrics.s(330),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: DudoTextStyles.serif(
              color: palette.foreground,
              fontSize: metrics.s(24),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.s(10)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: palette.mutedForeground ?? DudoColors.textSecondary,
              fontSize: metrics.s(13),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: metrics.s(18)),
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: metrics.s(38),
                padding: EdgeInsets.symmetric(horizontal: metrics.s(20)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.foreground,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  actionLabel!,
                  style: DudoTextStyles.sans(
                    color: palette.background,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
