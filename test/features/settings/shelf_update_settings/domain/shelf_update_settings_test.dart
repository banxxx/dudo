import 'dart:convert';

import 'package:dudo/features/settings/shelf_update_settings/domain/shelf_update_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults check the shelf every day over Wi-Fi with alerts on', () {
    final settings = ShelfUpdateSettings.defaults();

    expect(settings.enabled, isTrue);
    expect(settings.frequency, ShelfUpdateFrequency.daily);
    expect(settings.wifiOnly, isTrue);
    expect(settings.chapterAlerts, isTrue);
  });

  test('the entry label follows the frequency and the enabled state', () {
    expect(ShelfUpdateSettings.defaults().entryLabel, '每天');
    expect(
      ShelfUpdateSettings.defaults()
          .copyWith(frequency: ShelfUpdateFrequency.everyThreeDays)
          .entryLabel,
      '每 3 天',
    );
    expect(
      ShelfUpdateSettings.defaults().copyWith(enabled: false).entryLabel,
      '已关闭',
    );
  });

  test('the schedule label spells out the network condition', () {
    expect(ShelfUpdateSettings.defaults().scheduleLabel, '每天 · 仅 Wi-Fi');
    expect(
      ShelfUpdateSettings.defaults()
          .copyWith(frequency: ShelfUpdateFrequency.weekly, wifiOnly: false)
          .scheduleLabel,
      '每周 · 任意网络',
    );
    expect(
      ShelfUpdateSettings.defaults().copyWith(enabled: false).scheduleLabel,
      '自动更新已关闭',
    );
  });

  test('frequencies carry the intervals the scheduler needs', () {
    expect(ShelfUpdateFrequency.daily.interval, const Duration(days: 1));
    expect(
      ShelfUpdateFrequency.everyThreeDays.interval,
      const Duration(days: 3),
    );
    expect(ShelfUpdateFrequency.weekly.interval, const Duration(days: 7));
  });

  test('JSON round trip keeps every field', () {
    final settings = ShelfUpdateSettings.defaults().copyWith(
      enabled: false,
      frequency: ShelfUpdateFrequency.everyThreeDays,
      wifiOnly: false,
      chapterAlerts: false,
    );

    final decoded = ShelfUpdateSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );

    expect(decoded, settings);
  });

  test('missing or malformed values fall back to the defaults', () {
    expect(ShelfUpdateSettings.fromJson('nope'), ShelfUpdateSettings.defaults());
    expect(
      ShelfUpdateSettings.fromJson(const {}),
      ShelfUpdateSettings.defaults(),
    );
    expect(
      ShelfUpdateSettings.fromJson(const {'frequency': 'hourly'}).frequency,
      ShelfUpdateFrequency.daily,
    );
    expect(
      ShelfUpdateSettings.fromJson(const {'enabled': 'yes'}).enabled,
      isTrue,
    );
  });
}
