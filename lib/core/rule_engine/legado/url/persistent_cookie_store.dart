import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import 'cookie_merge.dart';

abstract interface class LegadoCookiePersistence {
  Future<String?> read(String key);

  void write(String key, String value);
}

class DriftLegadoCookiePersistence implements LegadoCookiePersistence {
  const DriftLegadoCookiePersistence(this.database);

  final AppDatabase database;

  @override
  Future<String?> read(String key) async {
    final row = await (database.select(database.appPreferences)
          ..where((table) => table.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  void write(String key, String value) {
    unawaited(
      database.into(database.appPreferences).insertOnConflictUpdate(
            AppPreferencesCompanion(
              key: Value(key),
              value: Value(value),
              updatedAt: Value(DateTime.now()),
            ),
          ),
    );
  }
}

/// 在线书源 Cookie 持久化存储。
///
/// 运行时读取内存镜像以保持同步接口简单，初始化和写回通过 AppPreferences 完成。
/// 该类只服务 Legado 在线规则运行时，不参与本地 TXT/EPUB 阅读流程。
class PersistentLegadoCookieStore implements LegadoCookieStore {
  PersistentLegadoCookieStore({
    required AppDatabase database,
    this.preferenceKey = 'legado.cookies',
    this.cookieMerge = const LegadoCookieMerge(),
  }) : _persistence = DriftLegadoCookiePersistence(database);

  PersistentLegadoCookieStore.withPersistence({
    required LegadoCookiePersistence persistence,
    this.preferenceKey = 'legado.cookies',
    this.cookieMerge = const LegadoCookieMerge(),
  }) : _persistence = persistence;

  final LegadoCookiePersistence _persistence;
  final String preferenceKey;
  final LegadoCookieMerge cookieMerge;
  final Map<String, String> _cookiesByHost = {};
  var _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final storedValue = await _persistence.read(preferenceKey);
    if (storedValue != null) {
      _cookiesByHost
        ..clear()
        ..addAll(_decode(storedValue));
    }
    _initialized = true;
  }

  @override
  String? cookieFor(Uri uri) => _cookiesByHost[_hostKey(uri)];

  @override
  void saveFromResponse(Uri uri, Iterable<String> setCookieHeaders) {
    final responseCookie = _cookieHeaderFromSetCookie(setCookieHeaders);
    if (responseCookie == null) return;
    final key = _hostKey(uri);
    final merged = cookieMerge.merge(
      storedCookie: _cookiesByHost[key],
      headerCookie: responseCookie,
    );
    if (merged == null || merged.trim().isEmpty) {
      _cookiesByHost.remove(key);
    } else {
      _cookiesByHost[key] = merged;
    }
    _persist();
  }

  String _hostKey(Uri uri) => uri.host.toLowerCase();

  String? _cookieHeaderFromSetCookie(Iterable<String> setCookieHeaders) {
    final pairs = <String>[];
    for (final header in setCookieHeaders) {
      final cookiePair = header.split(';').first.trim();
      if (cookiePair.isEmpty || !cookiePair.contains('=')) continue;
      pairs.add(cookiePair);
    }
    if (pairs.isEmpty) return null;
    return pairs.join('; ');
  }

  Map<String, String> _decode(String value) {
    final cookies = <String, String>{};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final host = entry.key.toString().trim().toLowerCase();
          final cookie = entry.value?.toString().trim() ?? '';
          if (host.isEmpty || cookie.isEmpty) continue;
          cookies[host] = cookie;
        }
        return cookies;
      }
    } on FormatException {
      // 兼容早期调试版本的行存储格式，避免已有 Cookie 被直接丢弃。
    }

    for (final line in value.split('\n')) {
      final index = line.indexOf('\t');
      if (index <= 0) continue;
      final host = line.substring(0, index).trim().toLowerCase();
      final cookie = line.substring(index + 1).trim();
      if (host.isEmpty || cookie.isEmpty) continue;
      cookies[host] = cookie;
    }
    return cookies;
  }

  String _encode() {
    final entries = _cookiesByHost.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode({
      for (final entry in entries) entry.key: entry.value,
    });
  }

  void _persist() {
    if (!_initialized) return;
    _persistence.write(preferenceKey, _encode());
  }
}
