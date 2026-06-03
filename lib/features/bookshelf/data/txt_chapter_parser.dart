class ParsedTxtChapter {
  const ParsedTxtChapter({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

class TxtChapterParseResult {
  const TxtChapterParseResult({
    required this.chapters,
    required this.usedFallbackChunks,
  });

  final List<ParsedTxtChapter> chapters;
  final bool usedFallbackChunks;
}

class TxtChapterParser {
  const TxtChapterParser._();

  static const int fallbackChunkSize = 30000;

  static TxtChapterParseResult parse(
    String content, {
    int fallbackSize = fallbackChunkSize,
  }) {
    final normalized = _normalize(content);
    final parsed = _parseByChapterTitles(normalized);
    if (parsed.length >= 2) {
      return TxtChapterParseResult(chapters: parsed, usedFallbackChunks: false);
    }
    return TxtChapterParseResult(
      chapters: _fallbackChunks(normalized, fallbackSize),
      usedFallbackChunks: true,
    );
  }

  static String _normalize(String content) {
    return content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('﻿', '')
        .trim();
  }

  static List<ParsedTxtChapter> _parseByChapterTitles(String content) {
    if (content.isEmpty) return const [];

    final matches = <_ChapterTitleMatch>[];
    var lineStart = 0;
    while (lineStart <= content.length) {
      final lineEnd = content.indexOf('\n', lineStart);
      final end = lineEnd == -1 ? content.length : lineEnd;
      final line = content.substring(lineStart, end);
      final title = _chapterTitle(line);
      if (title != null) {
        matches.add(_ChapterTitleMatch(title: title, offset: lineStart));
      }
      if (lineEnd == -1) break;
      lineStart = lineEnd + 1;
    }

    if (matches.length < 2) return const [];

    final chapters = <ParsedTxtChapter>[];
    final prefix = content.substring(0, matches.first.offset).trim();
    if (prefix.isNotEmpty && prefix.length > 120) {
      chapters.add(ParsedTxtChapter(title: '序章', content: prefix));
    }

    for (var i = 0; i < matches.length; i++) {
      final current = matches[i];
      final nextOffset = i + 1 < matches.length ? matches[i + 1].offset : content.length;
      final chapterContent = content.substring(current.offset, nextOffset).trim();
      if (chapterContent.isEmpty) continue;
      chapters.add(ParsedTxtChapter(title: current.title, content: chapterContent));
    }

    return chapters;
  }

  static String? _chapterTitle(String line) {
    final text = line.trim();
    if (text.isEmpty || text.length > 60) return null;
    if (_chineseChapterPattern.hasMatch(text) ||
        _englishChapterPattern.hasMatch(text) ||
        _volumePattern.hasMatch(text)) {
      return text;
    }
    return null;
  }

  static List<ParsedTxtChapter> _fallbackChunks(String content, int chunkSize) {
    if (content.isEmpty) {
      return const [ParsedTxtChapter(title: '全文', content: '')];
    }

    final chapters = <ParsedTxtChapter>[];
    var start = 0;
    while (start < content.length) {
      var end = (start + chunkSize).clamp(0, content.length);
      if (end < content.length) {
        final paragraphBreak = content.lastIndexOf('\n', end);
        if (paragraphBreak > start + chunkSize ~/ 2) {
          end = paragraphBreak;
        }
      }
      final chunk = content.substring(start, end).trim();
      if (chunk.isNotEmpty) {
        chapters.add(ParsedTxtChapter(
          title: chapters.isEmpty ? '全文' : '全文 ${chapters.length + 1}',
          content: chunk,
        ));
      }
      start = end;
      while (start < content.length && content.codeUnitAt(start) == 10) {
        start++;
      }
    }

    return chapters.isEmpty
        ? const [ParsedTxtChapter(title: '全文', content: '')]
        : chapters;
  }

  static final RegExp _chineseChapterPattern = RegExp(
    r'^(?:正文\s*)?第[0-9零〇一二三四五六七八九十百千万两]+[章节回卷集部篇](?:\s+|[:：、.．\-—])?.{0,40}$',
  );

  static final RegExp _volumePattern = RegExp(
    r'^[卷集部篇][0-9零〇一二三四五六七八九十百千万两]+(?:\s+|[:：、.．\-—])?.{0,40}$',
  );

  static final RegExp _englishChapterPattern = RegExp(
    r'^(?:chapter|chap)\s+[0-9ivxlcdm]+[\s:：.\-—]*.{0,50}$',
    caseSensitive: false,
  );
}

class _ChapterTitleMatch {
  const _ChapterTitleMatch({required this.title, required this.offset});

  final String title;
  final int offset;
}
