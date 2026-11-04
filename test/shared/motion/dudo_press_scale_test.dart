import 'package:dudo/shared/motion/dudo_press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('eases in while pressed and returns on release', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: DudoPressScale(
            child: SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );

    final scale = find.byType(AnimatedScale);
    expect(tester.widget<AnimatedScale>(scale).scale, 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox)),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(scale).scale, 0.985);

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets('does not react when the platform asks for reduced motion',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: DudoPressScale(
              child: SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox)),
    );
    await tester.pump();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
  });
}
