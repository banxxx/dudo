import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../shared/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';
import '../../settings/data_sync_settings/application/data_sync_settings_provider.dart';
import '../../settings/data_sync_settings/domain/data_sync_settings.dart';
import '../../settings/read_aloud_settings/application/read_aloud_settings_provider.dart';
import '../../settings/read_aloud_settings/domain/read_aloud_settings.dart';
import '../../settings/shelf_update_settings/application/shelf_update_settings_provider.dart';
import '../../settings/shelf_update_settings/domain/shelf_update_settings.dart';
import '../../settings/storage_settings/application/storage_usage_provider.dart';
import '../../settings/storage_settings/domain/storage_usage.dart';
import '../../settings/theme_settings/application/theme_settings_provider.dart';
import '../../settings/theme_settings/domain/theme_settings.dart';
import '../../settings/typography_settings/application/reader_font_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider).valueOrNull ??
        ThemeSettings.defaults();
    final themeModeLabel = switch (themeSettings.mode) {
      DudoThemeMode.paper => '纸色',
      DudoThemeMode.dark => '深色',
      DudoThemeMode.system => '跟随系统',
    };
    final selectedFont = ref.watch(selectedReaderFontProvider).valueOrNull;
    final readAloud = ref.watch(readAloudSettingsProvider).valueOrNull;
    final shelfUpdate = ref.watch(shelfUpdateSettingsProvider).valueOrNull ??
        ShelfUpdateSettings.defaults();
    final dataSync = ref.watch(dataSyncSettingsProvider).valueOrNull ??
        DataSyncSettings.defaults();
    final storageUsage = ref.watch(storageUsageProvider).valueOrNull;
    final readAloudVoice = readAloud?.engine == ReadAloudEngine.online
        ? '在线引擎'
        : (readAloud?.voiceName == null ? '系统语音' : '自定义音色');
    final readAloudValue =
        '$readAloudVoice · ${(readAloud?.speechRate ?? 1.0).toStringAsFixed(1)}x';

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        constrainWidth: false,
        eager: true,
        children: [
          const _TopActions(),
          const SizedBox(height: 14),
          const _SettingsHero(),
          const SizedBox(height: 14),
          _SettingsSection(
            title: '阅读体验',
            rows: [
              _SettingRowData(
                title: '主题与外观',
                description: '纸感、深色、跟随系统',
                value: '${themeSettings.accent.label} · $themeModeLabel',
                icon: LucideIcons.palette,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.themeSettings,
              ),
              _SettingRowData(
                title: '字体管理',
                description: '导入、选择和管理阅读字体',
                value: selectedFont?.displayName ?? '默认字体',
                icon: LucideIcons.type,
                iconFill: DudoColors.surfaceLow,
                route: AppRoutes.typographySettings,
              ),
              _SettingRowData(
                title: '阅读朗读',
                description: '声音、语速、定时与后台播放',
                value: readAloudValue,
                icon: LucideIcons.volume2,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.readAloudSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: '内容与书源',
            rows: [
              _SettingRowData(
                title: '书架更新',
                description: '更新频率、章节提醒和自动拉取',
                value: shelfUpdate.entryLabel,
                icon: LucideIcons.refreshCw,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.shelfUpdateSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: '通用',
            rows: [
              _SettingRowData(
                title: '数据同步',
                description: '阅读进度、书签、高亮和设置',
                value: dataSync.entryLabel,
                icon: LucideIcons.cloud,
                iconFill: DudoColors.surfaceLow,
                route: AppRoutes.dataSyncSettings,
              ),
              _SettingRowData(
                title: '缓存与存储',
                description: '封面缓存、语音与数据库',
                value: storageUsage == null
                    ? '计算中'
                    : formatStorageBytes(storageUsage.totalBytes),
                icon: LucideIcons.hardDrive,
                iconFill: DudoColors.primaryContainer,
                route: AppRoutes.storageSettings,
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
    final dark = DudoColors.isDark;
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2225251F),
            offset: const Offset(0, 12),
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
              color: dark
                  ? DudoColors.onInk.withValues(alpha: 0.10)
                  : const Color(0x22FFF8EA),
              borderRadius: BorderRadius.circular(31),
            ),
            child: Icon(
              LucideIcons.settings,
              color: dark ? DudoColors.primary : DudoColors.secondaryContainer,
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
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '设置',
                  style: DudoTextStyles.serif(
                    color: DudoColors.onInk,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '调整阅读体验、书源与同步，让书房按你的习惯运转。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
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
          ),
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
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconFill;
  final String? value;
  final String? route;
}

void _handleOpenSetting(BuildContext context, String? route) {
  if (route != null) {
    context.push(route);
  }
}

void _handleOpenHelp(BuildContext context) {
  context.push(AppRoutes.aboutApp);
}
