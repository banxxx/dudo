import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_content_block.dart';
import '../../domain/reader_settings.dart';

class ReaderTextLayer extends StatelessWidget {
  const ReaderTextLayer({
    super.key,
    required this.blocks,
    required this.settings,
    required this.palette,
  });

  final List<ReaderContentBlock> blocks;
  final ReaderSettings settings;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          _BlockText(
            block: block,
            settings: settings,
            palette: palette,
          ),
      ],
    );
  }
}

class _BlockText extends StatelessWidget {
  const _BlockText({
    required this.block,
    required this.settings,
    required this.palette,
  });

  final ReaderContentBlock block;
  final ReaderSettings settings;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final currentBlock = block;
    final text = switch (currentBlock) {
      ReaderHeadingBlock(:final text) => text,
      ReaderParagraphBlock(:final text) => text,
      ReaderImageBlock(:final alt) => alt ?? '',
    };
    final isHeading = currentBlock is ReaderHeadingBlock;
    final bottomSpacing =
        currentBlock is ReaderParagraphBlock && !currentBlock.addBottomSpacing
            ? 0.0
            : settings.paragraphSpacing;
    final textStyle = DudoTextStyles.serif(
      color: palette.foreground,
      fontSize: isHeading ? settings.fontSize * (24 / 19) : settings.fontSize,
      height: settings.lineHeight,
      fontWeight: isHeading
          ? settings.textEnhancementEnabled
              ? FontWeight.w700
              : FontWeight.w600
          : settings.textEnhancementEnabled
              ? FontWeight.w500
              : FontWeight.w400,
      letterSpacing: isHeading ? 0 : 0.4,
    );
    final shouldIndent = currentBlock is ReaderParagraphBlock &&
        settings.firstLineIndentEnabled &&
        text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: shouldIndent
          ? Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(width: settings.fontSize * 2),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: textStyle,
            )
          : Text(
              text,
              style: textStyle,
            ),
    );
  }
}
