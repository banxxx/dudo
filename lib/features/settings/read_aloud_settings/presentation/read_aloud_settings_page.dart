import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

class ReadAloudSettingsPage extends StatelessWidget {
  const ReadAloudSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '阅读朗读',
          actionIcon: LucideIcons.headphones,
        ),
        SizedBox(height: 14),
        _VoicePreviewPlayer(),
        SizedBox(height: 14),
        SettingsSectionTitle('声音'),
        SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: Row(
            children: [
              Expanded(
                child: _VoiceChoice(
                  label: '清澈女声',
                  state: '默认',
                  selected: true,
                  iconColor: DudoColors.primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _VoiceChoice(
                  label: '温和男声',
                  state: '低沉',
                  iconColor: DudoColors.secondary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _VoiceChoice(
                  label: '童话旁白',
                  state: '轻快',
                  iconColor: DudoColors.secondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        SettingsMeterControl(
          label: '语速',
          value: '1.0x',
          color: DudoColors.primary,
          fraction: 0.55,
        ),
        SizedBox(height: 8),
        SettingsMeterControl(
          label: '音调',
          value: '标准',
          color: DudoColors.accent,
          fraction: 0.61,
        ),
        SizedBox(height: 8),
        SettingsMeterControl(
          label: '音量',
          value: '72%',
          color: DudoColors.secondary,
          fraction: 0.74,
        ),
        SizedBox(height: 14),
        SettingsOptionRow(
          title: '定时停止',
          description: '开启后可自定义停止时间',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeChip(),
              SizedBox(width: 12),
              SettingsDudoSwitch(on: true),
            ],
          ),
          height: 52,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '后台朗读',
          description: '锁屏继续播放',
          trailing: SettingsDudoSwitch(on: true),
          height: 52,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '段落跟读',
          description: '关闭时不跟随高亮段落',
          trailing: SettingsDudoSwitch(on: false),
          height: 52,
        ),
      ],
    );
  }
}

class _VoicePreviewPlayer extends StatelessWidget {
  const _VoicePreviewPlayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '试听朗读',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '00:42',
                style: DudoTextStyles.numeric(
                  color: DudoColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '宇宙像一片沉默的海，声音从纸页深处慢慢浮起。',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DudoColors.textPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: DudoColors.surfaceHigh,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: DudoColors.surface.withValues(alpha: 0.67),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.48,
                      child: Container(color: DudoColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceChoice extends StatelessWidget {
  const _VoiceChoice({
    required this.label,
    required this.state,
    required this.iconColor,
    this.selected = false,
  });

  final String label;
  final String state;
  final Color iconColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? DudoColors.secondary : DudoColors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.volume2, color: iconColor, size: 18),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            state,
            style: DudoTextStyles.sans(color: DudoColors.secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '30 分钟',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            LucideIcons.chevronRight,
            color: Color(0xFFB8A88E),
            size: 14,
          ),
        ],
      ),
    );
  }
}
