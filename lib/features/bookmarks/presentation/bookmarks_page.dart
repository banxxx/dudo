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

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  BookmarkEntryType? _typeFilter;
  _BookmarkSort _sort = _BookmarkSort.newest;

  bool get _hasActiveOptions =>
      _typeFilter != null || _sort != _BookmarkSort.newest;

  List<BookmarkEntry> _visibleEntries(List<BookmarkEntry> entries) {
    final filtered = _typeFilter == null
        ? [...entries]
        : entries.where((entry) => entry.type == _typeFilter).toList();
    filtered.sort((a, b) => _sort == _BookmarkSort.oldest
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> _openOptions(List<BookmarkEntry> entries) async {
    final selection = await showModalBottomSheet<_BookmarkOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookmarkOptionsSheet(
        entries: entries,
        selectedType: _typeFilter,
        sort: _sort,
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _typeFilter = selection.type;
      _sort = selection.sort;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bookmarkEntriesProvider);
    final entries = entriesAsync.valueOrNull ?? const <BookmarkEntry>[];
    final visibleEntries = _visibleEntries(entries);
    final hasError = entriesAsync.hasError && !entriesAsync.hasValue;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        bottomSafeArea: false,
        children: [
          _BookmarksHeader(
            onOpenOptions:
                entries.isEmpty ? null : () => _openOptions(entries),
            optionsActive: _hasActiveOptions,
          ),
          const SizedBox(height: 16),
          if (hasError)
            ErrorStateView(
              title: '书签加载失败',
              message: '${entriesAsync.error}',
              action: TextButton(
                onPressed: () => ref.invalidate(bookmarkEntriesProvider),
                child: const Text('重试'),
              ),
            )
          else if (entries.isEmpty) ...[
            const _BookmarkEmptySummary(),
            const SizedBox(height: 16),
          ] else ...[
            _BookmarkSummary(entries: entries),
            const SizedBox(height: 12),
            _BookmarkFilterChips(
              counts: _BookmarkCounts.of(entries),
              selected: _typeFilter,
              onSelected: (type) => setState(() => _typeFilter = type),
            ),
            const SizedBox(height: 14),
            if (visibleEntries.isEmpty)
              _FilteredEmptyCard(
                onClear: () => setState(() {
                  _typeFilter = null;
                  _sort = _BookmarkSort.newest;
                }),
              )
            else
              for (final entry in visibleEntries) ...[
                _BookmarkEntryCard(
                  entry: entry,
                  onTap: () => _openEntry(context, entry),
                  onDelete: () => _confirmDelete(context, ref, entry),
                ),
                const SizedBox(height: 10),
              ],
          ],
          if (entries.isEmpty && !hasError) ...[
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
  const _BookmarksHeader({
    required this.onOpenOptions,
    required this.optionsActive,
  });

  /// `null` hides the options button when there is nothing to filter.
  final VoidCallback? onOpenOptions;
  final bool optionsActive;

  @override
  Widget build(BuildContext context) {
    final onOpenOptions = this.onOpenOptions;
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
      trailing: onOpenOptions == null
          ? null
          : DudoCircleIconButton(
              key: const ValueKey('bookmarks-filter-button'),
              icon: LucideIcons.slidersHorizontal,
              iconSize: 20,
              backgroundColor:
                  optionsActive ? DudoColors.primaryContainer : null,
              iconColor: optionsActive ? DudoColors.primary : null,
              borderColor: optionsActive
                  ? DudoColors.primaryContainerStrong
                  : DudoColors.outlineVariant,
              onTap: onOpenOptions,
            ),
    );
  }
}

class _BookmarkCounts {
  const _BookmarkCounts({
    required this.total,
    required this.bookCount,
    required this.bookmarks,
    required this.highlights,
    required this.notes,
  });

  factory _BookmarkCounts.of(List<BookmarkEntry> entries) {
    final bookmarks = entries
        .where((entry) => entry.type == BookmarkEntryType.bookmark)
        .length;
    final notes =
        entries.where((entry) => entry.type == BookmarkEntryType.note).length;
    return _BookmarkCounts(
      total: entries.length,
      bookCount: entries.map((entry) => entry.bookId).toSet().length,
      bookmarks: bookmarks,
      highlights: entries.length - bookmarks - notes,
      notes: notes,
    );
  }

  final int total;
  final int bookCount;
  final int bookmarks;
  final int highlights;
  final int notes;

  int forType(BookmarkEntryType? type) {
    switch (type) {
      case null:
        return total;
      case BookmarkEntryType.bookmark:
        return bookmarks;
      case BookmarkEntryType.highlight:
        return highlights;
      case BookmarkEntryType.note:
        return notes;
    }
  }
}

class _BookmarkSummary extends StatelessWidget {
  const _BookmarkSummary({required this.entries});

  final List<BookmarkEntry> entries;

  @override
  Widget build(BuildContext context) {
    final counts = _BookmarkCounts.of(entries);
    final parts = <String>[
      if (counts.bookmarks > 0) '书签 ${counts.bookmarks}',
      if (counts.highlights > 0) '高亮 ${counts.highlights}',
      if (counts.notes > 0) '笔记 ${counts.notes}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
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
                  '共 ${counts.total} 条标记 · ${counts.bookCount} 本书',
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

class _BookmarkFilterChips extends StatelessWidget {
  const _BookmarkFilterChips({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final _BookmarkCounts counts;
  final BookmarkEntryType? selected;
  final ValueChanged<BookmarkEntryType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BookmarkFilterChip(
            key: const ValueKey('bookmark-filter-all'),
            label: '全部',
            count: counts.total,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final type in BookmarkEntryType.values)
            // Keep an empty type visible while it is the active filter so the
            // chip row always explains why the list is empty.
            if (counts.forType(type) > 0 || selected == type) ...[
              const SizedBox(width: 8),
              _BookmarkFilterChip(
                key: ValueKey('bookmark-filter-${type.name}'),
                label: type.label,
                count: counts.forType(type),
                selected: selected == type,
                onTap: () => onSelected(type),
              ),
            ],
        ],
      ),
    );
  }
}

class _BookmarkFilterChip extends StatelessWidget {
  const _BookmarkFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? DudoColors.surfaceHigh : DudoColors.secondaryDark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? DudoColors.textPrimary : DudoColors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: DudoTextStyles.numeric(
                  color: selected
                      ? DudoColors.surfaceHigh.withValues(alpha: 0.72)
                      : DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredEmptyCard extends StatelessWidget {
  const _FilteredEmptyCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '没有符合条件的标记',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '换一个类型，或者清除筛选查看全部标记。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: DudoColors.primary,
            ),
            child: const Text('清除筛选'),
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
                icon: Icon(
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
          Icon(
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
            child: Icon(
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
              decoration: BoxDecoration(
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
                  Icon(
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

enum _BookmarkSort {
  newest('最近在前'),
  oldest('最早在前');

  const _BookmarkSort(this.label);

  final String label;
}

class _BookmarkOptions {
  const _BookmarkOptions({required this.type, required this.sort});

  final BookmarkEntryType? type;
  final _BookmarkSort sort;
}

class _BookmarkOptionsSheet extends StatelessWidget {
  const _BookmarkOptionsSheet({
    required this.entries,
    required this.selectedType,
    required this.sort,
  });

  final List<BookmarkEntry> entries;
  final BookmarkEntryType? selectedType;
  final _BookmarkSort sort;

  @override
  Widget build(BuildContext context) {
    final counts = _BookmarkCounts.of(entries);

    return Container(
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3325251F),
            offset: Offset(0, -18),
            blurRadius: 36,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: DudoColors.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '阅读标记',
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '筛选与排序',
                        style: DudoTextStyles.serif(
                          color: DudoColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                DudoCircleIconButton(
                  key: const ValueKey('bookmark-options-close'),
                  icon: LucideIcons.x,
                  iconSize: 18,
                  borderColor: DudoColors.outlineVariant,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const _OptionsSectionTitle('标记类型'),
          _BookmarkOptionRow(
            key: const ValueKey('bookmark-option-all'),
            label: '全部',
            countLabel: '${counts.total} 条',
            selected: selectedType == null,
            onTap: () => Navigator.of(context).pop(
              _BookmarkOptions(type: null, sort: sort),
            ),
          ),
          for (final type in BookmarkEntryType.values)
            _BookmarkOptionRow(
              key: ValueKey('bookmark-option-${type.name}'),
              label: type.label,
              countLabel: '${counts.forType(type)} 条',
              selected: selectedType == type,
              onTap: () => Navigator.of(context).pop(
                _BookmarkOptions(type: type, sort: sort),
              ),
            ),
          const SizedBox(height: 6),
          const _OptionsSectionTitle('排序方式'),
          for (final option in _BookmarkSort.values)
            _BookmarkOptionRow(
              key: ValueKey('bookmark-option-sort-${option.name}'),
              label: option.label,
              selected: sort == option,
              onTap: () => Navigator.of(context).pop(
                _BookmarkOptions(type: selectedType, sort: option),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionsSectionTitle extends StatelessWidget {
  const _OptionsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _BookmarkOptionRow extends StatelessWidget {
  const _BookmarkOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.countLabel,
  });

  final String label;
  final String? countLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = this.countLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: DudoTextStyles.sans(
                      color: selected
                          ? DudoColors.textPrimary
                          : DudoColors.secondaryDark,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (countLabel != null)
                  Text(
                    countLabel,
                    style: DudoTextStyles.numeric(
                      color: DudoColors.secondary,
                      fontSize: 12.5,
                    ),
                  ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          color: DudoColors.primary,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
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
