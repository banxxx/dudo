import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_skeleton.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/start_page_settings_provider.dart';
import '../domain/start_page_settings.dart';

/// Picks the tab the app opens on. Only the four shell tabs are offered, so
/// the chosen page always comes with the bottom navigation bar.
class StartPageSettingsPage extends ConsumerWidget {
  const StartPageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(startPageSettingsProvider);
    // A read error should not leave the picker spinning forever; fall back to
    // the default selection the same way the other settings pages do.
    final settings = asyncSettings.valueOrNull ??
        (asyncSettings.hasError ? StartPageSettings.defaults() : null);

    return SettingsDetailScaffold(
      header: const SettingsDetailHeader(
        eyebrow: '通用',
        title: '启动页面',
        showAction: false,
      ),
      children: [
        const SizedBox(height: 14),
        if (settings == null)
          const _StartPageSkeleton()
        else ...[
          _StartPreview(page: settings.page),
          const SizedBox(height: 14),
          const SettingsSectionTitle('选择启动页'),
          const SizedBox(height: 10),
          for (var index = 0; index < StartPage.values.length; index += 2) ...[
            Row(
              children: [
                Expanded(
                  child: _StartPageCard(
                    page: StartPage.values[index],
                    selected: settings.page == StartPage.values[index],
                    iconFill: index.isEven
                        ? DudoColors.primaryContainer
                        : DudoColors.surfaceLow,
                    onTap: () =>
                        _select(ref, settings, StartPage.values[index]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StartPageCard(
                    page: StartPage.values[index + 1],
                    selected: settings.page == StartPage.values[index + 1],
                    iconFill: index.isEven
                        ? DudoColors.surfaceLow
                        : DudoColors.primaryContainer,
                    onTap: () =>
                        _select(ref, settings, StartPage.values[index + 1]),
                  ),
                ),
              ],
            ),
            if (index + 2 < StartPage.values.length) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text(
            '启动页会在下次打开应用时生效。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  void _select(WidgetRef ref, StartPageSettings settings, StartPage page) {
    if (settings.page == page) return;
    unawaited(
      ref
          .read(startPageSettingsRepositoryProvider)
          .save(settings.copyWith(page: page)),
    );
  }
}

/// The ink card that previews the page dudo will open on.
class _StartPreview extends StatelessWidget {
  const _StartPreview({required this.page});

  final StartPage page;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return Container(
      key: const ValueKey('start-page-preview'),
      height: 132,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启动预览',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  page.label,
                  style: DudoTextStyles.serif(
                    color: DudoColors.onInk,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  page.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: DudoColors.onInk.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFor(page),
              color: dark ? DudoColors.primary : DudoColors.secondaryContainer,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPageCard extends StatelessWidget {
  const _StartPageCard({
    required this.page,
    required this.selected,
    required this.iconFill,
    required this.onTap,
  });

  final StartPage page;
  final bool selected;
  final Color iconFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final titleColor = selected
        ? (dark ? DudoColors.onPrimaryContainer : DudoColors.primaryDark)
        : DudoColors.textPrimary;
    final descriptionColor = selected
        ? (dark ? DudoColors.onPrimaryContainer : DudoColors.primary)
        : DudoColors.textSecondary;

    return GestureDetector(
      key: ValueKey('start-page-${page.name}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? DudoColors.primaryContainer : DudoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? DudoColors.primaryContainerStrong
                : DudoColors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    // The selected card is a tinted container, so the icon
                    // tile switches to a raised surface to stay visible.
                    color: selected
                        ? (dark ? DudoColors.surfaceHigh : DudoColors.surface)
                        : iconFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconFor(page),
                    color: DudoColors.secondary,
                    size: 17,
                  ),
                ),
                const Spacer(),
                _SelectionMark(selected: selected),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              page.label,
              style: DudoTextStyles.sans(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              page.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: descriptionColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? DudoColors.surface : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              selected ? DudoColors.primaryContainerStrong : DudoColors.outline,
        ),
      ),
      child: selected
          ? Icon(
              LucideIcons.check,
              size: 12,
              color: DudoColors.primaryDark,
            )
          : null,
    );
  }
}

IconData _iconFor(StartPage page) {
  return switch (page) {
    StartPage.home => LucideIcons.house,
    StartPage.bookshelf => LucideIcons.library,
    StartPage.search => LucideIcons.search,
    StartPage.profile => LucideIcons.user,
  };
}

class _StartPageSkeleton extends StatelessWidget {
  const _StartPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DudoSkeleton(
          child: DudoSkeletonBox(height: 132, radius: 26),
        ),
        const SizedBox(height: 14),
        const DudoSkeleton(
          child: DudoSkeletonLine(widthFactor: 0.3, height: 15),
        ),
        const SizedBox(height: 10),
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          const DudoSkeleton(
            child: Row(
              children: [
                Expanded(child: DudoSkeletonBox(height: 112, radius: 20)),
                SizedBox(width: 10),
                Expanded(child: DudoSkeletonBox(height: 112, radius: 20)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
