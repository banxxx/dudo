import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_tokens.dart';

/// The gradient a book without artwork wears on the shelf.
///
/// The detail hero uses the same pair as its first paint, so tapping a card
/// continues the colour the reader was just looking at instead of flashing a
/// blank white block while the real cover loads.
class BookCoverPalette {
  const BookCoverPalette(this.start, this.end);

  final Color start;
  final Color end;
}

List<BookCoverPalette> get bookCoverPalettes => [
      BookCoverPalette(const Color(0xFF6F7E68), DudoColors.primaryContainer),
      BookCoverPalette(DudoColors.secondary, DudoColors.secondaryContainer),
      const BookCoverPalette(Color(0xFF5A6B84), Color(0xFFD7E0EA)),
      const BookCoverPalette(Color(0xFF9A6D45), Color(0xFFE8C99B)),
    ];

/// A book keeps the same cover colour wherever it appears, and keeps it when
/// the shelf is reordered. The hash is deterministic across app launches.
BookCoverPalette bookCoverPaletteFor(Book book) {
  final key = book.id.isNotEmpty ? book.id : book.title;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final palettes = bookCoverPalettes;
  return palettes[hash % palettes.length];
}
