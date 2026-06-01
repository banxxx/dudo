import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
            icon: const Icon(LucideIcons.plus),
            onPressed: () {},
            tooltip: 'Import',
          ),
        ],
      ),
      body: EmptyStateView(
        icon: LucideIcons.listChecks,
        title: l.emptySources,
        action: FilledButton.icon(
          icon: const Icon(LucideIcons.cloudDownload),
          label: const Text('导入书源'),
          onPressed: () {},
        ),
      ),
    );
  }
}
