import '../common/legado_trace.dart';

/// Legado 变量作用域定义。
///
/// - request：同一次规则执行内共享，当前已实现，随运行时上下文释放。
/// - chapter：章节级变量，后续应绑定在线章节记录或章节扩展 JSON。
/// - book：书籍级变量，后续应绑定在线书籍记录或书籍扩展 JSON。
/// - source：书源级变量，后续应绑定书源配置或独立持久化表。
enum LegadoRuntimeVariableScope {
  request,
  chapter,
  book,
  source,
}

/// Legado 在线运行时变量容器。
///
/// 当前只实现请求级内存变量，满足同一次规则执行内 `java.put/java.get`
/// 和 `cache.put/cache.get` 共享数据。书籍级、章节级、书源级持久化后续再接入。
class LegadoRuntimeVariables {
  LegadoRuntimeVariables({
    Map<String, Object?>? request,
    this.trace,
  }) : request = request ?? <String, Object?>{};

  final Map<String, Object?> request;
  final LegadoTrace? trace;

  static const supportedScope = LegadoRuntimeVariableScope.request;
  static const persistentScopes = <LegadoRuntimeVariableScope>[
    LegadoRuntimeVariableScope.chapter,
    LegadoRuntimeVariableScope.book,
    LegadoRuntimeVariableScope.source,
  ];

  Object? get(String key) => request[key];

  void put(String key, Object? value) {
    request[key] = value;
    trace?.add('runtime.variables.request.put:$key');
  }

  Map<String, Object?> asMap() => request;
}
