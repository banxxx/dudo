import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_page_frame.dart';
import '../../../../shared/widgets/dudo_page_header.dart';

class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        constrainWidth: false,
        eager: true,
        children: children,
      ),
    );
  }
}

class SettingsDetailHeader extends StatelessWidget {
  const SettingsDetailHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionIcon,
    this.onActionTap,
    this.showAction = true,
  });

  final String eyebrow;
  final String title;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return DudoPageHeader(
      title: title,
      height: 60,
      titleAlignment: Alignment.centerLeft,
      reserveTrailingSpace: false,
      leading: DudoCircleIconButton(
        icon: LucideIcons.chevronLeft,
        iconSize: 20,
        onTap: () => context.pop(),
      ),
      titleWidget: Padding(
        padding: const EdgeInsets.only(left: 12),
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
      trailing: showAction && actionIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: DudoCircleIconButton(
                icon: actionIcon!,
                iconSize: 20,
                onTap: onActionTap ?? () {},
              ),
            )
          : null,
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.text, {super.key});

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

class SettingsMeterControl extends StatelessWidget {
  const SettingsMeterControl({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.fraction,
    this.minValue = 0,
    this.maxValue = 1,
    this.onChanged,
  });

  final String label;
  final String value;
  final Color color;
  final double fraction;
  final double minValue;
  final double maxValue;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final currentValue =
        minValue + (maxValue - minValue) * fraction.clamp(0.0, 1.0);
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
          if (onChanged == null) ...[
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
          ] else
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: DudoColors.outlineVariant,
                thumbColor: color,
                trackHeight: 4,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: currentValue,
                min: minValue,
                max: maxValue,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({
    super.key,
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

class SettingsTrailingValue extends StatelessWidget {
  const SettingsTrailingValue(this.text, {super.key, required this.color});

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

class SettingsDudoSwitch extends StatelessWidget {
  const SettingsDudoSwitch({super.key, required this.on, this.onTap});

  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final indicator = Container(
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: on
            ? DudoColors.primaryContainer
            : (dark ? DudoColors.surfaceLow : DudoColors.surface),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: on
              ? (dark
                  ? DudoColors.primary.withValues(alpha: 0.55)
                  : DudoColors.accentMuted)
              : DudoColors.outline,
        ),
      ),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: on
              ? DudoColors.primary
              : (dark ? DudoColors.textSecondary : DudoColors.outline),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x66000000) : const Color(0x1F25251F),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) return indicator;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: indicator,
    );
  }
}
