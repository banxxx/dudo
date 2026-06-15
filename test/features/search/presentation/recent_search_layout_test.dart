import 'package:dudo/features/search/application/search_providers.dart';
import 'package:dudo/features/search/data/recent_search_repository.dart';
import 'package:dudo/features/search/presentation/search_page.dart';
import 'package:dudo/shared/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'recent search chips keep four Chinese characters before ellipsis',
      (tester) async {
    const shortKeyword =
        '\u957f\u591c\u4f59\u706b\u6700\u8fd1\u641c\u7d22\u5173\u952e\u8bcd';
    const longKeyword =
        '\u975e\u5e38\u975e\u5e38\u975e\u5e38\u957f\u7684\u641c\u7d22\u5173\u952e\u8bcd';
    const hiddenOldKeyword = '\u5218\u6148\u6b23';

    await tester.binding.setSurfaceSize(const Size(340, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enabledSourceCountProvider
              .overrideWith((ref) => const AsyncValue.data(0)),
          recentSearchRepositoryProvider
              .overrideWithValue(_NoopRecentSearchRepository()),
          recentSearchesProvider.overrideWith(
            (ref) => Stream.value(
              const [shortKeyword, longKeyword, hiddenOldKeyword],
            ),
          ),
        ],
        child: const MaterialApp(home: SearchPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'query');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(find.text('\u6700\u8fd1\u641c\u7d22'), findsOneWidget);
    expect(find.text(shortKeyword), findsOneWidget);
    expect(find.text(longKeyword), findsOneWidget);
    expect(find.text(hiddenOldKeyword), findsNothing);

    final shortChip = _chipFinder(shortKeyword);
    final longChip = _chipFinder(longKeyword);
    expect(tester.getSize(shortChip).width, lessThanOrEqualTo(148));
    expect(tester.getSize(longChip).width, greaterThanOrEqualTo(72));
    expect(tester.getSize(longChip).width, lessThan(148));

    final longText = tester.widget<Text>(find.text(longKeyword));
    expect(longText.maxLines, 1);
    expect(longText.overflow, TextOverflow.ellipsis);

    final horizontalLists = tester
        .widgetList<ListView>(find.byType(ListView))
        .where((listView) => listView.scrollDirection == Axis.horizontal);
    expect(horizontalLists, isEmpty);
  });

  test('recent search keeps short Chinese chip after compressed long chip', () {
    const longKeyword =
        '\u975e\u5e38\u975e\u5e38\u975e\u5e38\u957f\u7684\u641c\u7d22\u5173\u952e\u8bcd';
    const shortKeyword = '\u4e09\u4f53';

    final visible = debugVisibleRecentSearchChips(
      searches: const [longKeyword, shortKeyword],
      maxWidth: 204,
      chipMaxWidth: 148,
      textStyle: DudoTextStyles.sans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      textDirection: TextDirection.ltr,
    );

    expect(visible.map((chip) => chip.label), [longKeyword, shortKeyword]);
    expect(visible.first.width, lessThan(148));
    expect(visible.last.width, greaterThan(44));
  });
}

Finder _chipFinder(String keyword) {
  return find
      .ancestor(
        of: find.text(keyword),
        matching: find.byType(Container),
      )
      .first;
}

class _NoopRecentSearchRepository implements RecentSearchRepository {
  @override
  Future<void> addSearch(String keyword) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<List<String>> readRecentSearches() async => const [];

  @override
  Stream<List<String>> watchRecentSearches() => Stream.value(const []);
}
