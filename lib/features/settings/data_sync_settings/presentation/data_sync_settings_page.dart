import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../bookmarks/application/bookmarks_providers.dart';
import '../../../bookmarks/domain/bookmark_entry.dart';
import '../../../bookshelf/application/bookshelf_providers.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/data_sync_settings_provider.dart';
import '../data/data_sync_settings_repository.dart';
import '../domain/data_sync_settings.dart';

class DataSyncSettingsPage extends ConsumerStatefulWidget {
  const DataSyncSettingsPage({super.key});

  @override
  ConsumerState<DataSyncSettingsPage> createState() =>
      _DataSyncSettingsPageState();
}

class _DataSyncSettingsPageState extends ConsumerState<DataSyncSettingsPage> {
  DataSyncSettings? _settings;
  DataSyncSettingsRepository? _repository;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    DataSyncSettings settings;
    try {
      final repository = ref.read(dataSyncSettingsRepositoryProvider);
      _repository = repository;
      settings = await repository.load();
    } catch (_) {
      settings = DataSyncSettings.defaults();
    }
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  void _update(DataSyncSettings next) {
    setState(() => _settings = next);
    unawaited(_repository?.save(next));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final books = ref.watch(shelfBooksProvider).valueOrNull;
    final entries = ref.watch(bookmarkEntriesProvider).valueOrNull;

    final progressCount = books
        ?.where((book) =>
            book.lastChapterIndex > 0 || book.lastReadPosition > 0)
        .length;
    final bookmarkCount = entries
        ?.where((entry) => entry.type != BookmarkEntryType.highlight)
        .length;
    final highlightCount = entries
        ?.where((entry) => entry.type == BookmarkEntryType.highlight)
        .length;

    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '通用',
          title: '数据同步',
          showAction: false,
        ),
        const SizedBox(height: 14),
        if (settings == null)
          const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _CloudHero(enabled: settings.enabled),
          const SizedBox(height: 14),
          const SettingsSectionTitle('自动同步'),
          const SizedBox(height: 10),
          SettingsOptionRow(
            title: '启用同步',
            description: '连接云端后自动上传与下载',
            trailing: SettingsDudoSwitch(
              key: const ValueKey('data-sync-master-switch'),
              on: settings.enabled,
              onTap: () {
                _update(settings.copyWith(enabled: !settings.enabled));
              },
            ),
            height: 68,
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('同步范围'),
          const SizedBox(height: 10),
          _ScopeRow(
            title: '阅读进度',
            description: _countText(progressCount, '本有阅读进度'),
            on: settings.progress,
            enabled: settings.enabled,
            switchKey: const ValueKey('data-sync-progress-switch'),
            onTap: () {
              _update(settings.copyWith(progress: !settings.progress));
            },
          ),
          const SizedBox(height: 9),
          _ScopeRow(
            title: '书签与笔记',
            description: _countText(bookmarkCount, '条'),
            on: settings.bookmarks,
            enabled: settings.enabled,
            switchKey: const ValueKey('data-sync-bookmarks-switch'),
            onTap: () {
              _update(settings.copyWith(bookmarks: !settings.bookmarks));
            },
          ),
          const SizedBox(height: 9),
          _ScopeRow(
            title: '高亮',
            description: _countText(highlightCount, '处'),
            on: settings.highlights,
            enabled: settings.enabled,
            switchKey: const ValueKey('data-sync-highlights-switch'),
            onTap: () {
              _update(settings.copyWith(highlights: !settings.highlights));
            },
          ),
          const SizedBox(height: 9),
          _ScopeRow(
            title: '设置',
            description: '主题、字体与朗读偏好',
            on: settings.settings,
            enabled: settings.enabled,
            switchKey: const ValueKey('data-sync-settings-switch'),
            onTap: () {
              _update(settings.copyWith(settings: !settings.settings));
            },
          ),
          const SizedBox(height: 12),
          Text(
            '同步范围只决定连接云端后会上传的数据；本地阅读数据始终保存在本机。',
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

  /// `null` means the count is still loading; `0` shows "暂无…".
  static String _countText(int? count, String suffix) {
    if (count == null) return '计算中…';
    if (count == 0) return '暂无数据';
    return '$count $suffix';
  }
}

class _CloudHero extends StatelessWidget {
  const _CloudHero({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final subtitle = enabled
        ? '尚未连接云端账号，同步设置会先保存在本机。'
        : '同步已关闭，开启后才会在连接云端时同步。';

    return Container(
      height: 120,
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
                  '云端状态',
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '未连接云端',
                  style: DudoTextStyles.serif(
                    color: DudoColors.onInk,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.onInkMuted,
                    fontSize: 11,
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
              color: DudoColors.onInk.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.cloudOff,
              color: DudoColors.onInkMuted,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.title,
    required this.description,
    required this.on,
    required this.enabled,
    required this.switchKey,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool on;
  final bool enabled;
  final Key switchKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SettingsOptionRow(
        title: title,
        description: description,
        trailing: SettingsDudoSwitch(
          key: switchKey,
          on: on,
          onTap: enabled ? onTap : null,
        ),
        height: 68,
      ),
    );
  }
}
