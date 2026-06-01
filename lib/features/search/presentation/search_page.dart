import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

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

  @override
  Widget build(BuildContext context) {
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
          const _SourceSelectorSection(),
          const SizedBox(height: 14),
          if (_hasQuery)
            const _SearchResultsSection()
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
  const _SourceSelectorSection();

  @override
  Widget build(BuildContext context) {
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
        const Row(
          children: [
            Expanded(
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
            SizedBox(width: 10),
            Expanded(
              child: _SourceCard(
                title: '网络书源',
                subtitle: '12 个启用',
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
  const _SearchResultsSection();

  static const _results = [
    _SearchResultData(
      title: '三体',
      meta: '刘慈欣 · 科幻 · 本地书架',
      intro: '文明在宇宙尺度中的回响，从一次偶然监听开始。',
      start: Color(0xFF2F3A4D),
      end: Color(0xFF9AA7B8),
    ),
    _SearchResultData(
      title: '三体：黑暗森林',
      meta: '刘慈欣 · 网络书源 · 已缓存',
      intro: '面壁计划、黑暗森林法则，以及人类文......',
      start: DudoColors.primary,
      end: DudoColors.primaryContainer,
    ),
    _SearchResultData(
      title: '三体全集',
      meta: '刘慈欣 · 网络书源 · 6 个来源',
      intro: '三部曲合集，适合一次性加入书架后离线阅读。',
      start: DudoColors.secondary,
      end: DudoColors.secondaryContainer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              '24 条',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final result in _results) ...[
          _SearchResultCard(result: result),
          if (result != _results.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result});

  final _SearchResultData result;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [result.start, result.end],
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
                  result.title,
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
                  result.meta,
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
                  result.intro,
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
    );
  }
}

class _SearchResultData {
  const _SearchResultData({
    required this.title,
    required this.meta,
    required this.intro,
    required this.start,
    required this.end,
  });

  final String title;
  final String meta;
  final String intro;
  final Color start;
  final Color end;
}

void _handleOpenFilters() {
  // Reserved for source filtering once search data is wired.
}
