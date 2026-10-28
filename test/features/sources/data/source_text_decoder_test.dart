import 'dart:convert';
import 'dart:typed_data';

import 'package:dudo/features/sources/data/source_text_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes utf-8 and strips the bom', () async {
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('[{"a":1}]')];

    expect(await decodeSourceImportText(bytes), '[{"a":1}]');
  });

  test('decodes utf-16 little endian with bom', () async {
    const text = '[{"a":1}]';
    final bytes = <int>[0xFF, 0xFE];
    for (final unit in text.codeUnits) {
      bytes
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }

    expect(await decodeSourceImportText(bytes), text);
  });

  test('decodes utf-16 big endian with bom', () async {
    const text = '[{"a":1}]';
    final bytes = <int>[0xFE, 0xFF];
    for (final unit in text.codeUnits) {
      bytes
        ..add(unit >> 8)
        ..add(unit & 0xFF);
    }

    expect(await decodeSourceImportText(bytes), text);
  });

  test('decodes plain utf-8 without a bom', () async {
    expect(await decodeSourceImportText(utf8.encode('书源')), '书源');
  });

  test('returns an empty string for empty bytes', () async {
    expect(await decodeSourceImportText(const <int>[]), '');
  });

  test('reports unsupported encodings', () async {
    await expectLater(
      decodeSourceImportText(Uint8List.fromList(const [0xFF, 0xFF, 0xFF])),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'unsupported-encoding',
        ),
      ),
    );
  });
}
