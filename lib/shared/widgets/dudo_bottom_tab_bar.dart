import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_tokens.dart';

class DudoBottomTabBar extends StatelessWidget {
  const DudoBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DudoBottomTabDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: isDark ? DudoColors.darkBackground : DudoColors.paperBackground,
      child: SizedBox(
        height: 98,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            bottomPadding > 0 ? bottomPadding : 20,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.full,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? DudoColors.darkNavigationShadow
                      : DudoColors.navigationShadow,
                  offset: const Offset(0, 12),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.full,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DudoColors.darkSurface
                        : DudoColors.surface.withValues(alpha: 0.95),
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: isDark
                          ? DudoColors.darkNavigationStroke
                          : DudoColors.navigationStroke,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var index = 0;
                          index < destinations.length;
                          index++) ...[
                        Expanded(
                          child: _DudoBottomTabItem(
                            destination: destinations[index],
                            selected: index == currentIndex,
                            selectedBackground: isDark
                                ? DudoColors.darkNavigationActive
                                : DudoColors.textPrimary,
                            selectedForeground: isDark
                                ? DudoColors.darkNavigationActiveForeground
                                : DudoColors.surfaceHigh,
                            unselectedForeground: isDark
                                ? DudoColors.darkNavigationInactive
                                : DudoColors.secondary,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                        if (index != destinations.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DudoBottomTabDestination {
  const DudoBottomTabDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _DudoBottomTabItem extends StatelessWidget {
  const _DudoBottomTabItem({
    required this.destination,
    required this.selected,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.onTap,
  });

  final DudoBottomTabDestination destination;
  final bool selected;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color unselectedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? selectedForeground : unselectedForeground;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xLarge,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.emphasized,
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: AppRadius.xLarge,
            ),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 20),
              child: DefaultTextStyle(
                style: GoogleFonts.notoSansSc(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        selected ? destination.selectedIcon : destination.icon),
                    const SizedBox(height: 4),
                    Text(destination.label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
