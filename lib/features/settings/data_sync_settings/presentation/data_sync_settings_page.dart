import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../bookmarks/application/bookmarks_providers.dart';
import '../../../bookmarks/domain/bookmark_entry.dart';
import '../../../bookshelf/application/bookshelf_providers.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/data_sync_controller.dart';
import '../application/data_sync_settings_provider.dart';
import '../domain/data_sync_settings.dart';

/// Configures a self-hosted Dudo Sync server, the data scopes and the
/// foreground auto-sync schedule. Connection credentials stay on this device
/// and are never part of a snapshot.
class DataSyncSettingsPage extends ConsumerStatefulWidget {
  const DataSyncSettingsPage({super.key});

  @override
  ConsumerState<DataSyncSettingsPage> createState() =>
      _DataSyncSettingsPageState();
}

class _DataSyncSettingsPageState extends ConsumerState<DataSyncSettingsPage> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _fieldsReady = false;
  bool _obscureToken = true;
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataSyncControllerProvider);
    final books = ref.watch(shelfBooksProvider).valueOrNull;
    final entries = ref.watch(bookmarkEntriesProvider).valueOrNull;

    if (state.initialized && !_fieldsReady) {
      _fieldsReady = true;
      _urlController.text = state.settings.serverUrl ?? '';
      _tokenController.text = state.settings.accessToken ?? '';
    }

    final bookmarkCount = entries
            ?.where((entry) => entry.type == BookmarkEntryType.bookmark)
            .length ??
        0;
    final annotationCount = entries
            ?.where((entry) => entry.type != BookmarkEntryType.bookmark)
            .length ??
        0;

    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '通用',
          title: '数据同步',
          subtitle: '连接你的后端服务器，掌控自己的阅读数据',
          showAction: false,
        ),
        const SizedBox(height: 14),
        if (!state.initialized)
          const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _SyncHero(
            connected: state.settings.isConfigured,
            host: _hostOf(state.settings.serverUrl),
            bookCount: books?.length ?? 0,
            bookmarkCount: bookmarkCount,
            annotationCount: annotationCount,
          ),
          const SizedBox(height: 14),
          _ServerConfigCard(
            urlController: _urlController,
            tokenController: _tokenController,
            obscureToken: _obscureToken,
            onToggleToken: () {
              setState(() => _obscureToken = !_obscureToken);
            },
            onTest: _testConnection,
            onSave: _saveConnection,
            testing: state.phase == DataSyncPhase.testing,
            testOk: state.testOk,
            testMessage: state.testMessage,
            urlError: _urlError,
            onUrlChanged: () {
              if (_urlError != null) setState(() => _urlError = null);
            },
          ),
          const SizedBox(height: 14),
          _ScopeCard(
            progress: state.settings.progress,
            annotations: state.settings.annotations,
            settings: state.settings.settings,
            onProgress: (value) {
              ref.read(dataSyncControllerProvider.notifier).setProgress(value);
            },
            onAnnotations: (value) {
              ref
                  .read(dataSyncControllerProvider.notifier)
                  .setAnnotations(value);
            },
            onSettings: (value) {
              ref
                  .read(dataSyncControllerProvider.notifier)
                  .setSettingsScope(value);
            },
          ),
          const SizedBox(height: 14),
          _AutoSyncCard(
            enabled: state.settings.enabled,
            configured: state.settings.isConfigured,
            lastSyncedAt: state.settings.lastSyncedAt,
            onChanged: (value) {
              ref.read(dataSyncControllerProvider.notifier).setEnabled(value);
            },
          ),
          const SizedBox(height: 14),
          _ManualSyncCard(
            configured: state.settings.isConfigured,
            hasScope: state.settings.hasScope,
            phase: state.phase,
            syncOk: state.syncOk,
            syncMessage: state.syncMessage,
            onSync: () => _syncNow(state.settings),
          ),
        ],
      ],
    );
  }

  Future<void> _saveConnection() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      final error = dataSyncUrlError(url);
      if (error != null) {
        setState(() => _urlError = error);
        return;
      }
    }
    setState(() => _urlError = null);
    await ref.read(dataSyncControllerProvider.notifier).saveConnection(
          serverUrl: _urlController.text,
          accessToken: _tokenController.text,
        );
  }

  Future<void> _testConnection() async {
    final error = dataSyncUrlError(_urlController.text);
    if (error != null) {
      setState(() => _urlError = error);
      return;
    }
    setState(() => _urlError = null);
    await ref.read(dataSyncControllerProvider.notifier).testConnection(
          serverUrl: _urlController.text,
          accessToken: _tokenController.text,
        );
  }

  Future<void> _syncNow(DataSyncSettings settings) async {
    if (!settings.isConfigured) return;
    final controller = ref.read(dataSyncControllerProvider.notifier);
    final dirty = _urlController.text.trim() != (settings.serverUrl ?? '') ||
        _tokenController.text.trim() != (settings.accessToken ?? '');
    if (dirty) {
      final error = dataSyncUrlError(_urlController.text);
      if (error != null) {
        setState(() => _urlError = error);
        return;
      }
      setState(() => _urlError = null);
      // The manual sync below schedules the auto-sync timer itself; skipping
      // the reschedule here avoids an immediate auto sync racing the tap.
      await controller.saveConnection(
        serverUrl: _urlController.text,
        accessToken: _tokenController.text,
        reschedule: false,
      );
    }
    await controller.syncNow();
  }

  static String? _hostOf(String? serverUrl) {
    if (serverUrl == null) return null;
    final uri = Uri.tryParse(serverUrl);
    return uri?.host.isNotEmpty == true ? uri!.host : serverUrl;
  }
}

class _SyncHero extends StatelessWidget {
  const _SyncHero({
    required this.connected,
    required this.host,
    required this.bookCount,
    required this.bookmarkCount,
    required this.annotationCount,
  });

  final bool connected;
  final String? host;
  final int bookCount;
  final int bookmarkCount;
  final int annotationCount;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final description = connected
        ? '数据会同步到 ${host ?? '你的服务器'}，Dudo 不保存副本。'
        : '配置 HTTPS 地址与访问令牌后，可将书架、阅读进度、书签和标注同步到你的后端。';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.ink,
        borderRadius: BorderRadius.circular(26),
        border: dark ? Border.all(color: DudoColors.outline) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x2625251F),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: DudoColors.onInk.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Icon(
                  connected ? LucideIcons.cloudCheck : LucideIcons.serverCog,
                  color: DudoColors.onInk,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            connected ? '已连接服务器' : '尚未连接服务器',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.onInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HeroPill(
                          text: connected ? '云端同步' : '本地模式',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInkMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PreviewStat(value: '$bookCount', label: '书架'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreviewStat(value: '$bookmarkCount', label: '书签'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreviewStat(
                  value: '$annotationCount',
                  label: '标注',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DudoColors.onInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DudoColors.onInk.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: DudoTextStyles.sans(
          color: DudoColors.isDark
              ? DudoColors.primaryDark
              : DudoColors.primaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: DudoColors.onInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: DudoTextStyles.numeric(
              color: DudoColors.onInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: DudoTextStyles.sans(
              color: DudoColors.onInkMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerConfigCard extends StatelessWidget {
  const _ServerConfigCard({
    required this.urlController,
    required this.tokenController,
    required this.obscureToken,
    required this.onToggleToken,
    required this.onTest,
    required this.onSave,
    required this.testing,
    required this.testOk,
    required this.testMessage,
    required this.urlError,
    required this.onUrlChanged,
  });

  final TextEditingController urlController;
  final TextEditingController tokenController;
  final bool obscureToken;
  final VoidCallback onToggleToken;
  final VoidCallback onTest;
  final VoidCallback onSave;
  final bool testing;
  final bool? testOk;
  final String? testMessage;
  final String? urlError;
  final VoidCallback onUrlChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '后端服务器',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '支持自建 Dudo Sync API',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const _HttpsBadge(),
            ],
          ),
          const SizedBox(height: 13),
          _ServerField(
            label: '服务器地址',
            fieldKey: const ValueKey('data-sync-server-url'),
            controller: urlController,
            hint: 'https://sync.example.com',
            icon: LucideIcons.globe,
            keyboardType: TextInputType.url,
            onChanged: (_) => onUrlChanged(),
          ),
          if (urlError != null) ...[
            const SizedBox(height: 6),
            Text(
              urlError!,
              style: DudoTextStyles.sans(
                color: DudoColors.accent,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 13),
          _ServerField(
            label: '访问令牌',
            fieldKey: const ValueKey('data-sync-access-token'),
            controller: tokenController,
            hint: '粘贴访问令牌（可选）',
            icon: LucideIcons.keyRound,
            obscure: obscureToken,
            suffix: IconButton(
              onPressed: onToggleToken,
              icon: Icon(
                obscureToken ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
                color: DudoColors.secondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 40,
                height: 40,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _ConfigButton(
                  key: const ValueKey('data-sync-test'),
                  icon: LucideIcons.plugZap,
                  label: testing ? '测试中…' : '测试连接',
                  fill: DudoColors.surfaceLow,
                  foreground: DudoColors.secondary,
                  onTap: testing ? null : onTest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ConfigButton(
                  key: const ValueKey('data-sync-save'),
                  icon: LucideIcons.shieldCheck,
                  label: '保存',
                  fill: DudoColors.isDark ? DudoColors.onInk : DudoColors.ink,
                  foreground:
                      DudoColors.isDark ? DudoColors.ink : DudoColors.onInk,
                  onTap: onSave,
                ),
              ),
            ],
          ),
          if (testMessage != null) ...[
            const SizedBox(height: 10),
            _StatusLine(
              message: testMessage!,
              ok: testOk,
            ),
          ],
        ],
      ),
    );
  }
}

class _HttpsBadge extends StatelessWidget {
  const _HttpsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.lockKeyhole,
            size: 13,
            color: DudoColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            'HTTPS',
            style: DudoTextStyles.sans(
              color: DudoColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerField extends StatelessWidget {
  const _ServerField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DudoTextStyles.sans(
            color: DudoColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 52,
          child: TextField(
            key: fieldKey,
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onChanged: onChanged,
            autocorrect: false,
            enableSuggestions: false,
            textAlignVertical: TextAlignVertical.center,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: DudoColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              prefixIcon: Icon(
                icon,
                size: 17,
                color: DudoColors.secondary,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 17,
              ),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: DudoColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: DudoColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigButton extends StatelessWidget {
  const _ConfigButton({
    super.key,
    required this.icon,
    required this.label,
    required this.fill,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 7),
          Text(
            label,
            style: DudoTextStyles.sans(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final tap = onTap;
    if (tap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(23),
        child: content,
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.message, required this.ok});

  final String message;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final color = switch (ok) {
      true => DudoColors.primary,
      false => DudoColors.accent,
      null => DudoColors.secondary,
    };
    final icon = switch (ok) {
      true => LucideIcons.circleCheck,
      false => LucideIcons.triangleAlert,
      null => LucideIcons.info,
    };
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.progress,
    required this.annotations,
    required this.settings,
    required this.onProgress,
    required this.onAnnotations,
    required this.onSettings,
  });

  final bool progress;
  final bool annotations;
  final bool settings;
  final ValueChanged<bool> onProgress;
  final ValueChanged<bool> onAnnotations;
  final ValueChanged<bool> onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '同步内容',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _ScopeRow(
            icon: LucideIcons.library,
            iconFill: DudoColors.primaryContainer,
            iconColor: DudoColors.primary,
            title: '书架与阅读进度',
            description: '书籍、当前章节、阅读位置',
            switchKey: const ValueKey('data-sync-progress-switch'),
            on: progress,
            onChanged: onProgress,
          ),
          _ScopeRow(
            icon: LucideIcons.bookmark,
            iconFill: DudoColors.primaryContainer,
            iconColor: DudoColors.primary,
            title: '书签与标注',
            description: '收藏段落、笔记摘录',
            switchKey: const ValueKey('data-sync-annotations-switch'),
            on: annotations,
            onChanged: onAnnotations,
          ),
          _ScopeRow(
            icon: LucideIcons.settings,
            iconFill: DudoColors.surfaceLow,
            iconColor: DudoColors.secondary,
            title: '阅读设置',
            description: '主题、字体、翻页偏好',
            switchKey: const ValueKey('data-sync-settings-switch'),
            on: settings,
            onChanged: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.icon,
    required this.iconFill,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.switchKey,
    required this.on,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconFill;
  final Color iconColor;
  final String title;
  final String description;
  final Key switchKey;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
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
          const SizedBox(width: 8),
          SettingsDudoSwitch(
            key: switchKey,
            on: on,
            onTap: () => onChanged(!on),
          ),
        ],
      ),
    );
  }
}

class _AutoSyncCard extends StatelessWidget {
  const _AutoSyncCard({
    required this.enabled,
    required this.configured,
    required this.lastSyncedAt,
    required this.onChanged,
  });

  final bool enabled;
  final bool configured;
  final DateTime? lastSyncedAt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final description = !configured
        ? '保存服务器配置后生效'
        : enabled
            ? '应用运行期间每 30 分钟自动同步一次'
            : '自动同步已关闭';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动同步',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: DudoTextStyles.sans(
                        color: dark
                            ? DudoColors.onInkMuted
                            : DudoColors.secondaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SettingsDudoSwitch(
                key: const ValueKey('data-sync-auto-switch'),
                on: enabled,
                onTap: () => onChanged(!enabled),
                activeFill: DudoColors.primary,
                activeThumb: dark ? DudoColors.ink : DudoColors.onInk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.clock3,
                size: 15,
                color: DudoColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                _lastSyncLabel(lastSyncedAt),
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _lastSyncLabel(DateTime? last) {
    if (last == null) return '上次同步：尚未同步';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(last.year, last.month, last.day);
    final difference = today.difference(day).inDays;
    final time = '${last.hour.toString().padLeft(2, '0')}:'
        '${last.minute.toString().padLeft(2, '0')}';
    if (difference == 0) return '上次同步：今天 $time';
    if (difference == 1) return '上次同步：昨天 $time';
    return '上次同步：${last.month}月${last.day}日 $time';
  }
}

class _ManualSyncCard extends StatelessWidget {
  const _ManualSyncCard({
    required this.configured,
    required this.hasScope,
    required this.phase,
    required this.syncOk,
    required this.syncMessage,
    required this.onSync,
  });

  final bool configured;
  final bool hasScope;
  final DataSyncPhase phase;
  final bool? syncOk;
  final String? syncMessage;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final syncing = phase == DataSyncPhase.syncing;
    final ready = configured && hasScope && !syncing;
    final label = !configured
        ? '先保存服务器配置'
        : !hasScope
            ? '请至少选择一项同步内容'
            : syncing
                ? '同步中…'
                : '立即同步到服务器';
    final readyForeground = dark ? DudoColors.ink : DudoColors.onInk;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              dark ? DudoColors.outline : Colors.white.withValues(alpha: 0.68),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            width: double.infinity,
            child: Material(
              color: ready ? DudoColors.primary : DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                key: const ValueKey('data-sync-sync-now'),
                onTap: ready ? onSync : null,
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      syncing
                          ? LucideIcons.loaderCircle
                          : LucideIcons.cloudUpload,
                      size: 17,
                      color: ready ? readyForeground : DudoColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: DudoTextStyles.sans(
                        color: ready ? readyForeground : DudoColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (syncMessage != null) ...[
            const SizedBox(height: 9),
            _StatusLine(message: syncMessage!, ok: syncOk),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                LucideIcons.shield,
                size: 14,
                color: DudoColors.secondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '数据仅上传到你填写的服务器，Dudo 不保存副本。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
