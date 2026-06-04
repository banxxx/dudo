import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_tokens.dart';

class ReadingGoalCircleButton extends StatelessWidget {
  const ReadingGoalCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outline),
          ),
          child: Icon(
            icon,
            color: DudoColors.secondary,
            size: icon == LucideIcons.chevronLeft ? 22 : 19,
          ),
        ),
      ),
    );
  }
}
