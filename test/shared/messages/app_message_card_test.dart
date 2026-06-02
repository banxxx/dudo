import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_card.dart';
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
}
