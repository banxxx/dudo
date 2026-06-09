import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/reader_theme.dart';
import '../../data/reader_document_source.dart';
import '../../domain/reader_location.dart';
import '../../domain/reader_settings.dart';
import '../../domain/reader_viewport_state.dart';
import '../../layout/reader_layout_engine.dart';
import '../../layout/reader_position_mapper.dart';
import '../widgets/reader_text_layer.dart';

class ScrollReaderView extends StatefulWidget {
  const ScrollReaderView({
    super.key,
    required this.bookId,
    required this.chapterCount,
    required this.source,
    required this.layoutEngine,
    required this.viewportSize,
    required this.viewport,
    required this.settings,
    required this.palette,
    this.externalPageTurnRequestId = 0,
    this.externalPageTurnDirection = 0,
    required this.onContentTap,
    required this.onLocationChanged,
  });

  final String bookId;
  final int chapterCount;
  final ReaderDocumentSource source;
  final ReaderLayoutEngine layoutEngine;
  final Size viewportSize;
  final ReaderViewportState viewport;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final int externalPageTurnRequestId;
  final int externalPageTurnDirection;
  final VoidCallback onContentTap;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<ScrollReaderView> createState() => _ScrollReaderViewState();
}

class _ScrollReaderViewState extends State<ScrollReaderView> {
  static const int _maxWindowChapters = 5;

  late ScrollController _controller;
  final List<ReaderChapterWindowItem> _entries = [];
  final Set<int> _loadingChapters = {};

  Timer? _settleTimer;
  int _windowVersion = 0;
  int _viewportGeneration = 0;
  int? _positionedChapterIndex;
  int? _lastReportedChapterIndex;
  int? _lastReportedOffset;
  double? _lastReportedScrollOffset;
  String? _settingsKey;
  int _handledExternalPageTurnRequestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = _createScrollController();
    _resetWindowFromViewport();
  }

  @override
  void didUpdateWidget(covariant ScrollReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSettingsKey = _settingsDigest();
    final needsReset = oldWidget.bookId != widget.bookId ||
        oldWidget.viewport.center.chapter.index !=
            widget.viewport.center.chapter.index ||
        oldWidget.viewport.currentLocation != widget.viewport.currentLocation ||
        _settingsKey != nextSettingsKey;

    if (needsReset) {
      _resetWindowFromViewport();
    }
    _handleExternalPageTurnIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleExternalPageTurnIfNeeded();
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.settings.pagePadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        padding.top,
        padding.right,
        padding.bottom,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onContentTap,
        child: KeyedSubtree(
          key: const ValueKey('reader-engine-scroll-view'),
          child: ListView.builder(
            key: ValueKey('reader-engine-scroll-window-$_viewportGeneration'),
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final item = _entries[index];
              return _ChapterSection(
                key: ValueKey(
                  'reader-engine-scroll-chapter-${item.chapter.index}',
                ),
                item: item,
                minHeight: _contentHeight(item),
                settings: widget.settings,
                palette: widget.palette,
              );
            },
          ),
        ),
      ),
    );
  }

  ScrollController _createScrollController({double initialOffset = 0}) {
    final controller = ScrollController(initialScrollOffset: initialOffset);
    controller.addListener(_handleScroll);
    return controller;
  }

  void _replaceScrollController({double initialOffset = 0}) {
    final previous = _controller;
    previous.removeListener(_handleScroll);
    _controller = _createScrollController(initialOffset: initialOffset);
    _viewportGeneration++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  void _resetWindowFromViewport() {
    _settleTimer?.cancel();
    _settingsKey = _settingsDigest();
    _windowVersion++;
    _positionedChapterIndex = null;
    _lastReportedChapterIndex = null;
    _lastReportedOffset = null;
    _lastReportedScrollOffset = null;
    _loadingChapters.clear();

    final nextEntries = <ReaderChapterWindowItem>[
      if (widget.viewport.previous != null) widget.viewport.previous!,
      widget.viewport.center,
      if (widget.viewport.next != null) widget.viewport.next!,
    ]..sort(
        (a, b) => a.chapter.index.compareTo(b.chapter.index),
      );

    final initialOffset = _entryStartOffsetIn(
          entries: nextEntries,
          chapterIndex: widget.viewport.center.chapter.index,
        ) +
        ReaderPositionMapper.scrollOffsetForLocation(
          layout: widget.viewport.center.layout,
          location: widget.viewport.currentLocation,
        );
    _replaceScrollController(initialOffset: initialOffset);
    setState(() {
      _entries
        ..clear()
        ..addAll(nextEntries);
    });
    _positionCurrentChapterAfterLayout();
    _loadAround(widget.viewport.center.chapter.index, _windowVersion);
  }

  void _positionCurrentChapterAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || _entries.isEmpty) return;
      final centerIndex = widget.viewport.center.chapter.index;
      if (_positionedChapterIndex == centerIndex) return;

      final targetOffset = _entryStartOffset(centerIndex) +
          ReaderPositionMapper.scrollOffsetForLocation(
            layout: widget.viewport.center.layout,
            location: widget.viewport.currentLocation,
          );
      _controller.jumpTo(
        targetOffset.clamp(0.0, _controller.position.maxScrollExtent),
      );
      _positionedChapterIndex = centerIndex;
      _reportProgressForOffset(_controller.offset, force: true);
    });
  }

  void _handleScroll() {
    if (!_controller.hasClients || _entries.isEmpty) return;
    final position = _controller.position;
    final threshold = math.max(position.viewportDimension * 1.2, 480.0);

    if (position.extentAfter < threshold) {
      unawaited(_loadNext());
    }
    if (position.extentBefore < threshold) {
      unawaited(_loadPrevious());
    }

    _reportProgressForOffset(position.pixels);
    _scheduleTrim();
  }

  Future<void> _loadAround(int chapterIndex, int version) async {
    await Future.wait([
      _loadChapter(chapterIndex - 1, insertAtStart: true, version: version),
      _loadChapter(chapterIndex + 1, insertAtStart: false, version: version),
    ]);
  }

  Future<void> _loadNext() async {
    if (_entries.isEmpty) return;
    await _loadChapter(
      _entries.last.chapter.index + 1,
      insertAtStart: false,
      version: _windowVersion,
    );
  }

  Future<void> _loadPrevious() async {
    if (_entries.isEmpty) return;
    await _loadChapter(
      _entries.first.chapter.index - 1,
      insertAtStart: true,
      version: _windowVersion,
    );
  }

  Future<void> _loadChapter(
    int chapterIndex, {
    required bool insertAtStart,
    required int version,
  }) async {
    if (chapterIndex < 0 || chapterIndex >= widget.chapterCount) return;
    if (_loadingChapters.contains(chapterIndex)) return;
    if (_entries.any((entry) => entry.chapter.index == chapterIndex)) return;

    _loadingChapters.add(chapterIndex);
    try {
      final chapter = await widget.source.loadChapter(
        bookId: widget.bookId,
        chapterIndex: chapterIndex,
      );
      final layout = await widget.layoutEngine.layoutChapter(
        chapter: chapter,
        settings: widget.settings,
        viewportSize: widget.viewportSize,
      );
      if (!mounted || version != _windowVersion) return;

      final item = ReaderChapterWindowItem(
        chapter: chapter,
        layout: layout,
        status: ReaderChapterLoadStatus.loaded,
      );
      if (insertAtStart) {
        final oldOffset = _controller.hasClients ? _controller.offset : 0.0;
        final insertedHeight = _contentHeight(item);
        setState(() => _entries.insert(0, item));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              !_controller.hasClients ||
              version != _windowVersion) {
            return;
          }
          _controller.jumpTo(
            (oldOffset + insertedHeight).clamp(
              _controller.position.minScrollExtent,
              _controller.position.maxScrollExtent,
            ),
          );
        });
      } else {
        setState(() => _entries.add(item));
      }
    } finally {
      _loadingChapters.remove(chapterIndex);
    }
  }

  void _reportProgressForOffset(double offset, {bool force = false}) {
    final location = _locationForWindowOffset(offset);
    if (location == null) return;
    if (!force && _lastReportedScrollOffset != null) {
      final minDelta = math.max(_readerHeight * 0.08, 72.0);
      if ((offset - _lastReportedScrollOffset!).abs() < minDelta &&
          _lastReportedChapterIndex == location.chapterIndex) {
        return;
      }
    }
    if (!force &&
        _lastReportedChapterIndex == location.chapterIndex &&
        _lastReportedOffset == location.offset) {
      return;
    }
    _lastReportedChapterIndex = location.chapterIndex;
    _lastReportedOffset = location.offset;
    _lastReportedScrollOffset = offset;
    widget.onLocationChanged(location);
  }

  ReaderLocation? _locationForWindowOffset(double offset) {
    var remaining = offset.clamp(0.0, _totalContentHeight());
    for (final entry in _entries) {
      final height = _contentHeight(entry);
      if (remaining < height || entry == _entries.last) {
        return ReaderPositionMapper.locationForScrollOffset(
          bookId: entry.chapter.bookId,
          layout: entry.layout,
          scrollOffset: remaining.clamp(0.0, height),
        );
      }
      remaining -= height;
    }
    return null;
  }

  double _entryStartOffset(int chapterIndex) {
    return _entryStartOffsetIn(entries: _entries, chapterIndex: chapterIndex);
  }

  double _entryStartOffsetIn({
    required List<ReaderChapterWindowItem> entries,
    required int chapterIndex,
  }) {
    var offset = 0.0;
    for (final entry in entries) {
      if (entry.chapter.index == chapterIndex) return offset;
      offset += _contentHeight(entry);
    }
    return 0.0;
  }

  double _totalContentHeight() {
    var height = 0.0;
    for (final entry in _entries) {
      height += _contentHeight(entry);
    }
    return height;
  }

  double _contentHeight(ReaderChapterWindowItem item) {
    return math.max(item.layout.contentHeight, _readerHeight);
  }

  double get _readerHeight {
    final padding = widget.settings.pagePadding;
    return math.max(1, widget.viewportSize.height - padding.vertical);
  }

  void _scheduleTrim() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 300), _trimWindow);
  }

  void _trimWindow() {
    if (!mounted || !_controller.hasClients) return;
    final anchor = _lastReportedChapterIndex ??
        widget.viewport.currentLocation.chapterIndex;

    while (_entries.length > _maxWindowChapters &&
        _entries.first.chapter.index < anchor - 1) {
      final removedHeight = _contentHeight(_entries.removeAt(0));
      _controller.jumpTo(
        math.max(_controller.position.minScrollExtent,
            _controller.offset - removedHeight),
      );
    }
    while (_entries.length > _maxWindowChapters &&
        _entries.last.chapter.index > anchor + 1) {
      _entries.removeLast();
    }
    if (mounted) setState(() {});
  }

  String _settingsDigest() {
    final padding = widget.settings.pagePadding;
    return [
      widget.settings.paletteId,
      widget.settings.fontFamily,
      widget.settings.fontSize,
      widget.settings.lineHeight,
      widget.settings.paragraphSpacing,
      widget.settings.firstLineIndentEnabled,
      widget.settings.textEnhancementEnabled,
      padding.left,
      padding.top,
      padding.right,
      padding.bottom,
      widget.viewportSize.width,
      widget.viewportSize.height,
    ].join('|');
  }

  void _handleExternalPageTurnIfNeeded() {
    final requestId = widget.externalPageTurnRequestId;
    final direction = widget.externalPageTurnDirection;
    if (requestId == 0 ||
        requestId == _handledExternalPageTurnRequestId ||
        direction == 0) {
      return;
    }
    _handledExternalPageTurnRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      final pageDistance = math.max(_readerHeight * 0.9, 1.0);
      final target = (_controller.offset + direction * pageDistance).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    super.key,
    required this.item,
    required this.minHeight,
    required this.settings,
    required this.palette,
  });

  final ReaderChapterWindowItem item;
  final double minHeight;
  final ReaderSettings settings;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ReaderTextLayer(
        blocks: item.chapter.blocks,
        settings: settings,
        palette: palette,
      ),
    );
  }
}
