import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../application/reader_engine_providers.dart';
import '../application/reader_engine_state.dart';
import '../controller/reader_session_controller.dart';
import '../controller/reader_viewport_controller.dart';
import '../domain/reader_catalog_item.dart';
import '../domain/reader_insets.dart';
import '../domain/reader_location.dart';
import '../domain/reader_overlay_mode.dart';
import '../domain/reader_reading_time.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_turn_mode.dart';
import '../domain/reader_viewport_state.dart';
import '../layout/reader_layout_cache.dart';
import '../layout/reader_layout_engine.dart';
import 'layout/reader_chrome_layout.dart';
import 'layout/reader_page_metrics.dart';
import 'reader_controls.dart';
import 'reader_viewport.dart';
import 'widgets/reader_background.dart';
import 'widgets/reader_brightness_overlay.dart';
import 'widgets/reader_progress.dart';
import 'widgets/reader_volume_page_turn_listener.dart';

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
  final ReaderLayoutCache _layoutCache = ReaderLayoutCache(maximumEntries: 96);
  bool _controllerRefreshScheduled = false;

  ReaderOverlayMode _overlayMode = ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _brightness = 1;
  bool _volumePageTurnEnabled = true;
  bool _isListening = false;
  int _volumePageTurnRequestId = 0;
  int _volumePageTurnDirection = 0;
  List<ReaderCatalogItem> _catalogItems = const [];
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
        body: ReaderVolumePageTurnListener(
          enabled: _volumePageTurnEnabled &&
              _overlayMode == ReaderOverlayMode.hidden,
          onPreviousPage: () => _requestVolumePageTurn(-1),
          onNextPage: () => _requestVolumePageTurn(1),
          child: SizedBox.expand(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final safePadding = MediaQuery.paddingOf(context);
                final chromeLayout =
                    ReaderChromeLayout.fromSize(size, safePadding);
                final metrics = chromeLayout.metrics;
                _ensureController(size, safePadding);
                return FutureBuilder<void>(
                  future: _initialization,
                  builder: (context, snapshot) {
                    final controller = _controller;
                    final state = controller?.state;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ReaderPaperBackground(palette: _palette),
                        ReaderSoftPageEdge(metrics: metrics),
                        if (controller == null ||
                            state == null ||
                            state.loadStatus == ReaderLoadStatus.loading)
                          Center(
                            child: _ReaderLoadingBar(
                              palette: _palette,
                              width: metrics.s(118),
                            ),
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
                        ReaderBrightnessOverlay(
                          brightness: _brightness,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _readerLayers({
    required BuildContext context,
    required ReaderPageMetrics metrics,
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
    return [
      Positioned.fill(
        child: ReaderViewport(
          state: state,
          palette: _palette,
          controlsVisible: _overlayMode != ReaderOverlayMode.hidden,
          source: controller.source,
          layoutEngine: controller.viewportController.layoutEngine,
          viewportSize: controller.viewportSize,
          chapterCount: document.chapterCount,
          externalPageTurnRequestId: _volumePageTurnRequestId,
          externalPageTurnDirection: _volumePageTurnDirection,
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
      if (_showsSecondaryMenuScrim)
        const Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Color(0x1A000000)),
          ),
        ),
      ReaderProgress(
        metrics: metrics,
        palette: _palette,
        pageLabel: pageLabel,
        progress: chapterProgress,
      ),
      ReaderControls(
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
        pageTurnMode: state.settings.turnMode,
        volumePageTurnEnabled: _volumePageTurnEnabled,
        isListening: _isListening,
        currentChapterIndex: location.chapterIndex,
        chapterCount: document.chapterCount,
        catalogItems: _catalogItems,
        catalogHasMore: false,
        catalogIsLoadingMore: _catalogLoading,
        onCatalogLoadMore: () => _loadCatalog(document.chapterCount),
        onBack: () => context.pop(),
        onClose: () => _setOverlayMode(ReaderOverlayMode.controls),
        onModeChanged: (mode) {
          _setOverlayMode(mode);
          if (mode == ReaderOverlayMode.catalog) {
            _loadCatalog(document.chapterCount);
          }
        },
        onChapterSelected: (chapterIndex) async {
          await controller.jumpToChapter(chapterIndex);
          if (mounted) {
            setState(() => _overlayMode = ReaderOverlayMode.hidden);
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
          await controller
              .updateSettings(state.settings.copyWith(turnMode: mode));
          if (mounted) {
            setState(() => _overlayMode = ReaderOverlayMode.hidden);
          }
        },
        onVolumePageTurnChanged: (value) {
          setState(() => _volumePageTurnEnabled = value);
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
    if (mounted) setState(() => _overlayMode = ReaderOverlayMode.hidden);
  }

  Future<void> _nextChapter(ReaderSessionController controller) async {
    await controller.goToNextChapter();
    if (mounted) setState(() => _overlayMode = ReaderOverlayMode.hidden);
  }

  Future<void> _updateFontSize(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    final fontSize = ReaderSettings.clampFontSize(value);
    setState(() => _fontSize = fontSize);
    await controller.updateSettings(
      state.settings.copyWith(
        fontSize: _scaledTextSize(fontSize),
        paragraphSpacing: _scaledParagraphSpacing(fontSize),
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
            ReaderCatalogItem(
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
      _overlayMode == ReaderOverlayMode.hidden
          ? ReaderOverlayMode.controls
          : ReaderOverlayMode.hidden,
    );
  }

  void _setOverlayMode(ReaderOverlayMode mode) {
    if (_overlayMode == mode) return;
    setState(() => _overlayMode = mode);
  }

  bool get _showsSecondaryMenuScrim {
    switch (_overlayMode) {
      case ReaderOverlayMode.typography:
      case ReaderOverlayMode.theme:
      case ReaderOverlayMode.listening:
      case ReaderOverlayMode.more:
      case ReaderOverlayMode.pageTurn:
        return true;
      case ReaderOverlayMode.hidden:
      case ReaderOverlayMode.controls:
      case ReaderOverlayMode.catalog:
        return false;
    }
  }

  void _requestVolumePageTurn(int direction) {
    if (!_volumePageTurnEnabled ||
        _overlayMode != ReaderOverlayMode.hidden ||
        direction == 0) {
      return;
    }
    setState(() {
      _volumePageTurnDirection = direction;
      _volumePageTurnRequestId++;
    });
  }

  ReaderSettings _initialSettings(Size size, EdgeInsets safePadding) {
    final metrics = ReaderPageMetrics.fromSize(size);
    return ReaderSettings.defaults().copyWith(
      fontSize: metrics.s(_fontSize),
      lineHeight: _lineHeight,
      turnMode: ReaderTurnMode.slide,
      paragraphSpacing: metrics.s(_fontSize * _lineHeight),
      pagePadding: _readerContentInsets(size, safePadding),
    );
  }

  ReaderInsets _readerContentInsets(Size size, EdgeInsets safePadding) {
    return ReaderChromeLayout.fromSize(size, safePadding).contentInsets;
  }

  double _scaledTextSize(double value) {
    final size = _lastViewportSize;
    if (size == null) return value;
    return ReaderPageMetrics.fromSize(size).s(value);
  }

  double _scaledParagraphSpacing(double fontSize) {
    final size = _lastViewportSize;
    if (size == null) return fontSize * _lineHeight;
    return ReaderPageMetrics.fromSize(size).s(fontSize * _lineHeight);
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
      layoutCache: _layoutCache,
    );
    final controller = ReaderSessionController(
      bookId: widget.bookId,
      source: source,
      viewportController: viewportController,
      progressRepository: progressRepository,
      initialSettings: _initialSettings(size, safePadding),
      viewportSize: size,
      onStateChanged: _scheduleControllerRefresh,
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

  void _scheduleControllerRefresh() {
    if (_controllerRefreshScheduled) return;
    _controllerRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerRefreshScheduled = false;
      if (mounted) setState(() {});
    });
  }
}

class _ReaderLoadingBar extends StatelessWidget {
  const _ReaderLoadingBar({
    required this.palette,
    required this.width,
  });

  final ReaderPalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '阅读器加载中',
      child: SizedBox(
        width: width.clamp(96.0, 136.0),
        height: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            color: palette.accent,
            backgroundColor: palette.foreground.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
