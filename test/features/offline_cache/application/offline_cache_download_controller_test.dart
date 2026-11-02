import 'dart:async';
import 'dart:math';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_download_controller.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache_task.dart';
import 'package:dudo/features/reader_engine/data/reader_document_source.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_document.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('caches every uncached chapter and removes the completed task',
      () async {
    final source = _FakeDocumentSource(
      totalChapters: 3,
      cachedIndexes: {1},
    );
    final messages = _RecordingMessageService();
    final controller = _controller(source, messages: messages);
    addTearDown(controller.dispose);

    final result = await controller.startBook(_book('book-a'));

    expect(result, OfflineCacheStartResult.started);
    await _waitFor(controller, (tasks) => tasks.isEmpty);
    expect(source.loadedIndexes, [0, 2]);
    expect(messages.successes, ['《三体》已缓存完成']);
  });

  test('limits concurrent books to the configured concurrency', () async {
    final gate = Completer<void>();
    final source = _FakeDocumentSource(totalChapters: 1, gate: gate);
    final controller = _controller(source);
    addTearDown(controller.dispose);

    await controller.startBook(_book('book-a'));
    await controller.startBook(_book('book-b'));

    expect(controller.state, hasLength(2));
    expect(
      controller.state[0].status,
      OfflineCacheTaskStatus.downloading,
    );
    expect(controller.state[1].status, OfflineCacheTaskStatus.queued);

    gate.complete();
    await _waitFor(controller, (tasks) => tasks.isEmpty);
    expect(source.loadedIndexes, [0, 0]);
  });

  test('pauses a running task and resumes it later', () async {
    final gate = Completer<void>();
    final source = _FakeDocumentSource(totalChapters: 1, gate: gate);
    final controller = _controller(source);
    addTearDown(controller.dispose);

    await controller.startBook(_book('book-a'));
    controller.pauseTask('book-a');
    expect(controller.state.single.status, OfflineCacheTaskStatus.paused);

    gate.complete();
    await _waitFor(
      controller,
      (tasks) =>
          tasks.length == 1 &&
          tasks.single.status == OfflineCacheTaskStatus.paused,
    );
    expect(source.loadedIndexes, isEmpty);

    controller.resumeTask('book-a');
    await _waitFor(controller, (tasks) => tasks.isEmpty);
    expect(source.loadedIndexes, [0]);
  });

  test('keeps downloaded chapters and marks the task failed on an error',
      () async {
    final source = _FakeDocumentSource(totalChapters: 3, failAt: 1);
    final messages = _RecordingMessageService();
    final controller = _controller(source, messages: messages);
    addTearDown(controller.dispose);

    await controller.startBook(_book('book-a'));
    await _waitFor(
      controller,
      (tasks) =>
          tasks.length == 1 &&
          tasks.single.status == OfflineCacheTaskStatus.failed,
    );

    final task = controller.state.single;
    expect(task.downloadedChapters, 1);
    expect(task.totalChapters, 3);
    expect(task.progress, closeTo(1 / 3, 0.001));
    expect(task.message, '连接中断，已保留已下载章节');
    expect(messages.errors, ['《三体》缓存失败']);
  });

  test('rejects local books and books without a source', () async {
    final controller = _controller(_FakeDocumentSource(totalChapters: 1));
    addTearDown(controller.dispose);

    expect(
      await controller.startBook(_book('local', localPath: '/tmp/book.txt')),
      OfflineCacheStartResult.localBook,
    );
    expect(
      await controller.startBook(_book('remote', sourceId: null)),
      OfflineCacheStartResult.notRemote,
    );
    expect(controller.state, isEmpty);
  });

  test('removes a task without discarding downloaded chapters', () async {
    final gate = Completer<void>();
    final source = _FakeDocumentSource(totalChapters: 1, gate: gate);
    var cacheChanges = 0;
    final controller = _controller(
      source,
      onCacheChanged: () => cacheChanges++,
    );
    addTearDown(controller.dispose);

    await controller.startBook(_book('book-a'));
    final removeFuture = controller.removeTask('book-a');
    gate.complete();
    await removeFuture;

    expect(controller.state, isEmpty);
    expect(cacheChanges, 1);
  });
}

OfflineCacheDownloadController _controller(
  ReaderDocumentSource source, {
  _RecordingMessageService? messages,
  void Function()? onCacheChanged,
}) {
  return OfflineCacheDownloadController(
    documentSource: () => source,
    concurrency: () => 1,
    onCacheChanged: onCacheChanged ?? () {},
    messageService: messages ?? _RecordingMessageService(),
  );
}

Future<void> _waitFor(
  OfflineCacheDownloadController controller,
  bool Function(List<OfflineCacheTask> tasks) predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate(controller.state)) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('cache tasks did not reach the expected state');
}

Book _book(
  String id, {
  String? localPath,
  String? sourceId = 'source',
}) {
  final now = DateTime(2026, 11, 1);
  return Book(
    id: id,
    title: '三体',
    author: '刘慈欣',
    intro: '简介',
    localPath: localPath,
    sourceId: sourceId,
    sourceBookUrl: sourceId == null ? null : 'https://example.test/$id',
    lastChapterIndex: 0,
    lastReadPosition: 0,
    createdAt: now,
    updatedAt: now,
    inShelf: true,
    sortOrder: 0,
  );
}

class _FakeDocumentSource implements ReaderDocumentSource {
  _FakeDocumentSource({
    required this.totalChapters,
    this.cachedIndexes = const {},
    this.failAt,
    this.gate,
  });

  final int totalChapters;
  final Set<int> cachedIndexes;
  final int? failAt;
  final Completer<void>? gate;
  final List<int> loadedIndexes = [];

  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    final gate = this.gate;
    if (gate != null) await gate.future;
    return ReaderDocument(
      bookId: bookId,
      title: '三体',
      sourceType: ReaderSourceType.remoteNovel,
      chapterCount: totalChapters,
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final end = min(offset + limit, totalChapters);
    return ReaderChapterMetaPage(
      items: [
        for (var index = offset; index < end; index++)
          ReaderChapterMeta(
            id: '$bookId:$index',
            bookId: bookId,
            index: index,
            title: '第 ${index + 1} 章',
            normalizedContentLength: 10,
            isCached: cachedIndexes.contains(index),
          ),
      ],
      offset: offset,
      limit: limit,
      hasMore: end < totalChapters,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    if (chapterIndex == failAt) throw StateError('network');
    loadedIndexes.add(chapterIndex);
    return ReaderChapter(
      id: '$bookId:$chapterIndex',
      bookId: bookId,
      index: chapterIndex,
      title: '第 ${chapterIndex + 1} 章',
      rawContent: '正文',
      normalizedText: '正文',
      blocks: const [],
    );
  }
}

class _RecordingMessageService implements AppMessageService {
  final successes = <String>[];
  final errors = <String>[];

  @override
  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    successes.add(message);
  }

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    errors.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
