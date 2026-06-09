import 'package:flutter/widgets.dart';

import '../../domain/reader_theme.dart';
import '../../layout/reader_line_layout_models.dart';
import '../widgets/reader_canvas_highlight.dart';
import '../widgets/reader_canvas_page.dart';

class ReaderLinePageSurface extends StatelessWidget {
  const ReaderLinePageSurface({
    super.key,
    required this.pageLayout,
    required this.palette,
    this.highlights = const [],
  });

  final ReaderPageLayout pageLayout;
  final ReaderPalette palette;
  final List<ReaderPageHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    return ReaderCanvasPage(
      pageLayout: pageLayout,
      palette: palette,
      highlights: highlights,
    );
  }
}
