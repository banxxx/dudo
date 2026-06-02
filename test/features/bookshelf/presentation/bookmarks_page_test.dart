import 'package:dudo/features/bookshelf/presentation/bookmarks_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Pencil G1 empty bookmarks design', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BookmarksPage(),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('阅读标记'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('暂无书签和高亮'), findsOneWidget);
    expect(find.text('阅读时点击书签或划线，高亮摘录会自动收集在这里。'), findsOneWidget);
    expect(find.text('把喜欢的句子留在这里'), findsOneWidget);
    expect(
      find.text('进入阅读器后，使用底部工具栏添加书签或高亮，之后可以按书籍、章节和时间回看。'),
      findsOneWidget,
    );
    expect(find.text('去阅读'), findsOneWidget);

    final summary = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('暂无书签和高亮'),
            matching: find.byType(Container),
          )
          .last,
    );
    final summaryDecoration = summary.decoration! as BoxDecoration;
    expect(summary.constraints?.maxHeight, 112);
    expect(summary.padding, const EdgeInsets.all(16));
    expect(summaryDecoration.color, DudoColors.primaryContainer);
    expect(summaryDecoration.borderRadius, BorderRadius.circular(24));

    final emptyState = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('把喜欢的句子留在这里'),
            matching: find.byType(Container),
          )
          .last,
    );
    final emptyDecoration = emptyState.decoration! as BoxDecoration;
    expect(emptyState.constraints?.maxHeight, 314);
    expect(emptyState.padding, const EdgeInsets.all(22));
    expect(emptyDecoration.color, DudoColors.surface);
    expect(emptyDecoration.borderRadius, BorderRadius.circular(26));
    expect(emptyDecoration.border?.top.color, DudoColors.outlineVariant);
  });
}
