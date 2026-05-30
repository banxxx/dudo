import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/router/app_router.dart';
import '../l10n/app_localizations.dart';

/// Adaptive home shell with a [NavigationBar] on phones and a
/// [NavigationRail] on wider screens (tablets / landscape).
class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const double _breakpointMedium = 600.0;
  static const double _breakpointLarge = 840.0;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool useRail = width >= _breakpointMedium;
    final bool useExtended = width >= _breakpointLarge;

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
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: <NavigationDestination>[
          for (final _Dest d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
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
    // FAB only on the bookshelf branch.
    if (navigationShell.currentIndex != 0) return null;
    return FloatingActionButton.extended(
      onPressed: () => context.goNamed(AppRoutes.searchName),
      icon: const Icon(Symbols.add_rounded),
      label: Text(AppLocalizations.of(context).addBook),
    );
  }

  List<_Dest> _destinations(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return <_Dest>[
      _Dest(
        icon: Symbols.menu_book_rounded,
        selectedIcon: Symbols.menu_book_rounded,
        label: l.bookshelf,
      ),
      _Dest(
        icon: Symbols.search_rounded,
        selectedIcon: Symbols.search_rounded,
        label: l.search,
      ),
      _Dest(
        icon: Symbols.travel_explore_rounded,
        selectedIcon: Symbols.travel_explore_rounded,
        label: l.sources,
      ),
      _Dest(
        icon: Symbols.person_rounded,
        selectedIcon: Symbols.person_rounded,
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
