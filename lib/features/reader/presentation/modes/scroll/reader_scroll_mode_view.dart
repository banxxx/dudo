import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../features/bookshelf/data/bookshelf_repository.dart';
import '../../../../../shared/theme/app_fonts.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/reader_paragraph_span.dart';
import '../../../domain/reader_text_normalizer.dart';
import '../../layout/reader_page_metrics.dart';
import 'reader_scroll_block.dart';
import 'reader_scroll_chapter_entry.dart';

class ReaderScrollModeView extends StatefulWidget {
  const ReaderScrollModeView({
    super.key,
    required this.bookId,
    required this.chapterCount,
    required this.initialChapterIndex,
    required this.initialReadPosition,
    required this.initialChapterTitle,
    required this.initialChapterText,
    required this.initialChapterRawContent,
    required this.repository,
    required this.metrics,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.top,
    required this.height,
    required this.interactive,
    required this.preview,
    required this.jumpRequest,
    this.externalPageTurnRequestId = 0,
    this.externalPageTurnDirection = 0,
    required this.onProgressChanged,
    required this.onTap,
  });

  final String bookId;
  final int chapterCount;
  final int initialChapterIndex;
  final int initialReadPosition;
  final String initialChapterTitle;
  final String initialChapterText;
  final String initialChapterRawContent;
  final BookshelfRepository repository;
  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final double top;
  final double height;
  final bool interactive;
  final bool preview;
  final ReaderScrollJumpRequest? jumpRequest;
  final int externalPageTurnRequestId;
  final int externalPageTurnDirection;
  final ValueChanged<ReaderScrollProgress> onProgressChanged;
  final VoidCallback onTap;

  @override
  State<ReaderScrollModeView> createState() => _ReaderScrollModeViewState();
}

class _ReaderScrollModeViewState extends State<ReaderScrollModeView> {
  static const int _maxWindowChapters = 5;

  late ScrollController _controller;
  final List<ReaderScrollChapterEntry> _entries = [];
  final Set<int> _loadingChapters = {};
  final Map<String, double> _heightCache = {};

  bool _didInitialJump = false;
  bool _isLoadingInitialWindow = false;
  Timer? _settleTimer;
  int _windowVersion = 0;
  int _viewportGeneration = 0;
  int? _handledJumpRequestId;
  int _handledExternalPageTurnRequestId = 0;
  int? _lastReportedChapterIndex;
  int? _lastReportedReadPosition;
  double? _lastReportedScrollOffset;

  @override
  void initState() {
    super.initState();
    _controller = _createScrollController();
    _loadInitialWindow();
    final jumpRequest = widget.jumpRequest;
    if (jumpRequest != null) {
      _handleJumpRequest(jumpRequest);
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScrollModeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final layoutChanged = oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineHeight != widget.lineHeight ||
        oldWidget.metrics.width != widget.metrics.width;
    if (layoutChanged) {
      _heightCache.clear();
      _didInitialJump = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _jumpToInitialPosition());
    }
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.initialChapterIndex != widget.initialChapterIndex) {
      _resetWindow();
      _loadInitialWindow();
    }
    final jumpRequest = widget.jumpRequest;
    if (jumpRequest != null &&
        oldWidget.jumpRequest?.requestId != jumpRequest.requestId) {
      _handleJumpRequest(jumpRequest);
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
    final style = _paragraphStyle;
    final blocks = _blocks;
    return Positioned(
      key: const ValueKey('reader-scroll-mode'),
      left: widget.metrics.x(30),
      top: widget.top,
      width: widget.metrics.s(330),
      height: widget.height,
      child: IgnorePointer(
        ignoring: !widget.interactive,
        child: Opacity(
          opacity: widget.preview ? 0.42 : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: KeyedSubtree(
              key: const ValueKey('reader-scroll-view'),
              child: ListView.builder(
                key: ValueKey('reader-scroll-view-$_viewportGeneration'),
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: widget.metrics.s(32)),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return switch (block) {
                    ReaderScrollChapterHeader() => Padding(
                        key: ValueKey(
                            'reader-scroll-chapter-${block.chapterIndex}'),
                        padding: EdgeInsets.only(
                          top: widget.metrics.s(20),
                          bottom: widget.metrics.s(16),
                        ),
                        child: Text(
                          block.title,
                          style: _chapterTitleStyle,
                        ),
                      ),
                    ReaderScrollParagraphBlock() => Padding(
                        key: ValueKey('reader-paragraph-${block.span.index}'),
                        padding: EdgeInsets.only(
                          bottom: widget.metrics
                              .s(widget.fontSize * widget.lineHeight),
                        ),
                        child: Text(block.span.text, style: style),
                      ),
                  };
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _paragraphStyle => DudoTextStyles.serif(
        color: widget.palette.foreground,
        fontSize: widget.metrics.s(widget.fontSize),
        height: widget.lineHeight,
        letterSpacing: 0.4,
      );

  TextStyle get _chapterTitleStyle => DudoTextStyles.serif(
        color: widget.palette.foreground,
        fontSize: widget.metrics.s(24),
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  ScrollController _createScrollController({
    double initialScrollOffset = 0.0,
  }) {
    final controller =
        ScrollController(initialScrollOffset: initialScrollOffset);
    controller.addListener(_handleScroll);
    return controller;
  }

  void _replaceViewport({double initialScrollOffset = 0.0}) {
    final previousController = _controller;
    previousController.removeListener(_handleScroll);
    _controller = _createScrollController(
      initialScrollOffset: initialScrollOffset,
    );
    _viewportGeneration++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
    });
  }

  List<ReaderScrollBlock> get _blocks {
    return [
      for (final entry in _entries) ...[
        ReaderScrollChapterHeader(
          chapterIndex: entry.chapterIndex,
          title: entry.title,
        ),
        for (final span in entry.paragraphSpans)
          ReaderScrollParagraphBlock(
            chapterIndex: entry.chapterIndex,
            span: span,
          ),
      ],
    ];
  }

  List<_ScrollBlockLayoutRange> get _layoutRanges {
    final ranges = <_ScrollBlockLayoutRange>[];
    var offset = 0.0;
    for (final block in _blocks) {
      final height = _heightForBlock(block);
      ranges.add(
        _ScrollBlockLayoutRange(
          block: block,
          start: offset,
          end: offset + height,
        ),
      );
      offset += height;
    }
    return ranges;
  }

  Future<void> _loadInitialWindow() async {
    if (_isLoadingInitialWindow) return;
    _isLoadingInitialWindow = true;
    final version = ++_windowVersion;
    final center = widget.initialChapterIndex.clamp(0, widget.chapterCount - 1);
    final initialEntry = _entryFromContent(
      chapterIndex: center,
      title: widget.initialChapterTitle,
      text: widget.initialChapterText,
      rawContent: widget.initialChapterRawContent,
    );
    setState(() {
      _entries
        ..clear()
        ..add(initialEntry);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _windowVersion) return;
      _jumpToInitialPosition();
      _loadAdjacentInitialChapters(center, version);
    });
    _isLoadingInitialWindow = false;
  }

  Future<void> _loadAdjacentInitialChapters(
    int center,
    int version, {
    bool includePrevious = true,
  }) async {
    final previousEntry =
        includePrevious && center > 0 ? await _fetchEntry(center - 1) : null;
    if (mounted && version == _windowVersion && previousEntry != null) {
      final insertedHeight = _heightForEntry(previousEntry);
      final oldOffset = _controller.hasClients ? _controller.offset : 0.0;
      setState(() => _entries.insert(0, previousEntry));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients || version != _windowVersion) {
          return;
        }
        _controller.jumpTo(
          (oldOffset + insertedHeight).clamp(
            _controller.position.minScrollExtent,
            _controller.position.maxScrollExtent,
          ),
        );
      });
    }

    final nextEntry =
        center + 1 < widget.chapterCount ? await _fetchEntry(center + 1) : null;
    if (mounted && version == _windowVersion && nextEntry != null) {
      setState(() => _entries.add(nextEntry));
    }
    _scheduleSettleTrim();
  }

  Future<ReaderScrollChapterEntry?> _fetchEntry(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= widget.chapterCount) return null;
    if (_loadingChapters.contains(chapterIndex)) return null;
    if (_entries.any((entry) => entry.chapterIndex == chapterIndex)) {
      return null;
    }

    _loadingChapters.add(chapterIndex);
    try {
      return await _readEntry(chapterIndex);
    } on NoSuchMethodError {
      return null;
    } finally {
      _loadingChapters.remove(chapterIndex);
    }
  }

  Future<ReaderScrollChapterEntry?> _readEntry(int chapterIndex) async {
    final meta = await widget.repository.fetchChapterMetaForBookAtIndex(
      bookId: widget.bookId,
      chapterIndex: chapterIndex,
    );
    final content = await widget.repository.fetchChapterContentForBookAtIndex(
      bookId: widget.bookId,
      chapterIndex: chapterIndex,
    );
    if (meta == null || content == null) return null;

    final rawContent = content.content ?? '';
    final text = normalizeReaderText(rawContent);
    return _entryFromContent(
      chapterIndex: chapterIndex,
      title: meta.title,
      text: text,
      rawContent: rawContent,
    );
  }

  ReaderScrollChapterEntry _entryFromContent({
    required int chapterIndex,
    required String title,
    required String text,
    required String rawContent,
  }) {
    final spans = buildReaderParagraphSpans(rawContent);
    return ReaderScrollChapterEntry(
      chapterIndex: chapterIndex,
      title: title,
      text: text,
      paragraphSpans: _withoutDuplicateTitleSpan(
        title: title,
        spans: spans,
      ),
    );
  }

  List<ReaderParagraphSpan> _withoutDuplicateTitleSpan({
    required String title,
    required List<ReaderParagraphSpan> spans,
  }) {
    if (spans.isEmpty) return spans;
    final first = spans.first.text.trim();
    final normalizedTitle = _normalizedTitleForCompare(title);
    final normalizedFirst = _normalizedTitleForCompare(first);
    final duplicated = normalizedTitle.isNotEmpty &&
        (normalizedFirst == normalizedTitle ||
            (normalizedFirst.startsWith(normalizedTitle) &&
                normalizedFirst.length <= normalizedTitle.length + 4));
    return duplicated ? spans.skip(1).toList(growable: false) : spans;
  }

  String _normalizedTitleForCompare(String value) {
    return value.trim().replaceAll(RegExp(r'[\s　:：。．.]+'), '').toLowerCase();
  }

  void _jumpToInitialPosition() {
    if (_didInitialJump || !_controller.hasClients || _entries.isEmpty) return;
    _didInitialJump = true;
    final target = _offsetForProgress(
      chapterIndex: widget.initialChapterIndex,
      readPosition: widget.initialReadPosition,
    );
    final maxScrollExtent = _controller.position.maxScrollExtent;
    _controller.jumpTo(target.clamp(0.0, maxScrollExtent));
    _reportProgress(
      chapterIndex: widget.initialChapterIndex,
      readPosition: widget.initialReadPosition,
      scrollOffset: _controller.offset,
      force: true,
    );
  }

  Future<void> _handleJumpRequest(ReaderScrollJumpRequest request) async {
    if (_handledJumpRequestId == request.requestId) return;
    _handledJumpRequestId = request.requestId;
    if (widget.chapterCount <= 0) return;

    final chapterIndex =
        request.chapterIndex.clamp(0, widget.chapterCount - 1).toInt();
    final existingEntry = _entryForChapter(chapterIndex);
    if (existingEntry != null) {
      final version = ++_windowVersion;
      _settleTimer?.cancel();
      _replaceViewport();
      setState(() {
        _entries
          ..clear()
          ..add(existingEntry);
        _didInitialJump = true;
        _lastReportedChapterIndex = null;
        _lastReportedReadPosition = null;
        _lastReportedScrollOffset = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || version != _windowVersion) return;
        _reportJumpedChapterProgress(
          chapterIndex: chapterIndex,
          readPosition: request.readPosition,
        );
        _loadAdjacentInitialChapters(
          chapterIndex,
          version,
          includePrevious: false,
        );
      });
      return;
    }

    final version = ++_windowVersion;
    _settleTimer?.cancel();
    final ReaderScrollChapterEntry? entry;
    try {
      entry = await _readEntry(chapterIndex);
    } on NoSuchMethodError {
      return;
    }
    if (!mounted || version != _windowVersion || entry == null) return;
    final loadedEntry = entry;

    _replaceViewport();
    setState(() {
      _entries
        ..clear()
        ..add(loadedEntry);
      _didInitialJump = true;
      _lastReportedChapterIndex = null;
      _lastReportedReadPosition = null;
      _lastReportedScrollOffset = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _windowVersion) return;
      _reportJumpedChapterProgress(
        chapterIndex: chapterIndex,
        readPosition: request.readPosition,
      );
      _loadAdjacentInitialChapters(
        chapterIndex,
        version,
        includePrevious: false,
      );
    });
  }

  void _reportJumpedChapterProgress({
    required int chapterIndex,
    required int readPosition,
  }) {
    if (!_controller.hasClients || _entries.isEmpty) return;
    if (readPosition > 0) {
      final target = _offsetForProgress(
        chapterIndex: chapterIndex,
        readPosition: readPosition,
      );
      final maxScrollExtent = _controller.position.maxScrollExtent;
      _controller.jumpTo(target.clamp(0.0, maxScrollExtent));
    }
    _reportProgress(
      chapterIndex: chapterIndex,
      readPosition: readPosition,
      scrollOffset: _controller.offset,
      force: true,
    );
  }

  void _handleScroll() {
    if (!_controller.hasClients || _entries.isEmpty) return;
    final position = _controller.position;
    final threshold = position.viewportDimension * 1.2;
    if (position.extentAfter < threshold) _loadNext();
    if (position.extentBefore < threshold) _loadPrevious();
    _reportProgressForOffset(position.pixels);
    _scheduleSettleTrim();
  }

  Future<void> _loadNext() async {
    if (_entries.isEmpty) return;
    final version = _windowVersion;
    final entry = await _fetchEntry(_entries.last.chapterIndex + 1);
    if (!mounted || version != _windowVersion || entry == null) return;
    setState(() => _entries.add(entry));
    _scheduleSettleTrim();
  }

  Future<void> _loadPrevious() async {
    if (_entries.isEmpty) return;
    final version = _windowVersion;
    final entry = await _fetchEntry(_entries.first.chapterIndex - 1);
    if (!mounted || version != _windowVersion || entry == null) return;
    final insertedHeight = _heightForEntry(entry);
    final oldOffset = _controller.hasClients ? _controller.offset : 0.0;
    setState(() => _entries.insert(0, entry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || version != _windowVersion) {
        return;
      }
      _controller.jumpTo(
        (oldOffset + insertedHeight).clamp(
          _controller.position.minScrollExtent,
          _controller.position.maxScrollExtent,
        ),
      );
      _scheduleSettleTrim();
    });
  }

  void _scheduleSettleTrim() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted || !_controller.hasClients) return;
      _trimWindowFromStartIfNeeded();
      _trimWindowFromEndIfNeeded();
    });
  }

  void _trimWindowFromStartIfNeeded() {
    while (_entries.length > _maxWindowChapters &&
        _entries.first.chapterIndex <
            (_lastReportedChapterIndex ?? widget.initialChapterIndex) - 1) {
      final removed = _entries.removeAt(0);
      final removedHeight = _heightForEntry(removed);
      if (_controller.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_controller.hasClients) return;
          _controller.jumpTo(math.max(0, _controller.offset - removedHeight));
        });
      }
    }
  }

  void _trimWindowFromEndIfNeeded() {
    while (_entries.length > _maxWindowChapters &&
        _entries.last.chapterIndex >
            (_lastReportedChapterIndex ?? widget.initialChapterIndex) + 1) {
      _entries.removeLast();
    }
  }

  void _reportProgressForOffset(double offset, {bool force = false}) {
    final range = _rangeForOffset(offset + widget.metrics.s(12));
    if (range == null || range.block is! ReaderScrollParagraphBlock) return;
    final block = range.block as ReaderScrollParagraphBlock;
    final entry = _entryForChapter(block.chapterIndex);
    if (entry == null) return;

    final localRatio =
        ((offset - range.start) / math.max(range.end - range.start, 1))
            .clamp(0.0, 1.0);
    final readPosition =
        (block.span.startOffset + block.span.length * localRatio)
            .round()
            .clamp(block.span.startOffset, block.span.endOffset)
            .toInt();
    _reportProgress(
      chapterIndex: block.chapterIndex,
      readPosition: readPosition,
      scrollOffset: offset,
      force: force,
    );
  }

  void _reportProgress({
    required int chapterIndex,
    required int readPosition,
    required double scrollOffset,
    bool force = false,
  }) {
    final entry = _entryForChapter(chapterIndex);
    if (entry == null) return;
    final normalizedReadPosition =
        readPosition.clamp(0, entry.text.length).toInt();
    if (!force && _lastReportedScrollOffset != null) {
      final minDelta = math.max(widget.metrics.s(72), widget.height * 0.08);
      if ((scrollOffset - _lastReportedScrollOffset!).abs() < minDelta &&
          _lastReportedChapterIndex == chapterIndex) {
        return;
      }
    }
    if (_lastReportedChapterIndex == chapterIndex &&
        _lastReportedReadPosition == normalizedReadPosition) {
      return;
    }
    _lastReportedChapterIndex = chapterIndex;
    _lastReportedReadPosition = normalizedReadPosition;
    _lastReportedScrollOffset = scrollOffset;
    widget.onProgressChanged(
      ReaderScrollProgress(
        chapterIndex: chapterIndex,
        readPosition: normalizedReadPosition,
        chapterTitle: entry.title,
        contentLength: entry.text.length,
      ),
    );
  }

  double _offsetForProgress({
    required int chapterIndex,
    required int readPosition,
  }) {
    final ranges = _layoutRanges;
    final chapterRanges = [
      for (final range in ranges)
        if (range.block.chapterIndex == chapterIndex) range,
    ];
    if (chapterRanges.isEmpty) return 0;

    final paragraphRanges = [
      for (final range in chapterRanges)
        if (range.block is ReaderScrollParagraphBlock) range,
    ];
    if (paragraphRanges.isEmpty) return chapterRanges.first.start;

    if (readPosition <= 0) return chapterRanges.first.start;
    final entry = _entryForChapter(chapterIndex);
    if (entry != null && readPosition >= entry.text.length) {
      return math.max(
          chapterRanges.first.start, paragraphRanges.last.end - widget.height);
    }

    for (final range in paragraphRanges) {
      final block = range.block as ReaderScrollParagraphBlock;
      if (readPosition < block.span.startOffset ||
          readPosition > block.span.endOffset) {
        continue;
      }
      final ratio = ((readPosition - block.span.startOffset) /
              math.max(block.span.length, 1))
          .clamp(0.0, 1.0);
      return range.start + (range.end - range.start) * ratio;
    }
    return chapterRanges.first.start;
  }

  _ScrollBlockLayoutRange? _rangeForOffset(double offset) {
    final ranges = _layoutRanges;
    if (ranges.isEmpty) return null;
    if (offset <= ranges.first.start) return ranges.first;
    if (offset >= ranges.last.end) return ranges.last;
    var low = 0;
    var high = ranges.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final range = ranges[mid];
      if (offset < range.start) {
        high = mid - 1;
      } else if (offset > range.end) {
        low = mid + 1;
      } else {
        return range;
      }
    }
    return ranges[low.clamp(0, ranges.length - 1)];
  }

  double _heightForEntry(ReaderScrollChapterEntry entry) {
    var height = _heightForBlock(
      ReaderScrollChapterHeader(
        chapterIndex: entry.chapterIndex,
        title: entry.title,
      ),
    );
    for (final span in entry.paragraphSpans) {
      height += _heightForBlock(
        ReaderScrollParagraphBlock(
          chapterIndex: entry.chapterIndex,
          span: span,
        ),
      );
    }
    return height;
  }

  double _heightForBlock(ReaderScrollBlock block) {
    final key = switch (block) {
      ReaderScrollChapterHeader() =>
        'h:${block.chapterIndex}:${block.title}:${widget.metrics.width}:${widget.fontSize}:${widget.lineHeight}',
      ReaderScrollParagraphBlock() =>
        'p:${block.chapterIndex}:${block.span.index}:${block.span.text.hashCode}:${widget.metrics.width}:${widget.fontSize}:${widget.lineHeight}',
    };
    final cached = _heightCache[key];
    if (cached != null) return cached;
    final height = switch (block) {
      ReaderScrollChapterHeader() => _chapterHeaderHeight(block),
      ReaderScrollParagraphBlock() => _paragraphHeight(block),
    };
    _heightCache[key] = height;
    return height;
  }

  double _chapterHeaderHeight(ReaderScrollChapterHeader block) {
    final painter = TextPainter(
      text: TextSpan(text: block.title, style: _chapterTitleStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: widget.metrics.s(330));
    return widget.metrics.s(20) + painter.height + widget.metrics.s(16);
  }

  double _paragraphHeight(ReaderScrollParagraphBlock block) {
    final painter = TextPainter(
      text: TextSpan(text: block.span.text, style: _paragraphStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: widget.metrics.s(330));
    return painter.height +
        widget.metrics.s(widget.fontSize * widget.lineHeight);
  }

  ReaderScrollChapterEntry? _entryForChapter(int chapterIndex) {
    for (final entry in _entries) {
      if (entry.chapterIndex == chapterIndex) return entry;
    }
    return null;
  }

  void _resetWindow() {
    _windowVersion++;
    _didInitialJump = false;
    _lastReportedChapterIndex = null;
    _lastReportedReadPosition = null;
    _lastReportedScrollOffset = null;
    _entries.clear();
    _loadingChapters.clear();
    _heightCache.clear();
  }

  void _handleExternalPageTurnIfNeeded() {
    final requestId = widget.externalPageTurnRequestId;
    final direction = widget.externalPageTurnDirection;
    if (requestId == 0 ||
        requestId == _handledExternalPageTurnRequestId ||
        direction == 0 ||
        !widget.interactive) {
      return;
    }
    _handledExternalPageTurnRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      final pageDistance = math.max(widget.height * 0.9, 1.0);
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

class ReaderScrollJumpRequest {
  const ReaderScrollJumpRequest({
    required this.requestId,
    required this.chapterIndex,
    required this.readPosition,
  });

  final int requestId;
  final int chapterIndex;
  final int readPosition;
}

class _ScrollBlockLayoutRange {
  const _ScrollBlockLayoutRange({
    required this.block,
    required this.start,
    required this.end,
  });

  final ReaderScrollBlock block;
  final double start;
  final double end;
}
