class LegadoTrace {
  LegadoTrace([List<String>? events]) : events = events ?? <String>[];

  final List<String> events;

  void add(String event) => events.add(event);
}

class LegadoRuntimeException implements Exception {
  const LegadoRuntimeException(
    this.message, {
    this.stage,
    this.cause,
    this.trace,
  });

  final String message;
  final String? stage;
  final Object? cause;
  final LegadoTrace? trace;

  @override
  String toString() {
    final prefix = stage == null ? 'LegadoRuntimeException' : '[$stage]';
    final causeText = cause == null ? '' : ': $cause';
    return '$prefix $message$causeText';
  }
}
