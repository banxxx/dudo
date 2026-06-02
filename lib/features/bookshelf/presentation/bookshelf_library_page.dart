import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../application/bookshelf_providers.dart';

class BookshelfLibraryPage extends ConsumerStatefulWidget {
  const BookshelfLibraryPage({super.key});

  @override
  ConsumerState<BookshelfLibraryPage> createState() =>
      _BookshelfLibraryPageState();
}

class _BookshelfLibraryPageState extends ConsumerState<BookshelfLibraryPage> {
  bool _isManaging = false;
  bool _isDeleting = false;
  final Set<String> _selectedBookIds = <String>{};
  final GlobalKey<_BookshelfManageOverlayState> _manageOverlayKey =
      GlobalKey<_BookshelfManageOverlayState>();
  OverlayEntry? _manageOverlay;

  @override
  void dispose() {
    _removeManageOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(shelfBooksProvider);
    final tipsDismissed = ref.watch(bookshelfTipsDismissedProvider);
    final items = books.valueOrNull;
    final showTips = items?.isEmpty == true && !tipsDismissed;
    if (items != null) _pruneSelection(items);

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        children: [
          const _BookshelfHeader(),
          const SizedBox(height: 20),
          books.when(
            data: (items) => items.isEmpty
                ? _EmptyBookshelfCard(onImport: _importLocalBook)
                : _ShelfBooksSection(
                    books: items,
                    isManaging: _isManaging,
                    selectedBookIds: _selectedBookIds,
                    onManage: () => _enterManageMode(items),
                    onToggleBook: _toggleSelection,
                  ),
            loading: () => const _BookshelfLoadingCard(),
            error: (_, __) => _BookshelfErrorCard(
                onRetry: () => ref.invalidate(shelfBooksProvider)),
          ),
          if (showTips) ...[
            const SizedBox(height: 20),
            _LibraryTipsSection(
              onDismiss: () => ref
                  .read(bookshelfTipsDismissedProvider.notifier)
                  .state = true,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importLocalBook() async {
    await ref.read(localBookImportServiceProvider).importTxtBook();
    ref.invalidate(shelfBooksProvider);
  }

  void _enterManageMode(List<Book> books) {
    setState(() => _isManaging = true);
    _showManageOverlay(books);
  }

  Future<void> _exitManageMode() async {
    if (!_isManaging) return;
    await _manageOverlayKey.currentState?.close();
    if (!mounted) return;
    setState(() {
      _isManaging = false;
      _selectedBookIds.clear();
    });
    _removeManageOverlay();
  }

  void _toggleSelection(String bookId) {
    setState(() {
      if (!_selectedBookIds.add(bookId)) {
        _selectedBookIds.remove(bookId);
      }
    });
    _manageOverlay?.markNeedsBuild();
  }

  void _toggleSelectAll(List<Book> books) {
    final ids = books.map((book) => book.id).toSet();
    setState(() {
      if (_selectedBookIds.length == ids.length) {
        _selectedBookIds.clear();
      } else {
        _selectedBookIds
          ..clear()
          ..addAll(ids);
      }
    });
    _manageOverlay?.markNeedsBuild();
  }

  void _pruneSelection(List<Book> books) {
    final ids = books.map((book) => book.id).toSet();
    _selectedBookIds.removeWhere((id) => !ids.contains(id));
    if (books.isEmpty && _isManaging) {
      _isManaging = false;
      _selectedBookIds.clear();
      _removeManageOverlay();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manageOverlay?.markNeedsBuild();
    });
  }

  void _showManageOverlay(List<Book> books) {
    _removeManageOverlay();
    _manageOverlay = OverlayEntry(
      builder: (context) => _BookshelfManageOverlay(
        key: _manageOverlayKey,
        books: books,
        selectedBookIds: _selectedBookIds,
        isDeleting: _isDeleting,
        onExit: _exitManageMode,
        onSelectAll: () => _toggleSelectAll(books),
        onCancel: _exitManageMode,
        onDelete: _deleteSelectedBooks,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_manageOverlay!);
  }

  void _removeManageOverlay() {
    _manageOverlay?.remove();
    _manageOverlay = null;
  }

  Future<void> _deleteSelectedBooks() async {
    if (_selectedBookIds.isEmpty || _isDeleting) return;

    setState(() => _isDeleting = true);
    _manageOverlay?.markNeedsBuild();
    try {
      final deletedCount = await ref
          .read(localBookImportServiceProvider)
          .deleteLocalBooksByIds(_selectedBookIds);
      ref.invalidate(shelfBooksProvider);
      if (!mounted) return;
      await _manageOverlayKey.currentState?.close();
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isManaging = false;
        _selectedBookIds.clear();
      });
      _removeManageOverlay();
      ref.read(appMessageServiceProvider).success(
            '已从书架和本机缓存中移除',
            title: '已删除 $deletedCount 本本地书籍',
            position: AppMessagePosition.top,
            dedupeKey: 'bookshelf-delete-local-books',
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _manageOverlay?.markNeedsBuild();
      ref.read(appMessageServiceProvider).error(
            '请稍后重试',
            title: '删除失败',
            position: AppMessagePosition.top,
            dedupeKey: 'bookshelf-delete-local-books',
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }
}

class _BookshelfHeader extends StatelessWidget {
  const _BookshelfHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '晚上好，Ban',
          style: DudoTextStyles.sans(
            color: DudoColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '我的书架',
          style: DudoTextStyles.serif(
            color: DudoColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ShelfBooksSection extends StatelessWidget {
  const _ShelfBooksSection({
    required this.books,
    required this.isManaging,
    required this.selectedBookIds,
    required this.onManage,
    required this.onToggleBook,
  });

  final List<Book> books;
  final bool isManaging;
  final Set<String> selectedBookIds;
  final VoidCallback onManage;
  final void Function(String bookId) onToggleBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已导入 ${books.length} 本',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: isManaging ? null : onManage,
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.primary,
                disabledForegroundColor: DudoColors.secondary,
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: DudoTextStyles.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(isManaging ? '管理中' : '管理'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final cardWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < books.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: _ShelfBookCard(
                      book: books[index],
                      paletteIndex: index,
                      isManaging: isManaging,
                      isSelected: selectedBookIds.contains(books[index].id),
                      onTap: isManaging
                          ? () => onToggleBook(books[index].id)
                          : () => context.push(
                                '${AppRoutes.reader}/${books[index].id}?chapter=${books[index].lastChapterIndex}',
                              ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BookshelfManageOverlay extends StatefulWidget {
  const _BookshelfManageOverlay({
    super.key,
    required this.books,
    required this.selectedBookIds,
    required this.isDeleting,
    required this.onExit,
    required this.onSelectAll,
    required this.onCancel,
    required this.onDelete,
  });

  final List<Book> books;
  final Set<String> selectedBookIds;
  final bool isDeleting;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  State<_BookshelfManageOverlay> createState() =>
      _BookshelfManageOverlayState();
}

class _BookshelfManageOverlayState extends State<_BookshelfManageOverlay> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  Future<void> close() async {
    if (!_visible) return;
    if (mounted) setState(() => _visible = false);
    await Future<void>.delayed(AppMotion.medium);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            top: media.padding.top + 20,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1.35),
                duration: AppMotion.medium,
                curve: Curves.easeOutCubic,
                child: _BookshelfManageBar(
                  selectedCount: widget.selectedBookIds.length,
                  allSelected:
                      widget.selectedBookIds.length == widget.books.length,
                  onExit: widget.onExit,
                  onSelectAll: widget.onSelectAll,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 1.2),
                duration: AppMotion.medium,
                curve: Curves.easeOutCubic,
                child: _BookshelfManageBottomBar(
                  selectedCount: widget.selectedBookIds.length,
                  isDeleting: widget.isDeleting,
                  onCancel: widget.onCancel,
                  onDelete: widget.onDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookshelfManageBar extends StatelessWidget {
  const _BookshelfManageBar({
    required this.selectedCount,
    required this.allSelected,
    required this.onExit,
    required this.onSelectAll,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.67)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F25251F),
            offset: Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Row(
        children: [
          _RoundManageButton(
            icon: LucideIcons.x,
            onTap: onExit,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '管理书架',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '已选 $selectedCount 本',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _ManageChipButton(
            label: allSelected ? '取消全选' : '全选',
            icon: LucideIcons.check,
            onTap: onSelectAll,
          ),
        ],
      ),
    );
  }
}

class _RoundManageButton extends StatelessWidget {
  const _RoundManageButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: DudoColors.secondary, size: 17),
        ),
      ),
    );
  }
}

class _ManageChipButton extends StatelessWidget {
  const _ManageChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.primaryContainer,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DudoColors.primary, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
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

class _BookshelfManageBottomBar extends StatelessWidget {
  const _BookshelfManageBottomBar({
    required this.selectedCount,
    required this.isDeleting,
    required this.onCancel,
    required this.onDelete,
  });

  final int selectedCount;
  final bool isDeleting;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canDelete = selectedCount > 0 && !isDeleting;

    return Container(
      height: 128,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.67)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2625251F),
            offset: Offset(0, 14),
            blurRadius: 34,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ManageActionButton(
              label: '取消',
              background: DudoColors.surfaceLow,
              foreground: DudoColors.secondary,
              onTap: onCancel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ManageActionButton(
              label: canDelete ? '删除 $selectedCount 本' : '请选择书籍',
              icon: LucideIcons.archive,
              background: canDelete
                  ? DudoColors.textPrimary
                  : DudoColors.outlineVariant,
              foreground:
                  canDelete ? DudoColors.surfaceHigh : DudoColors.secondary,
              onTap: canDelete ? onDelete : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageActionButton extends StatelessWidget {
  const _ManageActionButton({
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 17),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: 14,
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

class _ShelfBookCard extends StatelessWidget {
  const _ShelfBookCard({
    required this.book,
    required this.paletteIndex,
    required this.isManaging,
    required this.isSelected,
    required this.onTap,
  });

  final Book book;
  final int paletteIndex;
  final bool isManaging;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStarted = book.lastChapterIndex > 0 || book.lastReadPosition > 0;
    final palette = _coverPalettes[paletteIndex % _coverPalettes.length];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: AppMotion.short,
              height: 146,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DudoColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? DudoColors.primary
                      : DudoColors.outlineVariant,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x1F5E6F5B),
                          offset: Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                children: [
                  _ShelfBookCover(
                    title: book.title,
                    startColor: palette.start,
                    endColor: palette.end,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 102,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            book.author ?? '本地文件',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          _ReadingStateChip(isStarted: isStarted),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isManaging)
              Positioned(
                top: 10,
                right: 10,
                child: _BookSelectionMark(isSelected: isSelected),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookSelectionMark extends StatelessWidget {
  const _BookSelectionMark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isSelected ? DudoColors.primary : DudoColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected ? DudoColors.surfaceHigh : DudoColors.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(LucideIcons.check,
              color: DudoColors.surfaceHigh, size: 15)
          : null,
    );
  }
}

class _ShelfBookCover extends StatelessWidget {
  const _ShelfBookCover({
    required this.title,
    required this.startColor,
    required this.endColor,
  });

  final String title;
  final Color startColor;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    final coverTitle = title.characters.take(4).toString();

    return Container(
      width: 72,
      height: 102,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [startColor, endColor],
        ),
      ),
      child: Text(
        coverTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: DudoTextStyles.serif(
          color: DudoColors.surfaceHigh,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }
}

class _ReadingStateChip extends StatelessWidget {
  const _ReadingStateChip({required this.isStarted});

  final bool isStarted;

  @override
  Widget build(BuildContext context) {
    final background =
        isStarted ? DudoColors.primaryContainer : DudoColors.surfaceLow;
    final foreground = isStarted ? DudoColors.primary : DudoColors.secondary;

    return Container(
      height: 28,
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        isStarted ? '阅读中' : '未读',
        style: DudoTextStyles.sans(
          color: foreground,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CoverPalette {
  const _CoverPalette(this.start, this.end);

  final Color start;
  final Color end;
}

const _coverPalettes = [
  _CoverPalette(Color(0xFF6F7E68), DudoColors.primaryContainer),
  _CoverPalette(DudoColors.secondary, DudoColors.secondaryContainer),
  _CoverPalette(Color(0xFF5A6B84), Color(0xFFD7E0EA)),
  _CoverPalette(Color(0xFF9A6D45), Color(0xFFE8C99B)),
];

class _BookshelfLoadingCard extends StatelessWidget {
  const _BookshelfLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: DudoColors.primary),
    );
  }
}

class _BookshelfErrorCard extends StatelessWidget {
  const _BookshelfErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '书架加载失败',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _PillActionButton(
            label: '重试',
            icon: LucideIcons.refreshCw,
            background: DudoColors.textPrimary,
            foreground: DudoColors.surfaceHigh,
            borderColor: Colors.transparent,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyBookshelfCard extends StatelessWidget {
  const _EmptyBookshelfCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _EmptyShelfIllustration(),
          const SizedBox(height: 12),
          Text(
            '书架还是空的',
            style: DudoTextStyles.serif(
              color: DudoColors.onPrimaryContainer,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '把喜欢的作品加入书架后，阅读进度、收藏和缓存都会在这里安静地整理好。',
            style: DudoTextStyles.sans(
              color: DudoColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _EmptyStateActions(onImport: onImport),
        ],
      ),
    );
  }
}

class _EmptyShelfIllustration extends StatelessWidget {
  const _EmptyShelfIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.primaryContainerStrong),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _IllustrationBook(
                  width: 22,
                  height: 32,
                  color: DudoColors.primary,
                ),
                SizedBox(width: 7),
                _IllustrationBook(
                  width: 20,
                  height: 40,
                  color: DudoColors.secondary,
                ),
                SizedBox(width: 7),
                _IllustrationBook(
                  width: 22,
                  height: 28,
                  color: DudoColors.accentSoft,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: DudoColors.outline,
              borderRadius: AppRadius.full,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationBook extends StatelessWidget {
  const _IllustrationBook({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _EmptyStateActions extends StatelessWidget {
  const _EmptyStateActions({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillActionButton(
          label: '去找书',
          icon: LucideIcons.search,
          background: DudoColors.textPrimary,
          foreground: DudoColors.surfaceHigh,
          borderColor: Colors.transparent,
          labelFirst: true,
          onPressed: () => context.go(AppRoutes.search),
        ),
        const SizedBox(width: 8),
        _PillActionButton(
          label: '导入本地',
          icon: LucideIcons.fileUp,
          background: DudoColors.surface,
          foreground: DudoColors.primary,
          borderColor: DudoColors.outline,
          onPressed: onImport,
        ),
      ],
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.onPressed,
    this.labelFirst = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onPressed;
  final bool labelFirst;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: DudoTextStyles.sans(
        color: foreground,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
    final iconWidget = Icon(icon, color: foreground, size: 15);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.full,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: labelFirst
                ? [
                    labelText,
                    const SizedBox(width: 6),
                    iconWidget,
                  ]
                : [
                    iconWidget,
                    const SizedBox(width: 6),
                    labelText,
                  ],
          ),
        ),
      ),
    );
  }
}

class _LibraryTipsSection extends StatelessWidget {
  const _LibraryTipsSection({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '可以从这里开始',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.secondary,
                textStyle: DudoTextStyles.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: const Text('稍后再说'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _TipCard(
          icon: LucideIcons.search,
          title: '去搜索发现书籍',
          description: '从全站书源中找到想读的作品',
        ),
        const SizedBox(height: 6),
        const _TipCard(
          icon: LucideIcons.fileUp,
          title: '导入本地文件',
          description: '把已有的 txt、epub 放进书架',
        ),
        const SizedBox(height: 6),
        const _TipCard(
          icon: LucideIcons.bookmarkPlus,
          title: '收藏推荐作品',
          description: '遇到感兴趣的书，先加入待读清单',
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
      height: 62,
      padding: const EdgeInsets.all(10),
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
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: DudoColors.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
