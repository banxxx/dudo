import 'dart:convert';

import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults enable every scope', () {
    final settings = DataSyncSettings.defaults();

    expect(settings.enabled, isTrue);
    expect(settings.progress, isTrue);
    expect(settings.bookmarks, isTrue);
    expect(settings.highlights, isTrue);
    expect(settings.settings, isTrue);
  });

  test('the entry label follows the master switch', () {
    expect(DataSyncSettings.defaults().entryLabel, '已开启');
    expect(
      DataSyncSettings.defaults().copyWith(enabled: false).entryLabel,
      '已关闭',
    );
  });

  test('JSON round trip keeps every field', () {
    final settings = DataSyncSettings.defaults().copyWith(
      enabled: false,
      progress: false,
      bookmarks: false,
      highlights: false,
      settings: false,
    );

    final decoded = DataSyncSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );

    expect(decoded, settings);
  });

  test('missing or malformed values fall back to the defaults', () {
    expect(DataSyncSettings.fromJson('nope'), DataSyncSettings.defaults());
    expect(DataSyncSettings.fromJson(const {}), DataSyncSettings.defaults());
    expect(
      DataSyncSettings.fromJson(const {'enabled': 'yes'}).enabled,
      isTrue,
    );
    expect(
      DataSyncSettings.fromJson(const {'highlights': false}).highlights,
      isFalse,
    );
  });
}
