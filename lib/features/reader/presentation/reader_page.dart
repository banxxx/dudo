import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  _MockReaderChapter get _chapter => _mockChapter;

  @override
  void initState() {
    super.initState();
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
    _syncSystemUiMode();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _palette.foreground;
    final statusStyle = foreground.computeLuminance() > 0.5
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

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
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleOverlay,
              child: Stack(
                children: [
                  _ReaderPaperBackground(palette: _palette),
                  _SoftPageEdge(metrics: metrics),
                  _ReadingArticle(
                    metrics: metrics,
                    palette: _palette,
                    chapter: _chapter,
                    fontSize: _fontSize,
                    lineHeight: _lineHeight,
                    preview: _overlayMode != ReaderOverlayMode.hidden &&
                        _overlayMode != ReaderOverlayMode.controls,
                  ),
                  _ReaderProgress(
                    metrics: metrics,
                    palette: _palette,
                    chapterLabel: _chapter.chapterLabel,
                    progress: _chapter.progress,
                  ),
                  ReaderControls(
                    mode: _overlayMode,
                    bookTitle: _chapter.bookTitle,
                    chapterLabel: _chapter.chapterLabel,
                    chapterTitle: _chapter.title,
                    progress: _chapter.progress,
                    palette: _palette,
                    fontSize: _fontSize,
                    lineHeight: _lineHeight,
                    brightness: _brightness,
                    pageTurnMode: _pageTurnMode,
                    isListening: _isListening,
                    onBack: () => context.pop(),
                    onClose: () => _setOverlayMode(ReaderOverlayMode.controls),
                    onModeChanged: _setOverlayMode,
                    onPaletteChanged: (palette) =>
                        setState(() => _palette = palette),
                    onFontSizeChanged: (fontSize) =>
                        setState(() => _fontSize = fontSize),
                    onLineHeightChanged: (lineHeight) =>
                        setState(() => _lineHeight = lineHeight),
                    onBrightnessChanged: (brightness) =>
                        setState(() => _brightness = brightness),
                    onPageTurnModeChanged: (mode) =>
                        setState(() => _pageTurnMode = mode),
                    onListeningChanged: (listening) =>
                        setState(() => _isListening = listening),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
  final _MockReaderChapter chapter;
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
              Text(
                chapter.title,
                style: DudoTextStyles.serif(
                  color: palette.foreground,
                  fontSize: metrics.s(30),
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: metrics.s(8)),
              Text(
                chapter.chapterLabel,
                style: DudoTextStyles.sans(
                  color: palette.mutedForeground ?? DudoColors.secondary,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: metrics.s(18)),
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

class _MockReaderChapter {
  const _MockReaderChapter({
    required this.bookTitle,
    required this.chapterLabel,
    required this.title,
    required this.progress,
    required this.paragraphs,
  });

  final String bookTitle;
  final String chapterLabel;
  final String title;
  final double progress;
  final List<String> paragraphs;
}

const _mockChapter = _MockReaderChapter(
  bookTitle: '三体',
  chapterLabel: '第一章',
  title: '旧世界的回声',
  progress: 0.42,
  paragraphs: [
    '罗辑醒来的时候，窗外的天色还没有完全亮。城市像一页被轻轻翻起的旧纸，远处的楼宇隐藏在淡青色的雾里。',
    '他听见某种极轻的声音，像有人在很远的地方翻阅一本书。那声音并不急促，却让房间里所有物件都显得陌生起来。',
    '“有些故事并不是从开头开始的。”他想。那些被时间折起的角落，总会在某个清晨重新露出来。',
    '屏幕在桌面上亮起，显示着一条未读消息。罗辑没有立刻去看，只是让自己慢慢适应这个旧世界的清晨。',
    '窗外第一班列车穿过高架，低沉的震动沿着墙面传来，像一枚书签落入厚重的章节。',
  ],
);
