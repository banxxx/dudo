import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../layout/reader_page_metrics.dart';

class ReaderProgress extends StatelessWidget {
  const ReaderProgress({
    super.key,
    required this.metrics,
    required this.palette,
    required this.pageLabel,
    required this.progress,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String pageLabel;
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
                pageLabel,
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
