import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_skeleton.dart';
import '../../../offline_cache/application/offline_cache_provider.dart';
import '../../../offline_cache/domain/offline_cache.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/storage_usage_provider.dart';
import '../domain/storage_usage.dart';

/// Shows what the app actually occupies on this device and lets the reader
/// reclaim the regenerable parts: image cache, TTS temp audio and the cached
/// chapter text stored inside the database. The database's records and the
/// imported fonts are reported but never deleted from here.
class StorageSettingsPage extends ConsumerStatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  ConsumerState<StorageSettingsPage> createState() =>
      _StorageSettingsPageState();
}

class _StorageSettingsPageState extends ConsumerState<StorageSettingsPage> {
  _ClearTarget? _clearing;

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(storageUsageProvider);
    final offlineAsync = ref.watch(offlineCacheProvider);
    final usage = usageAsync.valueOrNull;
    final offline = offlineAsync.valueOrNull;
    final offlineBytes = offline?.totalBytes ?? 0;
    final rows = usage == null
        ? const <_StorageRowData>[]
        : _rowsFor(
            usage,
            offline,
            () => context.push(AppRoutes.typographySettings),
          );

    return SettingsDetailScaffold(
      header: SettingsDetailHeader(
        eyebrow: '通用',
        title: '缓存与存储',
        actionIcon: LucideIcons.refreshCw,
        onActionTap: _refresh,
      ),
      children: [
        const SizedBox(height: 14),
        _StorageHero(
          usage: usage,
          offlineBytes: offlineBytes,
          loading: usageAsync.isLoading,
        ),
        const SizedBox(height: 14),
        const SettingsSectionTitle('占用明细'),
        const SizedBox(height: 8),
        if (usage == null)
          if (usageAsync.hasError)
            _UnavailableCard(onRetry: _refresh)
          else
            const _StorageRowsSkeleton()
        else
          for (final row in rows) ...[
            _StorageRow(
              row: row,
              clearing: _clearing == row.target,
              onClear:
                  _clearing == null ? () => _confirmClear(row.target!) : null,
              onTap: row.onTap,
            ),
            if (row != rows.last) const SizedBox(height: 9),
          ],
        const SizedBox(height: 12),
        Text(
          '清理只删除可再生成的缓存与已下载章节，书架、阅读进度、书签与设置都会保留。'
          '导入字体请在字体管理中管理。',
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(storageUsageProvider);
    ref.invalidate(offlineCacheProvider);
  }

  List<_StorageRowData> _rowsFor(
    StorageUsage usage,
    OfflineCache? offline,
    VoidCallback onOpenFonts,
  ) {
    final cover = usage.itemFor(StorageCategory.coverCache);
    final speech = usage.itemFor(StorageCategory.speechCache);
    final database = usage.itemFor(StorageCategory.database);
    final fonts = usage.itemFor(StorageCategory.fonts);
    final offlineBytes = offline?.totalBytes ?? 0;
    final databaseBytes = database?.bytes ?? 0;
    final recordBytes =
        (databaseBytes - offlineBytes).clamp(0, databaseBytes).toInt();

    return [
      if (cover != null)
        _StorageRowData(
          keyName: 'coverCache',
          icon: LucideIcons.image,
          title: cover.title,
          description: cover.description,
          bytes: cover.bytes,
          action: _RowAction.clear,
          target: _ClearTarget.coverCache,
        ),
      if (speech != null)
        _StorageRowData(
          keyName: 'speechCache',
          icon: LucideIcons.audioLines,
          title: speech.title,
          description: speech.description,
          bytes: speech.bytes,
          action: _RowAction.clear,
          target: _ClearTarget.speechCache,
        ),
      _StorageRowData(
        keyName: 'offlineChapters',
        icon: LucideIcons.download,
        title: '离线章节',
        description: '已下载的章节正文',
        bytes: offlineBytes,
        action: _RowAction.clear,
        target: _ClearTarget.offlineChapters,
      ),
      _StorageRowData(
        keyName: 'databaseRecords',
        icon: LucideIcons.database,
        title: '数据库记录',
        description: '书籍目录、书签与偏好设置',
        bytes: recordBytes,
      ),
      if (fonts != null)
        _StorageRowData(
          keyName: 'fonts',
          icon: LucideIcons.type,
          title: fonts.title,
          description: fonts.description,
          bytes: fonts.bytes,
          action: _RowAction.manage,
          onTap: onOpenFonts,
        ),
    ];
  }

  Future<void> _confirmClear(_ClearTarget target) async {
    final data = _dialogDataFor(target);
    if (data == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ClearCacheDialog(data: data),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = target);
    try {
      if (target == _ClearTarget.offlineChapters) {
        await ref.read(offlineCacheRepositoryProvider).clearAllAndCompact();
      } else {
        await ref.read(storageUsageRepositoryProvider).clearCache(
              target == _ClearTarget.coverCache
                  ? StorageCategory.coverCache
                  : StorageCategory.speechCache,
            );
      }
      if (!mounted) return;
      _refresh();
      ref.read(appMessageServiceProvider).success('已清理${data.title}');
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error('清理失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _clearing = null);
    }
  }

  _ClearDialogData? _dialogDataFor(_ClearTarget target) {
    final usage = ref.read(storageUsageProvider).valueOrNull;
    final offlineBytes =
        ref.read(offlineCacheProvider).valueOrNull?.totalBytes ?? 0;

    switch (target) {
      case _ClearTarget.coverCache:
        {
          final item = usage?.itemFor(StorageCategory.coverCache);
          if (item == null) return null;
          return _ClearDialogData(
            icon: LucideIcons.image,
            title: item.title,
            message: '将删除${item.description}，阅读进度与书签不受影响。',
            bytes: item.bytes,
          );
        }
      case _ClearTarget.speechCache:
        {
          final item = usage?.itemFor(StorageCategory.speechCache);
          if (item == null) return null;
          return _ClearDialogData(
            icon: LucideIcons.audioLines,
            title: item.title,
            message: '将删除${item.description}，阅读进度与书签不受影响。',
            bytes: item.bytes,
          );
        }
      case _ClearTarget.offlineChapters:
        return _ClearDialogData(
          icon: LucideIcons.download,
          title: '离线章节',
          message: '将删除已下载的章节正文，书架与阅读进度不受影响。',
          bytes: offlineBytes,
        );
    }
  }
}

enum _RowAction { clear, manage, none }

enum _ClearTarget { coverCache, speechCache, offlineChapters }

class _StorageRowData {
  const _StorageRowData({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.description,
    required this.bytes,
    this.action = _RowAction.none,
    this.target,
    this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String description;
  final int bytes;
  final _RowAction action;
  final _ClearTarget? target;
  final VoidCallback? onTap;
}

class _StorageHero extends StatelessWidget {
  const _StorageHero({
    required this.usage,
    required this.offlineBytes,
    required this.loading,
  });

  final StorageUsage? usage;
  final int offlineBytes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final usage = this.usage;
    final coverBytes = usage?.itemFor(StorageCategory.coverCache)?.bytes ?? 0;
    final speechBytes = usage?.itemFor(StorageCategory.speechCache)?.bytes ?? 0;
    final databaseBytes = usage?.itemFor(StorageCategory.database)?.bytes ?? 0;
    final fontBytes = usage?.itemFor(StorageCategory.fonts)?.bytes ?? 0;
    final totalText = usage == null
        ? (loading ? '计算中…' : '—')
        : formatStorageBytes(usage.totalBytes);
    final clearableBytes = coverBytes + speechBytes + offlineBytes;
    final segments = [
      _BarSegment(
        label: '封面',
        color: dark ? DudoColors.primary : DudoColors.primaryContainer,
        bytes: coverBytes,
      ),
      _BarSegment(
        label: '语音',
        color: DudoColors.accent,
        bytes: speechBytes,
      ),
      _BarSegment(
        label: '数据库',
        color: DudoColors.onInkMuted,
        bytes: databaseBytes,
      ),
      _BarSegment(
        label: '字体',
        color: dark
            ? DudoColors.primary.withValues(alpha: 0.55)
            : DudoColors.primaryContainerStrong,
        bytes: fontBytes,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2625251F),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本机存储占用',
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DudoColors.onInk.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.hardDrive,
                  color: DudoColors.onInk,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalText,
                style: DudoTextStyles.numeric(
                  color: DudoColors.onInk,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '已使用',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (usage != null)
                _ReclaimableChip(
                  text: '可清理 ${formatStorageBytes(clearableBytes)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          _StorageBar(segments: segments),
          const SizedBox(height: 14),
          _StorageLegend(segments: segments),
        ],
      ),
    );
  }
}

class _BarSegment {
  const _BarSegment({
    required this.label,
    required this.color,
    required this.bytes,
  });

  final String label;
  final Color color;
  final int bytes;
}

/// A single rounded track. The clip keeps the outer ends round while the
/// boundaries between segments stay square.
class _StorageBar extends StatelessWidget {
  const _StorageBar({required this.segments});

  final List<_BarSegment> segments;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((segment) => segment.bytes > 0).toList();
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.bytes);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (visible.isEmpty || total <= 0) {
              return ColoredBox(
                color: DudoColors.onInk.withValues(alpha: 0.10),
              );
            }
            final minWidth = (constraints.maxWidth / visible.length)
                .clamp(0.0, 6.0)
                .toDouble();
            final available = (constraints.maxWidth - minWidth * visible.length)
                .clamp(0.0, constraints.maxWidth)
                .toDouble();
            return Row(
              children: [
                for (final segment in visible)
                  SizedBox(
                    width: minWidth + available * segment.bytes / total,
                    height: 9,
                    child: ColoredBox(color: segment.color),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StorageLegend extends StatelessWidget {
  const _StorageLegend({required this.segments});

  final List<_BarSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final segment in segments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: segment.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                segment.label,
                style: DudoTextStyles.sans(
                  color: DudoColors.onInkMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReclaimableChip extends StatelessWidget {
  const _ReclaimableChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DudoColors.onInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DudoColors.onInk.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: DudoTextStyles.sans(
          color: DudoColors.isDark
              ? DudoColors.primaryDark
              : DudoColors.primaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.row,
    required this.clearing,
    required this.onClear,
    required this.onTap,
  });

  final _StorageRowData row;
  final bool clearing;
  final VoidCallback? onClear;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clearable = row.action == _RowAction.clear;
    final iconFill =
        clearable ? DudoColors.primaryContainer : DudoColors.surfaceLow;
    final tint = clearable ? DudoColors.primary : DudoColors.secondary;
    final canClear = clearable && row.bytes > 0;
    final hasAction = canClear || row.action == _RowAction.manage;

    final content = Container(
      key: ValueKey('storage-row-${row.keyName}'),
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(row.icon, color: tint, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              formatStorageBytes(row.bytes),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: DudoTextStyles.numeric(
                color: clearable ? DudoColors.primary : DudoColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 28,
              child: canClear
                  ? _StoragePill(
                      key: ValueKey('storage-clear-${row.keyName}'),
                      label: clearing ? '清理中' : '清理',
                      fill: DudoColors.primaryContainer,
                      foreground: DudoColors.primary,
                      onTap: clearing ? null : onClear,
                    )
                  : _StoragePill(
                      label: '管理',
                      fill: DudoColors.surfaceLow,
                      foreground: DudoColors.secondary,
                    ),
            ),
          ],
        ],
      ),
    );

    final tap = onTap;
    if (tap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}

class _StoragePill extends StatelessWidget {
  const _StoragePill({
    super.key,
    required this.label,
    required this.fill,
    required this.foreground,
    this.onTap,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: DudoTextStyles.sans(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final tap = onTap;
    if (tap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class _StorageRowsSkeleton extends StatelessWidget {
  const _StorageRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          const DudoSkeletonCard(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            radius: 20,
            child: Row(
              children: [
                DudoSkeletonBox(width: 40, height: 40, shape: BoxShape.circle),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DudoSkeletonLine(widthFactor: 0.35, height: 12),
                      SizedBox(height: 7),
                      DudoSkeletonLine(widthFactor: 0.62, height: 9),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                DudoSkeletonBox(width: 52, height: 11, radius: 5),
                SizedBox(width: 8),
                DudoSkeletonBox(width: 44, height: 28, radius: 14),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.onRetry});

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
            LucideIcons.triangleAlert,
            color: DudoColors.secondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '无法读取存储信息',
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
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

class _ClearDialogData {
  const _ClearDialogData({
    required this.icon,
    required this.title,
    required this.message,
    required this.bytes,
  });

  final IconData icon;
  final String title;
  final String message;
  final int bytes;
}

class _ClearCacheDialog extends StatelessWidget {
  const _ClearCacheDialog({required this.data});

  final _ClearDialogData data;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
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
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DudoColors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                data.icon,
                color: DudoColors.primary,
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '清理${data.title}？',
              textAlign: TextAlign.center,
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.message,
              textAlign: TextAlign.center,
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: DudoColors.surfaceLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '预计释放',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    formatStorageBytes(data.bytes),
                    style: DudoTextStyles.numeric(
                      color: DudoColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '取消',
                    fill: DudoColors.surfaceLow,
                    foreground: DudoColors.secondary,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    key: const ValueKey('storage-clear-confirm'),
                    label: '清理',
                    fill: DudoColors.primary,
                    foreground: dark ? DudoColors.ink : DudoColors.onInk,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    super.key,
    required this.label,
    required this.fill,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Text(
              label,
              style: DudoTextStyles.sans(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
