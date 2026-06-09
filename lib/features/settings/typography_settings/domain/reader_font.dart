import '../../../../shared/theme/app_fonts.dart';

enum ReaderFontSource { builtin, imported }

class ReaderFont {
  const ReaderFont({
    required this.id,
    required this.displayName,
    required this.familyKey,
    required this.source,
    this.originalFileName,
    this.fileSize,
    this.relativePath,
    this.importedAt,
  });

  final String id;
  final String displayName;
  final String familyKey;
  final ReaderFontSource source;
  final String? originalFileName;
  final int? fileSize;
  final String? relativePath;
  final DateTime? importedAt;

  bool get isBuiltin => source == ReaderFontSource.builtin;
  bool get canDelete => source == ReaderFontSource.imported;
  String get sourceLabel => isBuiltin ? '内置字体' : '本地字体';
}

class ReaderFontLibrary {
  const ReaderFontLibrary({
    required this.fonts,
    required this.selectedFamilyKey,
  });

  final List<ReaderFont> fonts;
  final String selectedFamilyKey;

  List<ReaderFont> get builtinFonts =>
      fonts.where((font) => font.source == ReaderFontSource.builtin).toList();

  List<ReaderFont> get importedFonts =>
      fonts.where((font) => font.source == ReaderFontSource.imported).toList();

  ReaderFont get selectedFont => fonts.firstWhere(
        (font) => font.familyKey == selectedFamilyKey,
        orElse: () => fonts.first,
      );
}

class ReaderBuiltinFonts {
  ReaderBuiltinFonts._();

  static const serifSc = ReaderFont(
    id: 'builtin_noto_serif_sc',
    displayName: 'Noto Serif SC',
    familyKey: DudoFonts.serifSc,
    source: ReaderFontSource.builtin,
  );

  static const sansSc = ReaderFont(
    id: 'builtin_noto_sans_sc',
    displayName: 'Noto Sans SC',
    familyKey: DudoFonts.sansSc,
    source: ReaderFontSource.builtin,
  );

  static const List<ReaderFont> values = <ReaderFont>[serifSc, sansSc];
}
