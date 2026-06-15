import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../bookshelf/application/bookshelf_providers.dart';
import '../application/search_providers.dart';
import '../domain/online_search_models.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _submittedQuery;

  bool get _hasQuery => _controller.text.trim().isNotEmpty;
  bool get _hasSubmittedQuery => _submittedQuery?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleQueryChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final query = _controller.text.trim();
    if (query != _submittedQuery) {
      _submittedQuery = null;
    }
    setState(() {});
  }

  void _handleClearQuery() {
    _submittedQuery = null;
    _controller.clear();
  }

  void _handleSelectRecentSearch(String keyword) {
    _controller
      ..text = keyword
      ..selection = TextSelection.collapsed(offset: keyword.length);
    _focusNode.requestFocus();
  }

  void _handleSubmitSearch(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _submittedQuery = keyword;
    });
    unawaited(ref.read(recentSearchRepositoryProvider).addSearch(keyword));
  }

  void _handleClearRecentSearches() {
    unawaited(ref.read(recentSearchRepositoryProvider).clear());
  }

  Future<void> _handleOpenResult(OnlineSearchBookResult result) async {
    final bookUrl = result.bookUrl?.trim();
    final messages = ref.read(appMessageServiceProvider);
    if (bookUrl == null || bookUrl.isEmpty) {
      messages.warning('该搜索结果缺少详情地址，无法打开');
      return;
    }

    messages.info('正在加载《${result.name}》');
    try {
      final bookId =
          await ref.read(remoteBookImportServiceProvider).importRemoteBook(
                sourceId: result.sourceId,
                bookUrl: bookUrl,
                fallbackName: result.name,
                fallbackAuthor: result.author,
                fallbackCoverUrl: result.coverUrl,
                fallbackIntro: result.intro,
              );
      if (!mounted) return;
      ref
        ..invalidate(shelfBooksProvider)
        ..invalidate(bookByIdProvider(bookId))
        ..invalidate(bookChapterMetasProvider(bookId))
        ..invalidate(bookChapterCountProvider(bookId));
      context.push('${AppRoutes.bookDetail}/$bookId');
    } catch (error) {
      messages.error('无法打开远程书籍：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches =
        ref.watch(recentSearchesProvider).valueOrNull ?? const <String>[];
    final submittedQuery = _submittedQuery;
    final searchResults = _hasSubmittedQuery
        ? ref.watch(onlineSearchProvider(submittedQuery!))
        : null;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        children: [
          _SearchHeader(
            controller: _controller,
            focusNode: _focusNode,
            active: _hasQuery,
            onClear: _handleClearQuery,
            onFilter: _handleOpenFilters,
            onSubmitted: _handleSubmitSearch,
          ),
          const SizedBox(height: 14),
          if (recentSearches.isNotEmpty) ...[
            _RecentSearchSection(
              searches: recentSearches,
              onSelected: _handleSelectRecentSearch,
              onClear: _handleClearRecentSearches,
            ),
            const SizedBox(height: 14),
          ],
          if (_hasSubmittedQuery)
            _SearchResultsSection(
              query: submittedQuery!,
              results: searchResults!,
              onResultTap: _handleOpenResult,
            )
          else
            const _SearchEmptySuggestions(),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onClear,
    required this.onFilter,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onClear;
  final VoidCallback onFilter;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '探索书源与作品',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '搜索',
                    style: DudoTextStyles.serif(
                      color: DudoColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onFilter,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DudoColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: DudoColors.outline),
                  ),
                  child: const Icon(
                    LucideIcons.slidersHorizontal,
                    color: DudoColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SearchField(
          controller: controller,
          focusNode: focusNode,
          active: active,
          onClear: onClear,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focusNode.requestFocus,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? DudoColors.primary : DudoColors.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              color: active ? DudoColors.primary : DudoColors.secondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  IgnorePointer(
                    child: Text(
                      active ? controller.text : '搜索书名、作者、关键词',
                      style: active
                          ? DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            )
                          : DudoTextStyles.sans(
                              color: DudoColors.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    cursorColor: DudoColors.primary,
                    style: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 1,
                      height: 1,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (active) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  LucideIcons.x,
                  color: DudoColors.secondary,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchEmptySuggestions extends StatelessWidget {
  const _SearchEmptySuggestions();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              LucideIcons.telescope,
              color: DudoColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '输入关键词开始找书',
            textAlign: TextAlign.center,
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可以搜索书名、作者或关键词。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchSection extends StatelessWidget {
  const _RecentSearchSection({
    required this.searches,
    required this.onSelected,
    required this.onClear,
  });

  final List<String> searches;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '\u6700\u8fd1\u641c\u7d22',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: AppRadius.full,
              child: InkWell(
                onTap: onClear,
                borderRadius: AppRadius.full,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    '\u6e05\u9664\u5386\u53f2',
                    style: DudoTextStyles.sans(
                      color: DudoColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            );
            final chipMaxWidth = math.min(
              _recentSearchChipMaxWidth,
              constraints.maxWidth,
            );
            final visibleSearches = _visibleRecentSearchChips(
              searches: searches,
              maxWidth: constraints.maxWidth,
              chipMaxWidth: chipMaxWidth,
              textStyle: textStyle,
              textDirection: Directionality.of(context),
            );

            return Row(
              children: [
                for (var index = 0;
                    index < visibleSearches.length;
                    index++) ...[
                  if (index > 0) const SizedBox(width: _recentSearchChipGap),
                  _RecentSearchChip(
                    label: visibleSearches[index].label,
                    width: visibleSearches[index].width,
                    textStyle: textStyle,
                    onTap: () => onSelected(visibleSearches[index].label),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

const _recentSearchChipGap = 8.0;
const _recentSearchChipMaxWidth = 148.0;
const _recentSearchChipHorizontalPadding = 24.0;
const _recentSearchMinimumVisibleText = '\u4e2d\u6587\u5b57\u7b26';
const _recentSearchTextWidthSlack = 2.0;

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({
    required this.label,
    required this.width,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final double width;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          width: width,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: AppRadius.full,
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _VisibleRecentSearchChip {
  const _VisibleRecentSearchChip({
    required this.label,
    required this.width,
  });

  final String label;
  final double width;
}

List<_VisibleRecentSearchChip> _visibleRecentSearchChips({
  required List<String> searches,
  required double maxWidth,
  required double chipMaxWidth,
  required TextStyle textStyle,
  required TextDirection textDirection,
}) {
  if (searches.isEmpty || maxWidth <= 0) return const [];

  var usedWidth = 0.0;
  final visibleMetrics = <_MeasuredRecentSearchChip>[];
  var visibleWidths = <double>[];
  for (final search in searches) {
    final chip = _measureRecentSearchChip(
      search,
      textStyle,
      textDirection,
      chipMaxWidth,
    );
    if (chip == null) break;

    final spacing = visibleMetrics.isEmpty ? 0.0 : _recentSearchChipGap;
    final availableWidth = maxWidth - usedWidth - spacing;
    if (availableWidth >= chip.minimumWidth) {
      final width = math.min(chip.maxWidth, availableWidth);
      visibleMetrics.add(chip);
      visibleWidths.add(width);
      usedWidth += spacing + width;
      continue;
    }

    if (visibleMetrics.length == 1) {
      final rescuedMetrics = [...visibleMetrics, chip];
      final rescuedWidths = _allocateRecentSearchChipWidths(
        rescuedMetrics,
        maxWidth,
      );
      if (rescuedWidths != null) {
        visibleMetrics
          ..clear()
          ..addAll(rescuedMetrics);
        visibleWidths = rescuedWidths;
        usedWidth = _recentSearchChipRowWidth(visibleWidths);
        continue;
      }
    }

    break;
  }

  return [
    for (var index = 0; index < visibleMetrics.length; index++)
      _VisibleRecentSearchChip(
        label: visibleMetrics[index].label,
        width: visibleWidths[index],
      ),
  ];
}

@visibleForTesting
List<({String label, double width})> debugVisibleRecentSearchChips({
  required List<String> searches,
  required double maxWidth,
  required double chipMaxWidth,
  required TextStyle textStyle,
  required TextDirection textDirection,
}) {
  return [
    for (final chip in _visibleRecentSearchChips(
      searches: searches,
      maxWidth: maxWidth,
      chipMaxWidth: chipMaxWidth,
      textStyle: textStyle,
      textDirection: textDirection,
    ))
      (label: chip.label, width: chip.width),
  ];
}

List<double>? _allocateRecentSearchChipWidths(
  List<_MeasuredRecentSearchChip> chips,
  double maxWidth,
) {
  if (chips.isEmpty) return const [];

  final minimumRowWidth =
      chips.fold(0.0, (width, chip) => width + chip.minimumWidth) +
          _recentSearchChipGap * (chips.length - 1);
  if (minimumRowWidth > maxWidth) return null;

  var remainingWidth = maxWidth - minimumRowWidth;
  return [
    for (final chip in chips)
      chip.minimumWidth +
          (() {
            final extraWidth = math.min(
              remainingWidth,
              chip.maxWidth - chip.minimumWidth,
            );
            remainingWidth -= extraWidth;
            return extraWidth;
          })(),
  ];
}

double _recentSearchChipRowWidth(List<double> widths) {
  if (widths.isEmpty) return 0;
  return widths.fold(0.0, (sum, width) => sum + width) +
      _recentSearchChipGap * (widths.length - 1);
}

class _MeasuredRecentSearchChip {
  const _MeasuredRecentSearchChip({
    required this.label,
    required this.minimumWidth,
    required this.maxWidth,
  });

  final String label;
  final double minimumWidth;
  final double maxWidth;
}

_MeasuredRecentSearchChip? _measureRecentSearchChip(
  String label,
  TextStyle textStyle,
  TextDirection textDirection,
  double maxWidth,
) {
  final labelWidth = _measureRecentSearchTextWidth(
    label,
    textStyle,
    textDirection,
  );
  final intrinsicWidth = labelWidth + _recentSearchChipHorizontalPadding;
  final minimumVisibleWidth = _measureRecentSearchTextWidth(
        _recentSearchMinimumVisibleText,
        textStyle,
        textDirection,
      ) +
      _recentSearchChipHorizontalPadding;
  final minimumWidth = intrinsicWidth <= minimumVisibleWidth
      ? intrinsicWidth
      : minimumVisibleWidth;
  final cappedMaxWidth = math.min(intrinsicWidth, maxWidth);

  if (cappedMaxWidth < minimumWidth) return null;
  return _MeasuredRecentSearchChip(
    label: label,
    minimumWidth: minimumWidth,
    maxWidth: cappedMaxWidth,
  );
}

double _measureRecentSearchTextWidth(
  String text,
  TextStyle textStyle,
  TextDirection textDirection,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    maxLines: 1,
    textDirection: textDirection,
  )..layout();
  return painter.width.ceilToDouble() + _recentSearchTextWidthSlack;
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.query,
    required this.results,
    required this.onResultTap,
  });

  final String query;
  final AsyncValue<OnlineSearchResponse> results;
  final Future<void> Function(OnlineSearchBookResult result) onResultTap;

  @override
  Widget build(BuildContext context) {
    return results.when(
      loading: () => const _SearchStatusCard(
        icon: LucideIcons.loaderCircle,
        title: '正在搜索在线书源',
        message: '正在读取启用书源并执行规则，请稍候。',
        animateIcon: true,
      ),
      error: (error, _) => _SearchStatusCard(
        icon: LucideIcons.triangleAlert,
        title: '搜索失败',
        message: error.toString(),
      ),
      data: (response) {
        if (response.availableSourceCount == 0) {
          return const _SearchStatusCard(
            icon: LucideIcons.rss,
            title: '暂无启用书源',
            message: '请先在书源管理中导入并启用 Legado 书源。',
          );
        }
        if (response.allSearchedSourcesFailed) {
          return _SearchStatusCard(
            icon: LucideIcons.triangleAlert,
            title: '在线书源暂不可用',
            message: '已尝试 ${response.searchedSourceCount} 个书源，但规则或网络请求全部失败。',
          );
        }
        if (response.results.isEmpty) {
          return _SearchStatusCard(
            icon: LucideIcons.searchX,
            title: '没有找到“$query”',
            message: response.hasFailures
                ? '部分书源搜索失败，其余启用书源没有返回结果。'
                : '已搜索 ${response.searchedSourceCount} 个启用书源，没有匹配结果。',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '搜索结果',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${response.results.length} 条',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (response.hasFailures) ...[
              const SizedBox(height: 8),
              _PartialFailureNotice(failureCount: response.failures.length),
            ],
            const SizedBox(height: 10),
            for (final result in response.results) ...[
              _SearchResultCard(result: result, onTap: onResultTap),
              if (result != response.results.last) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _PartialFailureNotice extends StatelessWidget {
  const _PartialFailureNotice({required this.failureCount});

  final int failureCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DudoColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: DudoColors.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$failureCount 个书源搜索失败，已展示其余可用结果。',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchStatusCard extends StatelessWidget {
  const _SearchStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.animateIcon = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool animateIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: _StatusIcon(icon: icon, animate: animateIcon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DudoTextStyles.serif(
                    color: DudoColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 13,
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

class _StatusIcon extends StatefulWidget {
  const _StatusIcon({
    required this.icon,
    required this.animate,
  });

  final IconData icon;
  final bool animate;

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, color: DudoColors.primary, size: 24);
    if (!widget.animate) return icon;

    return RotationTransition(
      turns: _controller,
      child: icon,
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.onTap,
  });

  final OnlineSearchBookResult result;
  final Future<void> Function(OnlineSearchBookResult result) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onTap(result),
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [DudoColors.primary, DudoColors.primaryContainer],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _resultMeta(result),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _resultIntro(result),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _resultMeta(OnlineSearchBookResult result) {
  final author = result.author.trim().isEmpty ? '作者未知' : result.author.trim();
  return '$author · ${result.sourceName}';
}

String _resultIntro(OnlineSearchBookResult result) {
  final intro = result.intro?.trim();
  if (intro != null && intro.isNotEmpty) return intro;
  final bookUrl = result.bookUrl?.trim();
  if (bookUrl != null && bookUrl.isNotEmpty) return bookUrl;
  return '暂无简介，后续详情解析会补充更多信息。';
}

void _handleOpenFilters() {
  // Reserved for source filtering once search data is wired.
}
