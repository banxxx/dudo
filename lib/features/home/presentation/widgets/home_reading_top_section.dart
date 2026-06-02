import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/utils/time_greeting.dart';

class HomeReadingTopSection extends StatelessWidget {
  const HomeReadingTopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _HomeHeader(),
        SizedBox(height: 12),
        _ContinueReadingHero(),
      ],
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
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${timeGreeting()}，继续沉入书页',
                style: DudoTextStyles.serif(
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
            LucideIcons.leaf,
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
                      style: DudoTextStyles.sans(
                        color: DudoColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '三体 · 第 24 章',
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '旧世界的回声，在清晨雾气里慢慢浮现。',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
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
                      style: DudoTextStyles.sans(
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
            style: DudoTextStyles.numeric(
              color: DudoColors.surfaceHigh,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          Center(
            child: Text(
              '三体',
              style: DudoTextStyles.serif(
                color: DudoColors.surfaceHigh,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '62%',
            style: DudoTextStyles.numeric(
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
              style: DudoTextStyles.sans(
                color: DudoColors.surfaceHigh,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              LucideIcons.chevronRight,
              color: DudoColors.surfaceHigh,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
