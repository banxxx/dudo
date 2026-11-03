import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';

/// The Dudo title lockup printed over a user supplied cover: a small label at
/// the top, the book title in the middle and the author along the bottom.
///
/// Sizes are derived from the cover width so the same lockup works on the
/// detail hero, the edit preview and the shelf thumbnail.
class CoverTitleOverlay extends StatelessWidget {
  const CoverTitleOverlay({
    super.key,
    required this.title,
    this.author,
  });

  final String title;
  final String? author;

  static const _textColor = Color(0xFFFFF8EA);
  static const _mutedTextColor = Color(0xD9FFF8EA);

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return const SizedBox.shrink();
    final trimmedAuthor = author?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 160.0;
        final maxTitleWidth = width * 0.86;
        final length = math.max(1, trimmedTitle.characters.length);
        final fittedTitle = maxTitleWidth * 2.85 / length;
        final titleSize = math
            .min(width * 0.19, fittedTitle)
            .clamp(width * 0.085, width * 0.19);
        final labelSize = (width * 0.062).clamp(5.5, 11.0);
        final authorSize = (width * 0.055).clamp(5.0, 10.0);
        final shadows = [
          Shadow(
            color: const Color(0x6B000000),
            blurRadius: width * 0.035,
            offset: Offset(0, width * 0.008),
          ),
        ];

        return IgnorePointer(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.07,
              vertical: height * 0.06,
            ),
            child: Column(
              children: [
                Text(
                  '阅读收藏',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: _mutedTextColor,
                    fontSize: labelSize,
                  ).copyWith(shadows: shadows),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTitleWidth),
                  child: Text(
                    trimmedTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: DudoTextStyles.serif(
                      color: _textColor,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ).copyWith(shadows: shadows),
                  ),
                ),
                const Spacer(),
                if (trimmedAuthor.isNotEmpty)
                  Text(
                    trimmedAuthor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: _mutedTextColor,
                      fontSize: authorSize,
                    ).copyWith(shadows: shadows),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
