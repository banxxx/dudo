import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_fonts.dart';
import '../../layout/reader_page_metrics.dart';

class ReaderTimeBatteryLine extends StatelessWidget {
  const ReaderTimeBatteryLine({
    super.key,
    required this.metrics,
    required this.timeLabel,
    required this.batteryLabel,
    required this.batteryIcon,
    required this.color,
  });

  final ReaderPageMetrics metrics;
  final String timeLabel;
  final String batteryLabel;
  final IconData batteryIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final numericStyle = DudoTextStyles.numeric(
      color: color,
      fontSize: metrics.s(12),
      fontWeight: FontWeight.w600,
    );

    return Row(
      key: const ValueKey('reader-time-battery-line'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(timeLabel, style: numericStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              batteryIcon,
              size: metrics.s(15),
              color: color,
            ),
            SizedBox(width: metrics.s(4)),
            Text(batteryLabel, style: numericStyle),
          ],
        ),
      ],
    );
  }
}
