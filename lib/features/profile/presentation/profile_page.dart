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
          _ProfileStats(summary: summary),
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
      children: [
        Expanded(
          child: Text(
            '我的',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
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
    return Container(
      height: 138,
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
      child: Row(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
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
                    const SizedBox(height: 4),
                    Text(
                      summary.subtitle,
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.badgeCheck,
                      color: DudoColors.isDark
                          ? DudoColors.primary
                          : DudoColors.primaryContainer,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '静读会员',
                      style: DudoTextStyles.sans(
                        color: DudoColors.isDark
                            ? DudoColors.primary
                            : DudoColors.primaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStat(
              value: summary.monthReadingLabel,
              label: '本月阅读',
            ),
          ),
          Expanded(
            child: _ProfileStat(value: '${summary.shelfCount}', label: '收藏'),
          ),
          Expanded(
            child: _ProfileStat(
              value: '${summary.bookmarkCount}',
              label: '书签',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: DudoTextStyles.numeric(
            color: DudoColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _MonthlyGoalCard extends StatelessWidget {
  const _MonthlyGoalCard({required this.overview});

  final ReadingGoalOverview? overview;

  @override
  Widget build(BuildContext context) {
    final percent = overview?.progressPercent ?? 0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.push(AppRoutes.readingGoal),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: DudoColors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      overview?.title ?? '本月阅读目标',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    overview?.progressPercentText ?? '0%',
                    style: DudoTextStyles.numeric(
                      color: DudoColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: AppRadius.full,
                child: Container(
                  height: 8,
                  color: DudoColors.paperBackground,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DudoColors.primary,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                overview?.remainingDescription ?? '正在计算本月进度…',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
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
        _ToolItem(
          title: '数据同步',
          description: '云端保持最新',
          icon: LucideIcons.refreshCw,
          iconFill: DudoColors.primaryContainer,
          iconColor: DudoColors.primary,
          route: AppRoutes.dataSyncSettings,
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
