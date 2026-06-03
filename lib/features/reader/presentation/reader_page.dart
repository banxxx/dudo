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
  ReaderOverlayMode _overlayMode = ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _brightness = 0.72;
  String _pageTurnMode = '滑动';
  bool _isListening = false;
  late int _currentChapterIndex;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _syncSystemUiMode();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.initialChapterIndex != widget.initialChapterIndex) {
      _currentChapterIndex = widget.initialChapterIndex;
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
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleOverlay,
              child: Stack(
                children: [
                  _ReaderPaperBackground(palette: _palette),
                  _SoftPageEdge(metrics: metrics),
                  content,
                ],
              ),
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
    if (localPath != null && chapters.length == 1 && firstChapterContentLength > 60000) {
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

    return Stack(
      children: [
        _ReadingArticle(
          metrics: metrics,
          palette: _palette,
          chapter: view,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          preview: _overlayMode != ReaderOverlayMode.hidden &&
              _overlayMode != ReaderOverlayMode.controls,
        ),
        _ReaderProgress(
          metrics: metrics,
          palette: _palette,
          chapterLabel: view.chapterLabel,
          progress: view.progress,
        ),
        ReaderControls(
          mode: _overlayMode,
          bookTitle: view.bookTitle,
          chapterLabel: view.chapterLabel,
          chapterTitle: view.chapterTitle,
          progress: view.progress,
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
          onBack: () => context.pop(),
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
          onFontSizeChanged: (fontSize) => setState(() => _fontSize = fontSize),
          onLineHeightChanged: (lineHeight) =>
              setState(() => _lineHeight = lineHeight),
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

  void _selectChapter(int chapterIndex) {
    if (_currentChapterIndex == chapterIndex) {
      _setOverlayMode(ReaderOverlayMode.controls);
      return;
    }
    setState(() {
      _currentChapterIndex = chapterIndex;
      _overlayMode = ReaderOverlayMode.controls;
    });
    ref.read(bookshelfRepositoryProvider).updateReadingProgress(
          bookId: widget.bookId,
          chapterIndex: chapterIndex,
          readPosition: 0,
        );
    _syncSystemUiMode(ReaderOverlayMode.controls);
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

class _ReadingArticle extends StatelessWidget {
  const _ReadingArticle({
    required this.metrics,
    required this.palette,
    required this.chapter,
    required this.fontSize,
    required this.lineHeight,
    required this.preview,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final _ReaderChapterView chapter;
  final double fontSize;
  final double lineHeight;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-article'),
      left: metrics.x(30),
      top: metrics.y(92),
      width: metrics.s(330),
      height: metrics.s(642),
      child: Opacity(
        opacity: preview ? 0.42 : 1,
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  chapter.paragraphs.join('\n\n'),
                  overflow: TextOverflow.clip,
                  style: DudoTextStyles.serif(
                    color: palette.foreground,
                    fontSize: metrics.s(fontSize),
                    height: lineHeight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderProgress extends StatelessWidget {
  const _ReaderProgress({
    required this.metrics,
    required this.palette,
    required this.chapterLabel,
    required this.progress,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String chapterLabel;
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
                chapterLabel,
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
    required this.progress,
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
  final double progress;
  final List<String> paragraphs;
  final int currentChapterIndex;
  final int chapterCount;
  final int? previousChapterIndex;
  final int? nextChapterIndex;
  final List<ReaderCatalogItem> catalogItems;
  final bool contentMissing;

  bool get hasPrevious => previousChapterIndex != null;
  bool get hasNext => nextChapterIndex != null;

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
      progress: ((position + 1) / chapters.length).clamp(0, 1).toDouble(),
      paragraphs: paragraphs,
      currentChapterIndex: chapter.chapterIndex,
      chapterCount: chapters.length,
      previousChapterIndex:
          position > 0 ? chapters[position - 1].chapterIndex : null,
      nextChapterIndex:
          position + 1 < chapters.length ? chapters[position + 1].chapterIndex : null,
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
