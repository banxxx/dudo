import 'dart:convert';

import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults enable every scope but stay disconnected', () {
    final settings = DataSyncSettings.defaults();

    expect(settings.enabled, isTrue);
    expect(settings.progress, isTrue);
    expect(settings.annotations, isTrue);
    expect(settings.settings, isTrue);
    expect(settings.isConfigured, isFalse);
    expect(settings.hasScope, isTrue);
    expect(settings.lastSyncedAt, isNull);
  });

  test('the entry label follows the connection and the master switch', () {
    expect(DataSyncSettings.defaults().entryLabel, '未连接');
    expect(
      DataSyncSettings.defaults()
          .copyWith(serverUrl: 'https://sync.example.com')
          .entryLabel,
      '自动同步',
    );
    expect(
      DataSyncSettings.defaults()
          .copyWith(serverUrl: 'https://sync.example.com', enabled: false)
          .entryLabel,
      '手动同步',
    );
  });

  test('hasScope is false only when every scope is off', () {
    final settings = DataSyncSettings.defaults().copyWith(
      progress: false,
      annotations: false,
      settings: false,
    );

    expect(settings.hasScope, isFalse);
    expect(settings.copyWith(annotations: true).hasScope, isTrue);
  });

  test('JSON round trip keeps every field', () {
    final settings = DataSyncSettings.defaults().copyWith(
      enabled: false,
      progress: false,
      annotations: false,
      settings: false,
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
      lastSyncedAt: DateTime(2026, 5, 20, 14, 32),
    );

    final decoded = DataSyncSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );

    expect(decoded, settings);
  });

  test('clearing a field drops it from the copy and the JSON', () {
    final connected = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
      lastSyncedAt: DateTime(2026, 5, 20, 14, 32),
    );

    final cleared = connected.copyWith(
      clearServerUrl: true,
      clearAccessToken: true,
      clearLastSyncedAt: true,
    );

    expect(cleared.serverUrl, isNull);
    expect(cleared.accessToken, isNull);
    expect(cleared.lastSyncedAt, isNull);
    expect(cleared.toJson()['serverUrl'], isNull);
  });

  test('missing or malformed values fall back to the defaults', () {
    expect(DataSyncSettings.fromJson('nope'), DataSyncSettings.defaults());
    expect(DataSyncSettings.fromJson(const {}), DataSyncSettings.defaults());
    expect(
      DataSyncSettings.fromJson(const {'enabled': 'yes'}).enabled,
      isTrue,
    );
    expect(
      DataSyncSettings.fromJson(const {'annotations': false}).annotations,
      isFalse,
    );
    expect(
      DataSyncSettings.fromJson(const {'serverUrl': '   '}).serverUrl,
      isNull,
    );
    expect(
      DataSyncSettings.fromJson(const {'lastSyncedAt': 'nope'}).lastSyncedAt,
      isNull,
    );
  });

  test('legacy bookmark and highlight switches merge into annotations', () {
    expect(
      DataSyncSettings.fromJson(
        const {'bookmarks': false, 'highlights': false},
      ).annotations,
      isFalse,
    );
    expect(
      DataSyncSettings.fromJson(
        const {'bookmarks': true, 'highlights': false},
      ).annotations,
      isTrue,
    );
    expect(
      DataSyncSettings.fromJson(
        const {'bookmarks': false, 'highlights': true},
      ).annotations,
      isTrue,
    );
    // A stored annotations value always wins over the legacy keys.
    expect(
      DataSyncSettings.fromJson(
        const {'annotations': false, 'bookmarks': true, 'highlights': true},
      ).annotations,
      isFalse,
    );
  });

  group('dataSyncUrlError', () {
    test('rejects empty and malformed addresses', () {
      expect(dataSyncUrlError(null), '请填写服务器地址');
      expect(dataSyncUrlError('   '), '请填写服务器地址');
      expect(dataSyncUrlError('sync.example.com'), '地址需以 https:// 开头');
      expect(dataSyncUrlError('ftp://sync.example.com'),
          '仅支持 https:// 或 http:// 地址');
      expect(dataSyncUrlError('https://'), '地址缺少服务器域名或 IP');
    });

    test('requires HTTPS except for loopback development servers', () {
      expect(dataSyncUrlError('http://sync.example.com'), '同步服务需要使用 HTTPS 地址');
      expect(dataSyncUrlError('http://localhost:8080'), isNull);
      expect(dataSyncUrlError('http://127.0.0.1:8080'), isNull);
      expect(dataSyncUrlError('http://10.0.2.2:8080'), isNull);
    });

    test('accepts HTTPS addresses with a path and trims whitespace', () {
      expect(dataSyncUrlError(' https://sync.example.com/api/v1 '), isNull);
    });
  });
}
