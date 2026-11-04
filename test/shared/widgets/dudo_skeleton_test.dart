import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/widgets/dudo_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders placeholder blocks on the paper surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoSkeleton(
            child: Column(
              children: [
                DudoSkeletonBox(height: 40),
                DudoSkeletonLine(widthFactor: 0.5),
                DudoSkeletonBox(width: 24, height: 24, shape: BoxShape.circle),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DudoSkeletonBox), findsNWidgets(3));
    expect(find.byType(DudoSkeletonLine), findsOneWidget);

    final circle = tester.widget<Container>(
      find.descendant(
        of: find.byType(DudoSkeletonBox).last,
        matching: find.byType(Container),
      ),
    );
    final decoration = circle.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, DudoColors.surfaceLow);
  });

  testWidgets('card keeps the surface frame and skeleton contents', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoSkeletonCard(
            height: 88,
            child: Row(
              children: [DudoSkeletonBox(width: 48, height: 68)],
            ),
          ),
        ),
      ),
    );

    final card = tester.widget<Container>(
      find.descendant(
        of: find.byType(DudoSkeletonCard),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(card.constraints?.maxHeight, 88);
    expect(decoration.color, DudoColors.surface);
    expect(decoration.borderRadius, BorderRadius.circular(22));
    expect(decoration.border?.top.color, DudoColors.outlineVariant);
    expect(find.byType(DudoSkeleton), findsOneWidget);
  });

  testWidgets('list tile mirrors the settings row rhythm', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DudoSkeletonListTile(trailingWidth: 44),
        ),
      ),
    );

    final leading = tester.widget<Container>(
      find.descendant(
        of: find.byType(DudoSkeletonBox).first,
        matching: find.byType(Container),
      ),
    );
    expect(leading.constraints?.maxHeight, 40);
    expect(leading.constraints?.maxWidth, 40);
    expect(find.byType(DudoSkeletonBox), findsNWidgets(4));
  });

  testWidgets('reduced motion still shows the blocks without a ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DudoSkeleton(child: DudoSkeletonBox(height: 20)),
        ),
      ),
    );

    // The sweep is off, so settling finishes instead of running forever.
    await tester.pumpAndSettle();
    expect(find.byType(DudoSkeletonBox), findsOneWidget);
    expect(AppMotion.reduced(tester.element(find.byType(DudoSkeleton))), isTrue);
  });
}
