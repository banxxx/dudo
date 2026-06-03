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

  bool get _isPureReading => _overlayMode == ReaderOverlayMode.hidden;

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
                  _ReaderStatusBar(metrics: metrics, palette: _palette),
                  _SoftPageEdge(metrics: metrics, pureReading: _isPureReading),
                  _ReadingArticle(
                    metrics: metrics,
                    palette: _palette,
                    chapter: _chapter,
                    pureReading: _isPureReading,
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
                    pureReading: _isPureReading,
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
                    onClose: () => setState(
                        () => _overlayMode = ReaderOverlayMode.controls),
                    onModeChanged: (mode) =>
                        setState(() => _overlayMode = mode),
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
    setState(() {
      _overlayMode = _overlayMode == ReaderOverlayMode.hidden
          ? ReaderOverlayMode.controls
          : ReaderOverlayMode.hidden;
    });
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

class _ReaderStatusBar extends StatelessWidget {
  const _ReaderStatusBar({required this.metrics, required this.palette});

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.left,
      top: 0,
      width: metrics.width,
      height: metrics.s(62),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.s(24),
          metrics.s(18),
          metrics.s(24),
          metrics.s(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '9:41',
              style: DudoTextStyles.numeric(
                color: palette.foreground,
                fontSize: metrics.s(15),
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                _StatusDot(
                    width: metrics.s(15),
                    height: metrics.s(10),
                    color: palette.foreground),
                SizedBox(width: metrics.s(6)),
                _StatusDot(
                    width: metrics.s(16),
                    height: metrics.s(12),
                    color: palette.foreground),
                SizedBox(width: metrics.s(6)),
                _BatteryIcon(metrics: metrics, color: palette.foreground),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(
      {required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon({required this.metrics, required this.color});

  final _ReaderPageMetrics metrics;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.s(20),
      height: metrics.s(14),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: metrics.s(18),
            height: metrics.s(12),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Positioned(
            left: metrics.s(3),
            child: Container(
              width: metrics.s(11),
              height: metrics.s(6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: metrics.s(2),
              height: metrics.s(6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPageEdge extends StatelessWidget {
  const _SoftPageEdge({required this.metrics, required this.pureReading});

  final _ReaderPageMetrics metrics;
  final bool pureReading;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(18),
      top: metrics.y(pureReading ? 100 : 170),
      width: metrics.s(1),
      height: metrics.s(pureReading ? 610 : 432),
      child: const ColoredBox(color: Color(0x66D8CDBB)),
    );
  }
}

class _ReadingArticle extends StatelessWidget {
  const _ReadingArticle({
    required this.metrics,
    required this.palette,
    required this.chapter,
    required this.pureReading,
    required this.fontSize,
    required this.lineHeight,
    required this.preview,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final _MockReaderChapter chapter;
  final bool pureReading;
  final double fontSize;
  final double lineHeight;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final titleSize = pureReading ? 30.0 : 28.0;
    final bodySize =
        pureReading ? fontSize : (fontSize - 1).clamp(16, 23).toDouble();
    return Positioned(
      key: const ValueKey('reader-article'),
      left: metrics.x(30),
      top: metrics.y(pureReading ? 92 : 164),
      width: metrics.s(330),
      height: metrics.s(pureReading ? 642 : 450),
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
                  fontSize: metrics.s(titleSize),
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: metrics.s(pureReading ? 8 : 6)),
              Text(
                chapter.chapterLabel,
                style: DudoTextStyles.sans(
                  color: palette.mutedForeground ?? DudoColors.secondary,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: metrics.s(pureReading ? 18 : 14)),
              Expanded(
                child: Text(
                  chapter.paragraphs.join('\n\n'),
                  overflow: TextOverflow.clip,
                  style: DudoTextStyles.serif(
                    color: palette.foreground,
                    fontSize: metrics.s(bodySize),
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
    required this.pureReading,
  });

  final _ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String chapterLabel;
  final double progress;
  final bool pureReading;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-progress'),
      left: metrics.x(30),
      top: metrics.y(pureReading ? 766 : 650),
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
