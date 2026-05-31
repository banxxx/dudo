import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state_view.dart';

class BookshelfLibraryPage extends ConsumerWidget {
  const BookshelfLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: Symbols.menu_book_rounded,
          title: l.emptyBookshelf,
          action: FilledButton.icon(
            icon: const Icon(Symbols.search_rounded),
            label: Text(l.search),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
