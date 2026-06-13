import 'dart:async';

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
    expect(find.text('搜索结果'), findsNothing);
    expect(find.text('正在搜索在线书源'), findsNothing);
    expect(find.text('刘慈欣 · 测试书源'), findsNothing);

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

  testWidgets('shows loading state while online search is pending',
      (tester) async {
    final completer = Completer<OnlineSearchResponse>();

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 1),
        onlineSearchProvider('三体').overrideWith((ref) => completer.future),
      ],
    );

    await _enterQuery(tester, '三体');

    expect(find.text('正在搜索在线书源'), findsOneWidget);
    expect(find.text('正在读取启用书源并执行规则，请稍候。'), findsOneWidget);
    expect(find.text('搜索结果'), findsNothing);

    completer.complete(
      const OnlineSearchResponse(
        searchedSourceCount: 0,
        availableSourceCount: 0,
        failures: [],
        results: [],
      ),
    );
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
        OnlineSearchBookResult(
          sourceId: 'https://source.example',
          sourceName: '测试书源',
          name: '三体Ⅱ',
          author: '',
          intro: '',
          bookUrl: 'https://source.example/book/2',
        ),
      ],
    );

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 1),
        onlineSearchProvider('三体').overrideWith((ref) async => response),
      ],
    );

    await _enterQuery(tester, '三体');
    await tester.pump();

    expect(find.text('三体'), findsWidgets);
    expect(find.text('最近搜索'), findsOneWidget);
    expect(find.text('长夜余火'), findsOneWidget);
    expect(find.text('刘慈欣'), findsWidgets);
    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('2 条'), findsOneWidget);
    expect(find.text('刘慈欣 · 测试书源'), findsOneWidget);
    expect(find.text('作者未知 · 测试书源'), findsOneWidget);
    expect(find.text('文明在宇宙尺度中的回响，从一次偶然监听开始。'), findsOneWidget);
    expect(find.text('https://source.example/book/2'), findsOneWidget);
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

  testWidgets('shows empty result state when enabled sources return no matches',
      (tester) async {
    const response = OnlineSearchResponse(
      searchedSourceCount: 1,
      availableSourceCount: 1,
      failures: [],
      results: [],
    );

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 1),
        onlineSearchProvider('不存在的书').overrideWith((ref) async => response),
      ],
    );

    await _enterQuery(tester, '不存在的书');
    await tester.pump();

    expect(find.text('没有找到“不存在的书”'), findsOneWidget);
    expect(find.text('已搜索 1 个启用书源，没有匹配结果。'), findsOneWidget);
    expect(find.text('搜索结果'), findsNothing);
  });

  testWidgets('shows provider error state when search provider throws',
      (tester) async {
    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 1),
        onlineSearchProvider('三体').overrideWith(
          (ref) async => throw StateError('network exploded'),
        ),
      ],
    );

    await _enterQuery(tester, '三体');
    await tester.pump();

    expect(find.text('搜索失败'), findsOneWidget);
    expect(find.textContaining('network exploded'), findsOneWidget);
  });

  testWidgets('shows no enabled source prompt when nothing can be searched',
      (tester) async {
    const response = OnlineSearchResponse(
      searchedSourceCount: 0,
      availableSourceCount: 0,
      failures: [],
      results: [],
    );

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 0),
        onlineSearchProvider('三体').overrideWith((ref) async => response),
      ],
    );

    await _enterQuery(tester, '三体');
    await tester.pump();

    expect(find.text('暂无启用书源'), findsOneWidget);
    expect(find.text('请先在书源管理中导入并启用 Legado 书源。'), findsOneWidget);
  });

  testWidgets('shows all-failed state when every searched source fails',
      (tester) async {
    const response = OnlineSearchResponse(
      searchedSourceCount: 2,
      availableSourceCount: 2,
      failures: [
        OnlineSearchFailure(
          sourceId: 'source-a',
          sourceName: '失败书源 A',
          message: 'fail A',
        ),
        OnlineSearchFailure(
          sourceId: 'source-b',
          sourceName: '失败书源 B',
          message: 'fail B',
        ),
      ],
      results: [],
    );

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 2),
        onlineSearchProvider('三体').overrideWith((ref) async => response),
      ],
    );

    await _enterQuery(tester, '三体');
    await tester.pump();

    expect(find.text('在线书源暂不可用'), findsOneWidget);
    expect(find.text('已尝试 2 个书源，但规则或网络请求全部失败。'), findsOneWidget);
  });

  testWidgets('keeps results visible when some sources fail', (tester) async {
    const response = OnlineSearchResponse(
      searchedSourceCount: 2,
      availableSourceCount: 2,
      failures: [
        OnlineSearchFailure(
          sourceId: 'failing-source',
          sourceName: '失败书源',
          message: 'network failed',
        ),
      ],
      results: [
        OnlineSearchBookResult(
          sourceId: 'good-source',
          sourceName: '可用书源',
          name: '三体',
          author: '刘慈欣',
          intro: '文明在宇宙尺度中的回响。',
        ),
      ],
    );

    await _pumpSearchPage(
      tester,
      overrides: [
        enabledSourceCountProvider.overrideWith((ref) async => 2),
        onlineSearchProvider('三体').overrideWith((ref) async => response),
      ],
    );

    await _enterQuery(tester, '三体');
    await tester.pump();

    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('三体'), findsWidgets);
    expect(find.text('刘慈欣 · 可用书源'), findsOneWidget);
    expect(find.text('1 个书源搜索失败，已展示其余可用结果。'), findsOneWidget);
  });
}

Future<void> _pumpSearchPage(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: SearchPage(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _enterQuery(WidgetTester tester, String query) async {
  await tester.tap(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), query);
  await tester.pump();
}
