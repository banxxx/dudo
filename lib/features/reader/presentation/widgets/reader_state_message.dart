import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../layout/reader_page_metrics.dart';

class ReaderStateMessage extends StatelessWidget {
  const ReaderStateMessage({
    super.key,
    required this.metrics,
    required this.palette,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(30),
      top: metrics.y(292),
      width: metrics.s(330),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: DudoTextStyles.serif(
              color: palette.foreground,
              fontSize: metrics.s(24),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.s(10)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: palette.mutedForeground ?? DudoColors.textSecondary,
              fontSize: metrics.s(13),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: metrics.s(18)),
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: metrics.s(38),
                padding: EdgeInsets.symmetric(horizontal: metrics.s(20)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.foreground,
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  actionLabel!,
                  style: DudoTextStyles.sans(
                    color: palette.background,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
