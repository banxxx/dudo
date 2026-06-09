import 'app_message.dart';

class AppMessageRegistry<T> {
  final Map<String, T> _active = <String, T>{};

  bool contains(String key) => _active.containsKey(key);

  T? operator [](String key) => _active[key];

  AppMessageRegistryDecision<T> prepare(AppMessageRequest request) {
    final key = request.effectiveKey;
    final existing = _active[key];
    if (existing == null) {
      return AppMessageRegistryDecision.show(key: key);
    }
    if (request.replaceExisting) {
      return AppMessageRegistryDecision.replace(key: key, existing: existing);
    }
    return AppMessageRegistryDecision.ignore(key: key, existing: existing);
  }

  void markShown(String key, T handle) {
    _active[key] = handle;
  }

  T? dismiss(String key) => _active.remove(key);

  bool dismissIfCurrent(String key, T handle) {
    if (!identical(_active[key], handle)) return false;
    _active.remove(key);
    return true;
  }

  Iterable<T> dismissAll() {
    final handles = List<T>.of(_active.values);
    _active.clear();
    return handles;
  }
}

class AppMessageRegistryDecision<T> {
  const AppMessageRegistryDecision._({
    required this.action,
    required this.key,
    this.existing,
  });

  const AppMessageRegistryDecision.show({required String key})
      : this._(action: AppMessageRegistryAction.show, key: key);

  const AppMessageRegistryDecision.ignore({
    required String key,
    required T existing,
  }) : this._(
          action: AppMessageRegistryAction.ignore,
          key: key,
          existing: existing,
        );

  const AppMessageRegistryDecision.replace({
    required String key,
    required T existing,
  }) : this._(
          action: AppMessageRegistryAction.replace,
          key: key,
          existing: existing,
        );

  final AppMessageRegistryAction action;
  final String key;
  final T? existing;
}

enum AppMessageRegistryAction {
  show,
  ignore,
  replace,
}
