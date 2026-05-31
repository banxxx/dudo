import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/theme/app_tokens.dart';

class BookshelfPage extends ConsumerWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          children: const [
            _HomeHeader(),
            SizedBox(height: 12),
            _ContinueReadingHero(),
            SizedBox(height: 12),
            _QuickActions(),
            SizedBox(height: 12),
            _RecommendationSection(),
            SizedBox(height: 12),
            _ReadingRhythmCard(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日阅读',
                style: GoogleFonts.notoSansSc(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '晚上好，继续沉入书页',
                style: GoogleFonts.notoSerifSc(
                  color: DudoColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: DudoColors.primaryContainer,
            borderRadius: AppRadius.full,
            border: Border.all(color: DudoColors.navigationStroke),
          ),
          child: const Icon(
            Symbols.eco_rounded,
            color: DudoColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingHero extends StatelessWidget {
  const _ContinueReadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: DudoColors.primary.withValues(alpha: 0.14),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Row(
        children: [
          const _HeroBookCover(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '继续阅读',
                      style: GoogleFonts.notoSansSc(
                        color: DudoColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '三体 · 第 24 章',
                      style: GoogleFonts.notoSerifSc(
                        color: DudoColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '旧世界的回声，在清晨雾气里慢慢浮现。',
                      style: GoogleFonts.notoSansSc(
                        color: DudoColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '剩余 8 分钟',
                      style: GoogleFonts.notoSansSc(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const _ReadButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBookCover extends StatelessWidget {
  const _HeroBookCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.large,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DudoColors.primary, DudoColors.accentMuted],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIU',
            style: GoogleFonts.inter(
              color: DudoColors.surfaceHigh,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          Center(
            child: Text(
              '三体',
              style: GoogleFonts.notoSerifSc(
                color: DudoColors.surfaceHigh,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '62%',
            style: GoogleFonts.inter(
              color: DudoColors.surfaceHigh,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadButton extends StatelessWidget {
  const _ReadButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.full,
      onTap: () {},
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: DudoColors.textPrimary,
          borderRadius: AppRadius.full,
        ),
        child: Row(
          children: [
            Text(
              '阅读',
              style: GoogleFonts.notoSansSc(
                color: DudoColors.surfaceHigh,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Symbols.chevron_right_rounded,
              color: DudoColors.surfaceHigh,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(icon: Symbols.search_rounded, label: '找书'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _QuickAction(icon: Symbols.bookmark_rounded, label: '书签'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _QuickAction(icon: Symbols.bar_chart_rounded, label: '统计'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
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
              style: GoogleFonts.notoSansSc(
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
              style: GoogleFonts.notoSansSc(
                color: DudoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '全部',
              style: GoogleFonts.notoSansSc(
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
        Container(
          height: 98,
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
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
              style: GoogleFonts.inter(
                color: DudoColors.surfaceHigh,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansSc(
            color: DudoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.notoSansSc(
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
            style: GoogleFonts.notoSansSc(
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
                          style: GoogleFonts.notoSansSc(
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
