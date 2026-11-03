import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../domain/book_cover_style.dart';

/// A photographed shell and the two quads the app paints it with.
class BookMockupVariant {
  const BookMockupVariant({
    required this.shellAsset,
    required this.maskAsset,
    required this.coverQuad,
    required this.spineQuad,
  });

  final String shellAsset;
  final String maskAsset;

  /// Front cover face in asset pixels, clockwise from the top left.
  final List<Offset> coverQuad;

  /// Cloth spine in asset pixels, clockwise from the top left.
  final List<Offset> spineQuad;
}

/// Assets and geometry for the photoreal book mockup.
///
/// The shell is a pre-rendered product photograph of a blank hardcover (cloth
/// spine, paper grain, studio lighting). The cover artwork and the spine tint
/// are composited into it once at device resolution and cached, so the shelf
/// only ever paints a single texture per book.
///
/// Every shell is shot from the same camera and fitted to the same cover size,
/// so the three thicknesses differ only by how much spine shows. The quads come
/// from `tools/blender/gen_book.py` and must not be edited by hand.
class BookMockupGeometry {
  const BookMockupGeometry._();

  static const Size assetSize = Size(960, 1490);

  /// Untransformed canvas the cover type is laid out in.
  static const Size coverLayout = Size(600, 905);

  static const String coverLightAsset =
      'assets/images/book/book_cover_light.webp';

  static const Map<CoverSpineWidth, BookMockupVariant> variants = {
    CoverSpineWidth.thin: BookMockupVariant(
      shellAsset: 'assets/images/book/book_shell_thin.webp',
      maskAsset: 'assets/images/book/book_spine_mask_thin.webp',
      coverQuad: [
        Offset(103.42, 22.35),
        Offset(928.04, 60.95),
        Offset(928.04, 1429.05),
        Offset(103.42, 1467.65),
      ],
      spineQuad: [
        Offset(51.08, 24.50),
        Offset(105.81, 22.46),
        Offset(105.81, 1467.54),
        Offset(51.08, 1465.50),
      ],
    ),
    CoverSpineWidth.standard: BookMockupVariant(
      shellAsset: 'assets/images/book/book_shell_standard.webp',
      maskAsset: 'assets/images/book/book_spine_mask_standard.webp',
      coverQuad: [
        Offset(122.04, 22.35),
        Offset(946.03, 61.05),
        Offset(946.03, 1428.95),
        Offset(122.04, 1467.65),
      ],
      spineQuad: [
        Offset(42.42, 25.52),
        Offset(124.43, 22.46),
        Offset(124.43, 1467.54),
        Offset(42.42, 1464.48),
      ],
    ),
    CoverSpineWidth.wide: BookMockupVariant(
      shellAsset: 'assets/images/book/book_shell_wide.webp',
      maskAsset: 'assets/images/book/book_spine_mask_wide.webp',
      coverQuad: [
        Offset(143.19, 22.35),
        Offset(966.45, 61.15),
        Offset(966.45, 1428.85),
        Offset(143.19, 1467.65),
      ],
      spineQuad: [
        Offset(32.44, 26.69),
        Offset(145.59, 22.46),
        Offset(145.59, 1467.54),
        Offset(32.44, 1463.31),
      ],
    ),
  };

  static BookMockupVariant variantFor(CoverSpineWidth spineWidth) {
    return variants[spineWidth] ?? variants[CoverSpineWidth.standard]!;
  }

  static Rect bookRect(Size stageSize) {
    final bookHeight = stageSize.height * 0.94;
    final bookWidth = bookHeight * (assetSize.width / assetSize.height);
    return Rect.fromLTWH(
      (stageSize.width - bookWidth) / 2,
      stageSize.height * 0.005,
      bookWidth,
      bookHeight,
    );
  }

  static Offset toStage(Size stageSize, Offset point) {
    final rect = bookRect(stageSize);
    return Offset(
      rect.left + point.dx / assetSize.width * rect.width,
      rect.top + point.dy / assetSize.height * rect.height,
    );
  }

  static List<Offset> coverQuadFor(
    Size stageSize,
    CoverSpineWidth spineWidth,
  ) =>
      [
        for (final point in variantFor(spineWidth).coverQuad)
          toStage(stageSize, point),
      ];

  static List<Offset> spineQuadFor(
    Size stageSize,
    CoverSpineWidth spineWidth,
  ) =>
      [
        for (final point in variantFor(spineWidth).spineQuad)
          toStage(stageSize, point),
      ];
}

class BookMockupAssets {
  const BookMockupAssets._();

  static ui.Image? _coverLight;
  static Future<void>? _coverLightLoading;
  static final Map<CoverSpineWidth, ui.Image> _shells = {};
  static final Map<CoverSpineWidth, ui.Image> _masks = {};
  static final Map<CoverSpineWidth, Future<void>> _loading = {};

  static ui.Image shell(CoverSpineWidth spineWidth) => _shells[spineWidth]!;
  static ui.Image spineMask(CoverSpineWidth spineWidth) => _masks[spineWidth]!;
  static ui.Image get coverLight => _coverLight!;

  /// Decodes the shell and spine mask for [spineWidth] the first time that
  /// thickness is used. Each decoded shell is about 5.7 MB, so the untried
  /// thicknesses stay on disk rather than all being held at once.
  static Future<void> load(CoverSpineWidth spineWidth) {
    return _loading[spineWidth] ??= _load(spineWidth);
  }

  static Future<void> _load(CoverSpineWidth spineWidth) async {
    final variant = BookMockupGeometry.variantFor(spineWidth);
    final images = await Future.wait([
      _decode(variant.shellAsset),
      _decode(variant.maskAsset),
    ]);
    _shells[spineWidth] = images[0];
    _masks[spineWidth] = images[1];
    await (_coverLightLoading ??= _decode(
      BookMockupGeometry.coverLightAsset,
    ).then((image) {
      _coverLight = image;
    }));
  }

  static Future<ui.Image> _decode(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

/// Composites the photographed shell, the user's cover, the printed type and
/// the spine tint into one image at device resolution.
///
/// Supersampling is deliberately not used: the cover and type layers are built
/// at 600 px wide (denser than the ~390 px face they land on), so the warp
/// already samples from a higher-resolution source. Rendering the canvas above
/// [devicePixelRatio] only multiplied memory and fill cost — the detail hero
/// went from ~1.7 MB to ~6.8 MB per cached image.
///
/// The cover type is rasterised into its own flat layer and then sampled onto
/// the tilted face exactly like the artwork is. Glyphs are therefore rasterised
/// once, axis-aligned at full density, and never re-rasterised under a
/// transform — which is what made earlier versions look jagged, and what left a
/// faint offset copy of the title on some GPUs.
class BookMockupComposer {
  const BookMockupComposer._();

  static Future<ui.Image> compose({
    required Size stageSize,
    required double devicePixelRatio,
    required ui.Image? cover,
    required Color spineColor,
    required CoverSpineWidth spineWidth,
    required String title,
    required String? author,
    required bool showCoverType,
  }) async {
    await BookMockupAssets.load(spineWidth);

    final pixelRatio = devicePixelRatio;
    final bookRect = BookMockupGeometry.bookRect(stageSize);
    final coverQuad = BookMockupGeometry.coverQuadFor(stageSize, spineWidth);
    final faceWidth = coverQuad[1].dx - coverQuad[0].dx;

    final coverTexture = await _renderCoverTexture(
      cover: cover,
      title: title,
      author: author,
      pixelWidth: faceWidth,
      pixelRatio: pixelRatio,
    );
    final typeTexture = showCoverType && title.trim().isNotEmpty
        ? await _renderTypeTexture(
            title: title,
            author: author,
            pixelWidth: faceWidth * pixelRatio,
          )
        : null;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);

      _paintShadow(canvas, stageSize, bookRect, spineWidth);

      final shell = BookMockupAssets.shell(spineWidth);
      canvas.drawImageRect(
        shell,
        Offset.zero & _imageSize(shell),
        bookRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      _paintSpineTint(canvas, bookRect, spineColor, spineWidth);
      _paintCover(
        canvas,
        coverQuad: coverQuad,
        coverTexture: coverTexture,
        typeTexture: typeTexture,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (stageSize.width * pixelRatio).round(),
        (stageSize.height * pixelRatio).round(),
      );
      picture.dispose();
      return image;
    } finally {
      coverTexture.dispose();
      typeTexture?.dispose();
    }
  }

  /// Rasterises the printed label, title and author into a flat image in
  /// [BookMockupGeometry.coverLayout] units, dense enough for the face it will
  /// be sampled onto.
  static Future<ui.Image> _renderTypeTexture({
    required String title,
    required String? author,
    required double pixelWidth,
  }) async {
    const layout = BookMockupGeometry.coverLayout;
    final scale = (pixelWidth / layout.width).clamp(1.0, 2.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    paintCoverType(canvas, title: title, author: author);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (layout.width * scale).round(),
      (layout.height * scale).round(),
    );
    picture.dispose();
    return image;
  }

  /// Paints the cover artwork and the studio light into one flat image whose
  /// pixels are at least as dense as the face will be on screen.
  static Future<ui.Image> _renderCoverTexture({
    required ui.Image? cover,
    required String title,
    required String? author,
    required double pixelWidth,
    required double pixelRatio,
  }) async {
    const layout = BookMockupGeometry.coverLayout;
    final targetWidth = math.max(layout.width, pixelWidth * pixelRatio);
    final scale = (targetWidth / layout.width).clamp(1.0, 2.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);

    final coverRect = Offset.zero & layout;
    if (cover != null) {
      canvas.drawImageRect(
        cover,
        coverSourceRect(cover, layout),
        coverRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      // No artwork (or it failed to load): the app's own paper cover still gets
      // printed onto the shell, so every book reads as the same object.
      paintGeneratedCover(canvas, coverRect, title: title, author: author);
    }

    // The blank cover of the shell carries the studio light. Soft-lighting it
    // over the artwork keeps the cover seated in the photograph.
    final coverLight = BookMockupAssets.coverLight;
    canvas.drawImageRect(
      coverLight,
      Offset.zero & _imageSize(coverLight),
      coverRect,
      Paint()
        ..blendMode = BlendMode.softLight
        ..color = const Color(0xB8FFFFFF)
        ..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (layout.width * scale).round(),
      (layout.height * scale).round(),
    );
    picture.dispose();
    return image;
  }

  /// Casts the shadow from the book's own silhouette.
  ///
  /// A flat ellipse (or a straight band under the bottom edge) cannot sit under
  /// a perspective-projected block: the base is a tilted line, so the shadow
  /// ends in a vertical cut at the fore-edge corner and leaves a wedge of light
  /// at the tail. Dropping the silhouette itself keeps the shadow's outline
  /// parallel to every edge, and the blur fades it out before the stage bounds.
  static void _paintShadow(
    Canvas canvas,
    Size stageSize,
    Rect bookRect,
    CoverSpineWidth spineWidth,
  ) {
    final spine = BookMockupGeometry.spineQuadFor(stageSize, spineWidth);
    final cover = BookMockupGeometry.coverQuadFor(stageSize, spineWidth);
    // Tail corner, front board and fore-edge, joined into one closed outline.
    final silhouette = Path()
      ..addPolygon([
        spine[0],
        cover[0],
        cover[1],
        cover[2],
        cover[3],
        spine[3],
      ], true);

    void layer(double drop, double blur, Color color) {
      canvas.drawPath(
        silhouette.shift(Offset(0, bookRect.height * drop)),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(1, bookRect.width * blur),
          ),
      );
    }

    // Wide, faint spill on the surface, then a tight contact under the boards.
    layer(0.022, 0.030, const Color(0x1825251F));
    layer(0.006, 0.008, const Color(0x2225251F));
  }

  /// Recolours the cloth spine while keeping the photograph's woven texture,
  /// seams and highlight. The mask is feathered so the tint never shows a
  /// hard edge against the hinge.
  static void _paintSpineTint(
    Canvas canvas,
    Rect bookRect,
    Color color,
    CoverSpineWidth spineWidth,
  ) {
    final mask = BookMockupAssets.spineMask(spineWidth);
    canvas.saveLayer(bookRect, Paint()..blendMode = BlendMode.color);
    canvas.drawRect(
      bookRect,
      Paint()..color = color.withValues(alpha: 0.86),
    );
    canvas.drawImageRect(
      mask,
      Offset.zero & _imageSize(mask),
      bookRect,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
  }

  static void _paintCover(
    Canvas canvas, {
    required List<Offset> coverQuad,
    required ui.Image coverTexture,
    ui.Image? typeTexture,
  }) {
    const layout = BookMockupGeometry.coverLayout;
    final path = Path()..addPolygon(coverQuad, true);
    final type = Paint()..filterQuality = FilterQuality.high;

    canvas.save();
    canvas.clipPath(path);
    canvas.transform(homography(layout, coverQuad).storage);
    canvas.drawImageRect(
      coverTexture,
      Offset.zero & _imageSize(coverTexture),
      Offset.zero & layout,
      type,
    );
    if (typeTexture != null) {
      canvas.drawImageRect(
        typeTexture,
        Offset.zero & _imageSize(typeTexture),
        Offset.zero & layout,
        type,
      );
    }
    canvas.restore();
  }

  static Size _imageSize(ui.Image image) => Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

  static Rect coverSourceRect(ui.Image image, Size target) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final targetRatio = target.width / target.height;
    final imageRatio = imageSize.width / imageSize.height;
    if ((imageRatio - targetRatio).abs() < 0.001) {
      return Offset.zero & imageSize;
    }
    if (imageRatio > targetRatio) {
      final width = imageSize.height * targetRatio;
      return Rect.fromLTWH(
        (imageSize.width - width) / 2,
        0,
        width,
        imageSize.height,
      );
    }
    final height = imageSize.width / targetRatio;
    return Rect.fromLTWH(
      0,
      (imageSize.height - height) / 2,
      imageSize.width,
      height,
    );
  }

  /// Perspective transform mapping [source] (origin at its top left) onto the
  /// four [target] corners in order: top left, top right, bottom right, bottom
  /// left.
  static Matrix4 homography(Size source, List<Offset> target) {
    final p = [
      Offset.zero,
      Offset(source.width, 0),
      Offset(source.width, source.height),
      Offset(0, source.height),
    ];
    final rows = <List<double>>[];
    final values = <double>[];
    for (var index = 0; index < 4; index++) {
      final x = p[index].dx;
      final y = p[index].dy;
      final u = target[index].dx;
      final v = target[index].dy;
      rows.add([x, y, 1, 0, 0, 0, -u * x, -u * y]);
      values.add(u);
      rows.add([0, 0, 0, x, y, 1, -v * x, -v * y]);
      values.add(v);
    }
    final coefficients = _solve(rows, values);
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, coefficients[0]);
    matrix.setEntry(0, 1, coefficients[1]);
    matrix.setEntry(0, 3, coefficients[2]);
    matrix.setEntry(1, 0, coefficients[3]);
    matrix.setEntry(1, 1, coefficients[4]);
    matrix.setEntry(1, 3, coefficients[5]);
    matrix.setEntry(3, 0, coefficients[6]);
    matrix.setEntry(3, 1, coefficients[7]);
    return matrix;
  }

  static List<double> _solve(List<List<double>> rows, List<double> values) {
    const size = 8;
    for (var column = 0; column < size; column++) {
      var pivot = column;
      for (var row = column + 1; row < size; row++) {
        if (rows[row][column].abs() > rows[pivot][column].abs()) {
          pivot = row;
        }
      }
      if (pivot != column) {
        final rowSwap = rows[column];
        rows[column] = rows[pivot];
        rows[pivot] = rowSwap;
        final valueSwap = values[column];
        values[column] = values[pivot];
        values[pivot] = valueSwap;
      }
      final divisor = rows[column][column];
      for (var index = column; index < size; index++) {
        rows[column][index] /= divisor;
      }
      values[column] /= divisor;
      for (var row = 0; row < size; row++) {
        if (row == column) continue;
        final factor = rows[row][column];
        if (factor == 0) continue;
        for (var index = column; index < size; index++) {
          rows[row][index] -= factor * rows[column][index];
        }
        values[row] -= factor * values[column];
      }
    }
    return values;
  }
}

/// Paints the printed label, title and author into
/// [BookMockupGeometry.coverLayout] coordinates, axis-aligned.
///
/// Called while the type layer is rasterised, never on the tilted face, so the
/// glyphs keep their true shape and full density.
void paintCoverType(Canvas canvas, {required String title, String? author}) {
  const layout = BookMockupGeometry.coverLayout;
  final trimmedTitle = title.trim();
  final trimmedAuthor = author?.trim() ?? '';
  if (trimmedTitle.isEmpty) return;

  final width = layout.width;
  final height = layout.height;
  const textColor = Color(0xFFFFF8EA);
  const mutedColor = Color(0xD9FFF8EA);
  const shadows = [
    Shadow(
      color: Color(0x4D000000),
      blurRadius: 14,
      offset: Offset(0, 3),
    ),
  ];

  final padding = width * 0.07;
  final labelSize = width * 0.062;
  final authorSize = width * 0.055;

  final label = _fittedTextPainter(
    text: '阅读收藏',
    style: DudoTextStyles.sans(
      color: const Color(0xCCFFF8EA),
      fontSize: labelSize,
    ).copyWith(shadows: shadows),
    maxWidth: width - padding * 2,
    maxLines: 1,
  );
  label.paint(canvas, Offset((width - label.width) / 2, padding));

  final maxTitleWidth = width * 0.86;
  final length = math.max(1, trimmedTitle.characters.length);
  final fitted = maxTitleWidth * 2.85 / length;
  final titleSize =
      math.min(width * 0.19, fitted).clamp(width * 0.085, width * 0.19);
  final titlePainter = _fittedTextPainter(
    text: trimmedTitle,
    style: DudoTextStyles.serif(
      color: textColor,
      fontSize: titleSize,
      fontWeight: FontWeight.w700,
      height: 1.18,
    ).copyWith(shadows: shadows),
    maxWidth: maxTitleWidth,
    maxLines: 3,
  );
  titlePainter.paint(
    canvas,
    Offset(
      (width - titlePainter.width) / 2,
      (height - titlePainter.height) / 2 - width * 0.012,
    ),
  );

  if (trimmedAuthor.isEmpty) return;
  final authorPainter = _fittedTextPainter(
    text: trimmedAuthor,
    style: DudoTextStyles.sans(
      color: mutedColor,
      fontSize: authorSize,
    ).copyWith(shadows: shadows),
    maxWidth: width - padding * 2,
    maxLines: 1,
  );
  authorPainter.paint(
    canvas,
    Offset(
      (width - authorPainter.width) / 2,
      height - padding - authorPainter.height,
    ),
  );
}

/// Lays text out for painting.
///
/// `maxLines` only constrains the measurement: long text is truncated by
/// measurement and the painted paragraph carries no line limit.
TextPainter _fittedTextPainter({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required int maxLines,
}) {
  TextPainter measure(String value) {
    return TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
  }

  var value = text;
  if (measure(value).didExceedMaxLines) {
    final characters = text.characters;
    var low = 0;
    var high = characters.length;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      final candidate = '${characters.take(mid).toString().trimRight()}…';
      if (measure(candidate).didExceedMaxLines) {
        high = mid - 1;
      } else {
        low = mid;
      }
    }
    value = '${characters.take(low).toString().trimRight()}…';
  }

  return TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
}

/// Paints the app's own paper cover — the one used when a book has no artwork —
/// in [BookMockupGeometry.coverLayout] units.
///
/// It mirrors [BookCoverArtwork]'s generated card (same gradient, label and
/// four-character title) so a book without a cover still gets the photoreal
/// shell instead of dropping to the flat drawing.
void paintGeneratedCover(
  Canvas canvas,
  Rect rect, {
  required String title,
  String? author,
}) {
  final trimmedTitle = title.trim().isEmpty ? '书' : title.trim();
  final trimmedAuthor =
      author?.trim().isNotEmpty == true ? author!.trim() : 'Dudo';
  final width = rect.width;

  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DudoColors.textPrimary,
          DudoColors.primary,
          DudoColors.accentSoft,
        ],
        stops: const [0, 0.58, 1],
      ).createShader(rect),
  );

  final padding = width * 0.12;
  final labelSize = width * 0.09;
  final titleSize = width * 0.19;
  final centerX = rect.left + width / 2;

  final label = TextPainter(
    text: TextSpan(
      text: '阅读收藏',
      style: DudoTextStyles.sans(
        color: DudoColors.surfaceHigh,
        fontSize: labelSize,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(
    canvas,
    Offset(centerX - label.width / 2, rect.top + padding),
  );

  final authorPainter = TextPainter(
    text: TextSpan(
      text: trimmedAuthor,
      style: DudoTextStyles.sans(
        color: const Color(0xFFE8E4D8),
        fontSize: labelSize,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: width - padding * 2);
  authorPainter.paint(
    canvas,
    Offset(
      centerX - authorPainter.width / 2,
      rect.bottom - padding - authorPainter.height,
    ),
  );

  // The shelf card shortens long titles to four characters; keeping the same
  // rule here makes the hero read as the same object scaled up.
  final characters = trimmedTitle.runes.toList();
  final shortTitle = characters.length <= 4
      ? trimmedTitle
      : String.fromCharCodes(characters.take(4));
  final titlePainter = TextPainter(
    text: TextSpan(
      text: shortTitle,
      style: DudoTextStyles.serif(
        color: DudoColors.surfaceHigh,
        fontSize: titleSize,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 3,
    ellipsis: '…',
  )..layout(maxWidth: width - padding * 2);
  titlePainter.paint(
    canvas,
    Offset(
      centerX - titlePainter.width / 2,
      rect.center.dy - titlePainter.height / 2,
    ),
  );
}

/// Spine lettering, painted flat on the screen so it never passes through the
/// tilted-cover transform.
class BookMockupSpineTypePainter extends CustomPainter {
  const BookMockupSpineTypePainter({
    required this.stageSize,
    required this.title,
    required this.author,
    required this.spineColor,
    required this.spineWidth,
    required this.showText,
  });

  final Size stageSize;
  final String title;
  final String? author;
  final Color spineColor;
  final CoverSpineWidth spineWidth;
  final bool showText;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showText) return;
    final quad = BookMockupGeometry.spineQuadFor(stageSize, spineWidth);
    final spineTop = quad[0].dy;
    final spineBottom = quad[3].dy;
    final spineLeft = quad[0].dx;
    final spineRight = quad[1].dx;
    final faceWidth = spineRight - spineLeft;
    final span = spineBottom - spineTop;
    if (span < faceWidth * 2.4) return;

    final centerX = (spineLeft + spineRight) / 2;
    final ink = readableOn(spineColor);
    final shadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: math.max(1, faceWidth * 0.16),
      ),
    ];

    final titleSize = (faceWidth * 0.28).clamp(5.5, 15.0);
    final authorSize = (faceWidth * 0.20).clamp(4.5, 11.0);
    final titleCharacters = title.trim().characters.take(9).toList();
    final authorCharacters = (author?.trim() ?? '').characters.take(7).toList();
    if (titleCharacters.isEmpty) return;

    canvas.save();
    canvas.clipPath(Path()..addPolygon(quad, true));

    final titleStyle = DudoTextStyles.serif(
      color: ink,
      fontSize: titleSize,
      fontWeight: FontWeight.w700,
      height: 1,
    ).copyWith(shadows: shadows);
    var y = spineTop + span * 0.06;
    final titleLimit = spineTop + span * 0.62;
    for (final character in titleCharacters) {
      final painter = TextPainter(
        text: TextSpan(text: character, style: titleStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (y + painter.height > titleLimit) break;
      painter.paint(canvas, Offset(centerX - painter.width / 2, y));
      y += titleSize * 1.2;
    }

    if (authorCharacters.isEmpty) {
      canvas.restore();
      return;
    }

    final authorStyle = DudoTextStyles.sans(
      color: ink.withValues(alpha: 0.82),
      fontSize: authorSize,
      fontWeight: FontWeight.w500,
      height: 1,
    ).copyWith(shadows: shadows);
    final authorPainters = [
      for (final character in authorCharacters)
        TextPainter(
          text: TextSpan(text: character, style: authorStyle),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    var authorY = spineBottom - span * 0.05;
    for (final painter in authorPainters.reversed) {
      authorY -= painter.height + authorSize * 0.14;
      if (authorY < y + faceWidth * 0.3) break;
      painter.paint(canvas, Offset(centerX - painter.width / 2, authorY));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(BookMockupSpineTypePainter oldDelegate) {
    return oldDelegate.stageSize != stageSize ||
        oldDelegate.title != title ||
        oldDelegate.author != author ||
        oldDelegate.spineColor != spineColor ||
        oldDelegate.spineWidth != spineWidth ||
        oldDelegate.showText != showText;
  }
}

/// Small LRU cache for composed book images. Each entry is a few megabytes,
/// so the shelf never accumulates a whole library of them.
