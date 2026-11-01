import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_api.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ping uses the /api/v1 endpoint and sends the bearer token', () async {
    final adapter = _FakeAdapter(
      (_) => _jsonResponse({'ok': true}),
    );
    final api = DudoSyncApi(_dio(adapter));

    await api.ping(
      serverUrl: 'https://sync.example.com/',
      accessToken: ' token-123 ',
    );

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.toString(), 'https://sync.example.com/api/v1/ping');
    expect(request.headers['Authorization'], 'Bearer token-123');
    expect(request.headers['Accept'], 'application/json');
  });

  test('a server root ending in /api/v1 is not duplicated', () async {
    final adapter = _FakeAdapter((_) => _jsonResponse({'ok': true}));
    final api = DudoSyncApi(_dio(adapter));

    await api.ping(serverUrl: 'https://sync.example.com/api/v1');

    expect(
      adapter.requests.single.uri.toString(),
      'https://sync.example.com/api/v1/ping',
    );
  });

  test('no token means no Authorization header', () async {
    final adapter = _FakeAdapter((_) => _jsonResponse({'ok': true}));
    final api = DudoSyncApi(_dio(adapter));

    await api.ping(serverUrl: 'https://sync.example.com');

    expect(
        adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('sync posts the snapshot and parses a wrapped response', () async {
    final adapter = _FakeAdapter(
      (_) => _jsonResponse({
        'snapshot': {
          'schemaVersion': 1,
          'notes': [
            {
              'id': 'note-1',
              'bookId': 'book-1',
              'chapterId': 'book-1:1',
              'chapterIndex': 1,
              'startOffset': 0,
              'endOffset': 4,
              'content': '摘录',
              'createdAt': '2026-05-03T00:00:00.000Z',
            },
          ],
          'generatedAt': '2026-06-02T06:32:00.000Z',
        },
      }),
    );
    final api = DudoSyncApi(_dio(adapter));

    final response = await api.sync(
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
      snapshot: SyncSnapshot(
        notes: const [],
        generatedAt: DateTime(2026, 6, 2, 14, 32),
      ),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), 'https://sync.example.com/api/v1/sync');
    expect(request.headers['Authorization'], 'Bearer token-123');
    final body = request.data! as Map;
    expect(body['schemaVersion'], 1);
    expect(body['notes'], isEmpty);
    expect(body.containsKey('books'), isFalse);

    expect(response, isNotNull);
    expect(response!.notes!.single.id, 'note-1');
  });

  test('an empty sync response means there is nothing to apply', () async {
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromString('', 204),
    );
    final api = DudoSyncApi(_dio(adapter));

    final response = await api.sync(
      serverUrl: 'https://sync.example.com',
      snapshot: SyncSnapshot(generatedAt: DateTime(2026, 6, 2)),
    );

    expect(response, isNull);
  });

  test('a server that rejects ping surfaces a readable error', () async {
    final adapter = _FakeAdapter((_) => _jsonResponse({'ok': false}));
    final api = DudoSyncApi(_dio(adapter));

    expect(
      () => api.ping(serverUrl: 'https://sync.example.com'),
      throwsA(
        isA<DataSyncException>().having(
          (error) => error.message,
          'message',
          '服务器拒绝了连接',
        ),
      ),
    );
  });

  test('HTTP errors are mapped to actionable messages', () async {
    Future<DataSyncException> failure(int status) async {
      final adapter = _FakeAdapter(
        (_) => ResponseBody.fromString('', status),
      );
      final api = DudoSyncApi(_dio(adapter));
      try {
        await api.ping(serverUrl: 'https://sync.example.com');
      } on DataSyncException catch (error) {
        return error;
      }
      fail('expected a DataSyncException for HTTP $status');
    }

    expect((await failure(401)).message, '访问令牌无效或已过期');
    expect((await failure(403)).message, '访问令牌无效或已过期');
    expect((await failure(404)).message, '服务器未提供 Dudo Sync 接口');
    expect((await failure(500)).message, '服务器暂时不可用（HTTP 500）');
  });

  test('network failures are mapped to a connection message', () async {
    final adapter = _FakeAdapter(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final api = DudoSyncApi(_dio(adapter));

    expect(
      () => api.ping(serverUrl: 'https://sync.example.com'),
      throwsA(
        isA<DataSyncException>().having(
          (error) => error.message,
          'message',
          '无法连接服务器，请检查地址与网络',
        ),
      ),
    );
  });

  test('a malformed response is rejected', () async {
    final adapter = _FakeAdapter(
      (_) => _jsonResponse({
        'snapshot': {'notes': 'nope'},
      }),
    );
    final api = DudoSyncApi(_dio(adapter));

    expect(
      () => api.sync(
        serverUrl: 'https://sync.example.com',
        snapshot: SyncSnapshot(generatedAt: DateTime(2026, 6, 2)),
      ),
      throwsA(isA<DataSyncException>()),
    );
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio()..httpClientAdapter = adapter;
}

ResponseBody _jsonResponse(Object? data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
