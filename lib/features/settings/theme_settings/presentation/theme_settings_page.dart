import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/theme/dudo_palette.dart';
import '../../../reader_engine/application/reader_preferences_provider.dart';
import '../../../reader_engine/domain/reader_preferences.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/theme_settings_provider.dart';
import '../domain/theme_settings.dart';

/// Theme appearance settings: the light/dark mode, the accent colour, and the
/// reader's immersive ("hide top status info") master switch. The mode and
/// accent restyle the whole app through the active [DudoPalette]; the reader
/// switch toggles the three status-hide flags the reader already respects.
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider).valueOrNull ??
        ThemeSettings.defaults();
    final readerPrefs = ref.watch(readerPreferencesProvider).valueOrNull ??
        ReaderPreferences.defaults();
    final immersive = readerPrefs.timeBatteryHidden &&
        readerPrefs.chapterProgressHidden &&
        readerPrefs.systemStatusBarHidden;

    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '主题外观',
          actionIcon: LucideIcons.palette,
        ),
        const SizedBox(height: 14),
        _ThemePreview(settings: settings),
        const SizedBox(height: 14),
        const SettingsSectionTitle('模式'),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: '纸色',
                  subtitle: '暖纸底色',
                  fill: const Color(0xFFFFFBF2),
                  titleColor: const Color(0xFF25251F),
                  subtitleColor: const Color(0xFF8A735A),
                  selected: settings.mode == DudoThemeMode.paper,
                  onTap: () =>
                      _save(ref, settings.copyWith(mode: DudoThemeMode.paper)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  title: '深色',
                  subtitle: '夜间阅读',
                  fill: const Color(0xFF1C1F22),
                  titleColor: const Color(0xFFF4EBD8),
                  subtitleColor: const Color(0xFFB8AA91),
                  selected: settings.mode == DudoThemeMode.dark,
                  onTap: () =>
                      _save(ref, settings.copyWith(mode: DudoThemeMode.dark)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  title: '跟随系统',
                  subtitle: '自动切换',
                  fill: const Color(0xFFFFFBF2),
                  splitFill: const Color(0xFF1C1F22),
                  titleColor: const Color(0xFF25251F),
                  subtitleColor: const Color(0xFF8A735A),
                  selected: settings.mode == DudoThemeMode.system,
                  onTap: () =>
                      _save(ref, settings.copyWith(mode: DudoThemeMode.system)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SettingsSectionTitle('强调色'),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: Row(
            children: [
              for (final accent in DudoAccent.values) ...[
                Expanded(
                  child: _AccentChip(
                    label: accent.label,
                    color: accent.swatch,
                    selected: settings.accent == accent,
                    onTap: () => _save(ref, settings.copyWith(accent: accent)),
                  ),
                ),
                if (accent != DudoAccent.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingsOptionRow(
          title: '阅读页沉浸',
          description: '隐藏顶部状态信息',
          trailing: SettingsDudoSwitch(
            on: immersive,
            onTap: () => _toggleImmersive(ref, !immersive),
          ),
          height: 68,
        ),
      ],
    );
  }

  void _save(WidgetRef ref, ThemeSettings settings) {
    unawaited(ref.read(themeSettingsRepositoryProvider).save(settings));
  }

  void _toggleImmersive(WidgetRef ref, bool value) {
    final prefs = ref.read(readerPreferencesProvider).valueOrNull ??
        ReaderPreferences.defaults();
    unawaited(
      ref.read(readerPreferencesRepositoryProvider).save(
            prefs.copyWith(
              timeBatteryHidden: value,
              chapterProgressHidden: value,
              systemStatusBarHidden: value,
            ),
          ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.settings});

  final ThemeSettings settings;

  @override
  Widget build(BuildContext context) {
    final modeLabel = switch (settings.mode) {
      DudoThemeMode.paper => '纸色',
      DudoThemeMode.dark => '深色',
      DudoThemeMode.system => '跟随系统',
    };
    final dark = DudoColors.isDark;
    return Container(
      height: 178,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2225251F),
            offset: const Offset(0, 12),
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
              color: DudoColors.onInkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${settings.accent.label} · $modeLabel',
            style: DudoTextStyles.serif(
              color: DudoColors.onInk,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '强调色用于进度、书签和可操作按钮；模式决定纸张底色与明暗。',
            style: DudoTextStyles.sans(
              color: DudoColors.onInkMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _Swatch(DudoColors.paperBackground),
              const SizedBox(width: 8),
              _Swatch(dark
                  ? DudoColors.surfaceHigh
                  : DudoColors.secondaryContainer),
              const SizedBox(width: 8),
              _Swatch(dark
                  ? DudoColors.secondaryContainer
                  : DudoColors.primaryContainer),
              const SizedBox(width: 8),
              _Swatch(DudoColors.primary),
              const SizedBox(width: 8),
              _Swatch(dark ? DudoColors.accent : DudoColors.surfaceHigh),
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
        border: Border.all(
          color: DudoColors.isDark
              ? DudoColors.onInk.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.33),
        ),
      ),
    );
  }
}

/// Mode preview card. The fill shows the mode's own colours; the selected one
/// is marked with the app-wide check badge instead of a subtitle, so the state
/// is unmistakable next to the other two cards.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.fill,
    required this.titleColor,
    required this.subtitleColor,
    this.splitFill,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color fill;
  final Color? splitFill;
  final Color titleColor;
  final Color subtitleColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    // A full-strength paper swatch glares inside the dark theme, so dim the
    // light previews slightly while keeping their paper identity readable.
    final cardFill = dark
        ? Color.alphaBlend(DudoColors.surface.withValues(alpha: 0.22), fill)
        : fill;
    // The split card previews "system": its dark half has to stay readable as
    // a dark surface instead of vanishing into the near-black page.
    final splitHalf =
        splitFill == null ? null : (dark ? DudoColors.surfaceLow : splitFill!);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: splitHalf == null ? cardFill : null,
              gradient: splitHalf == null
                  ? null
                  : LinearGradient(
                      // Mostly light with a dark tail, so the dark-mode sliver
                      // is unmistakable while both labels stay readable.
                      colors: [cardFill, splitHalf],
                      stops: const [0.75, 0.75],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? DudoColors.primary
                    : (dark ? DudoColors.outline : DudoColors.outlineVariant),
                width: selected ? 2 : 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                  style:
                      DudoTextStyles.sans(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: DudoColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  color: DudoColors.isDark
                      ? DudoColors.paperBackground
                      : DudoColors.surfaceHigh,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Accent swatch tile. A raised, tinted paper tile rather than a flat outlined
/// pill: the swatch has its own gradient and shadow, and the selected tile
/// carries a soft accent glow plus a check badge.
class _AccentChip extends StatelessWidget {
  const _AccentChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasized,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  DudoColors.primary.withValues(alpha: dark ? 0.16 : 0.10),
                  DudoColors.surfaceLow,
                )
              : DudoColors.surfaceLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? DudoColors.primary : DudoColors.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withValues(alpha: dark ? 0.30 : 0.22)
                  : (dark ? const Color(0x33000000) : const Color(0x0F25251F)),
              offset: Offset(0, selected ? 6 : 2),
              blurRadius: selected ? 16 : 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AccentDot(color: color),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: selected
                          ? DudoColors.textPrimary
                          : DudoColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: DudoColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: dark
                        ? DudoColors.paperBackground
                        : DudoColors.surfaceHigh,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        // The ring keeps near-black swatches readable on the dark tile.
        border: Border.all(
          color: DudoColors.isDark
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.72),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.38),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}
