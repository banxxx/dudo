import 'reader_insets.dart';
import 'reader_turn_mode.dart';

class ReaderSettings {
  const ReaderSettings({
    required this.paletteId,
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.turnMode,
    required this.paragraphSpacing,
    required this.pagePadding,
    required this.firstLineIndentEnabled,
  });

  static const double minFontSize = 10;
  static const double maxFontSize = 45;
  static const double minParagraphSpacing = 0;
  static const double maxParagraphSpacing = 36;
  static const double minPageHorizontalMargin = 18;
  static const double maxPageHorizontalMargin = 52;
  static const double defaultPageHorizontalMargin = 30;

  factory ReaderSettings.defaults() {
    return const ReaderSettings(
      paletteId: 'default',
      fontFamily: 'Noto Serif SC',
      fontSize: 18,
      lineHeight: 1.7,
      turnMode: ReaderTurnMode.paged,
      paragraphSpacing: 12,
      pagePadding: ReaderInsets.symmetric(horizontal: 24, vertical: 28),
      firstLineIndentEnabled: true,
    );
  }

  final String paletteId;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final ReaderTurnMode turnMode;
  final double paragraphSpacing;
  final ReaderInsets pagePadding;
  final bool firstLineIndentEnabled;

  static double clampFontSize(double value) =>
      value.clamp(minFontSize, maxFontSize).toDouble();

  static double clampParagraphSpacing(double value) =>
      value.clamp(minParagraphSpacing, maxParagraphSpacing).toDouble();

  static double clampPageHorizontalMargin(double value) =>
      value.clamp(minPageHorizontalMargin, maxPageHorizontalMargin).toDouble();

  ReaderSettings copyWith({
    String? paletteId,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    ReaderTurnMode? turnMode,
    double? paragraphSpacing,
    ReaderInsets? pagePadding,
    bool? firstLineIndentEnabled,
  }) {
    return ReaderSettings(
      paletteId: paletteId ?? this.paletteId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      turnMode: turnMode ?? this.turnMode,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      pagePadding: pagePadding ?? this.pagePadding,
      firstLineIndentEnabled:
          firstLineIndentEnabled ?? this.firstLineIndentEnabled,
    );
  }
}
