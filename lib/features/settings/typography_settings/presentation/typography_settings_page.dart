import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

class TypographySettingsPage extends StatelessWidget {
  const TypographySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '字体与排版',
          actionIcon: LucideIcons.rotateCcw,
        ),
        SizedBox(height: 14),
        _ReadingPreview(),
        SizedBox(height: 14),
        SettingsSectionTitle('字体'),
        SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: Row(
            children: [
              Expanded(
                child: _FontChoice(
                  label: '思源宋体',
                  selected: true,
                  serif: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: _FontChoice(label: '系统黑体')),
              SizedBox(width: 10),
              Expanded(
                child: _FontChoice(
                  label: '霞鹜文楷',
                  serif: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        SettingsMeterControl(
          label: '字号',
          value: '19',
          color: DudoColors.primary,
          fraction: 0.68,
        ),
        SizedBox(height: 8),
        SettingsMeterControl(
          label: '行距',
          value: '1.55',
          color: DudoColors.accent,
          fraction: 0.76,
        ),
        SizedBox(height: 8),
        SettingsMeterControl(
          label: '段距',
          value: '中等',
          color: DudoColors.secondary,
          fraction: 0.53,
        ),
        SizedBox(height: 14),
        SettingsOptionRow(
          title: '首行缩进',
          description: '2 字符',
          trailing: SettingsDudoSwitch(on: true),
          height: 52,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '繁简转换',
          description: '跟随书籍',
          trailing: SettingsTrailingValue('自动', color: DudoColors.primary),
          height: 52,
        ),
        SizedBox(height: 7),
        SettingsOptionRow(
          title: '标点挤压',
          description: '关闭后保留原书标点间距',
          trailing: SettingsDudoSwitch(on: false),
          height: 52,
        ),
      ],
    );
  }
}

class _ReadingPreview extends StatelessWidget {
  const _ReadingPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '《三体》节选',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '她仰望着夜空，宇宙像一张深色纸页，所有星辰都在沉默地等待被阅读。',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontChoice extends StatelessWidget {
  const _FontChoice({
    required this.label,
    this.selected = false,
    this.serif = false,
  });

  final String label;
  final bool selected;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? DudoColors.secondary : DudoColors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '书',
            style: (serif ? DudoTextStyles.serif : DudoTextStyles.sans)(
              color: DudoColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style:
                DudoTextStyles.sans(color: DudoColors.secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

