import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 18),
        constrainWidth: false,
        eager: true,
        children: [
          _TopActions(),
          SizedBox(height: 14),
          _SettingsHero(),
          SizedBox(height: 14),
          _SettingsSection(
            title: '阅读体验',
            rows: [
              _SettingRowData(
                title: '主题与外观',
                description: '纸感、深色、跟随系统',
                value: '纸色',
                icon: LucideIcons.palette,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.themeSettings,
              ),
              _SettingRowData(
                title: '字体与排版',
                description: '字体、字号、行距和段距',
                value: '思源宋体',
                icon: LucideIcons.type,
                iconFill: DudoColors.surfaceLow,
                route: AppRoutes.typographySettings,
              ),
              _SettingRowData(
                title: '阅读朗读',
                description: '声音、语速、定时与后台播放',
                value: '女声 · 1.0x',
                icon: LucideIcons.volume2,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.readAloudSettings,
              ),
            ],
          ),
          SizedBox(height: 14),
          _SettingsSection(
            title: '内容与书源',
            rows: [
              _SettingRowData(
                title: '书架更新',
                description: '更新频率、章节提醒和自动拉取',
                value: '每天',
                icon: LucideIcons.refreshCw,
                iconFill: DudoColors.primaryContainer,
              ),
            ],
          ),
          SizedBox(height: 14),
          _SettingsSection(
            title: '通用',
            rows: [
              _SettingRowData(
                title: '数据同步',
                description: '阅读进度、书签、高亮和设置',
                icon: LucideIcons.cloud,
                iconFill: DudoColors.surfaceLow,
                trailingSwitch: true,
              ),
              _SettingRowData(
                title: '缓存与存储',
                description: '离线章节、封面缓存与清理',
                value: '1.2GB',
                icon: LucideIcons.hardDrive,
                iconFill: DudoColors.primaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () => context.pop(),
        ),
        const Spacer(),
        _RoundIconButton(
          icon: LucideIcons.info,
          onTap: () => _handleOpenHelp(context),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outline),
          ),
          child: Icon(icon, color: DudoColors.secondary, size: 20),
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0x22FFF8EA),
              borderRadius: BorderRadius.circular(31),
            ),
            child: const Icon(
              LucideIcons.settings,
              color: DudoColors.secondaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '偏好中心',
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '设置',
                  style: DudoTextStyles.serif(
                    color: DudoColors.surfaceHigh,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '调整阅读体验、书源与同步，让书房按你的习惯运转。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});

  final String title;
  final List<_SettingRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (final row in rows) ...[
          _SettingRow(data: row),
          if (row != rows.last) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.data});

  final _SettingRowData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _handleOpenSetting(context, data.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.iconFill,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: DudoColors.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.trailingSwitch)
                const _SyncSwitch()
              else ...[
                if (data.value != null) ...[
                  Text(
                    data.value!,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFFB8A88E),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncSwitch extends StatelessWidget {
  const _SyncSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('settings-sync-switch-track'),
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: DudoColors.accentMuted),
      ),
      alignment: Alignment.centerRight,
      child: Container(
        key: const ValueKey('settings-sync-switch-thumb'),
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: DudoColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F25251F),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRowData {
  const _SettingRowData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconFill,
    this.value,
    this.route,
    this.trailingSwitch = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconFill;
  final String? value;
  final String? route;
  final bool trailingSwitch;
}

void _handleOpenSetting(BuildContext context, String? route) {
  if (route != null) {
    context.push(route);
  }
}

void _handleOpenHelp(BuildContext context) {
  context.push(AppRoutes.aboutApp);
}
