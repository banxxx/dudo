import 'package:dudo/shared/theme/app_tokens.dart';
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

    expect(
      tester.getTopLeft(find.text('Tall content')).dy,
      lessThan(initialTopLeft.dy),
    );
  });

  testWidgets('centers default content on wide viewports', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            children: [
              SizedBox(height: 120, child: Text('Centered content')),
            ],
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, DudoLayout.tabletPagePadding);

    final frameBox = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.byType(ListView),
        matching: find.byType(ConstrainedBox),
      ),
    );
    final frameLeft = frameBox.localToGlobal(Offset.zero).dx;
    final frameWidth = frameBox.size.width;

    expect(frameWidth, DudoLayout.tabletContentMaxWidth);
    expect(frameLeft, (1000 - DudoLayout.tabletContentMaxWidth) / 2);
  });

  testWidgets('respects explicit maxWidth override', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            maxWidth: 520,
            children: [
              SizedBox(height: 120, child: Text('Narrow content')),
            ],
          ),
        ),
      ),
    );

    final frameBox = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.byType(ListView),
        matching: find.byType(ConstrainedBox),
      ),
    );

    expect(frameBox.size.width, 520);
  });
  testWidgets('can disable width constraint for full-width pages',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            constrainWidth: false,
            children: [
              SizedBox(height: 120, child: Text('Full width content')),
            ],
          ),
        ),
      ),
    );

    final listViewBox = tester.renderObject<RenderBox>(find.byType(ListView));

    expect(listViewBox.size.width, 1000);
  });
}
