import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_fonts.dart';
import '../theme/app_tokens.dart';
import 'app_message.dart';

class AppMessageCard extends StatelessWidget {
  const AppMessageCard({
    super.key,
    required this.request,
    this.onClose,
  });

  final AppMessageRequest request;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _colors(scheme, request.kind, request.visualStyle);
    final isDialog = request.size == AppMessageSize.dialog;

    return SafeArea(
      minimum: EdgeInsets.symmetric(
        horizontal: isDialog ? AppSpacing.md : 20,
        vertical: isDialog ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Center(
        widthFactor: isDialog ? null : 1,
        heightFactor: isDialog ? null : 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDialog ? 420 : 350,
            minWidth: isDialog ? 280 : 350,
            minHeight: isDialog ? 0 : 82,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDialog ? 28 : 26),
              boxShadow: request.visualStyle == AppMessageVisualStyle.paper
                  ? [
                      BoxShadow(
                        color: DudoColors.textPrimary.withValues(alpha: 0.16),
                        offset: const Offset(0, 16),
                        blurRadius: 36,
                      ),
                    ]
                  : const [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isDialog ? 28 : 26),
              child: BackdropFilter(
                filter: request.visualStyle == AppMessageVisualStyle.paper
                    ? ImageFilter.blur(sigmaX: 18, sigmaY: 18)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Material(
                  color: colors.background,
                  elevation:
                      request.visualStyle == AppMessageVisualStyle.paper ? 0 : 6,
                  shadowColor: DudoColors.textPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(isDialog ? 28 : 26),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isDialog ? 28 : 26),
                      border: Border.all(color: colors.border),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDialog ? AppSpacing.lg : 14,
                      vertical: isDialog ? AppSpacing.lg : 12,
                    ),
                    child: isDialog
                        ? _DialogContent(
                            request: request,
                            colors: colors,
                            onClose: onClose,
                          )
                        : _CompactContent(
                            request: request,
                            colors: colors,
                            onClose: onClose,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({
    required this.request,
    required this.colors,
    this.onClose,
  });

  final AppMessageRequest request;
  final _MessageColors colors;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MessageIcon(kind: request.kind, colors: colors, size: 48),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.title,
                style: DudoTextStyles.sans(
                  color: colors.title,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (request.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  request.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: colors.description,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (request.actionLabel != null && request.onAction != null) ...[
          const SizedBox(width: 12),
          _ToastActionButton(
            label: request.actionLabel!,
            onTap: request.onAction!,
            colors: colors,
          ),
        ] else if (request.dismissible && onClose != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onClose,
            borderRadius: AppRadius.full,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.x, color: colors.close, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final VoidCallback onTap;
  final _MessageColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.actionBackground,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: colors.actionForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    required this.request,
    required this.colors,
    this.onClose,
  });

  final AppMessageRequest request;
  final _MessageColors colors;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MessageIcon(kind: request.kind, colors: colors, size: 58),
            const SizedBox(height: AppSpacing.md),
            Text(
              request.title,
              style: DudoTextStyles.serif(
                color: colors.title,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (request.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.description!,
                style: DudoTextStyles.sans(
                  color: colors.description,
                  fontSize: 13,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        if (request.dismissible && onClose != null)
          PositionedDirectional(
            top: -8,
            end: -8,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(LucideIcons.x, color: colors.close),
              tooltip: '关闭',
            ),
          ),
      ],
    );
  }
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon({
    required this.kind,
    required this.colors,
    required this.size,
  });

  final AppMessageKind kind;
  final _MessageColors colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.iconBackground,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(_icon(kind), color: colors.icon, size: size * 0.48),
    );
  }
}

_MessageColors _colors(
  ColorScheme scheme,
  AppMessageKind kind,
  AppMessageVisualStyle style,
) {
  if (style == AppMessageVisualStyle.filled) {
    return switch (kind) {
      AppMessageKind.success => _MessageColors.filled(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
      AppMessageKind.warning => _MessageColors.filled(
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
      AppMessageKind.error => _MessageColors.filled(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
      AppMessageKind.loading || AppMessageKind.info => _MessageColors.filled(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
    };
  }

  return switch (kind) {
    AppMessageKind.success => const _MessageColors.paper(
        accent: DudoColors.primary,
        iconBackground: DudoColors.primaryContainer,
      ),
    AppMessageKind.warning => const _MessageColors.paper(
        accent: DudoColors.secondary,
        iconBackground: DudoColors.surfaceLow,
      ),
    AppMessageKind.error => const _MessageColors.paper(
        accent: DudoColors.accent,
        iconBackground: DudoColors.surfaceLow,
      ),
    AppMessageKind.loading || AppMessageKind.info => const _MessageColors.paper(
        accent: DudoColors.secondary,
        iconBackground: DudoColors.surfaceLow,
      ),
  };
}

IconData _icon(AppMessageKind kind) {
  return switch (kind) {
    AppMessageKind.info => LucideIcons.info,
    AppMessageKind.success => LucideIcons.check,
    AppMessageKind.warning => LucideIcons.triangleAlert,
    AppMessageKind.error => LucideIcons.circleAlert,
    AppMessageKind.loading => LucideIcons.hourglass,
  };
}

class _MessageColors {
  const _MessageColors({
    required this.background,
    required this.border,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.actionBackground,
    required this.actionForeground,
    required this.close,
  });

  const _MessageColors.paper({
    required Color accent,
    required this.iconBackground,
  })  : background = const Color(0xF7FFFBF2),
        border = const Color(0xCCFFFFFF),
        title = DudoColors.textPrimary,
        description = DudoColors.textSecondary,
        icon = accent,
        actionBackground = DudoColors.textPrimary,
        actionForeground = DudoColors.surfaceHigh,
        close = DudoColors.secondary;

  const _MessageColors.filled({
    required Color background,
    required Color foreground,
  }) : this(
          background: background,
          border: Colors.transparent,
          title: foreground,
          description: foreground,
          icon: foreground,
          iconBackground: Colors.white24,
          actionBackground: Colors.white24,
          actionForeground: foreground,
          close: foreground,
        );

  final Color background;
  final Color border;
  final Color title;
  final Color description;
  final Color icon;
  final Color iconBackground;
  final Color actionBackground;
  final Color actionForeground;
  final Color close;
}
