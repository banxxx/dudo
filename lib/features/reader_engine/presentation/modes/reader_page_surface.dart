import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_settings.dart';
import '../widgets/reader_text_layer.dart';
import 'reader_paged_window.dart';

class ReaderPageSurface extends StatelessWidget {
  const ReaderPageSurface({
    super.key,
    required this.resolvedPage,
    required this.settings,
    required this.palette,
  });

  final ReaderResolvedPage resolvedPage;
  final ReaderSettings settings;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        settings.pagePadding.left,
        settings.pagePadding.top,
        settings.pagePadding.right,
        settings.pagePadding.bottom,
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ReaderTextLayer(
            blocks: resolvedPage.page.blocks,
            settings: settings,
            palette: palette,
          ),
        ),
      ),
    );
  }
}
