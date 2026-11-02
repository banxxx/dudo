import 'package:flutter/material.dart';

/// How wide the simulated spine is drawn relative to the whole wrap.
enum CoverSpineWidth {
  thin('thin', '细', 0.045, 0.035),
  standard('standard', '标准', 0.067, 0.05),
  wide('wide', '宽', 0.09, 0.07);

  const CoverSpineWidth(
    this.storageValue,
    this.label,
    this.wrapFraction,
    this.shelfFraction,
  );

  final String storageValue;
  final String label;

  /// Spine share of a full wrap preview.
  final double wrapFraction;

  /// Spine share of a narrow shelf cover thumbnail.
  final double shelfFraction;

  static CoverSpineWidth fromStorage(String? value) {
    for (final width in values) {
      if (width.storageValue == value) return width;
    }
    return CoverSpineWidth.standard;
  }
}

/// What fills the back cover when only the front was cropped.
enum CoverBackStyle {
  blur('blur', '同图模糊'),
  solid('solid', '纯色'),
  intro('intro', '简介卡');

  const CoverBackStyle(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static CoverBackStyle fromStorage(String? value) {
    for (final style in values) {
      if (style.storageValue == value) return style;
    }
    return CoverBackStyle.blur;
  }
}

/// The spine / back styling chosen for a locally supplied cover.
@immutable
class BookCoverStyle {
  const BookCoverStyle({
    required this.spineColor,
    this.spineWidth = CoverSpineWidth.standard,
    this.backStyle = CoverBackStyle.blur,
  });

  final Color spineColor;
  final CoverSpineWidth spineWidth;
  final CoverBackStyle backStyle;

  BookCoverStyle copyWith({
    Color? spineColor,
    CoverSpineWidth? spineWidth,
    CoverBackStyle? backStyle,
  }) {
    return BookCoverStyle(
      spineColor: spineColor ?? this.spineColor,
      spineWidth: spineWidth ?? this.spineWidth,
      backStyle: backStyle ?? this.backStyle,
    );
  }

  static BookCoverStyle fromBook({
    int? spineColor,
    String? spineWidth,
    String? backStyle,
  }) {
    return BookCoverStyle(
      spineColor: spineColor == null ? const Color(0xFF5E6F5B) : Color(spineColor),
      spineWidth: CoverSpineWidth.fromStorage(spineWidth),
      backStyle: CoverBackStyle.fromStorage(backStyle),
    );
  }
}

/// A foreground colour that stays readable on [background].
Color readableOn(Color background) {
  return background.computeLuminance() > 0.55
      ? const Color(0xFF25251F)
      : const Color(0xFFFFF8EA);
}

/// Swatches offered in the spine editor. The first entry is the colour sampled
/// from the user's own artwork.
const List<Color> coverSpinePresets = [
  Color(0xFF4B5A45),
  Color(0xFF8A735A),
  Color(0xFFD3B98E),
  Color(0xFF25251F),
  Color(0xFFB98242),
];
