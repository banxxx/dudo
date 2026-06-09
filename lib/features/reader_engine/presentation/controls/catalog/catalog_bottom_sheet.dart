part of '../../reader_controls.dart';

class _CatalogBottomSheet extends StatefulWidget {
  const _CatalogBottomSheet({
    required this.metrics,
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterCount,
    required this.currentChapterIndex,
    required this.chapters,
    required this.hasMore,
    required this.isLoadingMore,
    required this.palette,
    required this.onClose,
    required this.onChapterSelected,
    this.onLoadMore,
  });

  final _ReaderOverlayMetrics metrics;
  final String bookTitle;
  final String chapterTitle;
  final int chapterCount;
  final int currentChapterIndex;
  final List<ReaderCatalogItem> chapters;
  final bool hasMore;
  final bool isLoadingMore;
  final ReaderPalette palette;
  final VoidCallback onClose;
  final ValueChanged<int> onChapterSelected;
  final VoidCallback? onLoadMore;

  @override
  State<_CatalogBottomSheet> createState() => _CatalogBottomSheetState();
}

class _CatalogBottomSheetState extends State<_CatalogBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dragController;
  late final ScrollController _listController;
  double _dragOffset = 0;
  int? _lastAutoScrolledChapterIndex;
  int _lastAutoScrolledChapterCount = -1;

  @override
  void initState() {
    super.initState();
    final initialChapterIndex = _currentChapterListIndex();
    _listController = ScrollController(
      initialScrollOffset:
          _catalogOffsetForIndex(initialChapterIndex, widget.metrics),
    );
    if (initialChapterIndex >= 0) {
      _lastAutoScrolledChapterIndex = widget.currentChapterIndex;
      _lastAutoScrolledChapterCount = widget.chapters.length;
    }
    _dragController = AnimationController.unbounded(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _dragOffset = _dragController.value);
      });
  }

  @override
  void didUpdateWidget(covariant _CatalogBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentChapterIndex != widget.currentChapterIndex ||
        oldWidget.chapters.length != widget.chapters.length) {
      _scheduleScrollToCurrentChapter();
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    _listController.dispose();
    super.dispose();
  }

  double _catalogRowHeight(_ReaderOverlayMetrics metrics) => metrics.s(64);

  double _catalogSeparatorHeight(_ReaderOverlayMetrics metrics) => metrics.s(8);

  int _currentChapterListIndex() {
    return widget.chapters.indexWhere(
      (chapter) => chapter.chapterIndex == widget.currentChapterIndex,
    );
  }

  double _catalogOffsetForIndex(
      int chapterListIndex, _ReaderOverlayMetrics metrics) {
    if (chapterListIndex < 0) return 0;
    return chapterListIndex *
        (_catalogRowHeight(metrics) + _catalogSeparatorHeight(metrics));
  }

  void _scheduleScrollToCurrentChapter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listController.hasClients || widget.chapters.isEmpty) {
        return;
      }
      if (_lastAutoScrolledChapterIndex == widget.currentChapterIndex &&
          _lastAutoScrolledChapterCount == widget.chapters.length) {
        return;
      }
      final index = _currentChapterListIndex();
      if (index < 0) return;

      final targetOffset = _catalogOffsetForIndex(index, widget.metrics);
      final maxOffset = _listController.position.maxScrollExtent;
      _listController.jumpTo(targetOffset.clamp(0.0, maxOffset).toDouble());
      _lastAutoScrolledChapterIndex = widget.currentChapterIndex;
      _lastAutoScrolledChapterCount = widget.chapters.length;
    });
  }

  void _handleHeaderDragStart(DragStartDetails details) {
    _dragController.stop();
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    final nextOffset =
        (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    if (nextOffset == _dragOffset) return;
    setState(() => _dragOffset = nextOffset);
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    final sheetHeight = widget.metrics.catalogSheetHeight(608);
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset > sheetHeight * 0.25 ||
        (velocity > 900 && _dragOffset > sheetHeight * 0.08);
    if (shouldClose) {
      _animateClosed(sheetHeight: sheetHeight, velocity: velocity);
      return;
    }
    _animateBack();
  }

  void _handleHeaderDragCancel() {
    _animateBack();
  }

  void _animateBack() {
    _dragController.value = _dragOffset;
    _dragController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _animateClosed({
    required double sheetHeight,
    required double velocity,
  }) {
    final remainingDistance =
        (sheetHeight - _dragOffset).clamp(1.0, sheetHeight).toDouble();
    final effectiveVelocity = velocity.abs().clamp(900.0, 3200.0).toDouble();
    final durationMs =
        (remainingDistance / effectiveVelocity * 1000).clamp(110, 260).round();

    _dragController.value = _dragOffset;
    _dragController
        .animateTo(
      sheetHeight,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final palette = widget.palette;
    final hasMore = widget.hasMore;
    final isLoadingMore = widget.isLoadingMore;
    final onLoadMore = widget.onLoadMore;
    final chapters = widget.chapters;
    final currentChapterIndex = widget.currentChapterIndex;
    final chapterCount = widget.chapterCount;
    final bookTitle = widget.bookTitle;
    final onChapterSelected = widget.onChapterSelected;
    final sheetHeight = metrics.catalogSheetHeight(608);
    final catalogRowHeight = _catalogRowHeight(metrics);
    final catalogSeparatorHeight = _catalogSeparatorHeight(metrics);

    return Positioned(
      key: const ValueKey('reader-catalog-sheet'),
      left: metrics.left,
      top: metrics.height - sheetHeight,
      width: metrics.width,
      height: sheetHeight,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: _GlassSurface(
          fill: context.readerControls.surface.panel,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(metrics.s(28)),
            topRight: Radius.circular(metrics.s(28)),
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
          shadowColor: context.readerControls.surface.sheetShadow,
          shadowOffset: Offset(0, -metrics.s(12)),
          shadowBlur: metrics.s(34),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                metrics.s(20), metrics.s(14), metrics.s(20), metrics.s(18)),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _handleHeaderDragStart,
                  onVerticalDragUpdate: _handleHeaderDragUpdate,
                  onVerticalDragEnd: _handleHeaderDragEnd,
                  onVerticalDragCancel: _handleHeaderDragCancel,
                  child: Column(
                    children: [
                      Container(
                        width: metrics.s(42),
                        height: metrics.s(4),
                        decoration: BoxDecoration(
                          color: (palette.outline ??
                                  context.readerControls.surface.outline)
                              .withValues(alpha: 0.7),
                          borderRadius: AppRadius.full,
                        ),
                      ),
                      SizedBox(height: metrics.s(18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$bookTitle · 共 $chapterCount 章',
                                style: DudoTextStyles.sans(
                                  color: context.readerControls.text.secondary,
                                  fontSize: metrics.s(12),
                                ),
                              ),
                              SizedBox(height: metrics.s(4)),
                              Text(
                                '目录',
                                style: DudoTextStyles.serif(
                                  color: context.readerControls.text.primary,
                                  fontSize: metrics.s(26),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '倒序',
                            style: DudoTextStyles.sans(
                              color: context.readerControls.action.accent,
                              fontSize: metrics.s(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.s(14)),
                      _SegmentTabs(
                          metrics: metrics,
                          labels: const ['目录', '书签', '笔记'],
                          selected: 0,
                          palette: palette),
                    ],
                  ),
                ),
                SizedBox(height: metrics.s(14)),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < metrics.s(160) &&
                          hasMore &&
                          !isLoadingMore) {
                        onLoadMore?.call();
                      }
                      return false;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bottomPadding =
                            (constraints.maxHeight - catalogRowHeight)
                                .clamp(0.0, double.infinity)
                                .toDouble();
                        return ListView.separated(
                          key: const ValueKey('reader-catalog-list'),
                          controller: _listController,
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          itemCount: chapters.length +
                              (hasMore || isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              SizedBox(height: catalogSeparatorHeight),
                          itemBuilder: (context, index) {
                            if (index >= chapters.length) {
                              return _CatalogLoadingFooter(
                                metrics: metrics,
                                palette: palette,
                                isLoading: isLoadingMore,
                              );
                            }
                            final chapter = chapters[index];
                            final active =
                                chapter.chapterIndex == currentChapterIndex;
                            return GestureDetector(
                              key: ValueKey(
                                  'reader-catalog-chapter-${chapter.chapterIndex}'),
                              onTap: () =>
                                  onChapterSelected(chapter.chapterIndex),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                height: catalogRowHeight,
                                padding: EdgeInsets.symmetric(
                                    horizontal: metrics.s(14),
                                    vertical: metrics.s(10)),
                                decoration: BoxDecoration(
                                  color: active
                                      ? context.readerControls.action.accentSoft
                                      : context
                                          .readerControls.overlay.transparent,
                                  borderRadius:
                                      BorderRadius.circular(metrics.s(18)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapter.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: DudoTextStyles.sans(
                                              color: palette.foreground,
                                              fontSize: metrics.s(14),
                                              fontWeight: active
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: metrics.s(4)),
                                          Text(
                                            chapter.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: DudoTextStyles.sans(
                                              color: palette.mutedForeground ??
                                                  context.readerControls.text
                                                      .secondary,
                                              fontSize: metrics.s(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (active)
                                      Icon(LucideIcons.bookOpenCheck,
                                          size: metrics.s(18),
                                          color: context
                                              .readerControls.action.accent),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogLoadingFooter extends StatelessWidget {
  const _CatalogLoadingFooter({
    required this.metrics,
    required this.palette,
    required this.isLoading,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('reader-catalog-loading-footer'),
      padding: EdgeInsets.symmetric(vertical: metrics.s(12)),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: metrics.s(18),
                height: metrics.s(18),
                child: CircularProgressIndicator(
                  strokeWidth: metrics.s(2),
                  color: context.readerControls.action.accent,
                ),
              )
            : Text(
                '继续加载目录',
                style: DudoTextStyles.sans(
                  color: palette.mutedForeground ??
                      context.readerControls.text.secondary,
                  fontSize: metrics.s(12),
                ),
              ),
      ),
    );
  }
}
