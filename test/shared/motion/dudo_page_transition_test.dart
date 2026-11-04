import 'package:dudo/shared/motion/dudo_page_transition.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DudoPageTransition<void> page() => const DudoPageTransition<void>(
        key: ValueKey('page'),
        child: Text('page'),
      );

  test('uses the house page timing', () {
    final transition = page();
    expect(transition.transitionDuration, AppMotion.page);
    expect(transition.reverseTransitionDuration, AppMotion.fast);
  });

  testWidgets('fades and lifts the incoming page', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    final built = page().transitionsBuilder(
      context,
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0),
      const Text('page'),
    );

    final fade = built as FadeTransition;
    // Halfway through the fade the standard curve is already well past half.
    expect(fade.opacity.value, greaterThan(0.5));
    expect(fade.child, isA<SlideTransition>());
  });

  testWidgets('skips the transition when motion is reduced', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final built = page().transitionsBuilder(
      context,
      const AlwaysStoppedAnimation(1),
      const AlwaysStoppedAnimation(0),
      const Text('page'),
    );

    expect(built, isA<Text>());
  });
}
