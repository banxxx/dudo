import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '主题外观',
          actionIcon: LucideIcons.palette,
        ),
        SizedBox(height: 14),
        _ThemePreview(),
        SizedBox(height: 14),
        SettingsSectionTitle('模式'),
        SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: '纸色',
                  subtitle: '已选择',
                  fill: DudoColors.surface,
                  border: DudoColors.secondary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  title: '深色',
                  subtitle: '夜间阅读',
                  fill: DudoColors.textPrimary,
                  titleColor: DudoColors.surfaceHigh,
                  subtitleColor: DudoColors.outline,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  title: '跟随系统',
                  subtitle: '自动切换',
                  fill: DudoColors.primaryContainer,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        SettingsSectionTitle('强调色'),
        SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: Row(
            children: [
              Expanded(
                  child: _AccentChip(label: '松叶绿', color: DudoColors.primary)),
              SizedBox(width: 10),
              Expanded(
                  child: _AccentChip(label: '荔枝棕', color: DudoColors.accent)),
              SizedBox(width: 10),
              Expanded(
                  child:
                      _AccentChip(label: '墨黑', color: DudoColors.textPrimary)),
              SizedBox(width: 10),
              Expanded(
                  child:
                      _AccentChip(label: '米杏', color: DudoColors.accentMuted)),
            ],
          ),
        ),
        SizedBox(height: 14),
        SettingsOptionRow(
          title: '护眼纸纹',
          description: '轻微颗粒与纸张纹理',
          trailing: SettingsDudoSwitch(on: true),
          height: 54,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '阅读页沉浸',
          description: '隐藏顶部状态信息',
          trailing: SettingsTrailingValue('手动', color: DudoColors.primary),
          height: 54,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '封面取色',
          description: '关闭后详情页不自动取封面色',
          trailing: SettingsDudoSwitch(on: false),
          height: 54,
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前主题',
            style: DudoTextStyles.sans(
              color: DudoColors.outline,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '静纸 · 暖色',
            style: DudoTextStyles.serif(
              color: DudoColors.surfaceHigh,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '纸张底色偏暖，强调色用于进度、书签和可操作按钮。',
            style: DudoTextStyles.sans(
              color: DudoColors.outline,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              _Swatch(DudoColors.paperBackground),
              SizedBox(width: 8),
              _Swatch(DudoColors.surface),
              SizedBox(width: 8),
              _Swatch(DudoColors.primaryContainer),
              SizedBox(width: 8),
              _Swatch(DudoColors.secondary),
              SizedBox(width: 8),
              _Swatch(DudoColors.textPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.33)),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.fill,
    this.border = DudoColors.outlineVariant,
    this.titleColor = DudoColors.textPrimary,
    this.subtitleColor = DudoColors.secondary,
  });

  final String title;
  final String subtitle;
  final Color fill;
  final Color border;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DudoTextStyles.sans(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: DudoTextStyles.sans(color: subtitleColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  const _AccentChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

