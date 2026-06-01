import 'package:flutter/material.dart';

class DudoPageFrame extends StatelessWidget {
  const DudoPageFrame({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 16),
    this.maxWidth,
    this.bottomSafeArea = true,
    this.eager = false,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double? maxWidth;
  final bool bottomSafeArea;
  final bool eager;

  @override
  Widget build(BuildContext context) {
    const scrollPhysics = ClampingScrollPhysics();

    final Widget content = eager
        ? SingleChildScrollView(
            physics: scrollPhysics,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          )
        : ListView(
            physics: scrollPhysics,
            padding: padding,
            children: children,
          );

    return SafeArea(
      bottom: bottomSafeArea,
      child: maxWidth == null
          ? content
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: content,
              ),
            ),
    );
  }
}
