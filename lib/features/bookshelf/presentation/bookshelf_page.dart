import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state_view.dart';

class BookshelfPage extends ConsumerWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.bookshelf),
        actions: [
          IconButton(
            icon: const Icon(Symbols.grid_view_rounded),
            onPressed: () {},
            tooltip: 'View mode',
          ),
          IconButton(
            icon: const Icon(Symbols.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: EmptyStateView(
        icon: Symbols.library_books_rounded,
        title: l.emptyBookshelf,
      ),
    );
  }
}
