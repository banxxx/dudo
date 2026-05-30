import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state_view.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                controller: _controller,
                hintText: l.emptySearch,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Symbols.search_rounded),
                ),
                trailing: [
                  IconButton(
                    icon: const Icon(Symbols.tune_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmptyStateView(
                icon: Symbols.travel_explore_rounded,
                title: l.emptySearch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
