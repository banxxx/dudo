/// Version of the snapshot contract understood by this build.
const int kSyncSchemaVersion = 1;

/// One sync payload. A `null` list means "this scope was not synced"; an empty
/// list means "nothing to change". The client never deletes local rows based on
/// a snapshot, so a missing or empty list cannot wipe a device.
class SyncSnapshot {
  const SyncSnapshot({
    this.books,
    this.bookmarks,
    this.notes,
    this.preferences,
    required this.generatedAt,
  });

  final List<SyncBook>? books;
  final List<SyncBookmark>? bookmarks;
  final List<SyncNote>? notes;

  /// Raw JSON values of the synced preference rows, keyed by preference key.
  final Map<String, String>? preferences;

  final DateTime generatedAt;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': kSyncSchemaVersion,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      if (books != null) 'books': [for (final book in books!) book.toJson()],
      if (bookmarks != null)
        'bookmarks': [for (final bookmark in bookmarks!) bookmark.toJson()],
      if (notes != null) 'notes': [for (final note in notes!) note.toJson()],
      if (preferences != null) 'preferences': preferences,
    };
  }

  factory SyncSnapshot.fromJson(Object? json) {
    final map = _asMap(json, '同步数据');
    final version = map['schemaVersion'];
    if (version is num && version.toInt() > kSyncSchemaVersion) {
      throw const FormatException('服务器使用的同步协议版本过新');
    }

    return SyncSnapshot(
      books: _list(map['books'], 'books', SyncBook.fromJson),
      bookmarks: _list(map['bookmarks'], 'bookmarks', SyncBookmark.fromJson),
      notes: _list(map['notes'], 'notes', SyncNote.fromJson),
      preferences: _preferences(map['preferences']),
      generatedAt: _date(map['generatedAt']) ?? DateTime.now(),
    );
  }

  /// Accepts either the snapshot itself or `{"snapshot": {...}}`, which leaves
  /// room for servers that wrap the payload with their own metadata.
  factory SyncSnapshot.fromResponse(Object? json) {
    if (json is Map && json['snapshot'] is Map) {
      return SyncSnapshot.fromJson(json['snapshot']);
    }
    return SyncSnapshot.fromJson(json);
  }

  static List<T>? _list<T>(
    Object? value,
    String field,
    T Function(Object?) parse,
  ) {
    if (value == null) return null;
    if (value is! List) throw FormatException('$field 字段格式不正确');
    return [for (final item in value) parse(item)];
  }

  static Map<String, String>? _preferences(Object? value) {
    if (value == null) return null;
    if (value is! Map) throw const FormatException('preferences 字段格式不正确');
    final result = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final preference = entry.value;
      if (key is String && preference is String) {
        result[key] = preference;
      }
    }
    return result;
  }
}

class SyncBook {
  const SyncBook({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.intro,
    this.sourceId,
    this.sourceBookUrl,
    this.lastChapterIndex = 0,
    this.lastReadPosition = 0,
    required this.createdAt,
    required this.updatedAt,
    this.inShelf = true,
    this.sortOrder = 0,
    this.remoteChapterCount,
    this.remoteNextTocUrl,
  });

  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? intro;
  final String? sourceId;
  final String? sourceBookUrl;
  final int lastChapterIndex;
  final int lastReadPosition;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool inShelf;
  final int sortOrder;
  final int? remoteChapterCount;
  final String? remoteNextTocUrl;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'intro': intro,
      'sourceId': sourceId,
      'sourceBookUrl': sourceBookUrl,
      'lastChapterIndex': lastChapterIndex,
      'lastReadPosition': lastReadPosition,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'inShelf': inShelf,
      'sortOrder': sortOrder,
      'remoteChapterCount': remoteChapterCount,
      'remoteNextTocUrl': remoteNextTocUrl,
    };
  }

  factory SyncBook.fromJson(Object? json) {
    final map = _asMap(json, '书籍');
    final updatedAt = _date(map['updatedAt']) ?? _epoch;
    return SyncBook(
      id: _requiredString(map['id'], '书籍 id'),
      title: _requiredString(map['title'], '书籍标题'),
      author: _string(map['author']),
      coverUrl: _string(map['coverUrl']),
      intro: _string(map['intro']),
      sourceId: _string(map['sourceId']),
      sourceBookUrl: _string(map['sourceBookUrl']),
      lastChapterIndex: _int(map['lastChapterIndex']),
      lastReadPosition: _int(map['lastReadPosition']),
      createdAt: _date(map['createdAt']) ?? updatedAt,
      updatedAt: updatedAt,
      inShelf: _bool(map['inShelf'], true),
      sortOrder: _int(map['sortOrder']),
      remoteChapterCount: _nullableInt(map['remoteChapterCount']),
      remoteNextTocUrl: _string(map['remoteNextTocUrl']),
    );
  }
}

class SyncBookmark {
  const SyncBookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterIndex,
    required this.position,
    this.preview,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String chapterId;
  final int chapterIndex;
  final int position;
  final String? preview;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterIndex': chapterIndex,
      'position': position,
      'preview': preview,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory SyncBookmark.fromJson(Object? json) {
    final map = _asMap(json, '书签');
    return SyncBookmark(
      id: _requiredString(map['id'], '书签 id'),
      bookId: _requiredString(map['bookId'], '书签 bookId'),
      chapterId: _string(map['chapterId']) ?? '',
      chapterIndex: _int(map['chapterIndex']),
      position: _int(map['position']),
      preview: _string(map['preview']),
      createdAt: _date(map['createdAt']) ?? _epoch,
    );
  }
}

class SyncNote {
  const SyncNote({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterIndex,
    required this.startOffset,
    required this.endOffset,
    required this.content,
    this.note,
    this.color,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String chapterId;
  final int chapterIndex;
  final int startOffset;
  final int endOffset;
  final String content;
  final String? note;
  final String? color;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterIndex': chapterIndex,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'content': content,
      'note': note,
      'color': color,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory SyncNote.fromJson(Object? json) {
    final map = _asMap(json, '笔记');
    return SyncNote(
      id: _requiredString(map['id'], '笔记 id'),
      bookId: _requiredString(map['bookId'], '笔记 bookId'),
      chapterId: _string(map['chapterId']) ?? '',
      chapterIndex: _int(map['chapterIndex']),
      startOffset: _int(map['startOffset']),
      endOffset: _int(map['endOffset']),
      content: _string(map['content']) ?? '',
      note: _string(map['note']),
      color: _string(map['color']),
      createdAt: _date(map['createdAt']) ?? _epoch,
    );
  }
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Map<String, Object?> _asMap(Object? json, String what) {
  if (json is! Map) throw FormatException('$what 格式不正确');
  return {
    for (final entry in json.entries) entry.key.toString(): entry.value,
  };
}

String _requiredString(Object? value, String what) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('缺少 $what');
  }
  return value.trim();
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _int(Object? value) {
  return value is num ? value.toInt() : 0;
}

int? _nullableInt(Object? value) {
  return value is num ? value.toInt() : null;
}

bool _bool(Object? value, bool fallback) {
  return value is bool ? value : fallback;
}

DateTime? _date(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
