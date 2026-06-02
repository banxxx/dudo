String compactBookTitle(String title, {int maxCharacters = 24}) {
  final trimmed = title.trim();
  final runes = trimmed.runes.toList();
  if (runes.length <= maxCharacters) return trimmed;
  return '${String.fromCharCodes(runes.take(maxCharacters))}...';
}
