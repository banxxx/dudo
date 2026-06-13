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
const _dangerFill = Color(0xFFF4DDD2);
const _dangerText = Color(0xFFA8553A);

class SourceManageSettingsPage extends ConsumerStatefulWidget {
  const SourceManageSettingsPage({super.key});

  @override
  ConsumerState<SourceManageSettingsPage> createState() =>
      _SourceManageSettingsPageState();
}

class _SourceManageSettingsPageState
    extends ConsumerState<SourceManageSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedSourceIds = <String>{};
  String _searchQuery = '';
  int _visibleCount = _sourcePageSize;
  bool _isManageMode = false;

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

  void _toggleManageMode() {
    setState(() {
      _isManageMode = !_isManageMode;
      if (!_isManageMode) {
        _selectedSourceIds.clear();
      }
    });
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

  void _toggleSourceSelected(String sourceId) {
    setState(() {
      if (_selectedSourceIds.contains(sourceId)) {
        _selectedSourceIds.remove(sourceId);
      } else {
        _selectedSourceIds.add(sourceId);
      }
    });
  }

  void _toggleAllFilteredSources(List<Source> filteredSources) {
    if (filteredSources.isEmpty) return;
    final filteredIds = filteredSources.map((source) => source.id).toSet();
    final allFilteredSelected = filteredIds.every(_selectedSourceIds.contains);
    setState(() {
      if (allFilteredSelected) {
        _selectedSourceIds.removeAll(filteredIds);
      } else {
        _selectedSourceIds.addAll(filteredIds);
      }
    });
  }

  Future<void> _enableSource(Source source) async {
    if (source.enabled) return;
    try {
      await ref
          .read(sourceRepositoryProvider)
          .setSourceEnabled(source.id, true);
      if (!mounted) return;
      setState(() => _selectedSourceIds.remove(source.id));
      ref.read(appMessageServiceProvider).success(
            '已启用“${source.name}”',
            title: '书源已启用',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '启用失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<void> _enableSelectedSources(List<Source> sources) async {
    final selectedDisabledSources = sources
        .where(
          (source) => _selectedSourceIds.contains(source.id) && !source.enabled,
        )
        .toList(growable: false);
    if (selectedDisabledSources.isEmpty) return;

    try {
      await ref.read(sourceRepositoryProvider).setSourcesEnabled(
            selectedDisabledSources.map((source) => source.id),
            true,
          );
      if (!mounted) return;
      setState(() {
        for (final source in selectedDisabledSources) {
          _selectedSourceIds.remove(source.id);
        }
      });
      ref.read(appMessageServiceProvider).success(
            '已启用 ${selectedDisabledSources.length} 个书源',
            title: '批量启用完成',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '批量启用失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<void> _disableSelectedSources(List<Source> sources) async {
    final selectedEnabledSources = sources
        .where(
          (source) => _selectedSourceIds.contains(source.id) && source.enabled,
        )
        .toList(growable: false);
    if (selectedEnabledSources.isEmpty) return;

    try {
      await ref.read(sourceRepositoryProvider).setSourcesEnabled(
            selectedEnabledSources.map((source) => source.id),
            false,
          );
      if (!mounted) return;
      setState(() {
        for (final source in selectedEnabledSources) {
          _selectedSourceIds.remove(source.id);
        }
      });
      ref.read(appMessageServiceProvider).success(
            '已禁用 ${selectedEnabledSources.length} 个书源',
            title: '批量禁用完成',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '批量禁用失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<void> _confirmDeleteSource(Source source) async {
    final confirmed = await _showDeleteConfirmation(
      title: '删除书源？',
      message: '将删除“${source.name}”，此操作不可撤销。',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(sourceRepositoryProvider).deleteSource(source.id);
      if (!mounted) return;
      setState(() => _selectedSourceIds.remove(source.id));
      ref.read(appMessageServiceProvider).success(
            '已删除“${source.name}”',
            title: '书源已删除',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '删除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<void> _confirmDeleteSelectedSources(List<Source> sources) async {
    final selectedSources = sources
        .where((source) => _selectedSourceIds.contains(source.id))
        .toList(growable: false);
    if (selectedSources.isEmpty) return;

    final confirmed = await _showDeleteConfirmation(
      title: '删除选中的书源？',
      message: '将删除 ${selectedSources.length} 个书源，此操作不可撤销。',
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(sourceRepositoryProvider).deleteSources(
            selectedSources.map((source) => source.id),
          );
      if (!mounted) return;
      setState(() {
        for (final source in selectedSources) {
          _selectedSourceIds.remove(source.id);
        }
      });
      ref.read(appMessageServiceProvider).success(
            '已删除 ${selectedSources.length} 个书源',
            title: '批量删除完成',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '批量删除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _sourceManageMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<bool?> _showDeleteConfirmation({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DudoColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesValue = ref.watch(sourcesProvider);

    return SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '内容与书源',
          title: '书源管理',
          actionIcon: LucideIcons.slidersHorizontal,
          onActionTap: _toggleManageMode,
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
        _SourceQuickActions(
          ref: ref,
          onAddSource: () => _openSourceAddPage(context),
        ),
        const SizedBox(height: 14),
        sourcesValue.when(
          loading: () => const _LoadingSourcesCard(),
          error: (error, _) => _SourceErrorCard(
            onRetry: () => ref.invalidate(sourcesProvider),
          ),
          data: (sources) {
            final filteredSources = _filterSources(sources, _searchQuery);
            final selectedFilteredCount = filteredSources
                .where((source) => _selectedSourceIds.contains(source.id))
                .length;
            final allFilteredSelected = filteredSources.isNotEmpty &&
                selectedFilteredCount == filteredSources.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isManageMode) ...[
                  _SourceManagementBar(
                    selectedCount: selectedFilteredCount,
                    totalCount: filteredSources.length,
                    allSelected: allFilteredSelected,
                    onSelectAll: () =>
                        _toggleAllFilteredSources(filteredSources),
                    onEnableSelected: () => _enableSelectedSources(sources),
                    onDisableSelected: () => _disableSelectedSources(sources),
                    onDeleteSelected: () =>
                        _confirmDeleteSelectedSources(sources),
                  ),
                  const SizedBox(height: 14),
                ],
                _SourceListSection(
                  sources: sources,
                  filteredSources: filteredSources,
                  query: _searchQuery,
                  visibleCount: _visibleCount,
                  searchController: _searchController,
                  isManageMode: _isManageMode,
                  selectedSourceIds: _selectedSourceIds,
                  onSearchChanged: _updateSearchQuery,
                  onLoadMore: _loadMoreSources,
                  onToggleSelected: _toggleSourceSelected,
                  onEnableSource: _enableSource,
                  onDeleteSource: _confirmDeleteSource,
                ),
              ],
            );
          },
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
    final disabledCount = (totalCount - enabledCount).clamp(0, totalCount);
    final title = message == null
        ? disabledCount > 0
            ? '$disabledCount 个书源待启用'
            : totalCount == 0
                ? '还没有书源'
                : '全部书源已启用'
        : '$enabledCount 个书源已启用';
    final description = message ??
        (totalCount == 0
            ? '先导入 Legado JSON 规则文件，再进入管理模式启用或删除。'
            : disabledCount > 0
                ? '启用后才会参与搜索与章节更新，可通过右上角进入管理模式。'
                : '共导入 $totalCount 个书源，可进入管理模式查看或删除。');

    return Container(
      height: 108,
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
                  title,
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
  const _SourceQuickActions({required this.ref, required this.onAddSource});

  final WidgetRef ref;
  final VoidCallback onAddSource;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.plus,
              label: '添加书源',
              selected: true,
              onTap: onAddSource,
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

class _SourceManagementBar extends StatelessWidget {
  const _SourceManagementBar({
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.onSelectAll,
    required this.onEnableSelected,
    required this.onDisableSelected,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onEnableSelected;
  final VoidCallback onDisableSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SourceSelectionBox(selected: allSelected),
                        const SizedBox(width: 7),
                        Text(
                          '全选',
                          style: DudoTextStyles.sans(
                            color: DudoColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                '已选 $selectedCount/$totalCount',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              _BulkActionButton(
                icon: LucideIcons.check,
                label: '批量启用',
                enabled: hasSelection,
                fill: DudoColors.primaryContainer,
                color: DudoColors.primary,
                onTap: onEnableSelected,
              ),
              _BulkActionButton(
                icon: LucideIcons.ban,
                label: '批量禁用',
                enabled: hasSelection,
                fill: DudoColors.surfaceLow,
                color: DudoColors.secondaryDark,
                onTap: onDisableSelected,
              ),
              _BulkActionButton(
                icon: LucideIcons.trash2,
                label: '批量删除',
                enabled: hasSelection,
                fill: _dangerFill,
                color: _dangerText,
                onTap: onDeleteSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.fill,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final Color fill;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : DudoColors.secondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: enabled ? fill : DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: effectiveColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: effectiveColor,
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

class _SourceListSection extends StatelessWidget {
  const _SourceListSection({
    required this.sources,
    required this.filteredSources,
    required this.query,
    required this.visibleCount,
    required this.searchController,
    required this.isManageMode,
    required this.selectedSourceIds,
    required this.onSearchChanged,
    required this.onLoadMore,
    required this.onToggleSelected,
    required this.onEnableSource,
    required this.onDeleteSource,
  });

  final List<Source> sources;
  final List<Source> filteredSources;
  final String query;
  final int visibleCount;
  final TextEditingController searchController;
  final bool isManageMode;
  final Set<String> selectedSourceIds;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onToggleSelected;
  final ValueChanged<Source> onEnableSource;
  final ValueChanged<Source> onDeleteSource;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.rss,
        title: '还没有书源',
        message: '先导入 Legado JSON 规则文件，后续可继续接入 dudo 自有书源格式。',
      );
    }

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
        _SourceListHeader(
          query: query,
          totalCount: sources.length,
          filteredCount: filteredSources.length,
          isManageMode: isManageMode,
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
            _SourceRow.fromSource(
              visibleSources[i],
              isManageMode: isManageMode,
              selected: selectedSourceIds.contains(visibleSources[i].id),
              onToggleSelected: () => onToggleSelected(visibleSources[i].id),
              onEnable: () => onEnableSource(visibleSources[i]),
              onDelete: () => onDeleteSource(visibleSources[i]),
            ),
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
}

class _SourceListHeader extends StatelessWidget {
  const _SourceListHeader({
    required this.query,
    required this.totalCount,
    required this.filteredCount,
    required this.isManageMode,
  });

  final String query;
  final int totalCount;
  final int filteredCount;
  final bool isManageMode;

  @override
  Widget build(BuildContext context) {
    final title = query.isEmpty
        ? '书源列表 · $totalCount 个'
        : '搜索结果 · $filteredCount / $totalCount 个';

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isManageMode)
          Text(
            '管理模式 · 可启用、禁用或删除',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
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
              Icon(icon, color: color, size: 17),
              const SizedBox(height: 4),
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
    required this.source,
    required this.description,
    required this.isManageMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onEnable,
    required this.onDelete,
  });

  factory _SourceRow.fromSource(
    Source source, {
    required bool isManageMode,
    required bool selected,
    required VoidCallback onToggleSelected,
    required VoidCallback onEnable,
    required VoidCallback onDelete,
  }) {
    final descriptionParts = <String>[
      if (source.groupName != null && source.groupName!.trim().isNotEmpty)
        source.groupName!.trim(),
      if (source.comment != null && source.comment!.trim().isNotEmpty)
        source.comment!.trim(),
      source.url,
    ];

    return _SourceRow(
      source: source,
      description: descriptionParts.join(' · '),
      isManageMode: isManageMode,
      selected: selected,
      onToggleSelected: onToggleSelected,
      onEnable: onEnable,
      onDelete: onDelete,
    );
  }

  final Source source;
  final String description;
  final bool isManageMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEnable;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dotColor = source.enabled ? DudoColors.primary : DudoColors.secondary;
    final dotFill =
        source.enabled ? DudoColors.primaryContainer : DudoColors.surfaceLow;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isManageMode ? onToggleSelected : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            children: [
              if (isManageMode) ...[
                _SourceSelectionBox(selected: selected),
                const SizedBox(width: 8),
              ],
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: dotFill,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.name,
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
              const SizedBox(width: 8),
              if (isManageMode) ...[
                _ActionPill(
                  icon: source.enabled ? LucideIcons.check : LucideIcons.power,
                  label: source.enabled ? '已启用' : '启用',
                  fill: source.enabled
                      ? DudoColors.primaryContainer
                      : DudoColors.textPrimary,
                  color: source.enabled
                      ? DudoColors.primary
                      : DudoColors.surfaceHigh,
                  onTap: source.enabled ? null : onEnable,
                ),
                const SizedBox(width: 5),
                _ActionPill(
                  icon: LucideIcons.trash2,
                  label: '删除',
                  fill: _dangerFill,
                  color: _dangerText,
                  onTap: onDelete,
                ),
              ] else
                Text(
                  source.enabled ? '启用中' : '已停用',
                  style: DudoTextStyles.sans(
                    color: source.enabled
                        ? DudoColors.primary
                        : DudoColors.secondary,
                    fontSize: 12,
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

class _SourceSelectionBox extends StatelessWidget {
  const _SourceSelectionBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? DudoColors.primary : DudoColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? DudoColors.primary : DudoColors.outline,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(LucideIcons.check,
              color: DudoColors.surfaceHigh, size: 13)
          : null,
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.fill,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
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
