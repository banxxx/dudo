import 'package:flutter/widgets.dart';

abstract interface class ReaderTextMeasure {
  double measureHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  });
}

class FlutterReaderTextMeasure implements ReaderTextMeasure {
  const FlutterReaderTextMeasure();

  @override
  double measureHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    if (text.isEmpty || maxWidth <= 0) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }
}
