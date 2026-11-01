import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/sync_snapshot.dart';

/// A sync failure with a message that can be shown to the reader.
class DataSyncException implements Exception {
  const DataSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The two calls the app makes against a self-hosted Dudo Sync server.
abstract interface class DataSyncApi {
  /// Verifies that the address and token reach a compatible server.
  Future<void> ping({required String serverUrl, String? accessToken});

  /// Uploads [snapshot] and returns the merged snapshot, or `null` when the
  /// server has no changes to send back.
  Future<SyncSnapshot?> sync({
    required String serverUrl,
    String? accessToken,
    required SyncSnapshot snapshot,
  });
}

/// Minimal client for the Dudo Sync API described in
/// `docs/data-sync-api.md`.
class DudoSyncApi implements DataSyncApi {
  DudoSyncApi(this._dio);

  final Dio _dio;

  @override
  Future<void> ping({required String serverUrl, String? accessToken}) {
    return _guard(() async {
      final response = await _dio.get<Object?>(
        _endpoint(serverUrl, 'ping'),
        options: _options(accessToken),
      );
      final data = response.data;
      if (data is Map && data['ok'] == false) {
        throw const DataSyncException('服务器拒绝了连接');
      }
    });
  }

  @override
  Future<SyncSnapshot?> sync({
    required String serverUrl,
    String? accessToken,
    required SyncSnapshot snapshot,
  }) {
    return _guard(() async {
      final response = await _dio.post<Object?>(
        _endpoint(serverUrl, 'sync'),
        data: snapshot.toJson(),
        options: _options(accessToken),
      );
      final data = response.data;
      if (data == null) return null;
      if (data is String) {
        if (data.trim().isEmpty) return null;
        return SyncSnapshot.fromResponse(jsonDecode(data));
      }
      return SyncSnapshot.fromResponse(data);
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DataSyncException {
      rethrow;
    } on DioException catch (error) {
      throw DataSyncException(_messageFor(error));
    } on FormatException catch (error) {
      throw DataSyncException(
        error.message.isEmpty ? '服务器返回的数据格式不正确' : error.message,
      );
    } catch (_) {
      throw const DataSyncException('同步请求失败，请稍后重试');
    }
  }

  Options _options(String? accessToken) {
    final token = accessToken?.trim() ?? '';
    return Options(
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Accepts either the server root or a URL that already ends in `/api/v1`.
  String _endpoint(String serverUrl, String path) {
    var base = serverUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('/api/v1')) {
      base = base.substring(0, base.length - '/api/v1'.length);
    }
    return '$base/api/v1/$path';
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '连接超时，请检查服务器地址与网络';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请检查地址与网络';
      case DioExceptionType.badCertificate:
        return 'HTTPS 证书无效，请检查服务器配置';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return '访问令牌无效或已过期';
        }
        if (status == 404) {
          return '服务器未提供 Dudo Sync 接口';
        }
        if (status != null && status >= 500) {
          return '服务器暂时不可用（HTTP $status）';
        }
        return '请求失败（HTTP ${status ?? '未知'}）';
      case DioExceptionType.unknown:
        return '无法连接服务器，请检查地址与网络';
    }
  }
}
