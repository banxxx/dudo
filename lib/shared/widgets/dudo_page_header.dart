import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';

class DudoCircleIconButton extends StatelessWidget {
  const DudoCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize,
    this.backgroundColor = DudoColors.surface,
    this.iconColor = DudoColors.secondary,
    this.borderColor = DudoColors.outline,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double? iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize ?? (icon == LucideIcons.chevronLeft ? 22 : 19),
          ),
        ),
      ),
    );
  }
}

class DudoPageHeader extends StatelessWidget {
  const DudoPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.trailing,
    this.titleWidget,
    this.height = 54,
    this.titleAlignment = Alignment.center,
    this.reserveLeadingSpace = true,
    this.reserveTrailingSpace = true,
  });

  final String title;
  final String? eyebrow;
  final Widget? leading;
  final Widget? trailing;
  final Widget? titleWidget;
  final double height;
  final Alignment titleAlignment;
  final bool reserveLeadingSpace;
  final bool reserveTrailingSpace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leading != null)
            leading!
          else if (reserveLeadingSpace)
            SizedBox(width: height),
          Expanded(
            child: Align(
              alignment: titleAlignment,
              child: titleWidget ??
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.serif(
                          color: DudoColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (reserveTrailingSpace)
            SizedBox(width: height),
        ],
      ),
    );
  }
}
