import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

class SourceManageSettingsPage extends StatelessWidget {
  const SourceManageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '内容与书源',
          title: '书源管理',
          actionIcon: LucideIcons.plus,
          onActionTap: () => context.push(AppRoutes.sourceAdd),
        ),
        const SizedBox(height: 14),
        const _SourceSummary(),
        const SizedBox(height: 14),
        SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.plus,
                  label: '添加书源',
                  selected: true,
                  onTap: () => context.push(AppRoutes.sourceAdd),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _QuickAction(
                  icon: LucideIcons.refreshCw,
                  label: '同步更新',
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _QuickAction(
                  icon: LucideIcons.wrench,
                  label: '修复失效',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SettingsSectionTitle('书源列表'),
        const SizedBox(height: 8),
        const _SourceRow(
          name: '番茄小说',
          description: '更新快 · 发现 12 本',
          state: '启用中',
          stateColor: DudoColors.primary,
          dotColor: DudoColors.primary,
          dotFill: DudoColors.primaryContainer,
        ),
        const SizedBox(height: 8),
        const _SourceRow(
          name: '起点中文',
          description: '章节完整 · 搜索稳定',
          state: '启用中',
          stateColor: DudoColors.primary,
          dotColor: DudoColors.primary,
          dotFill: DudoColors.primaryContainer,
        ),
        const SizedBox(height: 8),
        const _SourceRow(
          name: '本地 TXT',
          description: '导入 38 本本地书',
          state: '已挂载',
          stateColor: DudoColors.secondary,
          dotColor: DudoColors.secondary,
          dotFill: DudoColors.primaryContainer,
        ),
        const SizedBox(height: 8),
        const _SourceRow(
          name: '自定义源 A',
          description: '目录规则失效',
          state: '需维护',
          stateColor: DudoColors.accent,
          dotColor: DudoColors.accent,
          dotFill: DudoColors.surfaceLow,
        ),
      ],
    );
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.rss, color: DudoColors.primary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '8 个书源已启用',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '最近同步 12 分钟前，2 个书源需要更新规则。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
                    fontSize: 12,
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DudoColors.surfaceHigh : DudoColors.secondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? DudoColors.textPrimary : DudoColors.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                selected ? null : Border.all(color: DudoColors.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 5),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.name,
    required this.description,
    required this.state,
    required this.stateColor,
    required this.dotColor,
    required this.dotFill,
  });

  final String name;
  final String description;
  final String state;
  final Color stateColor;
  final Color dotColor;
  final Color dotFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
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
              color: dotFill,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            state,
            style: DudoTextStyles.sans(
              color: stateColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
