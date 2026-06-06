import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../reader/domain/reader_catalog_item.dart' as legacy;
import '../../reader/domain/reader_overlay_mode.dart' as legacy;
import '../../reader/domain/reader_reading_time.dart';
import '../../reader/presentation/layout/reader_page_metrics.dart' as legacy;
import '../../reader/presentation/modes/reader_turn_mode.dart' as legacy;
import '../../reader/presentation/reader_controls.dart' as legacy;
import '../../reader/presentation/widgets/reader_background.dart' as legacy;
import '../../reader/presentation/widgets/reader_progress.dart' as legacy;
import '../application/reader_engine_providers.dart';
import '../application/reader_engine_state.dart';
import '../controller/reader_session_controller.dart';
import '../controller/reader_viewport_controller.dart';
import '../domain/reader_insets.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_turn_mode.dart';
import '../domain/reader_viewport_state.dart';
import '../layout/reader_layout_engine.dart';
import 'reader_viewport.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    this.initialChapterIndex = 0,
  });

  final String bookId;
  final int initialChapterIndex;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const int _catalogPageSize = 200;

  ReaderSessionController? _controller;
  Future<void>? _initialization;
  Size? _lastViewportSize;
  EdgeInsets? _lastViewportPadding;

  legacy.ReaderOverlayMode _overlayMode = legacy.ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _brightness = 0.72;
  bool _isListening = false;
  List<legacy.ReaderCatalogItem> _catalogItems = const [];
  bool _catalogLoading = false;

  @override
  void initState() {
    super.initState();
    _syncSystemUiMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUiMode());
  }

  @override
  void dispose() {
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
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSystemUiMode();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _palette.foreground;
    final statusStyle = foreground.computeLuminance() > 0.5
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        key: const ValueKey('reader-engine-screen'),
        extendBodyBehindAppBar: true,
        backgroundColor: _palette.background,
        body: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final safePadding = MediaQuery.paddingOf(context);
              final metrics = legacy.ReaderPageMetrics.fromSize(size);
              _ensureController(size, safePadding);
              return FutureBuilder<void>(
                future: _initialization,
                builder: (context, snapshot) {
                  final controller = _controller;
                  final state = controller?.state;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      legacy.ReaderPaperBackground(palette: _palette),
                      legacy.ReaderSoftPageEdge(metrics: metrics),
                      if (_brightness < 0.98)
                        IgnorePointer(
                          child: ColoredBox(
                            color: Colors.black.withValues(
                              alpha: (1 - _brightness).clamp(0.0, 0.65),
                            ),
                          ),
                        ),
                      if (controller == null ||
                          state == null ||
                          state.loadStatus == ReaderLoadStatus.loading)
                        Center(
                          child:
                              CircularProgressIndicator(color: _palette.accent),
                        )
                      else if (state.loadStatus == ReaderLoadStatus.error)
                        Center(
                          child: Text(
                            '阅读器加载失败：${state.error}',
                            style: TextStyle(color: _palette.foreground),
                          ),
                        )
                      else
                        ..._readerLayers(
                          context: context,
                          metrics: metrics,
                          controller: controller,
                          state: state,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _readerLayers({
    required BuildContext context,
    required legacy.ReaderPageMetrics metrics,
    required ReaderSessionController controller,
    required ReaderSessionState state,
  }) {
    final document = state.document;
    final viewport = state.viewport;
    final location = state.location;
    if (document == null || viewport == null || location == null) {
      return [
        Center(
          child: Text('暂无正文', style: TextStyle(color: _palette.foreground)),
        ),
      ];
    }

    final isScrollMode = state.settings.turnMode == ReaderTurnMode.scroll;
    final displayItem = isScrollMode
        ? _chapterItemForLocation(viewport, location)
        : viewport.center;
    final chapter = displayItem.chapter;
    final remainingText = estimateReaderReadingTimeText(chapter.normalizedText);
    final chapterProgress = chapter.textLength <= 0
        ? 0.0
        : (location.offset / chapter.textLength).clamp(0.0, 1.0).toDouble();
    final bookProgress = document.chapterCount <= 0
        ? 0.0
        : ((location.chapterIndex + chapterProgress) / document.chapterCount)
            .clamp(0.0, 1.0)
            .toDouble();
    final pageLabel = isScrollMode
        ? chapter.title
        : '${chapter.title} · ${_pageIndexFor(state) + 1}/'
            '${viewport.currentLayout.pages.length}';
    final oldTurnMode = _legacyTurnMode(state.settings.turnMode);

    return [
      Positioned.fill(
        child: ReaderViewport(
          state: state,
          palette: _palette,
          brightness: _brightness,
          controlsVisible: _overlayMode != legacy.ReaderOverlayMode.hidden,
          source: controller.source,
          layoutEngine: controller.viewportController.layoutEngine,
          viewportSize: controller.viewportSize,
          chapterCount: document.chapterCount,
          onContentTap: _toggleOverlay,
          onPreviousBoundary: () => _previousChapter(controller),
          onNextBoundary: () => _nextChapter(controller),
          onLocationChanged: (location) async {
            if (state.settings.turnMode == ReaderTurnMode.scroll) {
              await controller.reportUserLocation(location);
            } else if (location.chapterIndex != viewport.center.chapter.index) {
              await controller.scrollToLocation(location);
            } else {
              await controller.reportUserLocation(location);
            }
            if (mounted) setState(() {});
          },
        ),
      ),
      legacy.ReaderProgress(
        metrics: metrics,
        palette: _palette,
        pageLabel: pageLabel,
        progress: chapterProgress,
      ),
      legacy.ReaderControls(
        mode: _overlayMode,
        bookTitle: document.title,
        chapterLabel: chapter.title,
        chapterTitle: chapter.title,
        progress: bookProgress,
        remainingText: remainingText,
        palette: _palette,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        brightness: _brightness,
        pageTurnMode: oldTurnMode,
        isListening: _isListening,
        currentChapterIndex: location.chapterIndex,
        chapterCount: document.chapterCount,
        catalogItems: _catalogItems,
        catalogHasMore: false,
        catalogIsLoadingMore: _catalogLoading,
        onCatalogLoadMore: () => _loadCatalog(document.chapterCount),
        onBack: () => context.pop(),
        onClose: () => _setOverlayMode(legacy.ReaderOverlayMode.controls),
        onModeChanged: (mode) {
          _setOverlayMode(mode);
          if (mode == legacy.ReaderOverlayMode.catalog) {
            _loadCatalog(document.chapterCount);
          }
        },
        onChapterSelected: (chapterIndex) async {
          await controller.jumpToChapter(chapterIndex);
          if (mounted) {
            setState(() => _overlayMode = legacy.ReaderOverlayMode.hidden);
          }
        },
        onPreviousChapter: location.chapterIndex <= 0
            ? null
            : () => _previousChapter(controller),
        onNextChapter: location.chapterIndex + 1 >= document.chapterCount
            ? null
            : () => _nextChapter(controller),
        onPaletteChanged: (palette) {
          setState(() => _palette = palette);
        },
        onFontSizeChanged: (value) => _updateFontSize(controller, state, value),
        onLineHeightChanged: (value) =>
            _updateLineHeight(controller, state, value),
        onBrightnessChanged: (value) {
          setState(() => _brightness = value);
        },
        onPageTurnModeChanged: (mode) async {
          await controller.updateSettings(
            state.settings.copyWith(turnMode: _engineTurnMode(mode)),
          );
          if (mounted) {
            setState(() => _overlayMode = legacy.ReaderOverlayMode.hidden);
          }
        },
        onListeningChanged: (value) {
          setState(() => _isListening = value);
        },
      ),
    ];
  }

  ReaderChapterWindowItem _chapterItemForLocation(
    ReaderViewportState viewport,
    ReaderLocation location,
  ) {
    if (viewport.center.chapter.index == location.chapterIndex) {
      return viewport.center;
    }
    final previous = viewport.previous;
    if (previous != null && previous.chapter.index == location.chapterIndex) {
      return previous;
    }
    final next = viewport.next;
    if (next != null && next.chapter.index == location.chapterIndex) {
      return next;
    }
    return viewport.center;
  }

  int _pageIndexFor(ReaderSessionState state) {
    final pages = state.viewport?.currentLayout.pages ?? const [];
    final location = state.location;
    if (pages.isEmpty || location == null) return 0;
    final page = pages.firstWhere(
      (page) =>
          location.offset >= page.start.offset &&
          location.offset <= page.end.offset,
      orElse: () => pages.last,
    );
    return page.pageIndex;
  }

  Future<void> _previousChapter(ReaderSessionController controller) async {
    await controller.goToPreviousChapter();
    if (mounted) setState(() => _overlayMode = legacy.ReaderOverlayMode.hidden);
  }

  Future<void> _nextChapter(ReaderSessionController controller) async {
    await controller.goToNextChapter();
    if (mounted) setState(() => _overlayMode = legacy.ReaderOverlayMode.hidden);
  }

  Future<void> _updateFontSize(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    setState(() => _fontSize = value);
    await controller.updateSettings(
      state.settings.copyWith(
        fontSize: _scaledTextSize(value),
        paragraphSpacing: _scaledParagraphSpacing(value),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateLineHeight(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    setState(() => _lineHeight = value);
    await controller.updateSettings(state.settings.copyWith(lineHeight: value));
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog(int chapterCount) async {
    if (_catalogLoading || _catalogItems.isNotEmpty) return;
    setState(() => _catalogLoading = true);
    try {
      final page =
          await ref.read(readerDocumentSourceProvider).loadChapterMetas(
                bookId: widget.bookId,
                offset: 0,
                limit: chapterCount == 0 ? _catalogPageSize : chapterCount,
              );
      if (!mounted) return;
      setState(() {
        _catalogItems = [
          for (final item in page.items)
            legacy.ReaderCatalogItem(
              chapterIndex: item.index,
              title: item.title,
              subtitle: item.normalizedContentLength > 0
                  ? '约 ${item.normalizedContentLength} 字'
                  : '章节 ${item.index + 1}',
            ),
        ];
      });
    } finally {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  void _toggleOverlay() {
    _setOverlayMode(
      _overlayMode == legacy.ReaderOverlayMode.hidden
          ? legacy.ReaderOverlayMode.controls
          : legacy.ReaderOverlayMode.hidden,
    );
  }

  void _setOverlayMode(legacy.ReaderOverlayMode mode) {
    if (_overlayMode == mode) return;
    setState(() => _overlayMode = mode);
  }

  legacy.ReaderTurnMode _legacyTurnMode(ReaderTurnMode mode) {
    return switch (mode) {
      ReaderTurnMode.scroll => legacy.ReaderTurnMode.scroll,
      ReaderTurnMode.simulated => legacy.ReaderTurnMode.simulation,
      _ => legacy.ReaderTurnMode.slide,
    };
  }

  ReaderTurnMode _engineTurnMode(legacy.ReaderTurnMode mode) {
    return switch (mode) {
      legacy.ReaderTurnMode.scroll => ReaderTurnMode.scroll,
      legacy.ReaderTurnMode.simulation => ReaderTurnMode.simulated,
      legacy.ReaderTurnMode.slide => ReaderTurnMode.slide,
    };
  }

  ReaderSettings _initialSettings(Size size, EdgeInsets safePadding) {
    final metrics = legacy.ReaderPageMetrics.fromSize(size);
    return ReaderSettings.defaults().copyWith(
      fontSize: metrics.s(_fontSize),
      lineHeight: _lineHeight,
      turnMode: ReaderTurnMode.slide,
      paragraphSpacing: metrics.s(_fontSize * _lineHeight),
      pagePadding: _readerContentInsets(size, safePadding),
    );
  }

  ReaderInsets _readerContentInsets(Size size, EdgeInsets safePadding) {
    final metrics = legacy.ReaderPageMetrics.fromSize(size);
    final left = metrics.x(30);
    final contentWidth = metrics.s(330);
    final right = (size.width - left - contentWidth).clamp(0.0, size.width);
    final top = safePadding.top + metrics.s(18);
    final footerTop = size.height - safePadding.bottom - metrics.s(44);
    final contentHeight = (footerTop - top - metrics.s(18))
        .clamp(metrics.s(520), size.height)
        .toDouble();
    final bottom = (size.height - top - contentHeight).clamp(0.0, size.height);

    return ReaderInsets(
      left: left,
      top: top,
      right: right.toDouble(),
      bottom: bottom.toDouble(),
    );
  }

  double _scaledTextSize(double value) {
    final size = _lastViewportSize;
    if (size == null) return value;
    return legacy.ReaderPageMetrics.fromSize(size).s(value);
  }

  double _scaledParagraphSpacing(double fontSize) {
    final size = _lastViewportSize;
    if (size == null) return fontSize * _lineHeight;
    return legacy.ReaderPageMetrics.fromSize(size).s(fontSize * _lineHeight);
  }

  void _ensureController(Size size, EdgeInsets safePadding) {
    if (_controller != null &&
        _lastViewportSize == size &&
        _lastViewportPadding == safePadding) {
      return;
    }
    _lastViewportSize = size;
    _lastViewportPadding = safePadding;
    final source = ref.read(readerDocumentSourceProvider);
    final progressRepository = ref.read(readerProgressRepositoryProvider);
    final viewportController = ReaderViewportController(
      source: source,
      layoutEngine: const FlutterReaderLayoutEngine(),
    );
    final controller = ReaderSessionController(
      bookId: widget.bookId,
      source: source,
      viewportController: viewportController,
      progressRepository: progressRepository,
      initialSettings: _initialSettings(size, safePadding),
      viewportSize: size,
    );
    _controller = controller;
    _initialization = controller.initialize().then((_) async {
      if (widget.initialChapterIndex > 0) {
        await controller.jumpToChapter(widget.initialChapterIndex);
      }
    });
  }

  void _syncSystemUiMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
