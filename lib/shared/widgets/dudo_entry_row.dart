import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

/// The app's standard two-line list entry.
///
/// Settings, profile tools and switch rows all share this layout so the
/// vertical rhythm stays consistent: a 68px minimum height, a 40px icon tile,
/// and a 3px gap between the title and its description. The row grows if the
/// content ever needs more room instead of clipping.
class DudoEntryRow extends StatelessWidget {
  const DudoEntryRow({
    super.key,
    this.icon,
    this.iconFill,
    this.iconColor,
    required this.title,
    required this.description,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.minHeight = 68,
  });

  final IconData? icon;
  final Color? iconFill;
  final Color? iconColor;
  final String title;
  final String description;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final value = this.value;
    final trailing = this.trailing;

    final content = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconFill ?? DudoColors.surfaceLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor ?? DudoColors.secondary,
                size: 19,
              ),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            Text(
              value,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              color: DudoColors.secondary.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}
