import '../../models/source_rule.dart';
import '../js/legado_js_context.dart';
import '../rule/rule_context.dart';
import '../rule/rule_value.dart';
import 'legado_runtime_variables.dart';

/// 在线书源规则执行上下文。
///
/// 该对象只属于 Legado 在线运行时，不应被本地 TXT/EPUB 导入或本地章节解析持有。
class LegadoRuntimeContext {
  LegadoRuntimeContext({
    required this.source,
    required this.baseUrl,
    this.book,
    this.chapter,
    this.src,
    this.result,
    this.redirectUrl,
    this.nextChapterUrl,
    this.page = 1,
    this.keyword = '',
    LegadoRuntimeVariables? variables,
    this.cookie,
    this.ajax,
    LegadoTrace? trace,
  })  : trace = trace ?? LegadoTrace(),
        variables = variables ?? LegadoRuntimeVariables(trace: trace);

  final SourceRule source;
  final Object? book;
  final Object? chapter;
  final Object? src;
  final Object? result;
  final String baseUrl;
  final String? redirectUrl;
  final String? nextChapterUrl;
  final int page;
  final String keyword;
  final LegadoRuntimeVariables variables;
  final String? cookie;
  final LegadoJsAjax? ajax;
  final LegadoTrace trace;

  LegadoRuntimeContext copyWith({
    Object? book,
    Object? chapter,
    Object? src,
    Object? result,
    String? baseUrl,
    String? redirectUrl,
    String? nextChapterUrl,
    int? page,
    String? keyword,
    LegadoRuntimeVariables? variables,
    String? cookie,
    LegadoJsAjax? ajax,
  }) {
    return LegadoRuntimeContext(
      source: source,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      src: src ?? this.src,
      result: result ?? this.result,
      baseUrl: baseUrl ?? this.baseUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      nextChapterUrl: nextChapterUrl ?? this.nextChapterUrl,
      page: page ?? this.page,
      keyword: keyword ?? this.keyword,
      variables: variables ?? this.variables,
      cookie: cookie ?? this.cookie,
      ajax: ajax ?? this.ajax,
      trace: trace,
    );
  }

  LegadoJsContext toJsContext({
    Object? src,
    Object? result,
    String? baseUrl,
  }) {
    return LegadoJsContext(
      key: keyword,
      page: page,
      baseUrl: baseUrl ?? redirectUrl ?? this.baseUrl,
      src: src ?? this.src,
      result: result ?? this.result,
      source: source,
      book: book,
      chapter: chapter,
      nextChapterUrl: nextChapterUrl,
      variables: variables.asMap(),
      cookie: cookie,
      ajax: ajax,
      trace: trace,
    );
  }

  RuleContext toRuleContext({
    required RuleInput input,
    Object? book,
    String? cookie,
    LegadoJsAjax? ajax,
  }) {
    return RuleContext(
      source: source,
      input: input,
      keyword: keyword,
      page: page,
      book: book ?? this.book,
      runtimeVariables: variables,
      cookie: cookie ?? this.cookie,
      ajax: ajax ?? this.ajax,
      trace: trace,
    );
  }
}
