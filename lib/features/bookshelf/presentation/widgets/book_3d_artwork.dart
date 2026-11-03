import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../domain/book_cover_style.dart';

/// A perspectively projected book standing upright: the supplied [child] is
/// the front cover, and the spine is painted as a true 3D face behind its
/// left edge.
///
/// The book is only yawed, never pitched, so its side edges stay vertical the
/// way a real book looks on a shelf. The projection keeps the front cover a
/// real widget, so its hit targets and typography still work.
class Book3DArtwork extends StatelessWidget {
  const Book3DArtwork({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.spineColor,
    this.spineTitle = '',
    this.spineAuthor,
    this.showSpineText = true,
    this.depthFactor = 0.30,
    this.yaw = 0.38,
  });

  final Widget child;
  final double width;
  final double height;
  final Color spineColor;

  /// Title stacked in characters down the spine.
  final String spineTitle;

  /// Author stacked under the title, in a smaller size.
  final String? spineAuthor;

  /// Some cover artwork already carries its own lettering, so the printed
  /// spine type can be turned off per book.
  final bool showSpineText;

  final double depthFactor;
  final double yaw;

  @override
  Widget build(BuildContext context) {
    final depth = width * depthFactor;
    // The spine faces away from the key light, so it always sits a step
    // darker than the artwork. Without this a pale sampled spine reads as a
    // separate white board glued to the cover.
    final lum = spineColor.computeLuminance().clamp(0.0, 1.0);
    final effectiveSpine = Color.lerp(
      spineColor,
      const Color(0xFF1B1C18),
      (0.22 + lum * 0.60).clamp(0.22, 0.68),
    )!;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, -0.0026)
      ..rotateY(yaw);
    final bookSize = Size(width, height);
    // Yawing pushes the spine past the left edge while the far edge moves
    // inward, so nudge the whole book right to keep it optically centered.
    final left = _project(matrix, bookSize, 0, 0, -depth).dx;
    final right = _project(matrix, bookSize, width, height, 0).dx;
    final shift = (width - (right - left)) / 2 - left;

    return SizedBox(
      width: width,
      height: height,
      child: Transform.translate(
        offset: Offset(shift, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _Book3DPainter(
                  matrix: matrix,
                  size: bookSize,
                  depth: depth,
                  spineColor: effectiveSpine,
                  spineTitle: spineTitle,
                  spineAuthor: spineAuthor,
                  showSpineText: showSpineText,
                ),
              ),
            ),
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: matrix,
                filterQuality: FilterQuality.high,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              // Fold shadow next to the hinge.
                              Colors.black.withValues(alpha: 0.16),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.transparent,
                              // The far edge recedes, so it loses a little light
                              // on the artwork and the printed type alike.
                              Colors.black.withValues(alpha: 0.045),
                              Colors.black.withValues(alpha: 0.12),
                            ],
                            stops: const [0, 0.04, 0.13, 0.62, 0.86, 1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Offset _project(Matrix4 matrix, Size size, double x, double y, double z) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final px = x - cx;
  final py = y - cy;
  final w = matrix.entry(3, 0) * px +
      matrix.entry(3, 1) * py +
      matrix.entry(3, 2) * z +
      matrix.entry(3, 3);
  final inv = w == 0 ? 1.0 : 1.0 / w;
  final tx = matrix.entry(0, 0) * px +
      matrix.entry(0, 1) * py +
      matrix.entry(0, 2) * z +
      matrix.entry(0, 3);
  final ty = matrix.entry(1, 0) * px +
      matrix.entry(1, 1) * py +
      matrix.entry(1, 2) * z +
      matrix.entry(1, 3);
  return Offset(tx * inv + cx, ty * inv + cy);
}

class _Book3DPainter extends CustomPainter {
  _Book3DPainter({
    required this.matrix,
    required this.size,
    required this.depth,
    required this.spineColor,
    required this.spineTitle,
    required this.spineAuthor,
    required this.showSpineText,
  });

  final Matrix4 matrix;
  final Size size;
  final double depth;
  final Color spineColor;
  final String spineTitle;
  final String? spineAuthor;
  final bool showSpineText;

  Offset project(double x, double y, double z) =>
      _project(matrix, size, x, y, z);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final frontTopLeft = project(0, 0, 0);
    final frontTopRight = project(size.width, 0, 0);
    final frontBottomLeft = project(0, size.height, 0);
    final frontBottomRight = project(size.width, size.height, 0);

    final backTopLeft = project(0, 0, -depth);
    final backBottomLeft = project(0, size.height, -depth);

    _paintShadow(canvas, frontBottomLeft, frontBottomRight);

    _paintSpine(
      canvas,
      frontTopLeft,
      frontBottomLeft,
      backTopLeft,
      backBottomLeft,
    );

    final edge = Paint()
      ..color = const Color(0x2625251F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(frontTopLeft, frontTopRight, edge);
  }

  void _paintShadow(Canvas canvas, Offset left, Offset right) {
    final shadowRect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        (left.dy + right.dy) / 2 + size.height * 0.035,
      ),
      width: size.width * 0.84,
      height: size.height * 0.08,
    );
    final shadow = Paint()
      ..color = const Color(0x3325251F)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(5, size.width * 0.055),
      );
    canvas.drawOval(shadowRect, shadow);
  }

  void _paintSpine(
    Canvas canvas,
    Offset frontTop,
    Offset frontBottom,
    Offset backTop,
    Offset backBottom,
  ) {
    final spineWidth = (frontTop.dx - backTop.dx).abs();
    // A real spine is a rounded board, not a flat plank. Bow the outer edge
    // outward and arc the head and tail so the silhouette reads as convex.
    final bow = math.max(0.8, spineWidth * 0.22);
    final capBulge = math.max(0.6, spineWidth * 0.18);

    final tailControl = Offset(
      (frontBottom.dx + backBottom.dx) / 2 - bow * 0.35,
      (frontBottom.dy + backBottom.dy) / 2 + capBulge,
    );
    final outerControl = Offset(
      (backBottom.dx + backTop.dx) / 2 - bow,
      (backBottom.dy + backTop.dy) / 2,
    );
    final headControl = Offset(
      (backTop.dx + frontTop.dx) / 2 - bow * 0.35,
      (backTop.dy + frontTop.dy) / 2 - capBulge,
    );

    final hingeEdge = Path()
      ..moveTo(frontTop.dx, frontTop.dy)
      ..lineTo(frontBottom.dx, frontBottom.dy);
    final tailEdge = Path()
      ..moveTo(frontBottom.dx, frontBottom.dy)
      ..quadraticBezierTo(
        tailControl.dx,
        tailControl.dy,
        backBottom.dx,
        backBottom.dy,
      );
    final outerEdge = Path()
      ..moveTo(backBottom.dx, backBottom.dy)
      ..quadraticBezierTo(
        outerControl.dx,
        outerControl.dy,
        backTop.dx,
        backTop.dy,
      );
    final headEdge = Path()
      ..moveTo(backTop.dx, backTop.dy)
      ..quadraticBezierTo(
        headControl.dx,
        headControl.dy,
        frontTop.dx,
        frontTop.dy,
      );

    final path = Path()
      ..moveTo(frontTop.dx, frontTop.dy)
      ..lineTo(frontBottom.dx, frontBottom.dy)
      ..quadraticBezierTo(
        tailControl.dx,
        tailControl.dy,
        backBottom.dx,
        backBottom.dy,
      )
      ..quadraticBezierTo(
        outerControl.dx,
        outerControl.dy,
        backTop.dx,
        backTop.dy,
      )
      ..quadraticBezierTo(
        headControl.dx,
        headControl.dy,
        frontTop.dx,
        frontTop.dy,
      )
      ..close();

    final bounds = path.getBounds();
    final deep = Color.lerp(spineColor, const Color(0xFF10110E), 0.50)!;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Color.lerp(spineColor, const Color(0xFF10110E), 0.26)!,
          Color.lerp(spineColor, const Color(0xFF10110E), 0.08)!,
          // Rounded crest catching the key light.
          Color.lerp(spineColor, Colors.white, 0.17)!,
          spineColor,
          deep,
        ],
        stops: const [0, 0.16, 0.44, 0.76, 1],
      ).createShader(bounds);
    canvas.drawPath(path, paint);

    // A thin specular line on the crest sells the cylinder.
    final crest = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = math.max(0.7, spineWidth * 0.09)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset.lerp(frontTop, backTop, 0.44)! - Offset(0, capBulge * 0.5),
      Offset.lerp(frontBottom, backBottom, 0.44)! + Offset(0, capBulge * 0.5),
      crest,
    );

    final groove = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = math.max(0.7, size.width * 0.005);
    canvas.drawLine(
      Offset.lerp(frontTop, backTop, 0.84)!,
      Offset.lerp(frontBottom, backBottom, 0.84)!,
      groove,
    );

    final outerEdgeLine = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;
    canvas.drawPath(outerEdge, outerEdgeLine);

    // Close the head and tail of the spine so it reads as a solid board
    // rather than a loose stack of paper.
    final cap = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 0.8;
    canvas.drawPath(headEdge, cap);
    canvas.drawPath(tailEdge, cap);

    final hinge = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..strokeWidth = 1;
    canvas.drawPath(hingeEdge, hinge);

    final hingeLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      frontTop.translate(size.width * 0.008, -capBulge * 0.7),
      frontBottom.translate(size.width * 0.008, capBulge * 0.7),
      hingeLight,
    );

    _paintSpineText(
      canvas,
      path,
      frontTop,
      frontBottom,
      backTop,
      backBottom,
    );
  }

  /// Stacks the title and author down the spine, the way a printed Chinese
  /// book spine is set. The type is clipped to the spine face and skipped
  /// entirely when the spine is too narrow or short to read.
  void _paintSpineText(
    Canvas canvas,
    Path spinePath,
    Offset frontTop,
    Offset frontBottom,
    Offset backTop,
    Offset backBottom,
  ) {
    final titleCharacters = spineTitle.trim().characters.take(10).toList();
    if (!showSpineText || titleCharacters.isEmpty) return;

    // Perspective pulls the back edge inward, so even a 150pt cover shows a
    // spine only around 9pt wide. Below that the glyphs stop being legible.
    final spineWidth = (frontTop.dx - backTop.dx).abs();
    if (spineWidth < 6) return;

    final top = (frontTop.dy + backTop.dy) / 2;
    final bottom = (frontBottom.dy + backBottom.dy) / 2;
    if (bottom - top < spineWidth * 2.4) return;

    final centerX = (frontTop.dx + backTop.dx) / 2;
    final inset = spineWidth * 0.75;
    final titleSize = (spineWidth * 0.66).clamp(5.0, 15.0);
    final authorSize = (spineWidth * 0.48).clamp(4.5, 12.0);
    final color = readableOn(spineColor);
    final shadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: spineWidth * 0.18,
      ),
    ];

    final titlePainters = [
      for (final character in titleCharacters)
        _spineCharacterPainter(
          character,
          titleSize,
          color,
          shadows,
          serif: true,
        ),
    ];
    final authorPainters = [
      for (final character
          in (spineAuthor?.trim() ?? '').characters.take(8).toList())
        _spineCharacterPainter(
          character,
          authorSize,
          color.withValues(alpha: 0.82),
          shadows,
          serif: false,
        ),
    ];

    var authorTop = bottom - inset;
    for (final painter in authorPainters) {
      authorTop -= painter.height + authorSize * 0.12;
    }

    canvas.save();
    canvas.clipPath(spinePath);

    var y = top + inset;
    for (final painter in titlePainters) {
      if (y + painter.height > authorTop - spineWidth * 0.45) break;
      painter.paint(canvas, Offset(centerX - painter.width / 2, y));
      y += painter.height + titleSize * 0.06;
    }

    var authorY = authorTop;
    for (final painter in authorPainters) {
      if (authorY < top + inset) break;
      painter.paint(canvas, Offset(centerX - painter.width / 2, authorY));
      authorY += painter.height + authorSize * 0.12;
    }

    canvas.restore();
  }

  TextPainter _spineCharacterPainter(
    String character,
    double fontSize,
    Color color,
    List<Shadow> shadows, {
    required bool serif,
  }) {
    final style = (serif ? DudoTextStyles.serif : DudoTextStyles.sans)(
      color: color,
      fontSize: fontSize,
      fontWeight: serif ? FontWeight.w700 : FontWeight.w500,
      height: 1,
    ).copyWith(shadows: shadows);
    return TextPainter(
      text: TextSpan(text: character, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _Book3DPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.size != size ||
        oldDelegate.depth != depth ||
        oldDelegate.spineColor != spineColor ||
        oldDelegate.spineTitle != spineTitle ||
        oldDelegate.spineAuthor != spineAuthor ||
        oldDelegate.showSpineText != showSpineText;
  }
}
