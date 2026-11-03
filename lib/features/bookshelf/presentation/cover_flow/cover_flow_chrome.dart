import 'dart:typed_data';
import 'dart:ui' as ui;

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
    final trailing = stepLabel ?? badge;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleButton(
                icon: LucideIcons.arrowLeft,
                onTap: onBack,
                tooltip: '返回',
              ),
            ),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  trailing,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
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
            width: 44,
            height: 44,
            child: Icon(icon, color: DudoColors.secondary, size: 22),
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
    this.height = 32,
    this.radius = 16,
    this.fontSize = 11,
    this.minWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double radius;
  final double fontSize;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DudoColors.ink : DudoColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          height: height,
          constraints:
              minWidth == null ? null : BoxConstraints(minWidth: minWidth!),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? DudoColors.onInk : DudoColors.secondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: selected ? DudoColors.onInk : DudoColors.textSecondary,
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoverFlowSwitch extends StatelessWidget {
  const CoverFlowSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.short,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? DudoColors.textPrimary : DudoColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? DudoColors.textPrimary : DudoColors.outlineVariant,
          ),
        ),
        child: AnimatedAlign(
          duration: AppMotion.short,
          curve: AppMotion.emphasized,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? DudoColors.surfaceHigh : DudoColors.surface,
              shape: BoxShape.circle,
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            color: DudoColors.primary,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: DudoTextStyles.sans(
                color: DudoColors.primaryDark,
                fontSize: 11,
                height: 1.4,
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
    this.radius = 20,
    this.labelSize = 14,
    this.labelWeight = FontWeight.w600,
    this.enableFeedback = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double radius;
  final double labelSize;
  final FontWeight labelWeight;

  /// The platform tap sound/haptics. Turn it off when the action plays its own
  /// single feedback, so one tap can never sound like several.
  final bool enableFeedback;

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
          enableFeedback: enableFeedback,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
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
                  if (icon != null) ...[
                    Icon(icon, color: DudoColors.onInk, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: DudoTextStyles.sans(
                      color: DudoColors.onInk,
                      fontSize: labelSize,
                      fontWeight: labelWeight,
                    ),
                  ),
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
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(
            LucideIcons.zoomOut,
            size: 18,
            color: DudoColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: controller.scale,
              builder: (context, scale, _) {
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
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
          const SizedBox(width: 10),
          Icon(
            LucideIcons.zoomIn,
            size: 18,
            color: DudoColors.secondary,
          ),
          const SizedBox(width: 10),
          Text(
            '缩放',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
      color: DudoColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: DudoColors.secondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A crop surface framed by a taller dark stage, matching the C-series crop
/// mockups: the source image is dimmed behind the active crop frame.
class CoverFlowCropStage extends StatelessWidget {
  const CoverFlowCropStage({
    super.key,
    required this.bytes,
    required this.aspectRatio,
    required this.controller,
    this.overlayBuilder,
    this.stageOverlayBuilder,
    this.stageHeightFactor = 406 / 350,
    this.frameWidthFactor = 230 / 350,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final CoverCropController controller;
  final Widget Function(Size viewport)? overlayBuilder;
  final Widget Function(Size stage, Rect frame)? stageOverlayBuilder;
  final double stageHeightFactor;
  final double frameWidthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final stageHeight = stageWidth * stageHeightFactor;
        final frameWidth = stageWidth * frameWidthFactor;
        final frameHeight = frameWidth / aspectRatio;
        final frameRect = Rect.fromLTWH(
          (stageWidth - frameWidth) / 2,
          (stageHeight - frameHeight) / 2,
          frameWidth,
          frameHeight,
        );
        return Container(
          width: stageWidth,
          height: stageHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF25251F),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4025251F),
                offset: Offset(0, 14),
                blurRadius: 28,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Frosted backdrop: the source blurred past recognition and
              // veiled with the page colour, so the crop frame is the only
              // sharp thing on the stage and the eye stays on it.
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 20,
                    sigmaY: 20,
                    tileMode: ui.TileMode.clamp,
                  ),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              ColoredBox(
                color: DudoColors.paperBackground.withValues(alpha: 0.7),
              ),
              Center(
                child: SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: CoverCropView(
                    key: ValueKey(aspectRatio),
                    bytes: bytes,
                    aspectRatio: aspectRatio,
                    controller: controller,
                    overlayBuilder: overlayBuilder,
                  ),
                ),
              ),
              if (stageOverlayBuilder != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: stageOverlayBuilder!(
                      Size(stageWidth, stageHeight),
                      frameRect,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
