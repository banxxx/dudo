import 'package:dudo/features/bookshelf/presentation/bookshelf_library_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Pencil A2 empty bookshelf design', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('晚上好，Ban'), findsOneWidget);
    expect(find.text('我的书架'), findsOneWidget);
    expect(find.text('书架还是空的'), findsOneWidget);
    expect(
      find.text('把喜欢的作品加入书架后，阅读进度、收藏和缓存都会在这里安静地整理好。'),
      findsOneWidget,
    );
    expect(find.text('去找书'), findsOneWidget);
    expect(find.text('导入本地'), findsOneWidget);
    expect(find.text('可以从这里开始'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
    expect(find.text('去搜索发现书籍'), findsOneWidget);
    expect(find.text('从全站书源中找到想读的作品'), findsOneWidget);
    expect(find.text('导入本地文件'), findsOneWidget);
    expect(find.text('把已有的 txt、epub 放进书架'), findsOneWidget);
    expect(find.text('收藏推荐作品'), findsOneWidget);
    expect(find.text('遇到感兴趣的书，先加入待读清单'), findsOneWidget);

    final greeting = tester.widget<Text>(find.text('晚上好，Ban'));
    expect(greeting.style?.color, DudoColors.textSecondary);
    expect(greeting.style?.fontSize, 13);

    final title = tester.widget<Text>(find.text('我的书架'));
    expect(title.style?.color, DudoColors.textPrimary);
    expect(title.style?.fontSize, 26);

    final emptyCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('书架还是空的'),
            matching: find.byType(Container),
          )
          .last,
    );
    final emptyCardDecoration = emptyCard.decoration! as BoxDecoration;
    expect(emptyCard.constraints?.maxHeight, 270);
    expect(emptyCard.padding, const EdgeInsets.all(18));
    expect(emptyCardDecoration.color, DudoColors.primaryContainer);
    expect(emptyCardDecoration.borderRadius, BorderRadius.circular(26));

    final findBooksButton = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('去找书'),
            matching: find.byType(Container),
          )
          .first,
    );
    final findBooksDecoration = findBooksButton.decoration! as BoxDecoration;
    expect(findBooksButton.constraints?.maxHeight, 36);
    expect(findBooksButton.padding, const EdgeInsets.symmetric(horizontal: 16));
    expect(findBooksDecoration.color, DudoColors.textPrimary);
    expect(findBooksDecoration.borderRadius, BorderRadius.circular(18));

    final importLocalLabel = tester.widget<Text>(find.text('导入本地'));
    expect(importLocalLabel.style?.color, DudoColors.primary);

    final skipAction = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('稍后再说'),
        matching: find.byType(TextButton),
      ),
    );
    expect(
        skipAction.style?.foregroundColor?.resolve({}), DudoColors.secondary);
    expect(
        skipAction.style?.textStyle?.resolve({})?.fontWeight, FontWeight.w400);

    final firstTip = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('去搜索发现书籍'),
            matching: find.byType(Container),
          )
          .first,
    );
    final tipDecoration = firstTip.decoration! as BoxDecoration;
    expect(firstTip.constraints?.maxHeight, 62);
    expect(firstTip.padding, const EdgeInsets.all(10));
    expect(tipDecoration.color, DudoColors.surface);
    expect(tipDecoration.borderRadius, BorderRadius.circular(18));
    expect(tipDecoration.border?.top.color, DudoColors.outlineVariant);

    final firstTipDescription = tester.widget<Text>(
      find.text('从全站书源中找到想读的作品'),
    );
    expect(firstTipDescription.style?.color, DudoColors.secondary);
  });
}
