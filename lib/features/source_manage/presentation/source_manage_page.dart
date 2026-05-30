import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state_view.dart';

class SourceManagePage extends ConsumerWidget {
  const SourceManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.sources),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_rounded),
            onPressed: () {},
            tooltip: 'Import',
          ),
        ],
      ),
      body: EmptyStateView(
        icon: Symbols.rule_rounded,
        title: l.emptySources,
        action: FilledButton.icon(
          icon: const Icon(Symbols.cloud_download_rounded),
          label: const Text('导入书源'),
          onPressed: () {},
        ),
      ),
    );
  }
}
