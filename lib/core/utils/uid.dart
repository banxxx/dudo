import 'dart:math';

/// Generates a short, URL-safe, base36 ID. Good enough for local entities.
String uid({int length = 12}) {
  final rng = Random();
  final buf = StringBuffer();
  while (buf.length < length) {
    buf.write(rng.nextInt(1 << 32).toRadixString(36));
  }
  return buf.toString().substring(0, length);
}
