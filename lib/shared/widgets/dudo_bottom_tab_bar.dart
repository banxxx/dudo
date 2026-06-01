import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';

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
        height: 78 + (bottomPadding > 0 ? bottomPadding : 20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            bottomPadding > 0 ? bottomPadding : 20,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
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
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DudoColors.darkSurface
                        : DudoColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark
                          ? DudoColors.darkNavigationStroke
                          : DudoColors.navigationStroke,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gapTotal = 6 * (destinations.length - 1);
                      final itemWidth = (constraints.maxWidth - gapTotal) /
                          destinations.length;
                      final indicatorLeft = currentIndex * (itemWidth + 6);

                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: AppMotion.medium,
                            curve: AppMotion.emphasized,
                            left: indicatorLeft,
                            top: 0,
                            bottom: 0,
                            width: itemWidth,
                            child: DecoratedBox(
                              key: const ValueKey('bottom-tab-indicator'),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DudoColors.darkNavigationActive
                                    : DudoColors.textPrimary,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var index = 0;
                                  index < destinations.length;
                                  index++) ...[
                                Expanded(
                                  child: _DudoBottomTabItem(
                                    destination: destinations[index],
                                    selected: index == currentIndex,
                                    selectedForeground: isDark
                                        ? DudoColors
                                            .darkNavigationActiveForeground
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
                        ],
                      );
                    },
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
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.onTap,
  });

  final DudoBottomTabDestination destination;
  final bool selected;
  final Color selectedForeground;
  final Color unselectedForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          builder: (context, value, child) {
            final foreground = Color.lerp(
              unselectedForeground,
              selectedForeground,
              value,
            )!;

            return DefaultTextStyle(
              style: DudoTextStyles.sans(
                color: foreground,
                fontSize: 10,
                fontWeight: FontWeight.lerp(
                  FontWeight.w400,
                  FontWeight.w600,
                  value,
                ),
              ),
              child: IconTheme(
                data: IconThemeData(color: foreground, size: 20),
                child: child!,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? destination.selectedIcon : destination.icon),
              const SizedBox(height: 4),
              Text(destination.label),
            ],
          ),
        ),
      ),
    );
  }
}
