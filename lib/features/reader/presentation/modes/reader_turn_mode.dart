enum ReaderTurnMode {
  simulation('仿真'),
  slide('滑动'),
  scroll('滚动');

  const ReaderTurnMode(this.label);

  final String label;

  static ReaderTurnMode fromLabel(String label) {
    return switch (label) {
      '仿真' => ReaderTurnMode.simulation,
      '滚动' => ReaderTurnMode.scroll,
      _ => ReaderTurnMode.slide,
    };
  }
}
