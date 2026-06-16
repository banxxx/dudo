import 'dart:async';

import '../common/legado_trace.dart';

/// JS 执行时可访问的上下文。
///
/// 这个文件只描述 JS Bridge 需要的输入，不放具体 JS 引擎实现，
/// 方便后续把 java/cookie/cache 等 Bridge 能力继续拆到独立文件。
class LegadoJsContext {
  const LegadoJsContext({
    required this.key,
    required this.page,
    this.baseUrl,
    this.src,
    this.result,
    this.source,
    this.book,
    this.chapter,
    this.nextChapterUrl,
    this.variables = const {},
    this.cookie,
    this.ajax,
    this.trace,
  });

  final String key;
  final int page;
  final String? baseUrl;
  final Object? src;
  final Object? result;
  final Object? source;
  final Object? book;
  final Object? chapter;
  final String? nextChapterUrl;
  final Map<String, Object?> variables;
  final String? cookie;
  final LegadoJsAjax? ajax;
  final LegadoTrace? trace;

  String get encodedKey => Uri.encodeQueryComponent(key);
}

typedef LegadoJsAjax = FutureOr<Object?> Function(String rawUrl);
