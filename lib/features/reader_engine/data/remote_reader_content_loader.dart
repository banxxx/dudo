import 'dart:convert';

import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../../core/utils/logger.dart';
import '../../sources/data/source_repository.dart';
import 'reader_content_parser.dart';
import 'text_reader_book_repository.dart';

typedef RemoteReaderSourceResolver = Future<RemoteReaderSourceRecord?> Function(
  String sourceId,
);

typedef RemoteReaderContentFetcher = Future<ContentResult?> Function(
  SourceRule source,
  String contentUrl,
);

class RemoteReaderContentLoader {
  const RemoteReaderContentLoader({
    required this.repository,
    required this.sourceResolver,
    required this.contentFetcher,
  });

  factory RemoteReaderContentLoader.fromRepositories({
    required TextReaderBookRepository repository,
    required SourceRepository sourceRepository,
    required RuleEngine ruleEngine,
  }) {
    return RemoteReaderContentLoader(
      repository: repository,
      sourceResolver: (sourceId) async {
        final source = await sourceRepository.findSourceById(sourceId);
        if (source == null) return null;
        return RemoteReaderSourceRecord(
          id: source.id,
          name: source.name,
          rulesJson: source.rulesJson,
        );
      },
      contentFetcher: ruleEngine.loadContent,
    );
  }

  final TextReaderBookRepository repository;
  final RemoteReaderSourceResolver sourceResolver;
  final RemoteReaderContentFetcher contentFetcher;

  Future<ReaderChapterRecord?> loadIfNeeded(
    ReaderBookRecord book,
    ReaderChapterRecord chapter,
  ) async {
    final chapterUrl = chapter.url?.trim();
    log.i(
      '[reader-remote-content] check bookId=${book.id} title=${book.title} '
      'sourceId=${book.sourceId} chapterIndex=${chapter.chapterIndex} '
      'chapterTitle=${chapter.title} cached=${chapter.isCached} '
      'hasContent=${chapter.content?.trim().isNotEmpty ?? false} '
      'url=$chapterUrl',
    );
    if (chapter.isCached && (chapter.content?.trim().isNotEmpty ?? false)) {
      log.i(
        '[reader-remote-content] skip cached '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }
    if (chapterUrl == null || chapterUrl.isEmpty) {
      log.w(
        '[reader-remote-content] skip empty chapter url '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }
    final sourceId = book.sourceId?.trim();
    if (sourceId == null || sourceId.isEmpty) {
      log.w(
        '[reader-remote-content] skip empty sourceId '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }

    final source = await sourceResolver(sourceId);
    if (source == null) {
      log.w(
        '[reader-remote-content] skip source not found '
        'sourceId=$sourceId bookId=${book.id}',
      );
      return null;
    }
    final rule = _parseSourceRule(source.rulesJson);
    if (rule == null || rule.content == null) {
      log.w(
        '[reader-remote-content] skip missing ruleContent '
        'sourceId=$sourceId bookId=${book.id}',
      );
      return null;
    }

    log.i(
      '[reader-remote-content] request content source=${source.name} '
      'sourceId=$sourceId chapterUrl=$chapterUrl '
      'contentRule=${_preview(rule.content?.content ?? '')}',
    );
    final content = await contentFetcher(rule, chapterUrl);
    final rawContent = content?.content.trim();
    log.i(
      '[reader-remote-content] result bookId=${book.id} '
      'chapterIndex=${chapter.chapterIndex} title=${content?.title} '
      'contentChars=${rawContent?.length ?? 0} '
      'nextContentUrl=${content?.nextContentUrl}',
    );
    if (rawContent == null || rawContent.isEmpty) {
      log.w(
        '[reader-remote-content] empty parsed content '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex} '
        'chapterUrl=$chapterUrl',
      );
      return null;
    }

    final normalizedLength = normalizeReaderEngineText(
      rawContent,
      title: chapter.title,
    ).length;
    await repository.cacheChapterContent(
      bookId: chapter.bookId,
      chapterIndex: chapter.chapterIndex,
      content: rawContent,
      normalizedContentLength: normalizedLength,
    );
    return ReaderChapterRecord(
      id: chapter.id,
      bookId: chapter.bookId,
      chapterIndex: chapter.chapterIndex,
      title: chapter.title,
      url: chapter.url,
      content: rawContent,
      normalizedContentLength: normalizedLength,
      isCached: true,
    );
  }

  SourceRule? _parseSourceRule(String rulesJson) {
    try {
      final decoded = jsonDecode(rulesJson);
      if (decoded is! Map) return null;
      return SourceRule.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  String _preview(String value, {int maxLength = 400}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }
}

class RemoteReaderSourceRecord {
  const RemoteReaderSourceRecord({
    required this.id,
    required this.name,
    required this.rulesJson,
  });

  final String id;
  final String name;
  final String rulesJson;
}
