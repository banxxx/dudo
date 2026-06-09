import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_fonts.dart';
import '../../layout/reader_page_metrics.dart';

class ReaderChapterProgressLine extends StatelessWidget {
  const ReaderChapterProgressLine({
    super.key,
    required this.metrics,
    required this.pageLabel,
    required this.progress,
    required this.color,
  });

  final ReaderPageMetrics metrics;
  final String pageLabel;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyle = DudoTextStyles.sans(
      color: color,
      fontSize: metrics.s(12),
      fontWeight: FontWeight.w600,
    );
    final numericStyle = DudoTextStyles.numeric(
      color: color,
      fontSize: metrics.s(12),
      fontWeight: FontWeight.w600,
    );

    return Row(
      key: const ValueKey('reader-chapter-progress-line'),
      children: [
        Expanded(
          child: Text(
            pageLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        SizedBox(width: metrics.s(16)),
        Text(
          '${(progress * 100).round()}%',
          key: const ValueKey('reader-progress-percent'),
          style: numericStyle,
        ),
      ],
    );
  }
}
