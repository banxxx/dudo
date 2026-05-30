import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/breakpoints.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_tokens.dart';
import 'reader_controls.dart';

/// Fullscreen reader. Independent of global theme; uses [ReaderPalette]s.
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
  bool _showControls = false;
  ReaderPalette _palette = ReaderTheme.parchment;

  @override
  Widget build(BuildContext context) {
    final LayoutMode mode = Breakpoints.of(context);
    final bool useTwoPane = mode == LayoutMode.twoPane;

    return Scaffold(
      backgroundColor: _palette.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showControls = !_showControls),
              child: useTwoPane ? _buildTwoPane() : _buildSinglePane(),
            ),
            if (_showControls)
              ReaderControls(
                onClose: () => setState(() => _showControls = false),
                onBack: () => context.pop(),
                palette: _palette,
                onPaletteChanged: (ReaderPalette p) =>
                    setState(() => _palette = p),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePane() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: _ReaderPageBody(palette: _palette, pageNumber: 1),
    );
  }

  Widget _buildTwoPane() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _ReaderPageBody(palette: _palette, pageNumber: 1),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _ReaderPageBody(palette: _palette, pageNumber: 2),
          ),
        ),
      ],
    );
  }
}

class _ReaderPageBody extends StatelessWidget {
  const _ReaderPageBody({required this.palette, required this.pageNumber});

  final ReaderPalette palette;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    // We use GoogleFonts so we don't have to bundle Noto Serif SC in pubspec.
    final TextStyle textStyle = GoogleFonts.notoSerifSc(
      color: palette.foreground,
      fontSize: 18,
      height: 1.8,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '第一章 · 开始',
          style: textStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              '正文骨架 — 此处由章节内容填充。\n\n'
              '阅读器使用独立的调色板，不跟随全局 Material You 主题。'
              '动效遵循 M3 emphasized 曲线，翻页动画在 ReaderControls 中可切换。',
              style: textStyle,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('第一章', style: textStyle.copyWith(fontSize: 12)),
            Text('$pageNumber / N', style: textStyle.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
