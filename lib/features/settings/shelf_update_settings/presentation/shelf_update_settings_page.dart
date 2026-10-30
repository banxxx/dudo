import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../bookshelf/application/bookshelf_providers.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/shelf_update_settings_provider.dart';
import '../data/shelf_update_settings_repository.dart';
import '../domain/shelf_update_settings.dart';

class ShelfUpdateSettingsPage extends ConsumerStatefulWidget {
  const ShelfUpdateSettingsPage({super.key});

  @override
  ConsumerState<ShelfUpdateSettingsPage> createState() =>
      _ShelfUpdateSettingsPageState();
}

class _ShelfUpdateSettingsPageState
    extends ConsumerState<ShelfUpdateSettingsPage> {
  ShelfUpdateSettings? _settings;
  ShelfUpdateSettingsRepository? _repository;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    ShelfUpdateSettings settings;
    try {
      final repository = ref.read(shelfUpdateSettingsRepositoryProvider);
      _repository = repository;
      settings = await repository.load();
    } catch (_) {
      settings = ShelfUpdateSettings.defaults();
    }
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  void _update(ShelfUpdateSettings next) {
    setState(() => _settings = next);
    unawaited(_repository?.save(next));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final books = ref.watch(shelfBooksProvider).valueOrNull;
    final onlineCount = books?.where(_isOnlineBook).length;

    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '内容与书源',
          title: '书架更新',
          showAction: false,
        ),
        const SizedBox(height: 14),
        if (settings == null)
          const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _UpdateHero(settings: settings, onlineBookCount: onlineCount),
          const SizedBox(height: 14),
          const SettingsSectionTitle('自动更新'),
          const SizedBox(height: 10),
          SettingsOptionRow(
            title: '自动更新书架',
            description: '定期检查在线书源的新章节',
            trailing: SettingsDudoSwitch(
              key: const ValueKey('shelf-update-auto-switch'),
              on: settings.enabled,
              onTap: () {
                _update(settings.copyWith(enabled: !settings.enabled));
              },
            ),
            height: 68,
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('更新频率'),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final frequency in ShelfUpdateFrequency.values) ...[
                Expanded(
                  child: _FrequencyCard(
                    frequency: frequency,
                    selected: settings.frequency == frequency,
                    onTap: () {
                      _update(settings.copyWith(frequency: frequency));
                    },
                  ),
                ),
                if (frequency != ShelfUpdateFrequency.values.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('更新条件'),
          const SizedBox(height: 10),
          SettingsOptionRow(
            title: '仅 Wi-Fi 更新',
            description: '移动网络下跳过自动检查',
            trailing: SettingsDudoSwitch(
              key: const ValueKey('shelf-update-wifi-switch'),
              on: settings.wifiOnly,
              onTap: () {
                _update(settings.copyWith(wifiOnly: !settings.wifiOnly));
              },
            ),
            height: 68,
          ),
          const SizedBox(height: 9),
          SettingsOptionRow(
            title: '章节更新提醒',
            description: '发现新章节时通知我',
            trailing: SettingsDudoSwitch(
              key: const ValueKey('shelf-update-alerts-switch'),
              on: settings.chapterAlerts,
              onTap: () {
                _update(
                  settings.copyWith(chapterAlerts: !settings.chapterAlerts),
                );
              },
            ),
            height: 68,
          ),
          const SizedBox(height: 12),
          Text(
            '自动更新只检查书架中带有书源信息的在线书籍，本地导入的书籍不会联网。',
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

  static bool _isOnlineBook(Book book) {
    return book.localPath == null &&
        (book.sourceId?.trim().isNotEmpty ?? false) &&
        (book.sourceBookUrl?.trim().isNotEmpty ?? false);
  }
}

class _UpdateHero extends StatelessWidget {
  const _UpdateHero({required this.settings, this.onlineBookCount});

  final ShelfUpdateSettings settings;
  final int? onlineBookCount;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final enabled = settings.enabled;
    final count = onlineBookCount;
    final onlineLabel = switch (count) {
      null => null,
      0 => '暂无在线书籍',
      _ => '$count 本在线书籍',
    };
    final subtitle = enabled
        ? [
            settings.wifiOnly ? '仅 Wi-Fi' : '任意网络',
            if (onlineLabel != null) onlineLabel,
          ].join(' · ')
        : '书架不会自动获取在线书源的新章节';

    return Container(
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
                  '更新计划',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  enabled ? settings.frequency.label : '已关闭',
                  style: DudoTextStyles.serif(
                    color: DudoColors.onInk,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 11,
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
              color: DudoColors.onInk.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              enabled ? LucideIcons.refreshCw : LucideIcons.wifiOff,
              color: enabled ? DudoColors.primary : DudoColors.onInkMuted,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({
    required this.frequency,
    required this.selected,
    required this.onTap,
  });

  final ShelfUpdateFrequency frequency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    return GestureDetector(
      key: ValueKey('shelf-update-frequency-${frequency.name}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected ? DudoColors.primaryContainer : DudoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? (dark
                    ? DudoColors.primary.withValues(alpha: 0.55)
                    : DudoColors.accentMuted)
                : DudoColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              frequency.label,
              textAlign: TextAlign.center,
              style: DudoTextStyles.sans(
                color: selected ? DudoColors.primary : DudoColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              frequency.hint,
              textAlign: TextAlign.center,
              style: DudoTextStyles.sans(
                color: selected
                    ? (dark ? DudoColors.onPrimaryContainer : DudoColors.secondary)
                    : DudoColors.secondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
