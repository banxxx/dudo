import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/utils/time_greeting.dart';
import '../../application/home_providers.dart';

class HomeReadingTopSection extends StatelessWidget {
  const HomeReadingTopSection({
    super.key,
    required this.snapshot,
    required this.onContinue,
  });

  final HomeReadingSnapshot snapshot;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HomeHeader(),
        const SizedBox(height: 12),
        _ContinueReadingHero(
          snapshot: snapshot,
          onContinue: onContinue,
        ),
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
  const _ContinueReadingHero({
    required this.snapshot,
    required this.onContinue,
  });

  final HomeReadingSnapshot snapshot;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: DudoColors.primary.withValues(alpha: 0.14),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Material(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onContinue,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _HeroBookCover(snapshot: snapshot),
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
                            snapshot.continueLabel,
                            style: DudoTextStyles.sans(
                              color: DudoColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.serif(
                              color: DudoColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.subtitle,
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
                          Flexible(
                            child: Text(
                              snapshot.remainingLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DudoTextStyles.sans(
                                color: DudoColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ReadButton(onTap: onContinue),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBookCover extends StatelessWidget {
  const _HeroBookCover({required this.snapshot});

  final HomeReadingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final coverTitle = snapshot.bookTitle.characters.take(4).toString();

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
            snapshot.coverLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.numeric(
              color: DudoColors.surfaceHigh,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          Center(
            child: Text(
              coverTitle,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.serif(
                color: DudoColors.surfaceHigh,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          Text(
            snapshot.progressLabel,
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
  const _ReadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.full,
      onTap: onTap,
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
