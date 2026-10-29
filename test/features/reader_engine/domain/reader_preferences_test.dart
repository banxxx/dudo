import 'package:dudo/features/reader_engine/domain/reader_preferences.dart';
import 'package:dudo/features/reader_engine/domain/reader_theme.dart';
import 'package:dudo/features/reader_engine/domain/reader_turn_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults match the reader defaults', () {
    final preferences = ReaderPreferences.defaults();

    expect(preferences.palette, ReaderTheme.parchment);
    expect(preferences.fontSize, 19);
    expect(preferences.lineHeight, 1.72);
    expect(preferences.paragraphSpacing, 15);
    expect(preferences.turnMode, ReaderTurnMode.slide);
    expect(preferences.brightness, 1);
    expect(preferences.systemStatusBarHidden, isTrue);
    expect(preferences.volumePageTurnEnabled, isTrue);
  });

  test('survives a JSON round trip', () {
    final preferences = ReaderPreferences.defaults().copyWith(
      paletteId: 'night',
      fontSize: 24,
      lineHeight: 1.9,
      paragraphSpacing: 20,
      pageHorizontalMargin: 40,
      firstLineIndentEnabled: false,
      textEnhancementEnabled: true,
      turnMode: ReaderTurnMode.scroll,
      brightness: 0.4,
      followSystemBrightness: true,
      eyeComfortEnhanced: true,
      timeBatteryHidden: true,
      chapterProgressHidden: true,
      systemStatusBarHidden: false,
      pageEdgeHidden: true,
      gestureNavigationBlocked: false,
      volumePageTurnEnabled: false,
    );

    final restored = ReaderPreferences.fromJson(preferences.toJson());

    expect(restored.paletteId, 'night');
    expect(restored.palette, ReaderTheme.night);
    expect(restored.fontSize, 24);
    expect(restored.lineHeight, 1.9);
    expect(restored.paragraphSpacing, 20);
    expect(restored.pageHorizontalMargin, 40);
    expect(restored.firstLineIndentEnabled, isFalse);
    expect(restored.textEnhancementEnabled, isTrue);
    expect(restored.turnMode, ReaderTurnMode.scroll);
    expect(restored.brightness, 0.4);
    expect(restored.followSystemBrightness, isTrue);
    expect(restored.eyeComfortEnhanced, isTrue);
    expect(restored.timeBatteryHidden, isTrue);
    expect(restored.chapterProgressHidden, isTrue);
    expect(restored.systemStatusBarHidden, isFalse);
    expect(restored.pageEdgeHidden, isTrue);
    expect(restored.gestureNavigationBlocked, isFalse);
    expect(restored.volumePageTurnEnabled, isFalse);
  });

  test('clamps out-of-range values from storage', () {
    final preferences = ReaderPreferences.fromJson({
      'fontSize': 999,
      'lineHeight': 9,
      'paragraphSpacing': -5,
      'pageHorizontalMargin': 500,
      'brightness': -1,
    });

    expect(preferences.fontSize, 45);
    expect(preferences.lineHeight, 2.6);
    expect(preferences.paragraphSpacing, 0);
    expect(preferences.pageHorizontalMargin, 52);
    expect(preferences.brightness, 0.1);
  });

  test('unknown palette and turn mode fall back to the defaults', () {
    final preferences = ReaderPreferences.fromJson({
      'paletteId': 'rainbow',
      'turnMode': 'flip',
      'fontSize': 'big',
    });

    expect(preferences.paletteId, 'parchment');
    expect(preferences.turnMode, ReaderTurnMode.slide);
    expect(preferences.fontSize, 19);
  });

  test('non-map JSON falls back to the defaults', () {
    expect(ReaderPreferences.fromJson(null).fontSize, 19);
    expect(ReaderPreferences.fromJson('broken').fontSize, 19);
    expect(ReaderPreferences.fromJson([1, 2]).fontSize, 19);
  });
}
