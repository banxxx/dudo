class ReaderInsets {
  const ReaderInsets({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  const ReaderInsets.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const ReaderInsets.symmetric({
    double horizontal = 0,
    double vertical = 0,
  })  : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get horizontal => left + right;
  double get vertical => top + bottom;

  ReaderInsets copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return ReaderInsets(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderInsets &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}
