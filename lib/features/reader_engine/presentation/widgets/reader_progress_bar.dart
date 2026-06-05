import 'package:flutter/material.dart';

import '../../application/reader_engine_state.dart';

class ReaderProgressBar extends StatelessWidget {
  const ReaderProgressBar({
    super.key,
    required this.state,
  });

  final ReaderSessionState state;

  @override
  Widget build(BuildContext context) {
    final document = state.document;
    final location = state.location;
    final progress = document == null ||
            location == null ||
            document.chapterCount <= 0
        ? 0.0
        : ((location.chapterIndex + 1) / document.chapterCount).clamp(0.0, 1.0);
    return LinearProgressIndicator(
      key: const ValueKey('reader-engine-progress'),
      minHeight: 2,
      value: progress,
      backgroundColor: Colors.black12,
      color: const Color(0xFF7A5B2E),
    );
  }
}
