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
    this.height = 188,
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4025251F),
              offset: Offset(0, 12),
              blurRadius: 24,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              SizedBox(
                width: backWidth,
                height: height,
                child: _BackCover(
                  frontBytes: frontBytes,
                  style: style,
                  text: backText,
                  title: title,
                  author: author,
                  textColor: onBack,
                ),
              ),
              SizedBox(
                width: spineWidth,
                height: height,
                child: _Spine(title: title, color: style.spineColor),
              ),
              SizedBox(
                width: frontWidth,
                height: height,
                child: Image.memory(
                  frontBytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ],
          ),
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
    required this.title,
    required this.author,
    required this.textColor,
  });

  final Uint8List frontBytes;
  final BookCoverStyle style;
  final String text;
  final String title;
  final String? author;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.serif(
              color: textColor,
              fontSize: 7.2,
              height: 1.55,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (author?.trim().isNotEmpty == true)
            Text(
              author!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 5.8,
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

class _Spine extends StatelessWidget {
  const _Spine({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = readableOn(color);
    final characters = title.trim().characters.take(6).toList();
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final character in characters)
            Text(
              character,
              style: DudoTextStyles.serif(
                color: textColor,
                fontSize: 8,
                height: 1.05,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
