import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../domain/book_cover_style.dart';
import 'cover_flow_models.dart';

/// A paper-model preview of the back, spine and front cover.
class BookWrapPreview extends StatelessWidget {
  const BookWrapPreview({
    super.key,
    required this.frontBytes,
    required this.title,
    required this.style,
    this.author,
    this.intro,
    this.height = 195,
  });

  final Uint8List frontBytes;
  final String title;
  final String? author;
  final String? intro;
  final BookCoverStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * fullWrapAspect;
    final spineWidth = width * style.spineWidth.wrapFraction;
    final frontWidth = width * 0.485;
    final backWidth = width - spineWidth - frontWidth;
    final backText = _backText();
    final onBack = style.backStyle == CoverBackStyle.intro
        ? DudoColors.textPrimary
        : const Color(0xFFFFF8EA);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Row(
          children: [
            SizedBox(
              width: backWidth,
              height: height,
              child: _BackCover(
                frontBytes: frontBytes,
                style: style,
                text: backText,
                textColor: onBack,
              ),
            ),
            SizedBox(
              width: spineWidth,
              height: height,
              child: _Spine(
                title: title,
                author: author,
                color: style.spineColor,
              ),
            ),
            SizedBox(
              width: frontWidth,
              height: height,
              child: _FrontCover(
                frontBytes: frontBytes,
                title: title,
                author: author,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _backText() {
    final value = intro?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value == null || value.isEmpty) {
      return '在 Dudo 收藏与阅读。';
    }
    return value.length <= 90 ? value : '${value.substring(0, 90)}…';
  }
}

class _BackCover extends StatelessWidget {
  const _BackCover({
    required this.frontBytes,
    required this.style,
    required this.text,
    required this.textColor,
  });

  final Uint8List frontBytes;
  final BookCoverStyle style;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.serif(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 8.5,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 60,
            height: 1,
            color: textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            'DUDO',
            style: DudoTextStyles.sans(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );

    switch (style.backStyle) {
      case CoverBackStyle.blur:
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Image.memory(
                frontBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            const ColoredBox(color: Color(0x6625251F)),
            content,
          ],
        );
      case CoverBackStyle.solid:
        return ColoredBox(
          color: Color.lerp(style.spineColor, const Color(0xFF25251F), 0.18)!,
          child: content,
        );
      case CoverBackStyle.intro:
        return ColoredBox(
          color: const Color(0xFFF3ECDD),
          child: content,
        );
    }
  }
}

class _FrontCover extends StatelessWidget {
  const _FrontCover({
    required this.frontBytes,
    required this.title,
    this.author,
  });

  final Uint8List frontBytes;
  final String title;
  final String? author;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          frontBytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Text(
                '阅读收藏',
                style: DudoTextStyles.sans(
                  color: const Color(0xCCFFF8EA),
                  fontSize: 8,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: DudoTextStyles.serif(
                  color: const Color(0xFFFFF8EA),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                author?.trim().isNotEmpty == true ? author!.trim() : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: const Color(0xCCFFF8EA),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Spine extends StatelessWidget {
  const _Spine({required this.title, required this.color, this.author});

  final String title;
  final String? author;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = readableOn(color);
    final titleCharacters = title.trim().characters.take(6).toList();
    final authorCharacters =
        (author?.trim() ?? '').characters.take(6).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(color, Colors.black, 0.18)!,
            color,
            Color.lerp(color, Colors.black, 0.1)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            for (final character in titleCharacters)
              Text(
                character,
                style: DudoTextStyles.serif(
                  color: textColor,
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const Spacer(),
            for (final character in authorCharacters)
              Text(
                character,
                style: DudoTextStyles.serif(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 8,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
