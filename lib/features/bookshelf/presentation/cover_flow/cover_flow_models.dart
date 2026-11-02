import 'dart:typed_data';

import '../../domain/book_cover_style.dart';

/// The crop shape offered on the front-cover editor.
enum CoverCropAspect {
  portrait(2 / 3, '封面 2:3'),
  square(1, '方形 1:1');

  const CoverCropAspect(this.ratio, this.label);

  final double ratio;
  final String label;
}

/// What the cover flow returns to the edit page. It is only written to the
/// database when the user saves the book profile.
class CoverFlowResult {
  const CoverFlowResult({
    required this.frontBytes,
    required this.style,
    this.wrapBytes,
  });

  final Uint8List frontBytes;
  final Uint8List? wrapBytes;
  final BookCoverStyle style;
}

/// A full wrap is back + spine + front laid out side by side.
const double fullWrapAspect = 1.374;
const double fullWrapBackFraction = 0.45;

double fullWrapFrontStart(CoverSpineWidth width) {
  return fullWrapBackFraction + width.wrapFraction;
}

double fullWrapFrontFraction(CoverSpineWidth width) {
  return 1 - fullWrapFrontStart(width);
}
