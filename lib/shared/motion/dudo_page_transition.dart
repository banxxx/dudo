import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';

/// The app's single route transition.
///
/// A pushed page fades in on the paper with a slight rise instead of sliding
/// in from the screen edge, so every push reads as the same calm motion no
/// matter which platform the app runs on. Popping is quicker than pushing:
/// leaving a page should feel like getting out of the way.
class DudoPageTransition<T> extends CustomTransitionPage<T> {
  const DudoPageTransition({
    required super.key,
    required super.child,
    super.name,
    super.arguments,
  }) : super(
          transitionDuration: AppMotion.page,
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: _buildTransition,
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
