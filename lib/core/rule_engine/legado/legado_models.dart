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

class LegadoBookInfo {
  const LegadoBookInfo({
    required this.name,
    required this.author,
    this.kind,
    this.lastChapter,
    this.intro,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
  });

  final String name;
  final String author;
  final String? kind;
  final String? lastChapter;
  final String? intro;
  final String? coverUrl;
  final String? tocUrl;
  final String? wordCount;
}

class LegadoTocChapter {
  const LegadoTocChapter({
    required this.name,
    this.url,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
  });

  final String name;
  final String? url;
  final String? isVolume;
  final String? isVip;
  final String? isPay;
  final String? updateTime;
}

class LegadoTocResult {
  const LegadoTocResult({
    required this.chapters,
    this.nextTocUrl,
  });

  final List<LegadoTocChapter> chapters;
  final String? nextTocUrl;
}
