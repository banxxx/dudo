import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

class BookshelfLibraryPage extends ConsumerWidget {
  const BookshelfLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        children: [
          _BookshelfHeader(),
          SizedBox(height: 20),
          _EmptyBookshelfCard(),
          SizedBox(height: 20),
          _LibraryTipsSection(),
        ],
      ),
    );
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

class _EmptyBookshelfCard extends StatelessWidget {
  const _EmptyBookshelfCard();

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
          const _EmptyStateActions(),
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
  const _EmptyStateActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillActionButton(
          label: '去找书',
          icon: LucideIcons.search,
          background: DudoColors.textPrimary,
          foreground: DudoColors.surfaceHigh,
          borderColor: Colors.transparent,
          labelFirst: true,
          onPressed: _handleSearchBooks,
        ),
        SizedBox(width: 8),
        _PillActionButton(
          label: '导入本地',
          icon: LucideIcons.fileUp,
          background: DudoColors.surface,
          foreground: DudoColors.primary,
          borderColor: DudoColors.outline,
          onPressed: _handleImportLocalBooks,
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
  const _LibraryTipsSection();

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
              onPressed: _handleSkipForNow,
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

void _handleSearchBooks() {
  // Reserved for navigating to the search flow when data features are wired.
}

void _handleImportLocalBooks() {
  // Reserved for future local book import support.
}

void _handleSkipForNow() {
  // Reserved for dismissing onboarding tips after persistence is available.
}
