import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/storage_usage_provider.dart';
import '../domain/storage_usage.dart';

/// Shows what the app actually occupies on this device and lets the reader
/// reclaim the regenerable parts (image cache, TTS temp audio). The database
/// and imported fonts are reported but never deleted from here.
class StorageSettingsPage extends ConsumerStatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  ConsumerState<StorageSettingsPage> createState() =>
      _StorageSettingsPageState();
}

class _StorageSettingsPageState extends ConsumerState<StorageSettingsPage> {
  StorageCategory? _clearing;

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(storageUsageProvider);
    final usage = usageAsync.valueOrNull;

    return SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '通用',
          title: '缓存与存储',
          actionIcon: LucideIcons.refreshCw,
          onActionTap: () => ref.invalidate(storageUsageProvider),
        ),
        const SizedBox(height: 14),
        _StorageHero(usage: usage, loading: usageAsync.isLoading),
        const SizedBox(height: 14),
        const SettingsSectionTitle('占用明细'),
        const SizedBox(height: 8),
        if (usage == null)
          _UnavailableCard(
            failed: usageAsync.hasError,
            onRetry: () => ref.invalidate(storageUsageProvider),
          )
        else
          for (final item in usage.items) ...[
            _UsageRow(
              item: item,
              clearing: _clearing == item.category,
              onClear: () => _confirmClear(item),
              onTap: item.category == StorageCategory.fonts
                  ? () => context.push(AppRoutes.typographySettings)
                  : null,
            ),
            if (item != usage.items.last) const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        Text(
          '清理只删除可再生成的缓存，书架、阅读进度、书签与设置都会保留。'
          '阅读数据库与导入字体请在各自页面管理。',
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(StorageUsageItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ClearCacheDialog(item: item),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = item.category);
    try {
      await ref.read(storageUsageRepositoryProvider).clearCache(item.category);
      if (!mounted) return;
      ref.invalidate(storageUsageProvider);
      ref.read(appMessageServiceProvider).success('已清理${item.title}');
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error('清理失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _clearing = null);
    }
  }
}

class _StorageHero extends StatelessWidget {
  const _StorageHero({required this.usage, required this.loading});

  final StorageUsage? usage;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final usage = this.usage;
    final total = usage == null
        ? (loading ? '计算中…' : '—')
        : formatStorageBytes(usage.totalBytes);

    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2225251F),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本机存储占用',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.onInk,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '封面、语音、数据库与字体',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DudoColors.onInk.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.hardDrive,
              color: DudoColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.item,
    required this.clearing,
    required this.onClear,
    this.onTap,
  });

  final StorageUsageItem item;
  final bool clearing;
  final VoidCallback onClear;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canClear = item.clearable && item.bytes > 0;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.clearable
                  ? DudoColors.primaryContainer
                  : DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              _iconFor(item.category),
              color: item.clearable ? DudoColors.primary : DudoColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
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
            formatStorageBytes(item.bytes),
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canClear) ...[
            const SizedBox(width: 6),
            TextButton(
              key: ValueKey('storage-clear-${item.category.name}'),
              onPressed: clearing ? null : onClear,
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.primary,
                minimumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: DudoTextStyles.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(clearing ? '清理中' : '清理'),
            ),
          ] else if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              color: DudoColors.secondary,
              size: 16,
            ),
          ],
        ],
      ),
    );

    final tap = onTap;
    if (tap == null) return row;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(20),
        child: row,
      ),
    );
  }

  IconData _iconFor(StorageCategory category) {
    switch (category) {
      case StorageCategory.coverCache:
        return LucideIcons.image;
      case StorageCategory.speechCache:
        return LucideIcons.audioLines;
      case StorageCategory.database:
        return LucideIcons.database;
      case StorageCategory.fonts:
        return LucideIcons.type;
    }
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            failed ? LucideIcons.triangleAlert : LucideIcons.loaderCircle,
            color: DudoColors.secondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              failed ? '无法读取存储信息' : '正在统计占用…',
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (failed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.primary,
                textStyle: DudoTextStyles.sans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

class _ClearCacheDialog extends StatelessWidget {
  const _ClearCacheDialog({required this.item});

  final StorageUsageItem item;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DudoColors.surfaceHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dark
                ? DudoColors.outline
                : Colors.white.withValues(alpha: 0.68),
          ),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x66000000) : const Color(0x2625251F),
              offset: const Offset(0, 14),
              blurRadius: 34,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '清理${item.title}？',
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '将删除${item.description}，可释放 '
              '${formatStorageBytes(item.bytes)}。'
              '阅读进度与书签不受影响。',
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: DudoColors.secondary,
                    textStyle: DudoTextStyles.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('storage-clear-confirm'),
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: DudoColors.textPrimary,
                    foregroundColor: DudoColors.surfaceHigh,
                    textStyle: DudoTextStyles.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('清理'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
