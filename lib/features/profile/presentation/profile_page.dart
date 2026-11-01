import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_entry_row.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../reading_goal/application/reading_goal_overview.dart';
import '../../reading_goal/application/reading_goal_providers.dart';
import '../application/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary =
        ref.watch(profileSummaryProvider).valueOrNull ?? ProfileSummary.empty;
    final goal = ref.watch(readingGoalOverviewProvider).valueOrNull;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 12),
          _ProfileIdentityCard(summary: summary),
          const SizedBox(height: 12),
          _MonthlyGoalCard(overview: goal),
          const SizedBox(height: 12),
          const _LibraryToolsSection(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '纸上旅居',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '我的',
                style: DudoTextStyles.serif(
                  color: DudoColors.textPrimary,
                  fontSize: 28,
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
            onTap: () => _handleOpenSettings(context),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              key: const ValueKey('profile-settings-button'),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DudoColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: DudoColors.outline),
              ),
              child: Icon(
                LucideIcons.settings,
                color: DudoColors.secondary,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final hairline = DudoColors.onInk.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2625251F),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: DudoColors.primaryContainer,
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: dark ? DudoColors.outline : const Color(0xCCFFF8EA),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '读',
                  style: DudoTextStyles.serif(
                    color: DudoColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '纸上旅人',
                      style: DudoTextStyles.serif(
                        color: DudoColors.onInk,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '读过的日子，都收在这里。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: hairline),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _IdentityStat(
                  key: const ValueKey('profile-stat-month'),
                  icon: LucideIcons.hourglass,
                  value: summary.monthReadingLabel,
                  label: '本月阅读',
                  padding: const EdgeInsets.only(right: 14),
                  onTap: () => context.push(AppRoutes.readingStats),
                ),
              ),
              _IdentityStatDivider(color: hairline),
              Expanded(
                child: _IdentityStat(
                  key: const ValueKey('profile-stat-shelf'),
                  icon: LucideIcons.libraryBig,
                  value: '${summary.shelfCount}',
                  label: '收藏',
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onTap: () => context.go(AppRoutes.bookshelf),
                ),
              ),
              _IdentityStatDivider(color: hairline),
              Expanded(
                child: _IdentityStat(
                  key: const ValueKey('profile-stat-bookmarks'),
                  icon: LucideIcons.bookmark,
                  value: '${summary.bookmarkCount}',
                  label: '书签',
                  padding: const EdgeInsets.only(left: 14),
                  onTap: () => context.push(AppRoutes.bookmarks),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the three ledger columns inside the identity card. The first column
/// drops its left inset so the numbers line up with the avatar above.
class _IdentityStat extends StatelessWidget {
  const _IdentityStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.padding,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: DudoColors.onInkMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.numeric(
                  color: DudoColors.onInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityStatDivider extends StatelessWidget {
  const _IdentityStatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: color);
  }
}

class _MonthlyGoalCard extends StatelessWidget {
  const _MonthlyGoalCard({required this.overview});

  final ReadingGoalOverview? overview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => context.push(AppRoutes.readingGoal),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DudoColors.primaryContainer,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              _GoalRing(
                key: const ValueKey('profile-goal-ring'),
                percent: overview?.progressPercent ?? 0,
                percentText: overview?.progressPercentText ?? '0%',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview?.title ?? '本月阅读目标',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      overview?.remainingDescription ?? '正在计算本月进度…',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondaryDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: DudoColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact echo of the reading goal page's donut: paper track, pine arc and
/// a paper disc holding the percentage.
class _GoalRing extends StatelessWidget {
  const _GoalRing({
    super.key,
    required this.percent,
    required this.percentText,
  });

  final double percent;
  final String percentText;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent),
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 62,
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: DudoColors.surface.withValues(alpha: 0.72),
                ),
              ),
              SizedBox(
                width: 62,
                height: 62,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: DudoColors.primary,
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  percentText,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryToolsSection extends StatelessWidget {
  const _LibraryToolsSection();

  /// Built per build, not cached: the fills come from the active palette and
  /// must follow a theme switch the moment the palette changes.
  List<_ToolItem> get _items => [
        _ToolItem(
          title: '书源管理',
          description: '添加、启用、更新和校验书源',
          icon: LucideIcons.rss,
          iconFill: DudoColors.surfaceLow,
          iconColor: DudoColors.secondary,
          route: AppRoutes.sourceSettings,
        ),
        _ToolItem(
          title: '阅读记录',
          description: '查看每日阅读曲线',
          icon: LucideIcons.timer,
          iconFill: DudoColors.surfaceLow,
          iconColor: DudoColors.secondary,
          route: AppRoutes.readingStats,
        ),
        _ToolItem(
          title: '离线缓存',
          description: '管理已下载章节',
          icon: LucideIcons.download,
          iconFill: DudoColors.primaryContainer,
          iconColor: DudoColors.primary,
          route: AppRoutes.offlineCache,
        ),
        _ToolItem(
          title: '笔记摘录',
          description: '整理高亮与想法',
          icon: LucideIcons.notebookPen,
          iconFill: DudoColors.surfaceLow,
          iconColor: DudoColors.secondary,
          route: AppRoutes.bookmarks,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '书房工具',
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items) ...[
          DudoEntryRow(
            icon: item.icon,
            iconFill: item.iconFill,
            iconColor: item.iconColor,
            title: item.title,
            description: item.description,
            showChevron: true,
            onTap: () => _handleOpenTool(context, item),
          ),
          if (item != items.last) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconFill,
    required this.iconColor,
    this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconFill;
  final Color iconColor;
  final String? route;
}

void _handleOpenSettings(BuildContext context) {
  context.push(AppRoutes.settings);
}

void _handleOpenTool(BuildContext context, _ToolItem item) {
  final route = item.route;
  if (route != null) {
    context.push(route);
  }
}
