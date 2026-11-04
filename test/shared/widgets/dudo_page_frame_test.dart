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

  testWidgets('keeps the header pinned while the content scrolls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            header: SizedBox(
              key: ValueKey('pinned-header-box'),
              height: 56,
              child: Text('Pinned header', key: ValueKey('pinned-header')),
            ),
            children: [
              SizedBox(height: 900, child: Text('Tall content')),
            ],
          ),
        ),
      ),
    );

    final headerTop = tester.getTopLeft(find.text('Pinned header'));
    final contentTop = tester.getTopLeft(find.text('Tall content'));
    final listTop = tester.getTopLeft(find.byType(ListView)).dy;

    expect(
      tester.getBottomLeft(find.text('Pinned header')).dy,
      lessThanOrEqualTo(listTop),
    );
    // The scroll viewport starts a gap below the header, so scrolled content
    // is clipped under a strip of paper instead of against the header.
    expect(
      listTop -
          tester.getBottomLeft(find.byKey(const ValueKey('pinned-header-box')))
              .dy,
      DudoLayout.pinnedHeaderGap,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Pinned header')), headerTop);
    expect(
      tester.getTopLeft(find.text('Tall content')).dy,
      lessThan(contentTop.dy),
    );
  });

  testWidgets('keeps a header pinned with eager content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoPageFrame(
            eager: true,
            header: SizedBox(
              height: 56,
              child: Text('Eager header', key: ValueKey('eager-header')),
            ),
            children: [
              SizedBox(height: 900, child: Text('Eager content')),
            ],
          ),
        ),
      ),
    );

    final headerTop = tester.getTopLeft(find.text('Eager header'));
    final contentTop = tester.getTopLeft(find.text('Eager content'));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Eager header')), headerTop);
    expect(
      tester.getTopLeft(find.text('Eager content')).dy,
      lessThan(contentTop.dy),
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
