class LegadoUrlPlaceholder {
  const LegadoUrlPlaceholder();

  String apply({
    required String rawUrl,
    required String keyword,
    int page = 1,
  }) {
    final encodedKeyword = Uri.encodeQueryComponent(keyword);
    return rawUrl
        .replaceAll('{{key}}', encodedKeyword)
        .replaceAll('{{page}}', page.toString())
        .replaceAllMapped(RegExp(r'<([^<>]+)>'), (match) {
      final pages = (match.group(1) ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (pages.isEmpty) return match.group(0)!;
      final index = page - 1;
      if (index < 0) return pages.first;
      if (index >= pages.length) return pages.last;
      return pages[index];
    });
  }
}
