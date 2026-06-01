import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/widgets/dudo_bottom_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  testWidgets('renders paper tab bar and reports selected index',
      (tester) async {
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: DudoBottomTabBar(
            currentIndex: 1,
            onDestinationSelected: (index) => selected = index,
            destinations: const [
              DudoBottomTabDestination(
                icon: Symbols.home_rounded,
                selectedIcon: Symbols.home_rounded,
                label: '首页',
              ),
              DudoBottomTabDestination(
                icon: Symbols.menu_book_rounded,
                selectedIcon: Symbols.menu_book_rounded,
                label: '书架',
              ),
              DudoBottomTabDestination(
                icon: Symbols.search_rounded,
                selectedIcon: Symbols.search_rounded,
                label: '搜索',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);

    final indicator = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('bottom-tab-indicator')),
    );
    final indicatorDecoration = indicator.decoration as BoxDecoration;
    expect(indicatorDecoration.color, DudoColors.textPrimary);
    expect(indicatorDecoration.borderRadius, BorderRadius.circular(24));

    final positioned = tester.widget<AnimatedPositioned>(
      find.ancestor(
        of: find.byKey(const ValueKey('bottom-tab-indicator')),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(positioned.top, 0);
    expect(positioned.bottom, 0);
    expect(positioned.left, greaterThan(0));

    final navigationSurface = tester.widget<Container>(
      find.byWidgetPredicate((widget) {
        if (widget is! Container) {
          return false;
        }
        final decoration = widget.decoration;
        return widget.constraints?.maxHeight == 68 &&
            widget.padding == const EdgeInsets.all(6) &&
            decoration is BoxDecoration &&
            decoration.color == DudoColors.surface.withValues(alpha: 0.95);
      }),
    );
    final navigationDecoration = navigationSurface.decoration! as BoxDecoration;
    expect(navigationSurface.constraints?.maxHeight, 68);
    expect(navigationSurface.padding, const EdgeInsets.all(6));
    expect(
        navigationDecoration.color, DudoColors.surface.withValues(alpha: 0.95));
    expect(navigationDecoration.borderRadius, BorderRadius.circular(30));
    expect(navigationDecoration.border?.top.color, DudoColors.navigationStroke);

    final shadowFinder = find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) {
        return false;
      }
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) {
        return false;
      }
      return decoration.boxShadow?.single.color ==
              DudoColors.navigationShadow &&
          decoration.boxShadow?.single.blurRadius == 30 &&
          decoration.boxShadow?.single.offset == const Offset(0, 12);
    });
    expect(
      find.ancestor(
        of: find.byType(ClipRRect),
        matching: shadowFinder,
      ),
      findsOneWidget,
    );
    expect(navigationDecoration.boxShadow, isNull);

    await tester.tap(find.text('搜索'));
    expect(selected, 2);
  });
}
