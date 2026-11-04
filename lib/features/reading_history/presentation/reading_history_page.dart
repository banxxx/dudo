import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../bookshelf/presentation/widgets/book_cover_palette.dart';
import '../../settings/shared/widgets/settings_detail_scaffold.dart';
import '../application/reading_history_provider.dart';
import '../domain/reading_history_entry.dart';

const _historyMessageKey = 'reading-history';
const _dangerText = Color(0xFFA8553A);

/// "最近打开" — the books the reader has started, newest first.
///
/// The weekly rhythm chart lives on the statistics page (home → 统计); this
/// page is the profile entry's list of books and where the reader left them.
class ReadingHistoryPage extends ConsumerStatefulWidget {
  const ReadingHistoryPage({super.key});

  @override
  ConsumerState<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends ConsumerState<ReadingHistoryPage> {
  ReadingHistoryFilter _filter = ReadingHistoryFilter.recent;
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(readingHistoryProvider);
    final entries = history.valueOrNull ?? const <ReadingHistoryEntry>[];
    final now = DateTime.now();

    return SettingsDetailScaffold(
      header: SettingsDetailHeader(
        eyebrow: '书房工具',
        title: '阅读记录',
        subtitle: '最近点开阅读过的书，会按时间整理在这里',
        actionLabel: '清空',
        showAction: entries.isNotEmpty,
        onActionTap: _clearing ? null : _clearHistory,
      ),
      children: [
        const SizedBox(height: 14),
        _HistoryFilters(
          filter: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 14),
        ..._content(history, now),
      ],
    );
  }

  List<Widget> _content(
    AsyncValue<List<ReadingHistoryEntry>> history,
    DateTime now,
  ) {
    if (history.isLoading && !history.hasValue) {
      return const [_HistoryLoadingCard()];
    }
    if (history.hasError) {
      return [
        _HistoryErrorCard(
          onRetry: () => ref.invalidate(readingHistoryProvider),
        ),
      ];
    }

    final visible = _visible(
      history.valueOrNull ?? const <ReadingHistoryEntry>[],
      now,
    );
    if (visible.isEmpty) {
      return [
        _HistoryEmptyCard(
          filter: _filter,
          onRead: () => context.go(AppRoutes.bookshelf),
        ),
      ];
    }

    return [
      for (var i = 0; i < visible.length; i++) ...[
        _HistoryCard(entry: visible[i], now: now),
        if (i != visible.length - 1) const SizedBox(height: 10),
      ],
    ];
  }

  List<ReadingHistoryEntry> _visible(
    List<ReadingHistoryEntry> entries,
    DateTime now,
  ) {
    final start = switch (_filter) {
      ReadingHistoryFilter.recent => null,
      ReadingHistoryFilter.week => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)),
      ReadingHistoryFilter.month => DateTime(now.year, now.month, 1),
    };
    if (start == null) return entries;
    return [
      for (final entry in entries)
        if (!entry.lastOpenedAt.isBefore(start)) entry,
    ];
  }

  Future<void> _clearHistory() async {
    if (_clearing) return;
    final confirmed = await _confirmClear();
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    try {
      await ref.read(readingHistoryRepositoryProvider).clear(DateTime.now());
      if (!mounted) return;
      setState(() => _clearing = false);
      ref.invalidate(readingHistoryClearedAtProvider);
      ref.read(appMessageServiceProvider).success(
            '已清空阅读记录',
            title: '操作完成',
            dedupeKey: _historyMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _clearing = false);
      ref.read(appMessageServiceProvider).error(
            '清空失败，请稍后重试。',
            title: '操作失败',
            dedupeKey: _historyMessageKey,
            visualStyle: AppMessageVisualStyle.paper,
          );
    }
  }

  Future<bool?> _confirmClear() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: DudoColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            '清空阅读记录？',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '只会清空“最近打开”列表，书籍和阅读进度都会保留。',
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
                '清空',
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.filter, required this.onChanged});

  final ReadingHistoryFilter filter;
  final ValueChanged<ReadingHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          for (final value in ReadingHistoryFilter.values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('reading-history-filter-${value.name}'),
                onTap: () => onChanged(value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == filter
                        ? DudoColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    value.label,
                    style: DudoTextStyles.sans(
                      color: value == filter
                          ? DudoColors.textPrimary
                          : DudoColors.secondary,
                      fontSize: 12,
                      fontWeight:
                          value == filter ? FontWeight.w600 : FontWeight.w400,
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.now});

  final ReadingHistoryEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final book = entry.book;
    final palette = bookCoverPaletteFor(book);
    final author = book.author?.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _openBook(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HistoryCover(title: book.title, palette: palette),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DudoTextStyles.sans(
                                  color: DudoColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TimePill(
                              key: ValueKey('reading-history-time-${book.id}'),
                              label: entry.timeLabel(now),
                              highlight: entry.openedToday(now),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          author == null || author.isEmpty ? '未知作者' : author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DudoTextStyles.sans(
                            color: DudoColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          entry.positionLabel,
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
              const SizedBox(height: 11),
              SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: DudoColors.surfaceLow,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (entry.percent / 100).clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _progressColor(palette),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(999)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    '已读 ${entry.percent}%',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  _ContinueButton(
                    bookId: book.id,
                    onTap: () => _openBook(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBook(BuildContext context) {
    context.push('${AppRoutes.reader}/${entry.book.id}');
  }

  /// The fill continues the cover's own colour, so the bar and the cover read
  /// as one book instead of two unrelated accents.
  Color _progressColor(BookCoverPalette palette) {
    return DudoColors.isDark ? DudoColors.primary : palette.start;
  }
}

class _HistoryCover extends StatelessWidget {
  const _HistoryCover({required this.title, required this.palette});

  final String title;
  final BookCoverPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.start, palette.end],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shortTitle(title),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: DudoTextStyles.serif(
              color: DudoColors.onInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: DudoColors.onInk.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortTitle(String title) {
    final value = title.trim();
    if (value.isEmpty) return '书';
    return String.fromCharCodes(value.runes.take(2));
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({super.key, required this.label, required this.highlight});

  final String label;

  /// Only a book opened today wears the pine tint; every other day stays on
  /// the quiet paper fill.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? DudoColors.primaryContainer : DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: DudoTextStyles.sans(
          color: highlight ? DudoColors.primary : DudoColors.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.bookId, required this.onTap});

  final String bookId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('reading-history-continue-$bookId'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: DudoColors.ink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookOpen, size: 13, color: DudoColors.onInk),
            const SizedBox(width: 6),
            Text(
              '继续读',
              style: DudoTextStyles.sans(
                color: DudoColors.onInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLoadingCard extends StatelessWidget {
  const _HistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 14),
          Text(
            '正在整理阅读记录…',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.onRetry});

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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4DDD2),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              LucideIcons.circleAlert,
              color: _dangerText,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '阅读记录加载失败',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '暂时无法读取最近打开的书，请稍后重试。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: DudoColors.primary,
              textStyle: DudoTextStyles.sans(
                fontSize: 13,
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

class _HistoryEmptyCard extends StatelessWidget {
  const _HistoryEmptyCard({required this.filter, required this.onRead});

  final ReadingHistoryFilter filter;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (filter) {
      ReadingHistoryFilter.recent => (
          '还没有最近打开的书',
          '开始阅读后，最近打开的书会按时间出现在这里。',
        ),
      ReadingHistoryFilter.week => (
          '本周还没有打开过书',
          '换到“最近”看看更早的阅读记录。',
        ),
      ReadingHistoryFilter.month => (
          '本月还没有打开过书',
          '换到“最近”看看更早的阅读记录。',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DudoColors.primaryContainer,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              LucideIcons.bookOpen,
              color: DudoColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRead,
            style: TextButton.styleFrom(
              foregroundColor: DudoColors.primary,
              textStyle: DudoTextStyles.sans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('去书架看看'),
          ),
        ],
      ),
    );
  }
}
