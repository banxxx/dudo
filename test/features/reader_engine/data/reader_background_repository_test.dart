import 'package:dudo/features/reader_engine/domain/reader_background.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderBackgroundPreference', () {
    test('round trips builtin bamboo preference from json', () {
      final preference = ReaderBackgroundPreference.bamboo();

      final restored = ReaderBackgroundPreference.fromJsonString(
        preference.toJsonString(),
      );

      expect(restored, preference);
      expect(restored.assetPath, ReaderBackgroundPreference.bambooAssetPath);
    });

    test('falls back to solid when json is invalid', () {
      expect(
        ReaderBackgroundPreference.fromJsonString('{bad json'),
        ReaderBackgroundPreference.defaults(),
      );
    });

    test('falls back to solid when stored builtin id is unknown', () {
      expect(
        ReaderBackgroundPreference.fromJson(const {
          'version': 1,
          'type': 'builtinImage',
          'id': 'missing_background',
        }),
        ReaderBackgroundPreference.defaults(),
      );
    });

    test('restores custom image preference when file path is present', () {
      final restored = ReaderBackgroundPreference.fromJson(const {
        'version': 1,
        'type': 'customImage',
        'id': 'custom_demo',
        'filePath': 'reader_backgrounds/custom_demo.webp',
        'opacity': 0.12,
        'alignment': 'center',
        'fit': 'cover',
        'tintEnabled': true,
      });

      expect(restored.type, ReaderBackgroundType.customImage);
      expect(restored.id, 'custom_demo');
      expect(restored.filePath, 'reader_backgrounds/custom_demo.webp');
    });
  });
}
