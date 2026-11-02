import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import 'cover_crop_view.dart';

class CoverFlowTopBar extends StatelessWidget {
  const CoverFlowTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.stepLabel,
    this.badge,
  });

  final String title;
  final VoidCallback onBack;
  final String? stepLabel;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            _CircleButton(
              icon: LucideIcons.arrowLeft,
              onTap: onBack,
              tooltip: '返回',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.serif(
                  color: DudoColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: DudoColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  badge!,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (stepLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DudoColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stepLabel!,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: DudoColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: DudoColors.textPrimary, size: 18),
          ),
        ),
      ),
    );
  }
}

class CoverFlowChip extends StatelessWidget {
  const CoverFlowChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DudoColors.primaryContainerStrong
          : DudoColors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? DudoColors.primary.withValues(alpha: 0.35)
                  : DudoColors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected
                      ? DudoColors.onPrimaryContainer
                      : DudoColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: selected
                      ? DudoColors.onPrimaryContainer
                      : DudoColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoverFlowHint extends StatelessWidget {
  const CoverFlowHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainerMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            color: DudoColors.onPrimaryContainer,
            size: 14,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: DudoTextStyles.sans(
                color: DudoColors.onPrimaryContainer,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoverFlowPrimaryButton extends StatelessWidget {
  const CoverFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: DudoColors.ink,
          foregroundColor: DudoColors.onInk,
          disabledBackgroundColor: DudoColors.ink.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DudoColors.onInk,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: DudoTextStyles.sans(
                      color: DudoColors.onInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, color: DudoColors.onInk, size: 17),
                  ],
                ],
              ),
      ),
    );
  }
}

class CoverZoomRow extends StatelessWidget {
  const CoverZoomRow({super.key, required this.controller});

  final CoverCropController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          LucideIcons.zoomOut,
          size: 15,
          color: DudoColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          '缩放',
          style: DudoTextStyles.sans(
            color: DudoColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: controller.scale,
            builder: (context, scale, _) {
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: DudoColors.primary,
                  inactiveTrackColor: DudoColors.outlineVariant,
                  thumbColor: DudoColors.primary,
                  overlayColor: DudoColors.primary.withValues(alpha: 0.12),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  min: 1,
                  max: 5,
                  value: scale.clamp(1, 5),
                  onChanged: controller.setScale,
                ),
              );
            },
          ),
        ),
        Icon(
          LucideIcons.zoomIn,
          size: 15,
          color: DudoColors.textSecondary,
        ),
      ],
    );
  }
}

class CoverSmallAction extends StatelessWidget {
  const CoverSmallAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surfaceHigh,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: DudoColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoverFlowStage extends StatelessWidget {
  const CoverFlowStage({
    super.key,
    required this.child,
    required this.aspectRatio,
  });

  final Widget child;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4025251F),
            offset: Offset(0, 14),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      ),
    );
  }
}
