import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../reader_engine/data/reader_document_source.dart';
import '../domain/offline_cache_task.dart';

enum OfflineCacheStartResult { started, alreadyRunning, localBook, notRemote }

/// Runs book-level chapter caching and exposes the tasks the offline cache
/// page renders.
///
/// The reader itself still caches the chapter it opens. This controller is the
/// "cache the whole book" path: it walks the chapter list, skips chapters that
/// are already cached and fetches the rest through the same document source
/// used by the reader, so both paths share the source rules and storage.
class OfflineCacheDownloadController
    extends StateNotifier<List<OfflineCacheTask>> {
  OfflineCacheDownloadController({
    required ReaderDocumentSource Function() documentSource,
    required int Function() concurrency,
    required void Function() onCacheChanged,
    required AppMessageService messageService,
    List<OfflineCacheTask> initialTasks = const [],
  })  : _documentSource = documentSource,
        _concurrency = concurrency,
        _onCacheChanged = onCacheChanged,
        _messageService = messageService,
        super(List.unmodifiable(initialTasks));

  final ReaderDocumentSource Function() _documentSource;
  final int Function() _concurrency;
  final void Function() _onCacheChanged;
  final AppMessageService _messageService;

  final Set<String> _pauseRequests = {};
  final Set<String> _cancelRequests = {};
  final Map<String, Future<void>> _running = {};
  bool _disposed = false;

  static const int _metaPageSize = 100;
  static const String _messageKey = 'offline-cache-download';

  Future<OfflineCacheStartResult> startBook(Book book) async {
    if (book.localPath?.trim().isNotEmpty ?? false) {
      return OfflineCacheStartResult.localBook;
    }
    if (book.sourceId?.trim().isEmpty ?? true) {
      return OfflineCacheStartResult.notRemote;
    }
    final existing = _taskFor(book.id);
    if (existing != null) {
      if (existing.status == OfflineCacheTaskStatus.failed ||
          existing.status == OfflineCacheTaskStatus.paused) {
        resumeTask(book.id);
        return OfflineCacheStartResult.started;
      }
      return OfflineCacheStartResult.alreadyRunning;
    }
    state = List.unmodifiable([
      ...state,
      OfflineCacheTask(
        bookId: book.id,
        title: book.title,
        author: book.author,
        status: OfflineCacheTaskStatus.queued,
        updatedAt: DateTime.now(),
      ),
    ]);
    _pump();
    return OfflineCacheStartResult.started;
  }

  void pauseTask(String bookId) {
    final task = _taskFor(bookId);
    if (task == null) return;
    if (task.status != OfflineCacheTaskStatus.downloading &&
        task.status != OfflineCacheTaskStatus.queued) {
      return;
    }
    _pauseRequests.add(bookId);
    _updateTask(
      bookId,
      status: OfflineCacheTaskStatus.paused,
      clearMessage: true,
    );
  }

  void resumeTask(String bookId) {
    final task = _taskFor(bookId);
    if (task == null) return;
    if (task.status != OfflineCacheTaskStatus.paused &&
        task.status != OfflineCacheTaskStatus.failed) {
      return;
    }
    _pauseRequests.remove(bookId);
    _cancelRequests.remove(bookId);
    _updateTask(
      bookId,
      status: OfflineCacheTaskStatus.queued,
      clearMessage: true,
    );
    _pump();
  }

  void retryTask(String bookId) => resumeTask(bookId);

  Future<void> removeTask(String bookId) async {
    _cancelRequests.add(bookId);
    final running = _running[bookId];
    if (running != null) {
      await running;
    }
    _cancelRequests.remove(bookId);
    _pauseRequests.remove(bookId);
    _removeTaskFromState(bookId);
    // Removing a task only dismisses it. Chapters that were already downloaded
    // stay cached and move into the regular cached-books list.
    _onCacheChanged();
  }

  /// Re-evaluates the queue after the concurrency setting changes.
  void pump() => _pump();

  void _pump() {
    if (_disposed) return;
    final active = state
        .where((task) => task.status == OfflineCacheTaskStatus.downloading)
        .length;
    var slots = _concurrency() - active;
    if (slots <= 0) return;
    for (final task in state
        .where((task) => task.status == OfflineCacheTaskStatus.queued)
        .toList(growable: false)) {
      if (slots <= 0) break;
      if (_running.containsKey(task.bookId)) continue;
      slots--;
      _startTask(task.bookId);
    }
  }

  void _startTask(String bookId) {
    _updateTask(
      bookId,
      status: OfflineCacheTaskStatus.downloading,
      clearMessage: true,
    );
    final future = _runTask(bookId);
    _running[bookId] = future;
    unawaited(
      future.whenComplete(() {
        _running.remove(bookId);
        _pump();
      }),
    );
  }

  Future<void> _runTask(String bookId) async {
    try {
      final source = _documentSource();
      final document = await source.loadDocument(bookId);
      final total = document.chapterCount;
      if (total <= 0) {
        _failTask(bookId, '目录尚未加载，请先更新目录');
        return;
      }
      _updateTask(
        bookId,
        totalChapters: total,
        downloadedChapters: 0,
        progress: 0,
      );

      var processed = 0;
      var offset = 0;
      while (offset < total) {
        _throwIfCancelled(bookId);
        if (_consumePause(bookId)) return;
        final page = await source.loadChapterMetas(
          bookId: bookId,
          offset: offset,
          limit: _metaPageSize,
        );
        if (page.items.isEmpty) break;
        for (final meta in page.items) {
          _throwIfCancelled(bookId);
          if (_consumePause(bookId)) return;
          if (!meta.isCached) {
            final chapter = await source.loadChapter(
              bookId: bookId,
              chapterIndex: meta.index,
            );
            if (chapter.rawContent.trim().isEmpty) {
              throw const _EmptyChapterException();
            }
          }
          processed++;
          _updateTask(
            bookId,
            downloadedChapters: processed,
            progress: processed / total,
          );
        }
        offset += page.items.length;
        if (!page.hasMore) break;
      }

      if (processed < total) {
        _failTask(bookId, '目录不完整，已保留已下载章节');
        return;
      }
      _completeTask(bookId);
    } on _CacheCancelledException {
      // removeTask is clearing this book; leave the state to the caller.
    } on _EmptyChapterException {
      if (_cancelRequests.contains(bookId) || _disposed) return;
      _failTask(bookId, '章节内容为空，已保留已下载章节');
    } catch (_) {
      if (_cancelRequests.contains(bookId) || _disposed) return;
      _failTask(bookId, '连接中断，已保留已下载章节');
    }
  }

  bool _consumePause(String bookId) {
    if (!_pauseRequests.remove(bookId)) return false;
    _updateTask(
      bookId,
      status: OfflineCacheTaskStatus.paused,
      clearMessage: true,
    );
    return true;
  }

  void _throwIfCancelled(String bookId) {
    if (_disposed || _cancelRequests.contains(bookId)) {
      throw const _CacheCancelledException();
    }
  }

  void _completeTask(String bookId) {
    final task = _taskFor(bookId);
    if (task == null) return;
    _removeTaskFromState(bookId);
    _onCacheChanged();
    _messageService.success(
      '《${task.title}》已缓存完成',
      title: '缓存完成',
      dedupeKey: _messageKey,
      visualStyle: AppMessageVisualStyle.paper,
    );
  }

  void _failTask(String bookId, String message) {
    if (_disposed) return;
    final task = _taskFor(bookId);
    if (task == null) return;
    _updateTask(
      bookId,
      status: OfflineCacheTaskStatus.failed,
      message: message,
    );
    _messageService.error(
      '《${task.title}》缓存失败',
      title: '缓存失败',
      dedupeKey: _messageKey,
      visualStyle: AppMessageVisualStyle.paper,
    );
  }

  void _updateTask(
    String bookId, {
    OfflineCacheTaskStatus? status,
    double? progress,
    int? downloadedChapters,
    int? totalChapters,
    String? message,
    bool clearMessage = false,
  }) {
    if (_disposed) return;
    var changed = false;
    final next = <OfflineCacheTask>[];
    for (final task in state) {
      if (task.bookId != bookId) {
        next.add(task);
        continue;
      }
      changed = true;
      next.add(
        task.copyWith(
          status: status,
          progress: progress,
          downloadedChapters: downloadedChapters,
          totalChapters: totalChapters,
          message: message,
          clearMessage: clearMessage,
        ),
      );
    }
    if (changed) state = List.unmodifiable(next);
  }

  void _removeTaskFromState(String bookId) {
    if (_disposed) return;
    state = List.unmodifiable(
      state.where((task) => task.bookId != bookId),
    );
  }

  OfflineCacheTask? _taskFor(String bookId) {
    for (final task in state) {
      if (task.bookId == bookId) return task;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _pauseRequests.clear();
    _cancelRequests.clear();
    super.dispose();
  }
}

class _CacheCancelledException implements Exception {
  const _CacheCancelledException();
}

class _EmptyChapterException implements Exception {
  const _EmptyChapterException();
}
