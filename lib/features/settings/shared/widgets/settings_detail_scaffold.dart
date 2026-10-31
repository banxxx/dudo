import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_entry_row.dart';
import '../../../../shared/widgets/dudo_page_frame.dart';
import '../../../../shared/widgets/dudo_page_header.dart';

class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({
    super.key,
    required this.children,
    this.bottomBar,
  });

  final List<Widget> children;
  final Widget? bottomBar;

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
      bottomNavigationBar: bottomBar,
    );
  }
}

class SettingsDetailHeader extends StatelessWidget {
  const SettingsDetailHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionIcon,
    this.actionLabel,
    this.actionEmphasized = false,
    this.onActionTap,
    this.showAction = true,
  });

  final String eyebrow;
  final String title;
  final IconData? actionIcon;

  /// When set, the trailing action renders as a text pill (e.g. 编辑 / 完成)
  /// instead of an icon circle. Text actions are easier to read for mode
  /// switches such as entering a list's editing state.
  final String? actionLabel;
  final bool actionEmphasized;
  final VoidCallback? onActionTap;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final actionIcon = this.actionIcon;
    final hasAction =
        showAction && (actionLabel != null || actionIcon != null);

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
      trailing: hasAction
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: actionLabel != null
                  ? _HeaderTextAction(
                      label: actionLabel,
                      emphasized: actionEmphasized,
                      onTap: onActionTap ?? () {},
                    )
                  : DudoCircleIconButton(
                      icon: actionIcon!,
                      iconSize: 20,
                      onTap: onActionTap ?? () {},
                    ),
            )
          : null,
    );
  }
}

class _HeaderTextAction extends StatelessWidget {
  const _HeaderTextAction({
    required this.label,
    required this.emphasized,
    required this.onTap,
  });

  final String label;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                emphasized ? DudoColors.primaryContainer : DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: emphasized
                  ? DudoColors.primaryContainerStrong
                  : DudoColors.outline,
            ),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color:
                  emphasized ? DudoColors.primaryDark : DudoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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

/// A switch/trailing row. It delegates to [DudoEntryRow] so it shares the same
/// height, padding and type scale as the settings and profile entries.
class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({
    super.key,
    required this.title,
    required this.description,
    required this.trailing,
    this.height = 68,
  });

  final String title;
  final String description;
  final Widget trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DudoEntryRow(
      title: title,
      description: description,
      trailing: trailing,
      minHeight: height,
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
