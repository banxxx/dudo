import 'package:dudo/features/search/application/search_providers.dart';
import 'package:dudo/features/search/domain/online_search_models.dart';
import 'package:dudo/features/search/presentation/search_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the initial search design', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enabledSourceCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(
          home: SearchPage(),
        ),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('探索书源与作品'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('搜索书名、作者、关键词'), findsOneWidget);
    expect(find.text('常用书源'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('本地书架'), findsOneWidget);
    expect(find.text('优先缓存'), findsOneWidget);
    expect(find.text('网络书源'), findsOneWidget);
    expect(find.text('0 个启用'), findsOneWidget);
    expect(find.text('输入关键词开始找书'), findsOneWidget);
    expect(find.text('可以搜索书名、作者，也可以从搜索来源中选择本地或在线书库。'), findsOneWidget);

    final eyebrow = tester.widget<Text>(find.text('探索书源与作品'));
    expect(eyebrow.style?.color, DudoColors.textSecondary);
    expect(eyebrow.style?.fontSize, 13);

    final title = tester.widget<Text>(find.text('搜索'));
    expect(title.style?.color, DudoColors.textPrimary);
    expect(title.style?.fontSize, 26);

    final searchField = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('搜索书名、作者、关键词'),
            matching: find.byType(Container),
          )
          .first,
    );
    final searchDecoration = searchField.decoration! as BoxDecoration;
    expect(searchField.constraints?.maxHeight, 56);
    expect(searchField.padding, const EdgeInsets.symmetric(horizontal: 16));
    expect(searchDecoration.color, DudoColors.surface);
    expect(searchDecoration.borderRadius, BorderRadius.circular(22));
    expect(searchDecoration.border?.top.color, DudoColors.outline);

    final placeholder = tester.widget<Text>(find.text('搜索书名、作者、关键词'));
    expect(placeholder.style?.color, DudoColors.secondary);
    expect(placeholder.style?.fontSize, 14);

    final localSource = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('本地书架'),
            matching: find.byType(Container),
          )
          .first,
    );
    final localSourceDecoration = localSource.decoration! as BoxDecoration;
    expect(localSource.constraints?.maxHeight, 76);
    expect(localSource.padding, const EdgeInsets.all(14));
    expect(localSourceDecoration.color, DudoColors.primaryContainer);
    expect(localSourceDecoration.borderRadius, BorderRadius.circular(18));
    expect(
      localSourceDecoration.border?.top.color,
      DudoColors.primaryContainerStrong,
    );

    final emptyCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('输入关键词开始找书'),
            matching: find.byType(Container),
          )
          .last,
    );
    final emptyCardDecoration = emptyCard.decoration! as BoxDecoration;
    expect(emptyCard.constraints?.maxHeight, 214);
    expect(emptyCard.padding, const EdgeInsets.all(18));
    expect(emptyCardDecoration.color, DudoColors.primaryContainer);
    expect(emptyCardDecoration.borderRadius, BorderRadius.circular(24));

    final emptyTitle = tester.widget<Text>(find.text('输入关键词开始找书'));
    expect(emptyTitle.style?.color, DudoColors.textPrimary);
    expect(emptyTitle.style?.fontSize, 22);
    expect(emptyTitle.style?.fontWeight, FontWeight.w700);

    final emptyText =
        tester.widget<Text>(find.text('可以搜索书名、作者，也可以从搜索来源中选择本地或在线书库。'));
    expect(emptyText.style?.color, DudoColors.textSecondary);
    expect(emptyText.style?.fontSize, 13);
    expect(emptyText.style?.height, 1.45);
  });

  testWidgets('renders real online search results from provider state',
      (tester) async {
    const response = OnlineSearchResponse(
      searchedSourceCount: 1,
      availableSourceCount: 1,
      failures: [],
      results: [
        OnlineSearchBookResult(
          sourceId: 'https://source.example',
          sourceName: '测试书源',
          name: '三体',
          author: '刘慈欣',
          intro: '文明在宇宙尺度中的回响，从一次偶然监听开始。',
          bookUrl: 'https://source.example/book/1',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enabledSourceCountProvider.overrideWith((ref) async => 1),
          onlineSearchProvider('三体').overrideWith((ref) async => response),
        ],
        child: const MaterialApp(
          home: SearchPage(),
        ),
      ),
    );

    await tester.tap(find.text('搜索书名、作者、关键词'));
    await tester.enterText(find.byType(EditableText), '三体');
    await tester.pump();
    await tester.pump();

    expect(find.text('三体'), findsWidgets);
    expect(find.text('最近搜索'), findsOneWidget);
    expect(find.text('长夜余火'), findsOneWidget);
    expect(find.text('刘慈欣'), findsWidgets);
    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
    expect(find.text('刘慈欣 · 测试书源'), findsOneWidget);
    expect(find.text('文明在宇宙尺度中的回响，从一次偶然监听开始。'), findsOneWidget);
    expect(find.text('输入关键词开始找书'), findsNothing);

    final searchField = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('三体').first,
            matching: find.byType(Container),
          )
          .first,
    );
    final searchDecoration = searchField.decoration! as BoxDecoration;
    expect(searchField.constraints?.maxHeight, 56);
    expect(searchDecoration.border?.top.color, DudoColors.primary);

    final query = tester.widget<Text>(find.text('三体').first);
    expect(query.style?.color, DudoColors.textPrimary);
    expect(query.style?.fontSize, 15);
    expect(query.style?.fontWeight, FontWeight.w500);

    final recentTitle = tester.widget<Text>(find.text('最近搜索'));
    expect(recentTitle.style?.color, DudoColors.textPrimary);
    expect(recentTitle.style?.fontSize, 18);
    expect(recentTitle.style?.fontWeight, FontWeight.w600);

    final chip = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('长夜余火'),
            matching: find.byType(Container),
          )
          .first,
    );
    final chipDecoration = chip.decoration! as BoxDecoration;
    expect(chip.constraints?.maxHeight, 32);
    expect(chip.padding, const EdgeInsets.symmetric(horizontal: 12));
    expect(chipDecoration.color, DudoColors.surface);
    expect(chipDecoration.borderRadius, AppRadius.full);
    expect(chipDecoration.border?.top.color, DudoColors.outlineVariant);

    final firstResult = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('刘慈欣 · 测试书源'),
            matching: find.byType(Container),
          )
          .last,
    );
    final resultDecoration = firstResult.decoration! as BoxDecoration;
    expect(firstResult.constraints?.maxHeight, 88);
    expect(firstResult.padding, const EdgeInsets.all(10));
    expect(resultDecoration.color, DudoColors.surface);
    expect(resultDecoration.borderRadius, BorderRadius.circular(18));
    expect(resultDecoration.border?.top.color, DudoColors.outlineVariant);

    final firstResultTitle = tester.widget<Text>(find.text('三体').last);
    expect(firstResultTitle.style?.color, DudoColors.textPrimary);
    expect(firstResultTitle.style?.fontSize, 15);
    expect(firstResultTitle.style?.fontWeight, FontWeight.w600);

    final firstResultMeta = tester.widget<Text>(find.text('刘慈欣 · 测试书源'));
    expect(firstResultMeta.style?.color, DudoColors.secondary);
    expect(firstResultMeta.style?.fontSize, 12);

    final firstResultIntro =
        tester.widget<Text>(find.text('文明在宇宙尺度中的回响，从一次偶然监听开始。'));
    expect(firstResultIntro.style?.color, DudoColors.textSecondary);
    expect(firstResultIntro.style?.fontSize, 12);
    expect(firstResultIntro.style?.height, 1.25);
  });
}
