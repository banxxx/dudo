import 'package:dudo/shared/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows title, message, and action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: '页面不存在',
            message: '无法打开 /missing',
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('返回书架'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.text('无法打开 /missing'), findsOneWidget);
    expect(find.text('返回书架'), findsOneWidget);

    await tester.tap(find.text('返回书架'));
    expect(tapped, isTrue);
  });
}
