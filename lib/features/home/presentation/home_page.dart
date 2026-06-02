import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import 'widgets/home_reading_top_section.dart';
import 'widgets/home_starter_top_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.hasReadingData = false});

  final bool hasReadingData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        bottomSafeArea: false,
        children: [
          if (hasReadingData)
            const HomeReadingTopSection()
          else
            const HomeStarterTopSection(),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 12),
          const _RecommendationSection(),
          const SizedBox(height: 12),
          const _ReadingRhythmCard(),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.search,
              label: '找书',
              onTap: () => context.go(AppRoutes.search),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.bookmark,
              label: '书签',
              onTap: () => context.push(AppRoutes.bookmarks),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: LucideIcons.chartNoAxesColumn,
              label: '统计',
              onTap: () => context.push(AppRoutes.readingStats),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DudoColors.secondary, size: 18),
            const SizedBox(height: 5),
            Text(
              label,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '为你精选',
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '全部',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _RecommendedBookCard(
                title: '云边有个小卖部',
                subtitle: '温柔乡土',
                label: 'ZHANG',
                gradient: [DudoColors.accent, DudoColors.secondaryContainer],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _RecommendedBookCard(
                title: '明朝那些事儿',
                subtitle: '历史叙事',
                label: 'MING',
                gradient: [DudoColors.primary, DudoColors.primaryContainer],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _RecommendedBookCard(
                title: '长安的荔枝',
                subtitle: '古代职场',
                label: 'CHANG',
                gradient: [DudoColors.secondary, DudoColors.outlineVariant],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.68,
          child: ClipRRect(
            borderRadius: AppRadius.large,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  label,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.surfaceHigh,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ReadingRhythmCard extends StatelessWidget {
  const _ReadingRhythmCard();

  @override
  Widget build(BuildContext context) {
    const bars = [18.0, 26.0, 32.0, 22.0, 38.0, 30.0, 40.0];
    const days = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周节奏',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 14,
                          height: bars[i],
                          decoration: BoxDecoration(
                            color: i == 2 || i == 4 || i == 6
                                ? DudoColors.primary
                                : DudoColors.outline,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          days[i],
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != days.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
