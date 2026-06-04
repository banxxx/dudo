import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/dudo_page_frame.dart';

class ReadingGoalPage extends StatelessWidget {
  const ReadingGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
        constrainWidth: false,
        eager: true,
        children: [
          _GoalHeader(),
          SizedBox(height: 10),
          _GoalHeroCard(),
          SizedBox(height: 10),
          _QuickMetrics(),
          SizedBox(height: 10),
          _WeeklyPaceCard(),
          SizedBox(height: 10),
          _GoalSettingsCard(),
          SizedBox(height: 10),
          _SuggestionCard(),
        ],
      ),
    );
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
              icon: LucideIcons.chevronLeft, onTap: () => context.pop()),
          Text(
            '五月阅读目标',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          _CircleButton(icon: LucideIcons.pencil, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

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
          child: Icon(icon,
              color: DudoColors.secondary,
              size: icon == LucideIcons.chevronLeft ? 22 : 19),
        ),
      ),
    );
  }
}

class _GoalHeroCard extends StatelessWidget {
  const _GoalHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月目标进度',
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '15h 36m',
                      style: DudoTextStyles.numeric(
                        color: DudoColors.surfaceHigh,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '目标 20 小时 · 已完成 78%',
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    _HeroBadge(
                      icon: LucideIcons.timer,
                      text: '差 4h24m',
                      iconColor: DudoColors.secondaryContainer,
                      textColor: DudoColors.secondaryContainer,
                      fill: Color(0x1FFFF8EA),
                    ),
                    SizedBox(width: 8),
                    _HeroBadge(
                      icon: LucideIcons.trendingUp,
                      text: '节奏正常',
                      iconColor: DudoColors.primaryContainer,
                      textColor: DudoColors.primaryContainer,
                      fill: Color(0x2BDDE8D4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _ProgressDonut(),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.fill,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration:
          BoxDecoration(color: fill, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: DudoTextStyles.sans(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDonut extends StatelessWidget {
  const _ProgressDonut();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              color: DudoColors.surfaceHigh.withValues(alpha: 0.13),
            ),
          ),
          const SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: 0.78,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              color: DudoColors.primaryContainer,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: DudoColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '78%',
                  style: DudoTextStyles.numeric(
                    color: DudoColors.surfaceHigh,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '完成',
                  style: DudoTextStyles.sans(
                    color: DudoColors.outline,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
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

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 72,
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              value: '23/31',
              label: '已记录天数',
              fill: DudoColors.surface,
              stroke: DudoColors.outlineVariant,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              value: '6天',
              label: '连续阅读',
              fill: DudoColors.primaryContainer,
              stroke: DudoColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.fill,
    required this.stroke,
  });

  final String value;
  final String label;
  final Color fill;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: DudoTextStyles.numeric(
              color: DudoColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPaceCard extends StatelessWidget {
  const _WeeklyPaceCard();

  static const _bars = [
    _WeekBar('一', 34, DudoColors.primaryContainer),
    _WeekBar('二', 44, DudoColors.primaryContainer),
    _WeekBar('三', 26, DudoColors.surfaceLow),
    _WeekBar('四', 52, DudoColors.primary),
    _WeekBar('五', 40, DudoColors.primaryContainer),
    _WeekBar('六', 48, DudoColors.primary),
    _WeekBar('日', 22, DudoColors.surfaceLow),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周节奏',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '日均 42 分钟',
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in _bars) ...[
                  Expanded(child: _WeekBarColumn(bar)),
                  if (bar != _bars.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar {
  const _WeekBar(this.label, this.height, this.color);

  final String label;
  final double height;
  final Color color;
}

class _WeekBarColumn extends StatelessWidget {
  const _WeekBarColumn(this.bar);

  final _WeekBar bar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: bar.height,
          decoration: BoxDecoration(
            color: bar.color,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          bar.label,
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

class _GoalSettingsCard extends StatelessWidget {
  const _GoalSettingsCard();

  @override
  Widget build(BuildContext context) {
    return const _PlainCard(
      height: 170,
      children: [
        _CardTitle('目标设置'),
        SizedBox(height: 6),
        _SettingLine(icon: LucideIcons.target, label: '月度时长', value: '20 小时'),
        SizedBox(height: 6),
        _SettingLine(icon: LucideIcons.bell, label: '阅读提醒', value: '21:30'),
        SizedBox(height: 6),
        _SettingLine(
            icon: LucideIcons.calendarCheck, label: '统计口径', value: '阅读时长'),
      ],
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

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

class _SettingLine extends StatelessWidget {
  const _SettingLine(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: DudoColors.secondary, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: DudoColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.leaf,
                color: DudoColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '每天再读 33 分钟即可达成',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '建议把睡前阅读提醒提前到 21:00。',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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
