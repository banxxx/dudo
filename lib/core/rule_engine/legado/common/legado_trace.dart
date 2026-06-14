class LegadoTrace {
  LegadoTrace([List<String>? events]) : events = events ?? <String>[];

  final List<String> events;

  void add(String event) => events.add(event);
}
