enum ReaderTurnMode {
  simulation('仿真'),
  cover('覆盖'),
  slide('滑动'),
  scroll('滚动'),
  noAnimation('无动画');

  const ReaderTurnMode(this.label);

  final String label;

  static ReaderTurnMode fromLabel(String label) {
    return switch (label) {
      '仿真' => ReaderTurnMode.simulation,
      '覆盖' => ReaderTurnMode.cover,
      '滑动' => ReaderTurnMode.slide,
      '滚动' => ReaderTurnMode.scroll,
      '无动画' => ReaderTurnMode.noAnimation,
      _ => ReaderTurnMode.slide,
    };
  }
}
