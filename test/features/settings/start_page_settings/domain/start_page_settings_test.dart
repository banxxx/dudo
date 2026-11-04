import 'dart:convert';

import 'package:dudo/features/settings/start_page_settings/domain/start_page_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the home tab', () {
    final settings = StartPageSettings.defaults();
    expect(settings.page, StartPage.home);
    expect(StartPageSettings.lastKnown.page, StartPage.home);
  });

  test('JSON round trip keeps the selected page', () {
    const settings = StartPageSettings(page: StartPage.search);
    final decoded =
        StartPageSettings.fromJson(jsonDecode(jsonEncode(settings.toJson())));
    expect(decoded, settings);
    expect(decoded.page, StartPage.search);
  });

  test('unknown or missing values fall back to home', () {
    expect(
      StartPageSettings.fromJson({'page': 'reader'}).page,
      StartPage.home,
    );
    expect(StartPageSettings.fromJson(null).page, StartPage.home);
    expect(StartPageSettings.fromJson({'page': 42}).page, StartPage.home);
  });

  test('every tab exposes a label and a description', () {
    for (final page in StartPage.values) {
      expect(page.label, isNotEmpty);
      expect(page.description, isNotEmpty);
    }
  });
}
