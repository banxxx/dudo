import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_skeleton.dart';
import '../../settings/shared/widgets/settings_detail_scaffold.dart';
import '../../settings/storage_settings/domain/storage_usage.dart';
import '../application/offline_cache_download_provider.dart';
import '../application/offline_cache_provider.dart';
import '../application/offline_cache_settings_provider.dart';
import '../domain/offline_cache.dart';
import '../domain/offline_cache_settings.dart';
import '../domain/offline_cache_task.dart';

const _offlineCacheMessageKey = 'offline-cache';
const _dangerText = Color(0xFFA5503F);
const _dangerFill = Color(0xFFF4D6CE);

Color get _dangerColor =>
    DudoColors.isDark ? const Color(0xFFE7A98F) : _dangerText;
Color get _dangerSurface =>
    DudoColors.isDark ? const Color(0xFF4A2F29) : _dangerFill;
Color get _dangerButtonFill =>
    DudoColors.isDark ? const Color(0xFF7A3A2C) : _dangerText;

/// The empty-state call to action inverts in dark mode. `ink` deliberately
/// resolves to the raised charcoal surface there, so using it as a button fill
/// would make the button disappear into the card.
Color get _ctaFill =>
    DudoColors.isDark ? DudoColors.textPrimary : DudoColors.ink;
Color get _ctaForeground =>
    DudoColors.isDark ? DudoColors.surface : DudoColors.onInk;

/// Manages the chapter content downloaded for offline reading and the
/// book-level cache tasks that are still running.
///
/// Clearing a book's cache only drops the stored text; the book, its catalog
/// and reading progress stay. Bulk clearing lives behind the 管理 mode so the
/// default page has no destructive button to mis-tap.
class OfflineCachePage extends ConsumerStatefulWidget {
  const OfflineCachePage({super.key});

  @override
  ConsumerState<OfflineCachePage> createState() => _OfflineCachePageState();
}

class _OfflineCachePageState extends ConsumerState<OfflineCachePage> {
  bool _manageMode = false;
  bool _clearing = false;
  final Set<String> _selectedBookIds = {};

  @override
  Widget build(BuildContext context) {
    final cacheAsync = ref.watch(offlineCacheProvider);
    final cache = cacheAsync.valueOrNull;
    final tasks = ref.watch(offlineCacheDownloadControllerProvider);
    final settings = ref.watch(offlineCacheSettingsControllerProvider);

    final taskBookIds = {for (final task in tasks) task.bookId};
    final cachedBooks = cache?.books ?? const <OfflineCacheBook>[];
    final visibleBooks = [
      for (final book in cachedBooks)
        if (!taskBookIds.contains(book.bookId)) book,
    ];
    final selectedBooks = [
      for (final book in visibleBooks)
        if (_selectedBookIds.contains(book.bookId)) book,
    ];
    final selectedIds = {for (final book in selectedBooks) book.bookId};
    final isManage = _manageMode && visibleBooks.isNotEmpty;
    final hasContent = visibleBooks.isNotEmpty || tasks.isNotEmpty;
    final showEmpty = cache != null && !hasContent;
    if (_manageMode && visibleBooks.isEmpty) {
      // The list can empty out from under manage mode (for example when the
      // last book starts a cache task). Reset the mode after this frame so the
      // page does not silently re-enter it when books reappear.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _manageMode) _exitManage();
      });
    }

    return SettingsDetailScaffold(
      header: SettingsDetailHeader(
        eyebrow: '书房工具',
        title: isManage ? '管理离线缓存' : '离线缓存',
        subtitle: isManage
            ? '选择要清除的书籍缓存'
            : tasks.isNotEmpty
                ? '正在缓存与已缓存书籍'
                : '管理已缓存章节与下载设置',
        actionIcon: isManage
            ? LucideIcons.check
            : visibleBooks.isNotEmpty
                ? LucideIcons.listChecks
                : showEmpty
                    ? LucideIcons.refreshCw
                    : null,
        actionEmphasized: isManage,
        onActionTap: isManage
            ? _exitManage
            : visibleBooks.isNotEmpty
                ? _enterManage
                : () => ref.invalidate(offlineCacheProvider),
      ),
      bottomBar: isManage
          ? _BulkClearBar(
              selectedCount: selectedBooks.length,
              busy: _clearing,
              onCancel: _exitManage,
              onDelete: selectedBooks.isEmpty
                  ? null
                  : () => _confirmClearSelected(selectedBooks),
            )
          : null,
      children: [
        const SizedBox(height: 14),
        if (isManage) ...[
          _SelectionSummary(
            selectedCount: selectedBooks.length,
            selectedBytes: selectedBooks.fold(
              0,
              (sum, book) => sum + book.bytes,
            ),
            allSelected: selectedIds.length == visibleBooks.length,
            onToggleAll: () => _toggleSelectAll(visibleBooks),
          ),
          const SizedBox(height: 14),
          for (final book in visibleBooks) ...[
            _ManageBookRow(
              book: book,
              selected: selectedIds.contains(book.bookId),
              onToggle: () => _toggleBook(book.bookId),
            ),
            if (book != visibleBooks.last) const SizedBox(height: 8),
          ],
        ] else ...[
          _DownloadSettingsCard(
            concurrency: settings.concurrency,
            onChanged: (value) => ref
                .read(offlineCacheSettingsControllerProvider.notifier)
                .setConcurrency(value),
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _TaskSection(
              tasks: tasks,
              onPause: (bookId) => ref
                  .read(offlineCacheDownloadControllerProvider.notifier)
                  .pauseTask(bookId),
              onResume: (bookId) => ref
                  .read(offlineCacheDownloadControllerProvider.notifier)
                  .resumeTask(bookId),
              onRemove: (bookId) => ref
                  .read(offlineCacheDownloadControllerProvider.notifier)
                  .removeTask(bookId),
            ),
          ],
          if (cache == null) ...[
            const SizedBox(height: 14),
            if (cacheAsync.hasError)
              _UnavailableCard(
                onRetry: () => ref.invalidate(offlineCacheProvider),
              )
            else
              const _CachedBooksSkeleton(),
          ] else if (visibleBooks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _CachedBooksSection(
              books: visibleBooks,
              onOpen: (book) => context.push(
                '${AppRoutes.bookDetail}/${book.bookId}',
              ),
            ),
          ] else if (showEmpty) ...[
            const SizedBox(height: 14),
            _EmptyCache(
              onOpenBookshelf: () => context.go(AppRoutes.bookshelf),
            ),
          ],
          if (cache != null && hasContent) ...[
            const SizedBox(height: 14),
            Text(
              tasks.isNotEmpty
                  ? '缓存任务会保留已下载的章节；清除缓存只删除正文，书架、进度与书签不受影响。'
                  : '清除缓存只删除已下载的章节正文，书架、阅读进度与书签都会保留。',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _enterManage() {
    setState(() {
      _manageMode = true;
      _selectedBookIds.clear();
    });
  }

  void _exitManage() {
    setState(() {
      _manageMode = false;
      _selectedBookIds.clear();
    });
  }

  void _toggleBook(String bookId) {
    if (_clearing) return;
    setState(() {
      if (!_selectedBookIds.add(bookId)) {
        _selectedBookIds.remove(bookId);
      }
    });
  }

  void _toggleSelectAll(List<OfflineCacheBook> books) {
    if (_clearing) return;
    setState(() {
      final allSelected = books.every(
        (book) => _selectedBookIds.contains(book.bookId),
      );
      if (allSelected) {
        _selectedBookIds.clear();
      } else {
        _selectedBookIds
          ..clear()
          ..addAll(books.map((book) => book.bookId));
      }
    });
  }

  Future<void> _confirmClearSelected(List<OfflineCacheBook> books) async {
    if (books.isEmpty || _clearing) return;
    final chapterCount = books.fold(0, (sum, book) => sum + book.chapterCount);
    final bytes = books.fold(0, (sum, book) => sum + book.bytes);
    final confirmed = await _showClearDialog(
      title: books.length == 1
          ? '清除「${books.first.title}」的缓存？'
          : '清除 ${books.length} 本书的缓存？',
      message: '将清除 $chapterCount 个已下载章节（${formatStorageBytes(bytes)}），'
          '之后阅读这些章节需要重新联网。',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    try {
      await ref
          .read(offlineCacheRepositoryProvider)
          .clearBooksAndCompact(books.map((book) => book.bookId));
      if (!mounted) return;
      ref.invalidate(offlineCacheProvider);
      setState(() {
        _manageMode = false;
        _selectedBookIds.clear();
        _clearing = false;
      });
      ref.read(appMessageServiceProvider).success(
            books.length == 1
                ? '已清除「${books.first.title}」的缓存'
                : '已清除 ${books.length} 本书的缓存',
            title: '清除完成',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _clearing = false);
      ref.read(appMessageServiceProvider).error(
            '清除失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _offlineCacheMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
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
                  color: _dangerColor,
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

class _DownloadSettingsCard extends StatelessWidget {
  const _DownloadSettingsCard({
    required this.concurrency,
    required this.onChanged,
  });

  final int concurrency;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
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
                      '同时下载数量',
                      style: DudoTextStyles.sans(
                        color: DudoColors.onPrimaryContainer,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '当前允许 $concurrency 本书同时下载，网络慢时可调低。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.primaryDark,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  color: DudoColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DudoColors.surfaceHigh,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              children: [
                for (final option in OfflineCacheSettings.concurrencyOptions)
                  Expanded(
                    child: _ConcurrencyOption(
                      value: option,
                      selected: option == concurrency,
                      onTap: onChanged,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                LucideIcons.info,
                color: DudoColors.secondary,
                size: 12,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '建议移动网络下使用 1–2 个任务。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConcurrencyOption extends StatelessWidget {
  const _ConcurrencyOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DudoColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        key: ValueKey('offline-concurrency-$value'),
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: 34,
          child: Center(
            child: Text(
              '$value',
              style: DudoTextStyles.sans(
                color: selected ? DudoColors.onInk : DudoColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
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
        if (detail != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CachedBooksSection extends StatelessWidget {
  const _CachedBooksSection({required this.books, required this.onOpen});

  final List<OfflineCacheBook> books;
  final ValueChanged<OfflineCacheBook> onOpen;

  @override
  Widget build(BuildContext context) {
    final chapters = books.fold(0, (sum, book) => sum + book.chapterCount);
    final bytes = books.fold(0, (sum, book) => sum + book.bytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '已缓存书籍',
          detail:
              '${books.length} 本 · $chapters 章 · ${formatStorageBytes(bytes)}',
        ),
        const SizedBox(height: 8),
        for (final book in books) ...[
          _CachedBookRow(book: book, onTap: () => onOpen(book)),
          if (book != books.last) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _CachedBookRow extends StatelessWidget {
  const _CachedBookRow({required this.book, required this.onTap});

  final OfflineCacheBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = book.author?.trim();
    return Material(
      color: DudoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: DudoColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _BookCoverTile(title: book.title),
              const SizedBox(width: 12),
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
                    if (author != null && author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: DudoColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${book.chapterCount} 章 · '
                            '${formatStorageBytes(book.bytes)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.secondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                LucideIcons.chevronRight,
                color: DudoColors.secondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.selectedCount,
    required this.selectedBytes,
    required this.allSelected,
    required this.onToggleAll,
  });

  final int selectedCount;
  final int selectedBytes;
  final bool allSelected;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '已选择 $selectedCount 项',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '预计释放 ${formatStorageBytes(selectedBytes)}',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: DudoColors.primaryContainer,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              key: const ValueKey('offline-select-all'),
              onTap: onToggleAll,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  allSelected ? '取消全选' : '全选',
                  style: DudoTextStyles.sans(
                    color: DudoColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageBookRow extends StatelessWidget {
  const _ManageBookRow({
    required this.book,
    required this.selected,
    required this.onToggle,
  });

  final OfflineCacheBook book;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: DudoColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? DudoColors.primary : DudoColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected ? DudoColors.primary : DudoColors.outline,
                  ),
                ),
                child: selected
                    ? Icon(
                        LucideIcons.check,
                        color: DudoColors.surfaceHigh,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              _BookCoverTile(title: book.title),
              const SizedBox(width: 12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${book.chapterCount} 章 · '
                      '${formatStorageBytes(book.bytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.tasks,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
  });

  final List<OfflineCacheTask> tasks;
  final ValueChanged<String> onPause;
  final ValueChanged<String> onResume;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '缓存任务', detail: _summary(tasks)),
        const SizedBox(height: 8),
        for (final task in tasks) ...[
          _CacheTaskCard(
            task: task,
            onPause: () => onPause(task.bookId),
            onResume: () => onResume(task.bookId),
            onRemove: () => onRemove(task.bookId),
          ),
          if (task != tasks.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _summary(List<OfflineCacheTask> tasks) {
    final active = tasks
        .where(
          (task) =>
              task.status == OfflineCacheTaskStatus.queued ||
              task.status == OfflineCacheTaskStatus.downloading,
        )
        .length;
    final paused = tasks
        .where((task) => task.status == OfflineCacheTaskStatus.paused)
        .length;
    final failed = tasks
        .where((task) => task.status == OfflineCacheTaskStatus.failed)
        .length;
    return [
      if (active > 0) '$active 个进行中',
      if (paused > 0) '$paused 个已暂停',
      if (failed > 0) '$failed 个失败',
    ].join(' · ');
  }
}

class _CacheTaskCard extends StatelessWidget {
  const _CacheTaskCard({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
  });

  final OfflineCacheTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final author = task.author?.trim();
    return Container(
      key: ValueKey('offline-task-card-${task.bookId}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCoverTile(title: task.title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TaskStatusPill(task: task),
                      ],
                    ),
                    if (author != null && author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      _progressLabel(task),
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
            ],
          ),
          const SizedBox(height: 10),
          _TaskProgressBar(task: task),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _footerLabel(task),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ..._actions(),
            ],
          ),
        ],
      ),
    );
  }

  /// Chapter counts are only shown when the book exposes them. Some sources
  /// cannot report per-chapter progress, so the card falls back to the overall
  /// percentage alone instead of inventing a chapter total.
  String _progressLabel(OfflineCacheTask task) {
    final percent = task.percent;
    if (task.hasChapterProgress) {
      final prefix = task.status == OfflineCacheTaskStatus.failed ? '已下载 ' : '';
      return '$prefix${task.downloadedChapters} / ${task.totalChapters} 章'
          '${percent == null ? '' : ' · $percent%'}';
    }
    if (percent != null) return '$percent%';
    return switch (task.status) {
      OfflineCacheTaskStatus.queued => '等待开始',
      OfflineCacheTaskStatus.downloading => '正在获取目录…',
      OfflineCacheTaskStatus.paused ||
      OfflineCacheTaskStatus.failed =>
        '暂无进度信息',
    };
  }

  String _footerLabel(OfflineCacheTask task) {
    final message = task.message?.trim();
    if (message != null && message.isNotEmpty) return message;
    return switch (task.status) {
      OfflineCacheTaskStatus.queued => '等待前面的任务完成',
      OfflineCacheTaskStatus.downloading => '后台缓存中，可离开此页',
      OfflineCacheTaskStatus.paused => '继续后会从已下载章节接着缓存',
      OfflineCacheTaskStatus.failed => '缓存失败，可重试',
    };
  }

  List<Widget> _actions() {
    return switch (task.status) {
      OfflineCacheTaskStatus.queued || OfflineCacheTaskStatus.downloading => [
          _TaskActionButton(
            key: ValueKey('offline-task-pause-${task.bookId}'),
            icon: LucideIcons.pause,
            label: '暂停',
            fill: DudoColors.surfaceLow,
            color: DudoColors.secondary,
            onTap: onPause,
          ),
        ],
      OfflineCacheTaskStatus.paused => [
          _TaskActionButton(
            key: ValueKey('offline-task-remove-${task.bookId}'),
            label: '移除',
            color: DudoColors.secondary,
            fontWeight: FontWeight.w400,
            onTap: onRemove,
          ),
          const SizedBox(width: 8),
          _TaskActionButton(
            key: ValueKey('offline-task-resume-${task.bookId}'),
            icon: LucideIcons.play,
            label: '继续',
            fill: DudoColors.primaryContainer,
            color: DudoColors.primary,
            onTap: onResume,
          ),
        ],
      OfflineCacheTaskStatus.failed => [
          _TaskActionButton(
            key: ValueKey('offline-task-remove-${task.bookId}'),
            label: '移除',
            color: DudoColors.secondary,
            fontWeight: FontWeight.w400,
            onTap: onRemove,
          ),
          const SizedBox(width: 8),
          _TaskActionButton(
            key: ValueKey('offline-task-retry-${task.bookId}'),
            icon: LucideIcons.refreshCw,
            label: '重试',
            fill: _dangerSurface,
            color: _dangerColor,
            onTap: onResume,
          ),
        ],
    };
  }
}

class _TaskStatusPill extends StatelessWidget {
  const _TaskStatusPill({required this.task});

  final OfflineCacheTask task;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (task.status) {
      OfflineCacheTaskStatus.downloading => (
          DudoColors.surfaceLow,
          DudoColors.accent,
        ),
      OfflineCacheTaskStatus.queued => (
          DudoColors.surfaceLow,
          DudoColors.secondary,
        ),
      OfflineCacheTaskStatus.paused => (
          DudoColors.surfaceLow,
          DudoColors.secondaryDark,
        ),
      OfflineCacheTaskStatus.failed => (_dangerSurface, _dangerColor),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        task.statusLabel,
        style: DudoTextStyles.sans(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskProgressBar extends StatelessWidget {
  const _TaskProgressBar({required this.task});

  final OfflineCacheTask task;

  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      OfflineCacheTaskStatus.downloading => DudoColors.accent,
      OfflineCacheTaskStatus.queued => DudoColors.primary,
      OfflineCacheTaskStatus.paused => DudoColors.secondary,
      OfflineCacheTaskStatus.failed => _dangerColor,
    };
    final progress = task.progress;
    // Only a running download has unknown progress worth animating. A queued
    // task is waiting, so an indeterminate bar would suggest activity that is
    // not happening yet.
    final canAnimate = task.status == OfflineCacheTaskStatus.downloading;

    final bar = progress != null
        ? LinearProgressIndicator(
            minHeight: 7,
            value: progress.clamp(0, 1),
            backgroundColor: DudoColors.surfaceLow,
            color: color,
          )
        : canAnimate
            ? LinearProgressIndicator(
                minHeight: 7,
                backgroundColor: DudoColors.surfaceLow,
                color: color,
              )
            : Container(height: 7, color: DudoColors.surfaceLow);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: bar,
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  const _TaskActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.fill,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? fill;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final fill = this.fill;
    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: fill == null ? 4 : 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: color,
                  fontSize: 11,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCache extends StatelessWidget {
  const _EmptyCache({required this.onOpenBookshelf});

  final VoidCallback onOpenBookshelf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 80,
                decoration: BoxDecoration(
                  color: DudoColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.download,
                      color: DudoColors.primary,
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 56,
                      height: 3,
                      decoration: BoxDecoration(
                        color: DudoColors.primaryContainerStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: DudoColors.primaryContainerStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '还没有离线章节',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  '阅读时打开的章节会自动缓存，之后无网络也能继续阅读。',
                  textAlign: TextAlign.center,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: _ctaFill,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onOpenBookshelf,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bookOpen,
                          color: _ctaForeground,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '去书架阅读',
                          style: DudoTextStyles.sans(
                            color: _ctaForeground,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '离线缓存会保留什么？',
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const _TipCard(
          icon: LucideIcons.bookOpen,
          title: '只存正文',
          description: '封面、目录与进度不会重复计入',
        ),
        const SizedBox(height: 8),
        const _TipCard(
          icon: LucideIcons.trash2,
          title: '随时清除',
          description: '清除后书架与阅读进度不受影响',
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DudoColors.secondary, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 10.5,
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

class _BulkClearBar extends StatelessWidget {
  const _BulkClearBar({
    required this.selectedCount,
    required this.busy,
    required this.onCancel,
    required this.onDelete,
  });

  final int selectedCount;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DudoColors.surfaceHigh,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: _dangerColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '仅清除本地章节内容，不会移出书架或影响阅读进度。',
                    style: DudoTextStyles.sans(
                      color: _dangerColor,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BarButton(
                    label: '取消',
                    fill: DudoColors.surfaceLow,
                    color: DudoColors.secondary,
                    onTap: busy ? null : onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BarButton(
                    label: busy
                        ? '清除中…'
                        : selectedCount > 0
                            ? '清除 $selectedCount 项'
                            : '清除',
                    fill: _dangerButtonFill,
                    color: DudoColors.onInk,
                    onTap: busy ? null : onDelete,
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

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.fill,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                label,
                style: DudoTextStyles.sans(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCoverTile extends StatelessWidget {
  const _BookCoverTile({required this.title});

  final String title;

  /// The five cover colours used by the design. They stay fixed instead of
  /// following the accent so a book keeps a recognisable cover on this page.
  static const _coverColors = [
    Color(0xFF8A735A),
    Color(0xFF9A6D45),
    Color(0xFF7A6A5A),
    Color(0xFF5A6B84),
    Color(0xFF5E6F5B),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = title.trim();
    final label = trimmed.isEmpty ? '书' : trimmed.characters.first;
    // The same stable hash the bookshelf uses, so similar titles do not all
    // land on one colour.
    var hash = 0;
    for (final unit in trimmed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final base = _coverColors[hash % _coverColors.length];
    // Light mode follows the design's warm-to-paper gradient. Dark mode keeps
    // the same hue but starts near the charcoal surface, so the cream initial
    // stays readable without turning the tile into a bright block.
    final start =
        DudoColors.isDark ? Color.lerp(base, DudoColors.ink, 0.35)! : base;
    final end = DudoColors.isDark ? base : DudoColors.secondaryContainer;

    return Container(
      width: 48,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [start, end],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: DudoTextStyles.serif(
          color: DudoColors.onInk,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: _dangerColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '无法读取离线缓存',
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

/// Cached book rows, with the same 48x68 cover the real list uses.
class _CachedBooksSkeleton extends StatelessWidget {
  const _CachedBooksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DudoSkeleton(
          child: DudoSkeletonLine(widthFactor: 0.32, height: 15),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          const DudoSkeletonCard(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                DudoSkeletonBox(width: 48, height: 68, radius: 4),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DudoSkeletonLine(widthFactor: 0.55, height: 13),
                      SizedBox(height: 7),
                      DudoSkeletonLine(widthFactor: 0.35, height: 10),
                      SizedBox(height: 8),
                      DudoSkeletonLine(widthFactor: 0.7, height: 9),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                DudoSkeletonBox(width: 16, height: 16, radius: 4),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
