import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
        children: [
          _ProfileHeader(),
          SizedBox(height: 12),
          _ProfileIdentityCard(),
          SizedBox(height: 12),
          _ProfileStats(),
          SizedBox(height: 12),
          _MonthlyGoalCard(),
          SizedBox(height: 12),
          _LibraryToolsSection(),
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
              child: const Icon(
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
  const _ProfileIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2625251F),
            offset: Offset(0, 12),
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
              border: Border.all(color: const Color(0xCCFFF8EA), width: 2),
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
                        color: DudoColors.surfaceHigh,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '本月已阅读 12 小时，收藏 38 本书',
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFF8EA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: DudoColors.secondaryContainer,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '静读会员',
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

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
      child: const Row(
        children: [
          Expanded(child: _ProfileStat(value: '12h', label: '本月阅读')),
          Expanded(child: _ProfileStat(value: '38', label: '收藏')),
          Expanded(child: _ProfileStat(value: '7', label: '书签')),
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
  const _MonthlyGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  '五月阅读目标',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '78%',
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
                widthFactor: 0.78,
                child: Container(
                  decoration: const BoxDecoration(
                    color: DudoColors.primary,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '距离 20 小时目标还差 4 小时 24 分钟。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryToolsSection extends StatelessWidget {
  const _LibraryToolsSection();

  static const _items = [
    _ToolItem(
      title: '阅读记录',
      description: '查看每日阅读曲线',
      icon: LucideIcons.timer,
      iconFill: DudoColors.surfaceLow,
      iconColor: DudoColors.secondary,
    ),
    _ToolItem(
      title: '离线缓存',
      description: '管理已下载章节',
      icon: LucideIcons.download,
      iconFill: DudoColors.primaryContainer,
      iconColor: DudoColors.primary,
    ),
    _ToolItem(
      title: '笔记摘录',
      description: '整理高亮与想法',
      icon: LucideIcons.notebookPen,
      iconFill: DudoColors.surfaceLow,
      iconColor: DudoColors.secondary,
    ),
    _ToolItem(
      title: '数据同步',
      description: '云端保持最新',
      icon: LucideIcons.refreshCw,
      iconFill: DudoColors.primaryContainer,
      iconColor: DudoColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 8),
        for (final item in _items) ...[
          _ToolRow(item: item),
          if (item != _items.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.item});

  final _ToolItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _handleOpenTool,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  color: item.iconFill,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: Color(0xFFB8A88E),
                size: 18,
              ),
            ],
          ),
        ),
      ),
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
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconFill;
  final Color iconColor;
}

void _handleOpenSettings(BuildContext context) {
  context.push(AppRoutes.settings);
}

void _handleOpenTool() {}
