import 'package:dudo/shared/widgets/dudo_page_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not move short content when dragged', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            children: [
              SizedBox(height: 120, child: Text('Short content')),
            ],
          ),
        ),
      ),
    );

    final initialTopLeft = tester.getTopLeft(find.text('Short content'));

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Short content')), initialTopLeft);
  });

  testWidgets('scrolls when content exceeds viewport', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            children: [
              SizedBox(height: 900, child: Text('Tall content')),
            ],
          ),
        ),
      ),
    );

    final initialTopLeft = tester.getTopLeft(find.text('Tall content'));

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Tall content')).dy, lessThan(initialTopLeft.dy));
  });
}
