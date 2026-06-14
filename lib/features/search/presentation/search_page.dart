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

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

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
    setState(() {});
  }

  void _handleClearQuery() {
    _controller.clear();
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
    final query = _controller.text.trim();
    final enabledSourceCount = ref.watch(enabledSourceCountProvider);
    final searchResults =
        _hasQuery ? ref.watch(onlineSearchProvider(query)) : null;

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
          ),
          const SizedBox(height: 14),
          if (_hasQuery) ...[
            const _RecentSearchSection(),
            const SizedBox(height: 14),
          ],
          _SourceSelectorSection(enabledSourceCount: enabledSourceCount),
          const SizedBox(height: 14),
          if (_hasQuery)
            _SearchResultsSection(
              query: query,
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onClear;
  final VoidCallback onFilter;

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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onClear;

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

class _SourceSelectorSection extends StatelessWidget {
  const _SourceSelectorSection({required this.enabledSourceCount});

  final AsyncValue<int> enabledSourceCount;

  @override
  Widget build(BuildContext context) {
    final onlineSubtitle = enabledSourceCount.when(
      data: (count) => '$count 个启用',
      loading: () => '读取中',
      error: (_, __) => '读取失败',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '常用书源',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '全部',
              style: DudoTextStyles.sans(
                color: DudoColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _SourceCard(
                title: '本地书架',
                subtitle: '优先缓存',
                icon: LucideIcons.library,
                fill: DudoColors.primaryContainer,
                border: DudoColors.primaryContainerStrong,
                iconFill: DudoColors.primaryContainerStrong,
                iconColor: DudoColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SourceCard(
                title: '网络书源',
                subtitle: onlineSubtitle,
                icon: LucideIcons.globe,
                fill: DudoColors.surface,
                border: DudoColors.outlineVariant,
                iconFill: DudoColors.surfaceLow,
                iconColor: DudoColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fill,
    required this.border,
    required this.iconFill,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color fill;
  final Color border;
  final Color iconFill;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
            '可以搜索书名、作者，也可以从搜索来源中选择本地或在线书库。',
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
  const _RecentSearchSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近搜索',
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RecentSearchChip(label: '长夜余火'),
            _RecentSearchChip(label: '三体'),
            _RecentSearchChip(label: '刘慈欣'),
          ],
        ),
      ],
    );
  }
}

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        style: DudoTextStyles.sans(
          color: DudoColors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
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
  });

  final IconData icon;
  final String title;
  final String message;

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
            child: Icon(icon, color: DudoColors.primary, size: 24),
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
