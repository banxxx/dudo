import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../features/sources/application/source_providers.dart';
import '../../../../shared/messages/app_message.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

const _sourceManageMessageKey = 'source-manage-actions';
const _sourcePageSize = 100;

class SourceManageSettingsPage extends ConsumerStatefulWidget {
  const SourceManageSettingsPage({super.key});

  @override
  ConsumerState<SourceManageSettingsPage> createState() =>
      _SourceManageSettingsPageState();
}

class _SourceManageSettingsPageState
    extends ConsumerState<SourceManageSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _visibleCount = _sourcePageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSourceAddPage(BuildContext context) async {
    final imported = await context.push<bool>(AppRoutes.sourceAdd);
    if (imported == true) {
      ref.invalidate(sourcesProvider);
    }
  }

  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value.trim();
      _visibleCount = _sourcePageSize;
    });
  }

  void _loadMoreSources() {
    setState(() => _visibleCount += _sourcePageSize);
  }

  @override
  Widget build(BuildContext context) {
    final sourcesValue = ref.watch(sourcesProvider);

    return SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '内容与书源',
          title: '书源管理',
          actionIcon: LucideIcons.plus,
          onActionTap: () => _openSourceAddPage(context),
        ),
        const SizedBox(height: 14),
        sourcesValue.when(
          loading: () => const _SourceSummary.loading(),
          error: (_, __) => const _SourceSummary.error(),
          data: (sources) => _SourceSummary(
            totalCount: sources.length,
            enabledCount: sources.where((source) => source.enabled).length,
          ),
        ),
        const SizedBox(height: 14),
        _SourceQuickActions(ref: ref),
        const SizedBox(height: 14),
        sourcesValue.when(
          loading: () => const _LoadingSourcesCard(),
          error: (error, _) => _SourceErrorCard(
            onRetry: () => ref.invalidate(sourcesProvider),
          ),
          data: (sources) => _SourceListSection(
            sources: sources,
            query: _searchQuery,
            visibleCount: _visibleCount,
            searchController: _searchController,
            onSearchChanged: _updateSearchQuery,
            onLoadMore: _loadMoreSources,
          ),
        ),
      ],
    );
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({
    required this.totalCount,
    required this.enabledCount,
  }) : message = null;

  const _SourceSummary.loading()
      : totalCount = 0,
        enabledCount = 0,
        message = '正在读取已导入书源...';

  const _SourceSummary.error()
      : totalCount = 0,
        enabledCount = 0,
        message = '书源列表读取失败，请稍后重试。';

  final int totalCount;
  final int enabledCount;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final description = message ??
        (totalCount == 0
            ? '还没有导入在线书源，可从 Legado JSON 规则文件开始。'
            : '共导入 $totalCount 个书源，当前支持本地规则管理；在线搜索、目录解析和阅读会后续接入。');

    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.rss, color: DudoColors.primary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$enabledCount 个书源已启用',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceQuickActions extends StatelessWidget {
  const _SourceQuickActions({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.plus,
              label: '添加书源',
              selected: true,
              onTap: () => context.push(AppRoutes.sourceAdd),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.refreshCw,
              label: '同步更新',
              onTap: () => _showComingSoon(ref, '同步更新'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.wrench,
              label: '修复失效',
              onTap: () => _showComingSoon(ref, '规则诊断'),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(WidgetRef ref, String feature) {
    ref.read(appMessageServiceProvider).info(
          '$feature 稍后支持，当前版本先支持 Legado 规则文件导入和管理。',
          title: '功能建设中',
          dedupeKey: _sourceManageMessageKey,
          visualStyle: AppMessageVisualStyle.paper,
        );
  }
}

class _SourceListSection extends StatelessWidget {
  const _SourceListSection({
    required this.sources,
    required this.query,
    required this.visibleCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onLoadMore,
  });

  final List<Source> sources;
  final String query;
  final int visibleCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.rss,
        title: '还没有书源',
        message: '先导入 Legado JSON 规则文件，后续可继续接入 dudo 自有书源格式。',
      );
    }

    final filteredSources = _filterSources(sources, query);
    final visibleSources = filteredSources.take(visibleCount).toList();
    final hiddenCount = filteredSources.length - visibleSources.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SourceSearchField(
          controller: searchController,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        SettingsSectionTitle(
          query.isEmpty
              ? '书源列表 · ${sources.length} 个'
              : '搜索结果 · ${filteredSources.length} / ${sources.length} 个',
        ),
        const SizedBox(height: 8),
        if (filteredSources.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.searchX,
            title: '没有匹配的书源',
            message: '试试搜索书源名称、分组或 URL。',
          )
        else ...[
          for (var i = 0; i < visibleSources.length; i++) ...[
            _SourceRow.fromSource(visibleSources[i]),
            if (i != visibleSources.length - 1) const SizedBox(height: 8),
          ],
          if (hiddenCount > 0) ...[
            const SizedBox(height: 12),
            _LoadMoreSourcesButton(
              hiddenCount: hiddenCount,
              onTap: onLoadMore,
            ),
          ],
        ],
      ],
    );
  }

  List<Source> _filterSources(List<Source> sources, String query) {
    if (query.isEmpty) return sources;
    final keyword = query.toLowerCase();
    return sources.where((source) {
      return source.name.toLowerCase().contains(keyword) ||
          source.url.toLowerCase().contains(keyword) ||
          (source.groupName?.toLowerCase().contains(keyword) ?? false) ||
          (source.comment?.toLowerCase().contains(keyword) ?? false);
    }).toList(growable: false);
  }
}

class _SourceSearchField extends StatelessWidget {
  const _SourceSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索书源名称、分组或 URL',
        prefixIcon: const Icon(LucideIcons.search, size: 18),
        filled: true,
        fillColor: DudoColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DudoColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DudoColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DudoColors.primary),
        ),
      ),
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 13,
      ),
    );
  }
}

class _LoadMoreSourcesButton extends StatelessWidget {
  const _LoadMoreSourcesButton({
    required this.hiddenCount,
    required this.onTap,
  });

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Text(
            '还有 $hiddenCount 个书源，加载更多',
            style: DudoTextStyles.sans(
              color: DudoColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSourcesCard extends StatelessWidget {
  const _LoadingSourcesCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SourceErrorCard extends StatelessWidget {
  const _SourceErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, color: DudoColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '书源列表读取失败',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DudoColors.surfaceHigh : DudoColors.secondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                selected ? null : Border.all(color: DudoColors.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 5),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.name,
    required this.description,
    required this.state,
    required this.stateColor,
    required this.dotColor,
    required this.dotFill,
  });

  factory _SourceRow.fromSource(Source source) {
    final descriptionParts = <String>[
      if (source.groupName != null && source.groupName!.trim().isNotEmpty)
        source.groupName!.trim(),
      if (source.comment != null && source.comment!.trim().isNotEmpty)
        source.comment!.trim(),
      source.url,
    ];

    return _SourceRow(
      name: source.name,
      description: descriptionParts.join(' · '),
      state: source.enabled ? '启用中' : '已停用',
      stateColor: source.enabled ? DudoColors.primary : DudoColors.secondary,
      dotColor: source.enabled ? DudoColors.primary : DudoColors.secondary,
      dotFill:
          source.enabled ? DudoColors.primaryContainer : DudoColors.surfaceLow,
    );
  }

  final String name;
  final String description;
  final String state;
  final Color stateColor;
  final Color dotColor;
  final Color dotFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dotFill,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            state,
            style: DudoTextStyles.sans(
              color: stateColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
