import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../exceptions/exception_mapper.dart';
import 'http_client.dart';

/// Concurrent download orchestrator for chapter content & cover images.
///
/// Real implementation should integrate `background_downloader` for OS-level
/// queueing. This skeleton just exposes the planned API.
class DownloadManager {
  DownloadManager({int concurrency = 4}) : _concurrency = concurrency;

  final int _concurrency;
  int _inFlight = 0;
  final _queue = <_DownloadTask>[];

  Future<File> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onProgress,
  }) {
    final completer = Completer<File>();
    _queue.add(_DownloadTask(
      url: url,
      savePath: savePath,
      onProgress: onProgress,
      completer: completer,
    ));
    _drain();
    return completer.future;
  }

  void _drain() {
    while (_inFlight < _concurrency && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _inFlight++;
      _runTask(task).whenComplete(() {
        _inFlight--;
        _drain();
      });
    }
  }

  Future<void> _runTask(_DownloadTask task) async {
    try {
      final dir = Directory(p.dirname(task.savePath));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await HttpClient.instance.dio.download(
        task.url,
        task.savePath,
        onReceiveProgress: task.onProgress,
      );
      task.completer.complete(File(task.savePath));
    } catch (e, st) {
      task.completer.completeError(ExceptionMapper.map(e, st), st);
    }
  }
}

class _DownloadTask {
  final String url;
  final String savePath;
  final ProgressCallback? onProgress;
  final Completer<File> completer;
  _DownloadTask({
    required this.url,
    required this.savePath,
    required this.completer,
    this.onProgress,
  });
}
