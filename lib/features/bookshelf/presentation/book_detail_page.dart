import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../application/bookshelf_providers.dart';

const _chapterCatalogPageSize = 80;
const _chapterCatalogPrefetchExtent = 900.0;

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Chapter> _catalogChapters = [];
  bool _showMoreMenu = false;
  bool _isAddingToShelf = false;
  bool _isLoadingCatalogPage = false;
  bool _hasMoreCatalogPages = true;
  bool _backfillStarted = false;
  Timer? _backfillTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybePrefetchCatalogPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadNextCatalogPage());
    });
  }

  @override
  void dispose() {
    _backfillTimer?.cancel();
    _scrollController.removeListener(_maybePrefetchCatalogPage);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookValue = ref.watch(bookByIdProvider(widget.bookId));
    final chapterCountValue =
        ref.watch(bookChapterCountProvider(widget.bookId));

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: bookValue.when(
        data: (book) {
          if (book == null) return _BookMissingState(onBack: _goBack);
          final chapterCount =
              chapterCountValue.valueOrNull ?? _catalogChapters.length;
          final chaptersLoading = _catalogChapters.isEmpty &&
              (_isLoadingCatalogPage || chapterCountValue.isLoading);
          final currentChapterValue = ref.watch(
            currentBookChapterMetaProvider(
              CurrentBookChapterKey(
                bookId: widget.bookId,
                chapterIndex: book.lastChapterIndex,
              ),
            ),
          );
          final currentChapter = currentChapterValue.valueOrNull;
          if (chapterCount > 0) _scheduleLengthBackfill();

          return Stack(
            children: [
              _BookDetailScrollView(
                controller: _scrollController,
                book: book,
                chapters: _catalogChapters,
                chapterCount: chapterCount,
                currentChapter: currentChapter,
                chaptersLoading: chaptersLoading,
                loadingMoreChapters: _isLoadingCatalogPage,
                hasMoreChapters: _hasMoreCatalogPages,
                isAddingToShelf: _isAddingToShelf,
                onRead: () => _openReader(book, chapterCount),
                onAddToShelf: () => _addToShelf(book),
                onChapterTap: (chapterIndex) =>
                    _openReader(book, chapterCount, chapterIndex: chapterIndex),
              ),
              _PinnedBookDetailTopBar(
                onBack: _goBack,
                onMore: () => setState(() => _showMoreMenu = true),
                onDoubleTap: _scrollToTop,
              ),
              if (_showMoreMenu)
                _BookMoreOverlay(
                  onDismiss: () => setState(() => _showMoreMenu = false),
                  onAction: (title) => _handleMoreAction(title, book),
                ),
            ],
          );
        },
        loading: () => const _BookDetailLoadingState(),
        error: (_, __) => _BookDetailErrorState(
          onRetry: () {
            _resetCatalogPaging();
            ref.invalidate(bookByIdProvider(widget.bookId));
            ref.invalidate(bookChapterCountProvider(widget.bookId));
            ref.invalidate(bookChapterMetasProvider(widget.bookId));
          },
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.bookshelf);
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleLengthBackfill() {
    if (_backfillStarted) return;
    _backfillStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _backfillTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        unawaited(
          ref
              .read(bookshelfRepositoryProvider)
              .backfillNormalizedContentLengths(widget.bookId),
        );
      });
    });
  }

  void _maybePrefetchCatalogPage() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > _chapterCatalogPrefetchExtent) return;
    unawaited(_loadNextCatalogPage());
  }

  Future<void> _loadNextCatalogPage() async {
    if (_isLoadingCatalogPage || !_hasMoreCatalogPages) return;
    setState(() => _isLoadingCatalogPage = true);
    try {
      final page =
          await ref.read(bookshelfRepositoryProvider).fetchChapterMetasPage(
                bookId: widget.bookId,
                offset: _catalogChapters.length,
                limit: _chapterCatalogPageSize,
              );
      if (!mounted) return;
      setState(() {
        _catalogChapters.addAll(page);
        _hasMoreCatalogPages = page.length == _chapterCatalogPageSize;
        _isLoadingCatalogPage = false;
      });
      _maybePrefetchCatalogPage();
    } catch (_) {
      if (mounted) setState(() => _isLoadingCatalogPage = false);
    }
  }

  void _resetCatalogPaging() {
    _catalogChapters.clear();
    _hasMoreCatalogPages = true;
    _isLoadingCatalogPage = false;
    unawaited(_loadNextCatalogPage());
  }

  void _openReader(
    Book book,
    int chapterCount, {
    int? chapterIndex,
  }) {
    if (chapterCount <= 0) {
      ref.read(appMessageServiceProvider).warning(
            '导入或刷新章节后再试',
            title: '暂无章节内容',
            position: AppMessagePosition.top,
            dedupeKey: 'book-detail-no-chapters',
          );
      return;
    }
    final targetChapter = chapterIndex ?? book.lastChapterIndex;
    context.push('${AppRoutes.reader}/${book.id}?chapter=$targetChapter');
  }

  Future<void> _addToShelf(Book book) async {
    if (book.inShelf || _isAddingToShelf) return;
    setState(() => _isAddingToShelf = true);
    try {
      await ref.read(bookshelfRepositoryProvider).addBookToShelf(book.id);
      if (!mounted) return;
      ref.read(appMessageServiceProvider).success(
            '可以从书架继续打开这本书',
            title: '已加入书架',
            position: AppMessagePosition.top,
            dedupeKey: 'book-detail-add-shelf',
          );
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).error(
            '请稍后重试',
            title: '加入书架失败',
            position: AppMessagePosition.top,
            dedupeKey: 'book-detail-add-shelf',
          );
    } finally {
      if (mounted) setState(() => _isAddingToShelf = false);
    }
  }

  void _handleMoreAction(String title, Book book) {
    setState(() => _showMoreMenu = false);
    if (title == '更新目录' && book.localPath != null) {
      ref.read(localBookChapterAnalysisServiceProvider).analyzeInBackground(
            bookId: book.id,
            localPath: book.localPath!,
          );
      ref.read(appMessageServiceProvider).info(
            '正在重新分析本地目录',
            title: title,
            position: AppMessagePosition.top,
            dedupeKey: 'book-detail-more-$title',
          );
      return;
    }
    ref.read(appMessageServiceProvider).info(
          '这个功能还在完善中',
          title: title,
          position: AppMessagePosition.top,
          dedupeKey: 'book-detail-more-$title',
        );
  }
}

class _BookDetailScrollView extends StatelessWidget {
  const _BookDetailScrollView({
    required this.controller,
    required this.book,
    required this.chapters,
    required this.chapterCount,
    required this.currentChapter,
    required this.chaptersLoading,
    required this.loadingMoreChapters,
    required this.hasMoreChapters,
    required this.isAddingToShelf,
    required this.onRead,
    required this.onAddToShelf,
    required this.onChapterTap,
  });

  final ScrollController controller;
  final Book book;
  final List<Chapter> chapters;
  final int chapterCount;
  final Chapter? currentChapter;
  final bool chaptersLoading;
  final bool loadingMoreChapters;
  final bool hasMoreChapters;
  final bool isAddingToShelf;
  final VoidCallback onRead;
  final VoidCallback onAddToShelf;
  final ValueChanged<int> onChapterTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = _horizontalPaddingForWidth(width);
    final maxWidth = _maxWidthForWidth(width);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            controller: controller,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 64, horizontalPadding, 10),
                sliver: SliverToBoxAdapter(
                  child: _BookDetailHeaderContent(
                    book: book,
                    chapters: chapters,
                    chapterCount: chapterCount,
                    currentChapter: currentChapter,
                    chaptersLoading: chaptersLoading,
                    isAddingToShelf: isAddingToShelf,
                    onRead: onRead,
                    onAddToShelf: onAddToShelf,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverToBoxAdapter(
                  child: _ChapterListHeader(
                    chapterCount: chapterCount,
                    loadingMoreChapters: loadingMoreChapters,
                  ),
                ),
              ),
              if (chaptersLoading && chapters.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: const SliverToBoxAdapter(
                    child: _ChapterListMessageTile(message: '正在加载目录...'),
                  ),
                )
              else if (chapters.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: const SliverToBoxAdapter(
                    child: _ChapterListMessageTile(message: '章节计算中'),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList.builder(
                    itemCount: chapters.length +
                        (loadingMoreChapters || hasMoreChapters ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chapters.length) {
                        return const _RemainingChaptersLoadingTile();
                      }
                      final chapter = chapters[index];
                      return _ChapterListTile(
                        chapter: chapter,
                        isFirst: index == 0,
                        isLast: index == chapters.length - 1 &&
                            !loadingMoreChapters &&
                            !hasMoreChapters,
                        onTap: () => onChapterTap(chapter.chapterIndex),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
            ],
          ),
        ),
      ),
    );
  }

  double _horizontalPaddingForWidth(double width) {
    if (width < DudoLayout.compactPhoneWidth) return 16;
    if (Breakpoints.isDesktopWidth(width)) return 40;
    if (Breakpoints.isTabletWidth(width)) return 32;
    return 20;
  }

  double _maxWidthForWidth(double width) {
    if (Breakpoints.isDesktopWidth(width)) {
      return DudoLayout.desktopContentMaxWidth;
    }
    if (Breakpoints.isTabletWidth(width)) {
      return DudoLayout.tabletContentMaxWidth;
    }
    return DudoLayout.phoneContentMaxWidth;
  }
}

class _BookDetailHeaderContent extends StatelessWidget {
  const _BookDetailHeaderContent({
    required this.book,
    required this.chapters,
    required this.chapterCount,
    required this.currentChapter,
    required this.chaptersLoading,
    required this.isAddingToShelf,
    required this.onRead,
    required this.onAddToShelf,
  });

  final Book book;
  final List<Chapter> chapters;
  final int chapterCount;
  final Chapter? currentChapter;
  final bool chaptersLoading;
  final bool isAddingToShelf;
  final VoidCallback onRead;
  final VoidCallback onAddToShelf;

  @override
  Widget build(BuildContext context) {
    final hasStarted = book.lastChapterIndex > 0 || book.lastReadPosition > 0;
    final showProgress = hasStarted;
    final chapterProgress = _chapterProgressPercent(book, currentChapter);
    final bookProgress =
        _bookProgressPercent(book, chapterCount, currentChapter);

    return Column(
      children: [
        _BookHeroSection(
          book: book,
          compact: showProgress,
        ),
        const SizedBox(height: 14),
        _BookActionRow(
          inShelf: book.inShelf,
          hasStarted: hasStarted,
          isAddingToShelf: isAddingToShelf,
          onRead: onRead,
          onAddToShelf: onAddToShelf,
        ),
        if (showProgress) ...[
          const SizedBox(height: 10),
          _BookProgressCard(
            progress: chapterProgress,
            currentChapterTitle: currentChapter?.title,
            chapterIndex: book.lastChapterIndex,
          ),
        ],
        const SizedBox(height: 10),
        _BookStatsRow(
          progress: bookProgress,
          chapterCount: chapterCount,
          chaptersLoading: chaptersLoading,
          progressLabel: showProgress ? '已读' : '进度',
        ),
        const SizedBox(height: 10),
        _BookIntroSection(intro: book.intro),
      ],
    );
  }

  int _chapterProgressPercent(Book book, Chapter? currentChapter) {
    if (book.lastChapterIndex <= 0 && book.lastReadPosition <= 0) return 0;
    final contentLength = currentChapter?.normalizedContentLength ?? 0;
    if (contentLength <= 0) return 0;
    return ((book.lastReadPosition.clamp(0, contentLength) / contentLength) *
            100)
        .round()
        .clamp(0, 100);
  }

  int _bookProgressPercent(
    Book book,
    int chapterCount,
    Chapter? currentChapter,
  ) {
    if (chapterCount <= 0) return 0;
    if (book.lastChapterIndex <= 0 && book.lastReadPosition <= 0) return 0;

    final current = book.lastChapterIndex.clamp(0, chapterCount - 1);
    final contentLength = currentChapter?.normalizedContentLength ?? 0;
    final chapterProgress = contentLength <= 0
        ? 0.0
        : book.lastReadPosition.clamp(0, contentLength).toDouble() /
            contentLength;
    return (((current + chapterProgress) / chapterCount) * 100)
        .round()
        .clamp(1, 100);
  }
}

class _PinnedBookDetailTopBar extends StatelessWidget {
  const _PinnedBookDetailTopBar({
    required this.onBack,
    required this.onMore,
    required this.onDoubleTap,
  });

  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: onDoubleTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 6, 20, 8),
          color: DudoColors.paperBackground,
          child: _BookDetailTopBar(onBack: onBack, onMore: onMore),
        ),
      ),
    );
  }
}

class _BookDetailTopBar extends StatelessWidget {
  const _BookDetailTopBar({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundActionButton(icon: LucideIcons.chevronLeft, onTap: onBack),
        _RoundActionButton(
          key: const ValueKey('book-detail-more-button'),
          icon: LucideIcons.ellipsis,
          onTap: onMore,
        ),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outline),
          ),
          child: Icon(icon, color: DudoColors.secondary, size: 22),
        ),
      ),
    );
  }
}

class _BookHeroSection extends StatelessWidget {
  const _BookHeroSection({required this.book, required this.compact});

  final Book book;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BookCover(
          book: book,
          width: compact ? 128 : 150,
          height: compact ? 168 : 198,
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: DudoTextStyles.serif(
            color: DudoColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _bookMeta(book),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: DudoTextStyles.sans(
            color: DudoColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _bookMeta(Book book) {
    final author =
        book.author?.trim().isEmpty == false ? book.author!.trim() : '未知作者';
    final source = book.localPath == null ? '在线书源' : '本地文件';
    return '$author · $source';
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover(
      {required this.book, required this.width, required this.height});

  final Book book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final title = book.title.trim().isEmpty ? '书' : book.title.trim();
    final author =
        book.author?.trim().isEmpty == false ? book.author!.trim() : 'Dudo';
    final coverUrl = book.coverUrl?.trim();

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: DudoColors.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x338A735A),
            offset: Offset(0, 18),
            blurRadius: 34,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: coverUrl == null || coverUrl.isEmpty
            ? _GeneratedBookCover(title: title, author: author)
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _GeneratedBookCover(
                  title: title,
                  author: author,
                ),
              ),
      ),
    );
  }
}

class _GeneratedBookCover extends StatelessWidget {
  const _GeneratedBookCover({required this.title, required this.author});

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DudoColors.textPrimary,
            DudoColors.primary,
            DudoColors.accentSoft,
          ],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '阅读收藏',
            style: DudoTextStyles.sans(
              color: DudoColors.surfaceHigh,
              fontSize: 12,
            ),
          ),
          Text(
            _compactCoverTitle(title),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: DudoTextStyles.serif(
              color: DudoColors.surfaceHigh,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: const Color(0xFFE8E4D8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _compactCoverTitle(String title) {
    final characters = title.runes.toList();
    if (characters.length <= 4) return title;
    return String.fromCharCodes(characters.take(4));
  }
}

class _BookActionRow extends StatelessWidget {
  const _BookActionRow({
    required this.inShelf,
    required this.hasStarted,
    required this.isAddingToShelf,
    required this.onRead,
    required this.onAddToShelf,
  });

  final bool inShelf;
  final bool hasStarted;
  final bool isAddingToShelf;
  final VoidCallback onRead;
  final VoidCallback onAddToShelf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: _PillActionButton(
              label: hasStarted ? '继续阅读' : '开始阅读',
              icon: LucideIcons.bookOpen,
              backgroundColor: DudoColors.textPrimary,
              foregroundColor: DudoColors.surfaceHigh,
              onTap: onRead,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 112,
            child: _PillActionButton(
              label: inShelf ? '已在书架' : '书架',
              icon: inShelf ? LucideIcons.check : LucideIcons.plus,
              backgroundColor: DudoColors.primaryContainer,
              foregroundColor: DudoColors.primary,
              borderColor: inShelf ? DudoColors.primaryContainerStrong : null,
              isLoading: isAddingToShelf,
              onTap: inShelf ? null : onAddToShelf,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: foregroundColor, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: DudoTextStyles.sans(
                          color: foregroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

class _BookProgressCard extends StatelessWidget {
  const _BookProgressCard({
    required this.progress,
    required this.currentChapterTitle,
    required this.chapterIndex,
  });

  final int progress;
  final String? currentChapterTitle;
  final int chapterIndex;

  @override
  Widget build(BuildContext context) {
    final chapterName = currentChapterTitle ?? '第 ${chapterIndex + 1} 章';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.primaryContainerStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '上次阅读',
                    style: DudoTextStyles.sans(
                      color: DudoColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已读到 $chapterName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.onPrimaryContainer,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$progress%',
                style: DudoTextStyles.numeric(
                  color: DudoColors.onPrimaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: DudoColors.primaryContainerMuted,
              color: DudoColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '继续从「$chapterName」开始，保留上次阅读的位置。',
            style: DudoTextStyles.sans(
              color: DudoColors.primaryDark,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookStatsRow extends StatelessWidget {
  const _BookStatsRow({
    required this.progress,
    required this.chapterCount,
    required this.chaptersLoading,
    required this.progressLabel,
  });

  final int progress;
  final int chapterCount;
  final bool chaptersLoading;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Expanded(child: _BookStatItem(value: '8.9', label: '评分')),
          Expanded(
            child: _BookStatItem(
              value: progress == 0 ? '还未开始阅读' : '$progress%',
              label: progressLabel,
            ),
          ),
          Expanded(
            child: _BookStatItem(
              value: chaptersLoading
                  ? '...'
                  : chapterCount == 0
                      ? '计算中'
                      : '$chapterCount',
              label: '章节',
            ),
          ),
        ],
      ),
    );
  }
}

class _BookStatItem extends StatelessWidget {
  const _BookStatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.serif(
            color: DudoColors.textPrimary,
            fontSize: value.length > 5
                ? 13
                : value.length > 3
                    ? 20
                    : 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BookIntroSection extends StatelessWidget {
  const _BookIntroSection({required this.intro});

  final String? intro;

  @override
  Widget build(BuildContext context) {
    final text = intro?.trim().isEmpty == false ? intro!.trim() : '暂无简介。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: DudoTextStyles.sans(
              color: DudoColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterListHeader extends StatelessWidget {
  const _ChapterListHeader({
    required this.chapterCount,
    required this.loadingMoreChapters,
  });

  final int chapterCount;
  final bool loadingMoreChapters;

  @override
  Widget build(BuildContext context) {
    final label = chapterCount <= 0 ? '' : '共 $chapterCount 章';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '目录',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              loadingMoreChapters && label.isEmpty ? '加载中' : label,
              style: DudoTextStyles.sans(
                color: DudoColors.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ChapterListMessageTile extends StatelessWidget {
  const _ChapterListMessageTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: DudoColors.secondary,
            size: 18,
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _RemainingChaptersLoadingTile extends StatelessWidget {
  const _RemainingChaptersLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DudoColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '正在加载更多章节',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterListTile extends StatelessWidget {
  const _ChapterListTile({
    required this.chapter,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Chapter chapter;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(18) : Radius.zero,
      bottom: isLast ? const Radius.circular(18) : Radius.zero,
    );

    return Material(
      color: DudoColors.surfaceLow,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.chevronRight,
                      color: DudoColors.secondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast)
              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: DudoColors.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _BookMoreOverlay extends StatelessWidget {
  const _BookMoreOverlay({required this.onDismiss, required this.onAction});

  final VoidCallback onDismiss;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 76;

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onDismiss,
            child: Container(color: const Color(0x2225251F)),
          ),
          Positioned(
            top: top,
            right: 20,
            child: AnimatedScale(
              scale: 1,
              duration: AppMotion.short,
              curve: AppMotion.emphasizedDecelerate,
              child: _BookMoreMenu(onAction: onAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookMoreMenu extends StatelessWidget {
  const _BookMoreMenu({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.67)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2625251F),
            offset: Offset(0, 12),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        children: [
          _BookMoreMenuItem(
            icon: LucideIcons.download,
            title: '缓存全书',
            description: '离线保留章节内容',
            onTap: () => onAction('缓存全书'),
          ),
          _BookMoreMenuItem(
            icon: LucideIcons.refreshCw,
            title: '更新目录',
            description: '同步最新章节',
            onTap: () => onAction('更新目录'),
          ),
          _BookMoreMenuItem(
            icon: LucideIcons.share2,
            title: '分享书籍',
            description: '生成书籍卡片',
            onTap: () => onAction('分享书籍'),
          ),
        ],
      ),
    );
  }
}

class _BookMoreMenuItem extends StatelessWidget {
  const _BookMoreMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: DudoColors.secondary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 10,
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

class _BookDetailLoadingState extends StatelessWidget {
  const _BookDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const DudoPageFrame(
      children: [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator(color: DudoColors.primary)),
      ],
    );
  }
}

class _BookDetailErrorState extends StatelessWidget {
  const _BookDetailErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DudoPageFrame(
      children: [
        const SizedBox(height: 120),
        ErrorStateView(
          title: '书籍详情加载失败',
          message: '请稍后重试',
          action: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: DudoColors.textPrimary,
              foregroundColor: DudoColors.surfaceHigh,
            ),
            child: const Text('重试'),
          ),
        ),
      ],
    );
  }
}

class _BookMissingState extends StatelessWidget {
  const _BookMissingState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DudoPageFrame(
      children: [
        const SizedBox(height: 120),
        ErrorStateView(
          title: '没有找到这本书',
          message: '它可能已经被移出书架。',
          action: FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              backgroundColor: DudoColors.textPrimary,
              foregroundColor: DudoColors.surfaceHigh,
            ),
            child: const Text('返回书架'),
          ),
        ),
      ],
    );
  }
}
