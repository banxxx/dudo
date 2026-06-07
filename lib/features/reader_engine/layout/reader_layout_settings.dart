import '../domain/reader_insets.dart';
import '../domain/reader_settings.dart';

enum ReaderTextAlign {
  start,
  center,
  end,
  justify,
}

class ReaderLayoutSettings {
  const ReaderLayoutSettings({
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.pagePadding,
    required this.firstLineIndent,
    required this.paragraphIndent,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.textAlign,
    required this.enableJustify,
    required this.enableKinsoku,
    required this.fontAssetVersion,
  });

  factory ReaderLayoutSettings.fromReaderSettings(
    ReaderSettings settings, {
    double firstLineIndent = 0,
    double paragraphIndent = 0,
    double letterSpacing = 0.4,
    double wordSpacing = 0,
    ReaderTextAlign textAlign = ReaderTextAlign.start,
    bool enableJustify = false,
    bool enableKinsoku = true,
    String fontAssetVersion = 'bundled-v1',
  }) {
    return ReaderLayoutSettings(
      fontFamily: settings.fontFamily,
      fontSize: settings.fontSize,
      lineHeight: settings.lineHeight,
      paragraphSpacing: settings.paragraphSpacing,
      pagePadding: settings.pagePadding,
      firstLineIndent: firstLineIndent,
      paragraphIndent: paragraphIndent,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textAlign: textAlign,
      enableJustify: enableJustify,
      enableKinsoku: enableKinsoku,
      fontAssetVersion: fontAssetVersion,
    );
  }

  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final ReaderInsets pagePadding;
  final double firstLineIndent;
  final double paragraphIndent;
  final double letterSpacing;
  final double wordSpacing;
  final ReaderTextAlign textAlign;
  final bool enableJustify;
  final bool enableKinsoku;
  final String fontAssetVersion;

  String get digest {
    return [
      fontFamily,
      fontSize,
      lineHeight,
      paragraphSpacing,
      pagePadding.left,
      pagePadding.top,
      pagePadding.right,
      pagePadding.bottom,
      firstLineIndent,
      paragraphIndent,
      letterSpacing,
      wordSpacing,
      textAlign.name,
      enableJustify,
      enableKinsoku,
      fontAssetVersion,
    ].join('|');
  }

  ReaderLayoutSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    ReaderInsets? pagePadding,
    double? firstLineIndent,
    double? paragraphIndent,
    double? letterSpacing,
    double? wordSpacing,
    ReaderTextAlign? textAlign,
    bool? enableJustify,
    bool? enableKinsoku,
    String? fontAssetVersion,
  }) {
    return ReaderLayoutSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      pagePadding: pagePadding ?? this.pagePadding,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      textAlign: textAlign ?? this.textAlign,
      enableJustify: enableJustify ?? this.enableJustify,
      enableKinsoku: enableKinsoku ?? this.enableKinsoku,
      fontAssetVersion: fontAssetVersion ?? this.fontAssetVersion,
    );
  }
}
