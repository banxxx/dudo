import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../../shared/widgets/dudo_page_header.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../application/bookmarks_providers.dart';
import '../domain/bookmark_entry.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bookmarkEntriesProvider);
    final entries = entriesAsync.valueOrNull ?? const <BookmarkEntry>[];

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        bottomSafeArea: false,
        children: [
          const _BookmarksHeader(),
          const SizedBox(height: 16),
          if (entriesAsync.hasError && !entriesAsync.hasValue)
            ErrorStateView(
              title: '书签加载失败',
              message: '${entriesAsync.error}',
              action: TextButton(
                onPressed: () => ref.invalidate(bookmarkEntriesProvider),
                child: const Text('重试'),
              ),
            )
          else if (entries.isEmpty) ...const [
            _BookmarkEmptySummary(),
            SizedBox(height: 16),
          ] else ...[
            _BookmarkSummary(entries: entries),
            const SizedBox(height: 14),
            for (final entry in entries) ...[
              _BookmarkEntryCard(
                entry: entry,
                onTap: () => _openEntry(context, entry),
                onDelete: () => _confirmDelete(context, ref, entry),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (entries.isEmpty && !entriesAsync.hasError) ...[
            _BookmarkEmptyState(
              onRead: () => context.go(AppRoutes.bookshelf),
            ),
          ],
        ],
      ),
    );
  }

  void _openEntry(BuildContext context, BookmarkEntry entry) {
    context.push(
      '${AppRoutes.reader}/${entry.bookId}'
      '?chapter=${entry.chapterIndex}&offset=${entry.offset}',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BookmarkEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: DudoColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            '删除这条${entry.type.label}？',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '删除后无法恢复。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.secondaryDark,
              ),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.primary,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await ref.read(bookmarksRepositoryProvider).deleteEntry(entry);
  }
}

class _BookmarksHeader extends StatelessWidget {
  const _BookmarksHeader();

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: '书签',
      height: 60,
      titleAlignment: Alignment.centerLeft,
      reserveTrailingSpace: false,
      leading: DudoCircleIconButton(
        key: const ValueKey('bookmarks-back-button'),
        icon: LucideIcons.chevronLeft,
        iconSize: 21,
        borderColor: DudoColors.outlineVariant,
        onTap: () => context.pop(),
      ),
      titleWidget: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '阅读标记',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '书签',
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      trailing: DudoCircleIconButton(
        icon: LucideIcons.slidersHorizontal,
        iconSize: 20,
        onTap: () {},
      ),
    );
  }
}

class _BookmarkSummary extends StatelessWidget {
  const _BookmarkSummary({required this.entries});

  final List<BookmarkEntry> entries;

  @override
  Widget build(BuildContext context) {
    final bookCount = entries.map((entry) => entry.bookId).toSet().length;
    final bookmarkCount = entries
        .where((entry) => entry.type == BookmarkEntryType.bookmark)
        .length;
    final noteCount =
        entries.where((entry) => entry.type == BookmarkEntryType.note).length;
    final highlightCount = entries.length - bookmarkCount - noteCount;

    final parts = <String>[
      if (bookmarkCount > 0) '书签 $bookmarkCount',
      if (highlightCount > 0) '高亮 $highlightCount',
      if (noteCount > 0) '笔记 $noteCount',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.bookmark,
            color: DudoColors.primary,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共 ${entries.length} 条标记 · $bookCount 本书',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parts.isEmpty ? '阅读时添加的书签和高亮' : parts.join(' · '),
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
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

class _BookmarkEntryCard extends StatelessWidget {
  const _BookmarkEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final BookmarkEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.type) {
      BookmarkEntryType.bookmark => DudoColors.primary,
      BookmarkEntryType.highlight => DudoColors.secondary,
      BookmarkEntryType.note => DudoColors.accent,
    };
    final icon = switch (entry.type) {
      BookmarkEntryType.bookmark => LucideIcons.bookmark,
      BookmarkEntryType.highlight => LucideIcons.highlighter,
      BookmarkEntryType.note => LucideIcons.penLine,
    };
    final excerpt = entry.excerpt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.bookTitle} · ${entry.chapterLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        excerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (entry.note != null &&
                        entry.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '笔记：${entry.note!.trim()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.primary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${entry.type.label} · ${_dateLabel(entry.createdAt)}',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('bookmark-delete-${entry.id}'),
                onPressed: onDelete,
                icon: const Icon(
                  LucideIcons.trash2,
                  color: DudoColors.secondary,
                  size: 18,
                ),
                tooltip: '删除',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkEmptySummary extends StatelessWidget {
  const _BookmarkEmptySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.bookmark,
            color: DudoColors.primary,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '暂无书签和高亮',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '阅读时点击书签或划线，高亮摘录会自动收集在这里。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

class _BookmarkEmptyState extends StatelessWidget {
  const _BookmarkEmptyState({required this.onRead});

  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 314,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(38),
            ),
            child: const Icon(
              LucideIcons.bookmark,
              color: DudoColors.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '把喜欢的句子留在这里',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '进入阅读器后，使用底部工具栏添加书签或高亮，之后可以按书籍、章节和时间回看。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRead,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: DudoColors.textPrimary,
                borderRadius: AppRadius.full,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '去阅读',
                    style: DudoTextStyles.sans(
                      color: DudoColors.surfaceHigh,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.arrowRight,
                    color: DudoColors.surfaceHigh,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  if (days == 0) return '今天';
  if (days == 1) return '昨天';
  if (date.year == now.year) return '${date.month} 月 ${date.day} 日';
  return '${date.year} 年 ${date.month} 月 ${date.day} 日';
}
