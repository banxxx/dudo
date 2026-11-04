import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_tokens.dart';

/// The paper skeleton shown while a page's own content is still loading.
///
/// Wrap only the placeholder blocks, never the card that holds them, so the
/// highlight sweeps the content shape while the card stays still. Reduced
/// motion keeps the blocks and drops the sweep.
class DudoSkeleton extends StatelessWidget {
  const DudoSkeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DudoColors.surfaceLow,
      highlightColor: DudoColors.surface,
      period: const Duration(milliseconds: 1500),
      enabled: !AppMotion.reduced(context),
      child: child,
    );
  }
}

/// One placeholder block. Defaults to full width so it can sit directly in a
/// [Column]; give it a width inside a [Row] or wrap it in [Expanded].
class DudoSkeletonBox extends StatelessWidget {
  const DudoSkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A text-shaped placeholder line.
class DudoSkeletonLine extends StatelessWidget {
  const DudoSkeletonLine({
    super.key,
    this.widthFactor = 1,
    this.height = 12,
    this.radius = 6,
  });

  final double widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: DudoSkeletonBox(height: height, radius: radius),
    );
  }
}

/// A surface card whose contents are placeholder blocks.
class DudoSkeletonCard extends StatelessWidget {
  const DudoSkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: DudoSkeleton(child: child),
    );
  }
}

/// The two-line row used by settings lists, source lists and cached books.
class DudoSkeletonListTile extends StatelessWidget {
  const DudoSkeletonListTile({
    super.key,
    this.leadingSize = 40,
    this.leadingRadius = 20,
    this.titleWidthFactor = 0.5,
    this.subtitleWidthFactor = 0.8,
    this.trailingWidth = 0,
    this.minHeight = 68,
  });

  final double leadingSize;
  final double leadingRadius;
  final double titleWidthFactor;
  final double subtitleWidthFactor;
  final double trailingWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return DudoSkeletonCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight - 24),
        child: Row(
          children: [
            DudoSkeletonBox(
              width: leadingSize,
              height: leadingSize,
              radius: leadingRadius,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DudoSkeletonLine(
                    widthFactor: titleWidthFactor,
                    height: 13,
                  ),
                  const SizedBox(height: 8),
                  DudoSkeletonLine(
                    widthFactor: subtitleWidthFactor,
                    height: 10,
                  ),
                ],
              ),
            ),
            if (trailingWidth > 0) ...[
              const SizedBox(width: 10),
              DudoSkeletonBox(width: trailingWidth, height: 10, radius: 5),
            ],
          ],
        ),
      ),
    );
  }
}
