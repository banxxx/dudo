import 'package:flutter/material.dart';

import '../../core/utils/breakpoints.dart';
import '../theme/app_tokens.dart';

class DudoPageFrame extends StatelessWidget {
  const DudoPageFrame({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 16),
    this.maxWidth,
    this.constrainWidth = true,
    this.bottomSafeArea = true,
    this.eager = false,
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double? maxWidth;
  final bool constrainWidth;
  final bool bottomSafeArea;
  final bool eager;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    const scrollPhysics = ClampingScrollPhysics();
    final width = MediaQuery.sizeOf(context).width;
    final effectivePadding = padding == _defaultPadding
        ? _responsivePaddingForWidth(width)
        : padding;
    final effectiveMaxWidth = maxWidth ?? _maxWidthForWidth(width);

    final Widget content = eager
        ? SingleChildScrollView(
            controller: controller,
            physics: scrollPhysics,
            padding: effectivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          )
        : ListView(
            controller: controller,
            physics: scrollPhysics,
            padding: effectivePadding,
            children: children,
          );

    return SafeArea(
      bottom: bottomSafeArea,
      child: constrainWidth
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
                child: content,
              ),
            )
          : content,
    );
  }

  static const EdgeInsets _defaultPadding = EdgeInsets.fromLTRB(20, 8, 20, 16);

  static EdgeInsets _responsivePaddingForWidth(double width) {
    if (width < DudoLayout.compactPhoneWidth) {
      return DudoLayout.compactPhonePagePadding;
    }
    if (Breakpoints.isDesktopWidth(width)) {
      return DudoLayout.desktopPagePadding;
    }
    if (Breakpoints.isTabletWidth(width)) {
      return DudoLayout.tabletPagePadding;
    }
    return DudoLayout.phonePagePadding;
  }

  static double _maxWidthForWidth(double width) {
    if (Breakpoints.isDesktopWidth(width)) {
      return DudoLayout.desktopContentMaxWidth;
    }
    if (Breakpoints.isTabletWidth(width)) {
      return DudoLayout.tabletContentMaxWidth;
    }
    return DudoLayout.phoneContentMaxWidth;
  }
}
