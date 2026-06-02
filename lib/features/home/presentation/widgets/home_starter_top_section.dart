import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';

class HomeStarterTopSection extends StatelessWidget {
  const HomeStarterTopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StarterHomeHeader(),
        SizedBox(height: 12),
        _StarterReadingHero(),
      ],
    );
  }
}

class _StarterHomeHeader extends StatelessWidget {
  const _StarterHomeHeader();

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
                '今天想读点什么？',
                style: DudoTextStyles.serif(
                  color: DudoColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '还没有正在读的书，先从灵感书单开始。',
                style: DudoTextStyles.sans(
                  color: DudoColors.textSecondary,
                  fontSize: 12,
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

class _StarterReadingHero extends StatelessWidget {
  const _StarterReadingHero();

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
          const _StarterBookStack(),
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
                      '阅读入口',
                      style: DudoTextStyles.sans(
                        color: DudoColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '开始新的阅读',
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '清晨的安静里，翻开一本新的故事。',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StartFindingBooksButton(
                      onTap: () => context.go(AppRoutes.search),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '3 本',
                          style: DudoTextStyles.numeric(
                            color: DudoColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '适合今天',
                          style: DudoTextStyles.sans(
                            color: DudoColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
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

class _StarterBookStack extends StatelessWidget {
  const _StarterBookStack();

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
            'DUDO',
            style: DudoTextStyles.numeric(
              color: DudoColors.surfaceHigh,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            '开始你的\n第一本书',
            style: DudoTextStyles.serif(
              color: DudoColors.surfaceHigh,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          Text(
            '今日推荐',
            style: DudoTextStyles.sans(
              color: DudoColors.surfaceHigh.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartFindingBooksButton extends StatelessWidget {
  const _StartFindingBooksButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.full,
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: DudoColors.textPrimary,
          borderRadius: AppRadius.full,
        ),
        child: Row(
          children: [
            Text(
              '去找书',
              style: DudoTextStyles.sans(
                color: DudoColors.surfaceHigh,
                fontSize: 12,
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
    );
  }
}
