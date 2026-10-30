import 'dart:convert';
import 'dart:typed_data';

import 'package:dudo/features/settings/typography_settings/data/reader_font_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderFontDisplayNameParser', () {
    test('reads the preferred typographic family name from OpenType name table',
        () {
      final bytes = _fontBytes(const [
        _NameRecord(
          nameId: 1,
          languageId: 0x0409,
          value: 'File Name',
        ),
        _NameRecord(
          nameId: 16,
          languageId: 0x0804,
          value: '霞鹜文楷',
        ),
      ]);

      expect(
        ReaderFontDisplayNameParser.tryReadDisplayName(bytes),
        '霞鹜文楷',
      );
    });

    test('returns null when bytes are not an OpenType font', () {
      expect(
          ReaderFontDisplayNameParser.tryReadDisplayName(Uint8List(4)), null);
    });
  });

  group('ReaderFontFileValidator', () {
    test('accepts the sfnt signatures the engine can load', () {
      expect(ReaderFontFileValidator.looksLikeFont(_sfntVersion(0x00010000)),
          isTrue);
      expect(ReaderFontFileValidator.looksLikeFont(_sfntTag('OTTO')), isTrue);
      expect(ReaderFontFileValidator.looksLikeFont(_sfntTag('true')), isTrue);
      expect(ReaderFontFileValidator.looksLikeFont(_sfntTag('typ1')), isTrue);
    });

    test('rejects short and non-font files', () {
      expect(ReaderFontFileValidator.looksLikeFont(Uint8List(4)), isFalse);
      expect(
        ReaderFontFileValidator.looksLikeFont(
          Uint8List.fromList(ascii.encode('<!DOCTYPE htm')),
        ),
        isFalse,
      );
      expect(
        ReaderFontFileValidator.looksLikeFont(
          Uint8List.fromList(
            const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0],
          ),
        ),
        isFalse,
      );
    });
  });
}

Uint8List _sfntVersion(int version) {
  final bytes = Uint8List(12);
  _writeUint32(bytes, 0, version);
  return bytes;
}

Uint8List _sfntTag(String tag) {
  final bytes = Uint8List(12);
  bytes.setRange(0, 4, ascii.encode(tag));
  return bytes;
}

Uint8List _fontBytes(List<_NameRecord> records) {
  final strings = BytesBuilder();
  final nameTableLength = 6 + records.length * 12;
  final table = Uint8List(nameTableLength);

  _writeUint16(table, 0, 0);
  _writeUint16(table, 2, records.length);
  _writeUint16(table, 4, nameTableLength);

  for (var i = 0; i < records.length; i++) {
    final record = records[i];
    final encoded = record.utf16BigEndian;
    final offset = strings.length;
    strings.add(encoded);

    final recordOffset = 6 + i * 12;
    _writeUint16(table, recordOffset, 3);
    _writeUint16(table, recordOffset + 2, 1);
    _writeUint16(table, recordOffset + 4, record.languageId);
    _writeUint16(table, recordOffset + 6, record.nameId);
    _writeUint16(table, recordOffset + 8, encoded.length);
    _writeUint16(table, recordOffset + 10, offset);
  }

  final nameTable = Uint8List.fromList([...table, ...strings.toBytes()]);
  const nameOffset = 28;
  final font = Uint8List(nameOffset + nameTable.length);

  _writeUint32(font, 0, 0x00010000);
  _writeUint16(font, 4, 1);
  font.setRange(12, 16, ascii.encode('name'));
  _writeUint32(font, 20, nameOffset);
  _writeUint32(font, 24, nameTable.length);
  font.setRange(nameOffset, nameOffset + nameTable.length, nameTable);

  return font;
}

void _writeUint16(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 8) & 0xff;
  bytes[offset + 1] = value & 0xff;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 24) & 0xff;
  bytes[offset + 1] = (value >> 16) & 0xff;
  bytes[offset + 2] = (value >> 8) & 0xff;
  bytes[offset + 3] = value & 0xff;
}

class _NameRecord {
  const _NameRecord({
    required this.nameId,
    required this.languageId,
    required this.value,
  });

  final int nameId;
  final int languageId;
  final String value;

  Uint8List get utf16BigEndian {
    final bytes = Uint8List(value.codeUnits.length * 2);
    for (var i = 0; i < value.codeUnits.length; i++) {
      _writeUint16(bytes, i * 2, value.codeUnits[i]);
    }
    return bytes;
  }
}
