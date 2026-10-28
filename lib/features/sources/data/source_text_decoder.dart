import 'dart:convert';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

/// Decodes a rule file or subscription response into text.
///
/// Tries UTF-8 (with BOM handling) first, then GB18030 for the Chinese
/// source packs that are commonly saved in GBK. Throws a [FormatException]
/// with message `unsupported-encoding` when neither works.
Future<String> decodeSourceImportText(List<int> bytes) async {
  if (bytes.isEmpty) return '';
  final data = Uint8List.fromList(bytes);

  if (_hasPrefix(data, const [0xEF, 0xBB, 0xBF])) {
    return _stripBom(utf8.decode(data.sublist(3), allowMalformed: false));
  }
  if (_hasPrefix(data, const [0xFF, 0xFE])) {
    return _decodeUtf16(data.sublist(2), Endian.little);
  }
  if (_hasPrefix(data, const [0xFE, 0xFF])) {
    return _decodeUtf16(data.sublist(2), Endian.big);
  }

  try {
    return _stripBom(utf8.decode(data, allowMalformed: false));
  } on FormatException {
    try {
      return await CharsetConverter.decode('gb18030', data);
    } catch (_) {
      throw const FormatException('unsupported-encoding');
    }
  }
}

String _stripBom(String text) =>
    text.startsWith('\uFEFF') ? text.substring(1) : text;

bool _hasPrefix(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

String _decodeUtf16(Uint8List bytes, Endian endian) {
  final data = ByteData.sublistView(bytes);
  final codeUnits = <int>[];
  for (var i = 0; i + 1 < data.lengthInBytes; i += 2) {
    codeUnits.add(data.getUint16(i, endian));
  }
  return _stripBom(String.fromCharCodes(codeUnits));
}
