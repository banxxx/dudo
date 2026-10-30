import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_card.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/theme/dudo_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders compact message card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMessageCard(
            request: AppMessageRequest(
              title: '保存成功',
              description: '内容已保存',
              kind: AppMessageKind.success,
            ),
          ),
        ),
      ),
    );

    expect(find.text('保存成功'), findsOneWidget);
    expect(find.text('内容已保存'), findsOneWidget);
  });

  testWidgets('aligns compact action to the right edge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMessageCard(
            request: AppMessageRequest(
              title: '导入成功',
              description: '《三体》已加入书架',
              kind: AppMessageKind.success,
              actionLabel: '查看',
              onAction: () {},
            ),
          ),
        ),
      ),
    );

    final card = find.byWidgetPredicate(
      (widget) =>
          widget is ConstrainedBox && widget.constraints.maxWidth == 350,
    );
    final cardBox = tester.renderObject<RenderBox>(card);
    final actionBox = tester.renderObject<RenderBox>(find.text('查看'));
    final cardRight =
        cardBox.localToGlobal(Offset.zero).dx + cardBox.size.width;
    final actionRight =
        actionBox.localToGlobal(Offset.zero).dx + actionBox.size.width;

    expect(cardBox.size.width, 350);
    expect(cardRight - actionRight, lessThan(30));
  });

  testWidgets('renders dialog message card and close button', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMessageCard(
            request: const AppMessageRequest(
              title: '导入失败',
              description: '请检查文件格式',
              kind: AppMessageKind.error,
              position: AppMessagePosition.center,
              size: AppMessageSize.dialog,
            ),
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('导入失败'), findsOneWidget);
    expect(find.text('请检查文件格式'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    expect(closed, isTrue);
  });

  testWidgets('renders snack message card with compact snackbar dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMessageCard(
            request: AppMessageRequest(
              title: '已启用「霞鹜文楷」',
              kind: AppMessageKind.success,
              visualStyle: AppMessageVisualStyle.snack,
              dismissible: false,
            ),
          ),
        ),
      ),
    );

    final card = find.byWidgetPredicate(
      (widget) =>
          widget is ConstrainedBox && widget.constraints.maxWidth == 520,
    );
    final cardBox = tester.renderObject<RenderBox>(card);
    final scaffoldBox = tester.renderObject<RenderBox>(find.byType(Scaffold));
    final cardLeft = cardBox.localToGlobal(Offset.zero).dx;
    final expectedLeft = (scaffoldBox.size.width - 520) / 2;

    expect(find.text('已启用「霞鹜文楷」'), findsOneWidget);
    expect(cardBox.size.width, 520);
    expect(cardBox.size.height, lessThan(70));
    expect(cardLeft, closeTo(expectedLeft, 0.1));
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('paper message keeps ink text on its cream card in dark mode', (
    tester,
  ) async {
    DudoColors.use(DudoPalette.dark(DudoAccent.pine));
    addTearDown(() => DudoColors.use(DudoPalette.light(DudoAccent.pine)));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMessageCard(
            request: AppMessageRequest(
              title: '已清理封面缓存',
              description: '缓存可以随时重新生成',
              kind: AppMessageKind.success,
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('已清理封面缓存'));
    expect(title.style?.color, const Color(0xFF25251F));

    final description = tester.widget<Text>(find.text('缓存可以随时重新生成'));
    expect(description.style?.color, const Color(0xFF6F6B61));
  });
}
