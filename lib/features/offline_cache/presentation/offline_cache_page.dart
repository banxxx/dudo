import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../settings/shared/widgets/settings_detail_scaffold.dart';
import '../../settings/storage_settings/domain/storage_usage.dart';
import '../application/offline_cache_provider.dart';
import '../domain/offline_cache.dart';

const _offlineCacheMessageKey = 'offline-cache';

/// Manages the chapter content downloaded while reading. Clearing a book's
/// cache only drops the stored text; the book, its catalog and progress stay.
class OfflineCachePage extends ConsumerStatefulWidget {
  const OfflineCachePage({super.key});

  @override
  ConsumerState<OfflineCachePage> createState() => _OfflineCachePageState();
}

class _OfflineCachePageState extends ConsumerState<OfflineCachePage> {
  String? _clearingBookId;
  bool _clearingAll = false;

  @override
  Widget build(BuildContext context) {
    final cacheAsync = ref.watch(offlineCacheProvider);
    final cache = cacheAsync.valueOrNull;

    return SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '书房工具',
          title: '离线缓存',
          actionIcon: cacheAsync.isLoading ? null : LucideIcons.refreshCw,
          onActionTap: () => ref.invalidate(offlineCacheProvider),
        ),
        const SizedBox(height: 14),
        _OfflineHero(
          cache: cache,
          loading: cacheAsync.isLoading,
          failed: cacheAsync.hasError,
        ),
        const SizedBox(height: 14),
        if (cache == null)
          _UnavailableCard(
            failed: cacheAsync.hasError,
            onRetry: () => ref.invalidate(offlineCacheProvider),
          )
        else if (cache.isEmpty)
          const EmptyStateView(
            icon: LucideIcons.download,
            title: '还没有离线章节',
            message: '阅读时下载的章节会保存在这里，之后无需网络也能打开。',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '已缓存书籍',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _clearingAll ? null : _confirmClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: _dangerText,
                  disabledForegroundColor: DudoColors.secondary,
                  textStyle: DudoTextStyles.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                icon: _clearingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.trash2, size: 14),
                label: Text(_clearingAll ? '清除中' : '全部清除'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final book in cache.books) ...[
            _OfflineBookRow(
              book: book,
              clearing: _clearingBookId == book.bookId,
              onClear: () => _confirmClearBook(book),
            ),
            if (book != cache.books.last) const SizedBox(height: 9),
          ],
          const SizedBox(height: 12),
          Text(
            '清除只删除下载的章节内容，书架、阅读进度与书签都会保留。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmClearBook(OfflineCacheBook book) async {
    final confirmed = await _showClearDialog(
      title: '清除「${book.title}」的缓存？',
      message:
          '将删除 ${book.chapterCount} 个已下载章节（${formatStorageBytes(book.bytes)}），'
          '之后阅读这些章节需要重新联网。',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingBookId = book.bookId);
    try {
      await ref.read(offlineCacheRepositoryProvider).clearBook(book.bookId);
      if (!mounted) return;
      ref.invalidate(offlineCacheProvider);
      ref.read(appMessageServiceProvider).success(
            '已清除「${book.title}」的缓存',
            title: '清理完成',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '清除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } finally {
      if (mounted) setState(() => _clearingBookId = null);
    }
  }

  Future<void> _confirmClearAll() async {
    final cache = ref.read(offlineCacheProvider).valueOrNull;
    if (cache == null || cache.isEmpty) return;

    final confirmed = await _showClearDialog(
      title: '清除全部离线缓存？',
      message:
          '将删除 ${cache.chapterCount} 个已下载章节（'
          '${formatStorageBytes(cache.totalBytes)}），之后阅读需要重新联网。',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingAll = true);
    try {
      await ref.read(offlineCacheRepositoryProvider).clearAll();
      if (!mounted) return;
      ref.invalidate(offlineCacheProvider);
      ref.read(appMessageServiceProvider).success(
            '已清除全部离线缓存',
            title: '清理完成',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '清除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } finally {
      if (mounted) setState(() => _clearingAll = false);
    }
  }

  Future<bool?> _showClearDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                '清除',
                style: DudoTextStyles.sans(
                  color: _dangerText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

const _dangerText = Color(0xFFA8553A);

class _OfflineHero extends StatelessWidget {
  const _OfflineHero({
    required this.cache,
    required this.loading,
    required this.failed,
  });

  final OfflineCache? cache;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final cache = this.cache;
    final total = cache == null
        ? (loading ? '计算中…' : '—')
        : formatStorageBytes(cache.totalBytes);
    final detail = cache == null
        ? (failed ? '无法读取离线缓存' : '正在统计已下载章节…')
        : '${cache.chapterCount} 章 · ${cache.bookCount} 本书';

    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, 12),
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
                  '离线缓存占用',
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
                  detail,
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
              LucideIcons.download,
              color: DudoColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBookRow extends StatelessWidget {
  const _OfflineBookRow({
    required this.book,
    required this.clearing,
    required this.onClear,
  });

  final OfflineCacheBook book;
  final bool clearing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final descriptionParts = <String>[
      '${book.chapterCount} 章',
      if (book.author != null && book.author!.trim().isNotEmpty)
        book.author!.trim(),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          _BookCoverTile(title: book.title),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descriptionParts.join(' · '),
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
          const SizedBox(width: 10),
          Text(
            formatStorageBytes(book.bytes),
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            key: ValueKey('offline-clear-${book.bookId}'),
            onPressed: clearing ? null : onClear,
            style: TextButton.styleFrom(
              foregroundColor: _dangerText,
              disabledForegroundColor: DudoColors.secondary,
              minimumSize: const Size(44, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: DudoTextStyles.sans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(clearing ? '清除中' : '清除'),
          ),
        ],
      ),
    );
  }
}

class _BookCoverTile extends StatelessWidget {
  const _BookCoverTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final trimmed = title.trim();
    final label = trimmed.isEmpty
        ? '书'
        : trimmed.characters.first;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            DudoColors.primaryContainer,
            DudoColors.primaryContainerStrong.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: DudoTextStyles.serif(
          color: DudoColors.primaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
              failed ? '无法读取离线缓存' : '正在统计已下载章节…',
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
