import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colors = _colors(scheme, request.kind);
    final isDialog = request.size == AppMessageSize.dialog;

    return SafeArea(
      minimum: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: isDialog ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Center(
        widthFactor: isDialog ? null : 1,
        heightFactor: isDialog ? null : 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDialog ? 480 : 560,
            minWidth: isDialog ? 280 : 0,
          ),
          child: Material(
            color: colors.background,
            elevation: isDialog ? 12 : 6,
            shadowColor: scheme.shadow.withValues(alpha: 0.18),
            surfaceTintColor: scheme.surfaceTint,
            borderRadius: isDialog ? AppRadius.xLarge : AppRadius.large,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(isDialog ? AppSpacing.lg : AppSpacing.md),
              child: isDialog
                  ? _DialogContent(
                      request: request,
                      colors: colors,
                      textTheme: textTheme,
                      onClose: onClose,
                    )
                  : _CompactContent(
                      request: request,
                      colors: colors,
                      textTheme: textTheme,
                      onClose: onClose,
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
    required this.textTheme,
    this.onClose,
  });

  final AppMessageRequest request;
  final _MessageColors colors;
  final TextTheme textTheme;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(request.kind), color: colors.foreground, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.title,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (request.description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  request.description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (request.dismissible && onClose != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(LucideIcons.x, color: colors.foreground),
            tooltip: '关闭',
          ),
        ],
      ],
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    required this.request,
    required this.colors,
    required this.textTheme,
    this.onClose,
  });

  final AppMessageRequest request;
  final _MessageColors colors;
  final TextTheme textTheme;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(request.kind), color: colors.foreground, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              request.title,
              style: textTheme.titleLarge?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (request.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.82),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        if (request.dismissible && onClose != null)
          PositionedDirectional(
            top: -AppSpacing.sm,
            end: -AppSpacing.sm,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(LucideIcons.x, color: colors.foreground),
              tooltip: '关闭',
            ),
          ),
      ],
    );
  }
}

_MessageColors _colors(ColorScheme scheme, AppMessageKind kind) {
  return switch (kind) {
    AppMessageKind.success => _MessageColors(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
    AppMessageKind.warning => _MessageColors(
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
    AppMessageKind.error => _MessageColors(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
    AppMessageKind.loading || AppMessageKind.info => _MessageColors(
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
  };
}

IconData _icon(AppMessageKind kind) {
  return switch (kind) {
    AppMessageKind.info => LucideIcons.info,
    AppMessageKind.success => LucideIcons.circleCheck,
    AppMessageKind.warning => LucideIcons.triangleAlert,
    AppMessageKind.error => LucideIcons.circleAlert,
    AppMessageKind.loading => LucideIcons.hourglass,
  };
}

class _MessageColors {
  const _MessageColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
