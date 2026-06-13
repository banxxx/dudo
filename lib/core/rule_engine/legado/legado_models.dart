class LegadoSearchItem {
  const LegadoSearchItem({
    required this.name,
    required this.author,
    this.coverUrl,
    this.bookUrl,
    this.intro,
    this.kind,
    this.lastChapter,
    this.wordCount,
    this.updateTime,
  });

  final String name;
  final String author;
  final String? coverUrl;
  final String? bookUrl;
  final String? intro;
  final String? kind;
  final String? lastChapter;
  final String? wordCount;
  final String? updateTime;
}
