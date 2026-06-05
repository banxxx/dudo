import 'package:flutter/material.dart';

import '../application/reader_engine_state.dart';
import '../domain/reader_turn_mode.dart';
import 'widgets/reader_progress_bar.dart';

class ReaderChrome extends StatelessWidget {
  const ReaderChrome({
    super.key,
    required this.state,
    required this.onBack,
    required this.onCatalog,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onTurnModeChanged,
  });

  final ReaderSessionState state;
  final VoidCallback onBack;
  final VoidCallback onCatalog;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final ValueChanged<ReaderTurnMode> onTurnModeChanged;

  @override
  Widget build(BuildContext context) {
    final title = state.document?.title ?? '';
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Column(
          children: [
            Material(
              color: const Color(0xCCFBF6EA),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '返回',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: '目录',
                      onPressed: onCatalog,
                      icon: const Icon(Icons.menu_book_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ReaderProgressBar(state: state),
            Material(
              color: const Color(0xCCFBF6EA),
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: '上一章',
                      onPressed: onPreviousChapter,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    SegmentedButton<ReaderTurnMode>(
                      segments: const [
                        ButtonSegment(
                          value: ReaderTurnMode.paged,
                          icon: Icon(Icons.view_agenda_outlined),
                        ),
                        ButtonSegment(
                          value: ReaderTurnMode.scroll,
                          icon: Icon(Icons.swap_vert),
                        ),
                      ],
                      selected: {state.settings.turnMode},
                      onSelectionChanged: (selection) {
                        onTurnModeChanged(selection.single);
                      },
                    ),
                    IconButton(
                      tooltip: '下一章',
                      onPressed: onNextChapter,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
