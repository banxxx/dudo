import 'reader_insets.dart';
import 'reader_turn_mode.dart';

class ReaderSettings {
  const ReaderSettings({
    required this.paletteId,
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.brightness,
    required this.turnMode,
    required this.paragraphSpacing,
    required this.pagePadding,
  });

  factory ReaderSettings.defaults() {
    return const ReaderSettings(
      paletteId: 'default',
      fontFamily: 'Noto Serif SC',
      fontSize: 18,
      lineHeight: 1.7,
      brightness: 1,
      turnMode: ReaderTurnMode.paged,
      paragraphSpacing: 12,
      pagePadding: ReaderInsets.symmetric(horizontal: 24, vertical: 28),
    );
  }

  final String paletteId;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double brightness;
  final ReaderTurnMode turnMode;
  final double paragraphSpacing;
  final ReaderInsets pagePadding;

  ReaderSettings copyWith({
    String? paletteId,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? brightness,
    ReaderTurnMode? turnMode,
    double? paragraphSpacing,
    ReaderInsets? pagePadding,
  }) {
    return ReaderSettings(
      paletteId: paletteId ?? this.paletteId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      brightness: brightness ?? this.brightness,
      turnMode: turnMode ?? this.turnMode,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      pagePadding: pagePadding ?? this.pagePadding,
    );
  }
}
