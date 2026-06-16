import '../common/legado_trace.dart';

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

  Object? get(String key) => request[key];

  void put(String key, Object? value) {
    request[key] = value;
    trace?.add('runtime.variables.request.put:$key');
  }

  Map<String, Object?> asMap() => request;
}
