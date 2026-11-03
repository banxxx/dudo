import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One composited book cover, together with the spine colour it was rendered
/// with. The colour travels with the image because it is sampled from the
/// artwork when the book has no stored style, and the live spine type must
/// match the pixels underneath it.
class BookMockupEntry {
  const BookMockupEntry({required this.image, required this.spineColor});

  final ui.Image image;
  final Color spineColor;
}

/// A small LRU of composited book covers.
///
/// Eight detail heroes stay resident — roughly a screenful of books — so
/// revisiting a book never pays for the composite twice. Entries are dropped
/// without disposing their image: a widget on another route may still be
/// painting the same bitmap, and `ui.Image` is reclaimed by the engine once
/// nothing references it.
class BookMockupCache {
  const BookMockupCache._();

  // One detail hero composite is ~570×750 px at dpr 3, about 1.7 MB decoded.
  static const int _maxEntries = 8;
  static final Map<String, BookMockupEntry> _entries = {};

  static BookMockupEntry? get(String key) => _entries[key];

  static void put(String key, BookMockupEntry entry) {
    _entries.remove(key);
    _entries[key] = entry;
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Drops every reusable composite. Called when the user clears the cover
  /// cache in storage settings, and after imported artwork is replaced.
  static void clear() => _entries.clear();
}
