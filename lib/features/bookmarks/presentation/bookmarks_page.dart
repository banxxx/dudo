import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../../shared/widgets/dudo_page_header.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        bottomSafeArea: false,
        children: [
          const _BookmarksHeader(),
          const SizedBox(height: 16),
          const _BookmarkEmptySummary(),
          const SizedBox(height: 16),
          _BookmarkEmptyState(
            onRead: () => context.go('${AppRoutes.reader}/demo-book'),
          ),
        ],
      ),
    );
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
