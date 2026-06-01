import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

class SourceManageSettingsPage extends StatelessWidget {
  const SourceManageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsDetailScaffold(
      children: [
        _DetailHeader(
          eyebrow: '内容与书源',
          title: '书源管理',
          actionIcon: LucideIcons.plus,
        ),
        SizedBox(height: 14),
        _SourceSummary(),
        SizedBox(height: 14),
        SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.plus,
                  label: '添加书源',
                  selected: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.download,
                  label: '导入订阅',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.shieldCheck,
                  label: '校验规则',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        _SectionTitle('书源列表'),
        SizedBox(height: 8),
        _SourceRow(
          name: '番茄小说',
          description: '更新快 · 发现 12 本',
          state: '启用中',
          stateColor: DudoColors.primary,
          dotColor: DudoColors.primary,
          dotFill: DudoColors.primaryContainer,
        ),
        SizedBox(height: 8),
        _SourceRow(
          name: '起点中文',
          description: '章节完整 · 搜索稳定',
          state: '启用中',
          stateColor: DudoColors.primary,
          dotColor: DudoColors.primary,
          dotFill: DudoColors.primaryContainer,
        ),
        SizedBox(height: 8),
        _SourceRow(
          name: '本地 TXT',
          description: '导入 38 本本地书',
          state: '已挂载',
          stateColor: DudoColors.secondary,
          dotColor: DudoColors.secondary,
          dotFill: DudoColors.primaryContainer,
        ),
        SizedBox(height: 8),
        _SourceRow(
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

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsDetailScaffold(
      children: [
        _DetailHeader(
          eyebrow: '阅读体验',
          title: '主题外观',
          actionIcon: LucideIcons.palette,
        ),
        SizedBox(height: 14),
        _ThemePreview(),
        SizedBox(height: 14),
        _SectionTitle('模式'),
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
        _SectionTitle('强调色'),
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
        _OptionRow(
          title: '护眼纸纹',
          description: '轻微颗粒与纸张纹理',
          trailing: _DudoSwitch(on: true),
          height: 54,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '阅读页沉浸',
          description: '隐藏顶部状态信息',
          trailing: _TrailingValue('手动', color: DudoColors.primary),
          height: 54,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '封面取色',
          description: '关闭后详情页不自动取封面色',
          trailing: _DudoSwitch(on: false),
          height: 54,
        ),
      ],
    );
  }
}

class TypographySettingsPage extends StatelessWidget {
  const TypographySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsDetailScaffold(
      children: [
        _DetailHeader(
          eyebrow: '阅读体验',
          title: '字体与排版',
          actionIcon: LucideIcons.rotateCcw,
        ),
        SizedBox(height: 14),
        _ReadingPreview(),
        SizedBox(height: 14),
        _SectionTitle('字体'),
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
        _MeterControl(
          label: '字号',
          value: '19',
          color: DudoColors.primary,
          fraction: 0.68,
        ),
        SizedBox(height: 8),
        _MeterControl(
          label: '行距',
          value: '1.55',
          color: DudoColors.accent,
          fraction: 0.76,
        ),
        SizedBox(height: 8),
        _MeterControl(
          label: '段距',
          value: '中等',
          color: DudoColors.secondary,
          fraction: 0.53,
        ),
        SizedBox(height: 14),
        _OptionRow(
          title: '首行缩进',
          description: '2 字符',
          trailing: _DudoSwitch(on: true),
          height: 52,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '繁简转换',
          description: '跟随书籍',
          trailing: _TrailingValue('自动', color: DudoColors.primary),
          height: 52,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '标点挤压',
          description: '关闭后保留原书标点间距',
          trailing: _DudoSwitch(on: false),
          height: 52,
        ),
      ],
    );
  }
}

class ReadAloudSettingsPage extends StatelessWidget {
  const ReadAloudSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsDetailScaffold(
      children: [
        _DetailHeader(
          eyebrow: '阅读体验',
          title: '阅读朗读',
          actionIcon: LucideIcons.headphones,
        ),
        SizedBox(height: 14),
        _VoicePreviewPlayer(),
        SizedBox(height: 14),
        _SectionTitle('声音'),
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
        _MeterControl(
          label: '语速',
          value: '1.0x',
          color: DudoColors.primary,
          fraction: 0.55,
        ),
        SizedBox(height: 8),
        _MeterControl(
          label: '音调',
          value: '标准',
          color: DudoColors.accent,
          fraction: 0.61,
        ),
        SizedBox(height: 8),
        _MeterControl(
          label: '音量',
          value: '72%',
          color: DudoColors.secondary,
          fraction: 0.74,
        ),
        SizedBox(height: 14),
        _OptionRow(
          title: '定时停止',
          description: '开启后可自定义停止时间',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeChip(),
              SizedBox(width: 12),
              _DudoSwitch(on: true),
            ],
          ),
          height: 52,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '后台朗读',
          description: '锁屏继续播放',
          trailing: _DudoSwitch(on: true),
          height: 52,
        ),
        SizedBox(height: 7),
        _OptionRow(
          title: '段落跟读',
          description: '关闭时不跟随高亮段落',
          trailing: _DudoSwitch(on: false),
          height: 52,
        ),
      ],
    );
  }
}

class _SettingsDetailScaffold extends StatelessWidget {
  const _SettingsDetailScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        eager: true,
        children: children,
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.eyebrow,
    required this.title,
    required this.actionIcon,
  });

  final String eyebrow;
  final String title;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _CircleIconButton(
                  icon: LucideIcons.chevronLeft,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: DudoTextStyles.serif(
                          color: DudoColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CircleIconButton(icon: actionIcon, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
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
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DudoColors.surfaceHigh : DudoColors.secondary;

    return Container(
      decoration: BoxDecoration(
        color: selected ? DudoColors.textPrimary : DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: DudoColors.outlineVariant),
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

class _MeterControl extends StatelessWidget {
  const _MeterControl({
    required this.label,
    required this.value,
    required this.color,
    required this.fraction,
  });

  final String label;
  final String value;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: DudoTextStyles.numeric(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: DudoColors.outlineVariant,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(color: color),
              ),
            ),
          ),
        ],
      ),
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
            style:
                DudoTextStyles.sans(color: DudoColors.secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.description,
    required this.trailing,
    required this.height,
  });

  final String title;
  final String description;
  final Widget trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _TrailingValue extends StatelessWidget {
  const _TrailingValue(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(color: color, fontSize: 12),
    );
  }
}

class _DudoSwitch extends StatelessWidget {
  const _DudoSwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: on ? DudoColors.primaryContainer : DudoColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: on ? DudoColors.accentMuted : DudoColors.outline,
        ),
      ),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: on ? DudoColors.primary : DudoColors.outline,
          shape: BoxShape.circle,
          boxShadow: const [
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
