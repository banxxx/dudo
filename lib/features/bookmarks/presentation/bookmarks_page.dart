import 'dart:math' as math;

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

// Shared page rhythm, also used to size the filtered-empty state so it can
// fill the space left under the chips without scrolling.
const double _pageTopPadding = 8;
const double _pageBottomPadding = 12;
const double _headerHeight = 60;
const double _summaryHeight = 112;
const double _chipHeight = 36;
const double _contentGap = 14;
const double _bulkBarHeight = 88;
const double _filteredEmptyOverhead = _pageTopPadding +
    _headerHeight +
    DudoLayout.pinnedHeaderGap +
    _summaryHeight +
    _contentGap +
    _chipHeight +
    _contentGap +
    _pageBottomPadding;

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  BookmarkEntryType? _typeFilter;
  _BookmarkSort _sort = _BookmarkSort.newest;
  bool _selecting = false;
  final Set<String> _selectedIds = <String>{};

  bool get _hasActiveOptions => _sort != _BookmarkSort.newest;

  List<BookmarkEntry> _visibleEntries(List<BookmarkEntry> entries) {
    final filtered = _typeFilter == null
        ? [...entries]
        : entries.where((entry) => entry.type == _typeFilter).toList();
    filtered.sort((a, b) => _sort == _BookmarkSort.oldest
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<BookmarkEntry> _selectedEntries(List<BookmarkEntry> entries) {
    return entries
        .where((entry) => _selectedIds.contains(entry.id))
        .toList(growable: false);
  }

  void _selectType(BookmarkEntryType? type) {
    if (_typeFilter == type) return;
    setState(() {
      _typeFilter = type;
      // The selection belongs to the previous filter; keeping invisible ids
      // would make a bulk delete remove entries the user can no longer see.
      _selectedIds.clear();
    });
  }

  void _enterSelection([BookmarkEntry? initial]) {
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      if (initial != null) _selectedIds.add(initial.id);
    });
  }

  void _exitSelection() {
    if (!_selecting && _selectedIds.isEmpty) return;
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(BookmarkEntry entry) {
    setState(() {
      if (!_selectedIds.remove(entry.id)) _selectedIds.add(entry.id);
    });
  }

  void _toggleSelectAll(List<BookmarkEntry> visibleEntries) {
    final ids = visibleEntries.map((entry) => entry.id).toSet();
    if (ids.isEmpty) return;
    setState(() {
      if (_selectedIds.containsAll(ids)) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  Future<void> _openOptions(int total) async {
    final selection = await showModalBottomSheet<_BookmarkOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookmarkOptionsSheet(sort: _sort, total: total),
    );
    if (selection == null || !mounted) return;
    if (selection.manage) {
      _enterSelection();
      return;
    }
    final sort = selection.sort;
    if (sort != null && sort != _sort) {
      setState(() => _sort = sort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bookmarkEntriesProvider);
    final entries = entriesAsync.valueOrNull ?? const <BookmarkEntry>[];
    final visibleEntries = _visibleEntries(entries);
    final hasError = entriesAsync.hasError && !entriesAsync.hasValue;
    final selectedEntries = _selectedEntries(entries);
    final allVisibleSelected = visibleEntries.isNotEmpty &&
        _selectedIds.containsAll(
          visibleEntries.map((entry) => entry.id),
        );
    final media = MediaQuery.of(context);
    final viewportHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    final filteredEmptyHeight = math.max(
      260.0,
      viewportHeight -
          _filteredEmptyOverhead -
          (_selecting ? _bulkBarHeight : 0),
    );

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: Scaffold(
        backgroundColor: DudoColors.paperBackground,
        body: DudoPageFrame(
          padding: const EdgeInsets.fromLTRB(
            20,
            _pageTopPadding,
            20,
            _pageBottomPadding,
          ),
          header: _selecting
              ? _BulkSelectBar(
                  selectedCount: selectedEntries.length,
                  allSelected: allVisibleSelected,
                  onExit: _exitSelection,
                  onToggleAll: () => _toggleSelectAll(visibleEntries),
                )
              : _BookmarksHeader(
                  // The filter control is part of the G1/G2 header even when
                  // the list is empty; the sheet then only offers sorting.
                  onOpenOptions: () => _openOptions(entries.length),
                  optionsActive: _hasActiveOptions,
                ),
          children: [
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
              _BookmarkEmptyState(
                onRead: () => context.go(AppRoutes.bookshelf),
              ),
            ] else ...[
              _BookmarkSummary(entries: entries),
              const SizedBox(height: _contentGap),
              _BookmarkFilterChips(
                selected: _typeFilter,
                onSelected: _selectType,
              ),
              const SizedBox(height: _contentGap),
              if (visibleEntries.isEmpty)
                _FilteredEmptyState(
                  height: filteredEmptyHeight,
                  typeLabel: _typeFilter?.label ?? '当前类型',
                )
              else
                for (final entry in visibleEntries) ...[
                  _BookmarkEntryCard(
                    entry: entry,
                    selecting: _selecting,
                    selected: _selectedIds.contains(entry.id),
                    onTap: () => _selecting
                        ? _toggleSelected(entry)
                        : _openEntry(context, entry),
                    onLongPress: () => _selecting
                        ? _toggleSelected(entry)
                        : _enterSelection(entry),
                  ),
                  if (entry != visibleEntries.last) const SizedBox(height: 10),
                ],
            ],
          ],
        ),
        bottomNavigationBar: _selecting
            ? _BulkActionBar(
                selectedCount: selectedEntries.length,
                onCancel: _exitSelection,
                onDelete: selectedEntries.isEmpty
                    ? null
                    : () => _confirmDeleteSelected(selectedEntries),
              )
            : null,
      ),
    );
  }

  void _openEntry(BuildContext context, BookmarkEntry entry) {
    context.push(
      '${AppRoutes.reader}/${entry.bookId}'
      '?chapter=${entry.chapterIndex}&offset=${entry.offset}',
    );
  }

  Future<void> _confirmDeleteSelected(
    List<BookmarkEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: DudoColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            '删除 ${entries.length} 条标记？',
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
    if (confirmed != true || !mounted) return;

    await ref.read(bookmarksRepositoryProvider).deleteEntries(entries);
    if (!mounted) return;
    _exitSelection();
  }
}

class _BookmarksHeader extends StatelessWidget {
  const _BookmarksHeader({
    required this.onOpenOptions,
    required this.optionsActive,
  });

  final VoidCallback onOpenOptions;
  final bool optionsActive;

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: '书签',
      height: _headerHeight,
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
        key: const ValueKey('bookmarks-filter-button'),
        icon: LucideIcons.slidersHorizontal,
        iconSize: 20,
        backgroundColor: optionsActive ? DudoColors.primaryContainer : null,
        iconColor: optionsActive ? DudoColors.primary : null,
        borderColor: optionsActive
            ? DudoColors.primaryContainerStrong
            : DudoColors.outline,
        onTap: onOpenOptions,
      ),
    );
  }
}

/// Replaces the page header while bulk selection is active (Pencil G3).
class _BulkSelectBar extends StatelessWidget {
  const _BulkSelectBar({
    required this.selectedCount,
    required this.allSelected,
    required this.onExit,
    required this.onToggleAll,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onExit;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('bookmarks-bulk-bar'),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const ValueKey('bookmarks-selection-exit'),
              onTap: onExit,
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 17,
                  color: DudoColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '批量选择',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '已选 $selectedCount 项',
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
          Material(
            color: DudoColors.primaryContainer,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              key: const ValueKey('bookmarks-select-all'),
              onTap: onToggleAll,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 15,
                      color: DudoColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allSelected ? '取消全选' : '全选',
                      style: DudoTextStyles.sans(
                        color: DudoColors.primary,
                        fontSize: 13,
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
    );
  }
}

/// The bottom delete bar shown while bulk selection is active (Pencil G3).
class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3325251F),
            offset: Offset(0, -12),
            blurRadius: 28,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _BulkActionButton(
                key: const ValueKey('bookmarks-selection-cancel'),
                label: '取消',
                background: DudoColors.surfaceLow,
                foreground: DudoColors.secondary,
                onTap: onCancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BulkActionButton(
                key: const ValueKey('bookmarks-selection-delete'),
                label: '删除 $selectedCount 项',
                icon: LucideIcons.trash2,
                background: onDelete == null
                    ? DudoColors.outlineVariant
                    : DudoColors.textPrimary,
                foreground: onDelete == null
                    ? DudoColors.secondary
                    : DudoColors.surfaceHigh,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: 13,
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

class _BookmarkSummary extends StatelessWidget {
  const _BookmarkSummary({required this.entries});

  final List<BookmarkEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final bookCount = entries.map((entry) => entry.bookId).toSet().length;

    return Container(
      height: _summaryHeight,
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
                  '$total 条标记 · $bookCount 本书',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recentBooksLabel(entries),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    required this.selected,
    required this.onSelected,
  });

  final BookmarkEntryType? selected;
  final ValueChanged<BookmarkEntryType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final types = <BookmarkEntryType?>[null, ...BookmarkEntryType.values];
    return Row(
      children: [
        for (final type in types) ...[
          if (type != null) const SizedBox(width: 8),
          Expanded(
            child: _BookmarkFilterChip(
              key: ValueKey(
                type == null
                    ? 'bookmark-filter-all'
                    : 'bookmark-filter-${type.name}',
              ),
              label: type?.label ?? '全部',
              selected: selected == type,
              onTap: () => onSelected(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookmarkFilterChip extends StatelessWidget {
  const _BookmarkFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: _chipHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.surfaceHigh : DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pencil G4: the empty state for an active type filter. It has no card
/// frame; it fills the space left below the chips so the content sits in the
/// middle of the page instead of hugging the filter row.
class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.height,
    required this.typeLabel,
  });

  final double height;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('bookmarks-filtered-empty'),
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.bookmarkX,
              color: DudoColors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '没有符合条件的标记',
            textAlign: TextAlign.center,
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              '「$typeLabel」下还没有标记，换个类型看看。',
              textAlign: TextAlign.center,
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
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
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final BookmarkEntry entry;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.type) {
      BookmarkEntryType.bookmark => DudoColors.primary,
      BookmarkEntryType.highlight => DudoColors.accent,
      BookmarkEntryType.note => DudoColors.secondary,
    };
    final icon = switch (entry.type) {
      BookmarkEntryType.bookmark => LucideIcons.bookmark,
      BookmarkEntryType.highlight => LucideIcons.highlighter,
      BookmarkEntryType.note => LucideIcons.quote,
    };
    final excerpt = entry.excerpt;
    final note = entry.note?.trim();

    return Semantics(
      selected: selected,
      child: Material(
        key: ValueKey('bookmark-entry-${entry.id}'),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Row(
                  // Center the type mark against the whole card body instead
                  // of pinning it to the first line of text.
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      key: ValueKey('bookmark-mark-${entry.id}'),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: DudoColors.surfaceLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        // The G3 check floats over the card's right edge, so
                        // reserve its width instead of letting text slide
                        // underneath it.
                        padding: EdgeInsets.only(right: selecting ? 34 : 0),
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
                              ),
                            ),
                            if (excerpt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                excerpt,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: DudoTextStyles.serif(
                                  color: DudoColors.textPrimary,
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            if (note != null && note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '笔记：$note',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DudoTextStyles.sans(
                                  color: DudoColors.primary,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _timeLabel(entry.createdAt),
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
                    ),
                  ],
                ),
                if (selecting)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 4,
                    child: Center(
                      child: _SelectionIndicator(
                        key: ValueKey('bookmark-select-${entry.id}'),
                        selected: selected,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? DudoColors.primary : DudoColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? DudoColors.primary : DudoColors.outline,
        ),
      ),
      child: selected
          ? Icon(
              LucideIcons.check,
              size: 15,
              color: DudoColors.surfaceHigh,
            )
          : null,
    );
  }
}

class _BookmarkEmptySummary extends StatelessWidget {
  const _BookmarkEmptySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _summaryHeight,
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
  const _BookmarkOptions.sort(this.sort) : manage = false;

  const _BookmarkOptions.manage()
      : sort = null,
        manage = true;

  final _BookmarkSort? sort;
  final bool manage;
}

class _BookmarkOptionsSheet extends StatelessWidget {
  const _BookmarkOptionsSheet({required this.sort, required this.total});

  final _BookmarkSort sort;
  final int total;

  @override
  Widget build(BuildContext context) {
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
                        '排序与整理',
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
          const _OptionsSectionTitle('排序方式'),
          for (final option in _BookmarkSort.values)
            _BookmarkOptionRow(
              key: ValueKey('bookmark-option-sort-${option.name}'),
              label: option.label,
              selected: sort == option,
              onTap: () => Navigator.of(context).pop(
                _BookmarkOptions.sort(option),
              ),
            ),
          if (total > 0) ...[
            const SizedBox(height: 6),
            const _OptionsSectionTitle('整理'),
            _BookmarkOptionRow(
              key: const ValueKey('bookmark-option-manage'),
              label: '批量管理',
              countLabel: '$total 条',
              trailingIcon: LucideIcons.chevronRight,
              selected: false,
              onTap: () => Navigator.of(context).pop(
                const _BookmarkOptions.manage(),
              ),
            ),
          ],
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
    this.trailingIcon,
  });

  final String label;
  final String? countLabel;
  final IconData? trailingIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = this.countLabel;
    final trailingIcon = this.trailingIcon;
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
                  child: trailingIcon != null
                      ? Icon(
                          trailingIcon,
                          color: DudoColors.secondary,
                          size: 18,
                        )
                      : selected
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

String _recentBooksLabel(List<BookmarkEntry> entries) {
  final titles = <String>[];
  final sorted = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final entry in sorted) {
    final title = entry.bookTitle.trim();
    if (title.isEmpty || titles.contains(title)) continue;
    titles.add(title);
    if (titles.length == 2) break;
  }
  if (titles.isEmpty) return '阅读时添加的书签和高亮会收集在这里。';
  if (titles.length == 1) {
    return '最近摘录来自《${titles.first}》，适合继续整理笔记。';
  }
  return '最近摘录来自《${titles[0]}》和《${titles[1]}》，适合继续整理笔记。';
}

const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String _timeLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  final time = '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
  if (days == 0) return '今天 $time';
  if (days == 1) return '昨天 $time';
  if (days > 1 && days < 7) {
    return '${_weekdayLabels[date.weekday - 1]} $time';
  }
  if (date.year == now.year) return '${date.month} 月 ${date.day} 日';
  return '${date.year} 年 ${date.month} 月 ${date.day} 日';
}
