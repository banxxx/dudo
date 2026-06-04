import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/breakpoints.dart';
import '../l10n/app_localizations.dart';
import 'dudo_bottom_tab_bar.dart';

/// Adaptive home shell with a [NavigationBar] on phones and a
/// [NavigationRail] on wider screens (tablets / landscape).
class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool useRail = Breakpoints.isTabletWidth(width);
    final bool useExtended = Breakpoints.isLargeWidth(width);

    final List<_Dest> destinations = _destinations(context);

    final Widget body = navigationShell;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              extended: useExtended,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: useExtended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const SizedBox(height: 16),
              destinations: <NavigationRailDestination>[
                for (final _Dest d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: _buildFab(context),
      );
    }

    return Scaffold(
      extendBody: true,
      body: body,
      bottomNavigationBar: DudoBottomTabBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: <DudoBottomTabDestination>[
          for (final _Dest d in destinations)
            DudoBottomTabDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget? _buildFab(BuildContext context) {
    return null;
  }

  List<_Dest> _destinations(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return <_Dest>[
      _Dest(
        icon: LucideIcons.house,
        selectedIcon: LucideIcons.house,
        label: l.home,
      ),
      _Dest(
        icon: LucideIcons.library,
        selectedIcon: LucideIcons.library,
        label: l.bookshelf,
      ),
      _Dest(
        icon: LucideIcons.search,
        selectedIcon: LucideIcons.search,
        label: l.search,
      ),
      _Dest(
        icon: LucideIcons.user,
        selectedIcon: LucideIcons.user,
        label: l.profile,
      ),
    ];
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Dest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
