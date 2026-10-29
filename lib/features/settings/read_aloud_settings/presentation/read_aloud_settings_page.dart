import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/tts/tts_models.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../application/read_aloud_player.dart';
import '../application/read_aloud_settings_provider.dart';
import '../data/read_aloud_settings_repository.dart';
import '../domain/read_aloud_settings.dart';

const _previewText = '宇宙像一片沉默的海，声音从纸页深处慢慢浮起。';

class ReadAloudSettingsPage extends ConsumerStatefulWidget {
  const ReadAloudSettingsPage({super.key});

  @override
  ConsumerState<ReadAloudSettingsPage> createState() =>
      _ReadAloudSettingsPageState();
}

class _ReadAloudSettingsPageState extends ConsumerState<ReadAloudSettingsPage> {
  ReadAloudSettings? _settings;
  List<TtsVoice> _voices = const [];
  bool _loadingVoices = true;
  bool _previewing = false;
  Timer? _saveTimer;
  bool _dirty = false;
  ReadAloudSettingsRepository? _repository;
  ReadAloudPlayer? _player;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _flushSave();
    final player = _player;
    player?.bind();
    if (_previewing) unawaited(player?.stop());
    super.dispose();
  }

  Future<void> _load() async {
    ReadAloudSettings settings;
    try {
      final repository = ref.read(readAloudSettingsRepositoryProvider);
      _repository = repository;
      settings = await repository.load();
    } catch (_) {
      settings = ReadAloudSettings.defaults();
    }
    if (!mounted) return;
    final player = ref.read(readAloudPlayerProvider);
    _player = player;
    setState(() => _settings = settings);
    unawaited(player.apply(settings));
    await _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final player =
          _player ?? ref.read<ReadAloudPlayer>(readAloudPlayerProvider);
      final voices = await player.voices();
      if (!mounted) return;
      setState(() {
        _voices = voices.where((voice) => voice.isChinese).toList();
        if (_voices.isEmpty) _voices = voices;
        _loadingVoices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVoices = false);
    }
  }

  void _update(ReadAloudSettings next) {
    setState(() => _settings = next);
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _flushSave);
  }

  void _flushSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final settings = _settings;
    final repository = _repository;
    if (!_dirty || settings == null || repository == null) return;
    _dirty = false;
    unawaited(repository.save(settings));
  }

  Future<void> _togglePreview() async {
    final settings = _settings;
    if (settings == null) return;
    final player = ref.read(readAloudPlayerProvider);
    if (_previewing) {
      setState(() => _previewing = false);
      await player.stop();
      return;
    }
    setState(() => _previewing = true);
    player.bind(
      onCompleted: () {
        if (mounted) setState(() => _previewing = false);
      },
    );
    await player.apply(settings);
    await player.play(const [_previewText]);
  }

  void _cycleTimerMinutes() {
    final settings = _settings;
    if (settings == null) return;
    const options = [15, 30, 60];
    final index = options.indexOf(settings.timerMinutes);
    final next = options[(index + 1) % options.length];
    _update(settings.copyWith(timerMinutes: next));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '阅读朗读',
          actionIcon: LucideIcons.headphones,
        ),
        const SizedBox(height: 14),
        if (settings == null)
          const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _VoicePreviewPlayer(
            playing: _previewing,
            rateLabel: _rateLabel(settings.speechRate),
            onToggle: _togglePreview,
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('声音'),
          const SizedBox(height: 8),
          _VoiceGrid(
            voices: _voices,
            loading: _loadingVoices,
            selectedName: settings.voiceName,
            onSelect: (voice) {
              _update(
                voice == null
                    ? settings.copyWith(clearVoiceName: true)
                    : settings.copyWith(
                        voiceName: voice.name,
                        voiceLocale: voice.locale,
                      ),
              );
            },
          ),
          if (!_loadingVoices && _voices.isEmpty) ...[
            const SizedBox(height: 8),
            const SettingsTrailingValue(
              '当前设备没有可用的系统语音，请先在系统设置的“文字转语音”中安装中文语音数据。',
              color: DudoColors.secondary,
            ),
          ],
          const SizedBox(height: 14),
          SettingsMeterControl(
            label: '语速',
            value: _rateLabel(settings.speechRate),
            color: DudoColors.primary,
            fraction: (settings.speechRate - 0.5) / 1.5,
            minValue: 0.5,
            maxValue: 2.0,
            onChanged: (value) {
              _update(settings.copyWith(speechRate: _roundToStep(value, 0.1)));
            },
          ),
          const SizedBox(height: 8),
          SettingsMeterControl(
            label: '音调',
            value: _pitchLabel(settings.pitch),
            color: DudoColors.accent,
            fraction: (settings.pitch - 0.5) / 1.5,
            minValue: 0.5,
            maxValue: 2.0,
            onChanged: (value) {
              _update(settings.copyWith(pitch: _roundToStep(value, 0.1)));
            },
          ),
          const SizedBox(height: 8),
          SettingsMeterControl(
            label: '音量',
            value: '${(settings.volume * 100).round()}%',
            color: DudoColors.secondary,
            fraction: settings.volume,
            onChanged: (value) {
              _update(settings.copyWith(volume: _roundToStep(value, 0.05)));
            },
          ),
          const SizedBox(height: 14),
          SettingsOptionRow(
            title: '定时停止',
            description: '开始朗读后按设定时间自动停止',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimeChip(
                  minutes: settings.timerMinutes,
                  onTap: _cycleTimerMinutes,
                ),
                const SizedBox(width: 12),
                SettingsDudoSwitch(
                  on: settings.timerEnabled,
                  onTap: () {
                    _update(
                      settings.copyWith(timerEnabled: !settings.timerEnabled),
                    );
                  },
                ),
              ],
            ),
            height: 52,
          ),
          const SizedBox(height: 7),
          SettingsOptionRow(
            title: '后台朗读',
            description: '锁屏或切到后台后继续播放',
            trailing: SettingsDudoSwitch(
              on: settings.backgroundEnabled,
              onTap: () {
                _update(
                  settings.copyWith(
                    backgroundEnabled: !settings.backgroundEnabled,
                  ),
                );
              },
            ),
            height: 52,
          ),
          const SizedBox(height: 7),
          SettingsOptionRow(
            title: '段落跟读',
            description: '朗读时页面自动跟随当前段落',
            trailing: SettingsDudoSwitch(
              on: settings.paragraphFollowEnabled,
              onTap: () {
                _update(
                  settings.copyWith(
                    paragraphFollowEnabled: !settings.paragraphFollowEnabled,
                  ),
                );
              },
            ),
            height: 52,
          ),
        ],
      ],
    );
  }

  static String _rateLabel(double rate) => '${rate.toStringAsFixed(1)}x';

  static String _pitchLabel(double pitch) {
    if ((pitch - 1.0).abs() < 0.001) return '标准';
    return pitch.toStringAsFixed(1);
  }

  static double _roundToStep(double value, double step) {
    return (value / step).round() * step;
  }
}

class _VoiceGrid extends StatelessWidget {
  const _VoiceGrid({
    required this.voices,
    required this.loading,
    required this.selectedName,
    required this.onSelect,
  });

  final List<TtsVoice> voices;
  final bool loading;
  final String? selectedName;
  final ValueChanged<TtsVoice?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 86,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final options = <TtsVoice?>[null, ...voices.take(8)];
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final voice = options[index];
          final selected = voice?.name == selectedName;
          return SizedBox(
            width: 116,
            child: _VoiceChoice(
              label: voice?.displayName ?? '系统默认',
              state: voice?.locale ?? '跟随系统',
              iconColor:
                  selected ? DudoColors.primary : DudoColors.secondary,
              selected: selected,
              onTap: () => onSelect(voice),
            ),
          );
        },
      ),
    );
  }
}

class _VoicePreviewPlayer extends StatelessWidget {
  const _VoicePreviewPlayer({
    required this.playing,
    required this.rateLabel,
    required this.onToggle,
  });

  final bool playing;
  final String rateLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '试听朗读',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                rateLabel,
                style: DudoTextStyles.numeric(
                  color: DudoColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _previewText,
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                key: const ValueKey('read-aloud-preview-button'),
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DudoColors.textPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    playing ? LucideIcons.square : LucideIcons.play,
                    color: DudoColors.surfaceHigh,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: DudoColors.surface.withValues(alpha: 0.67),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: playing ? 1 : 0.02,
                      child: Container(color: DudoColors.primary),
                    ),
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

class _VoiceChoice extends StatelessWidget {
  const _VoiceChoice({
    required this.label,
    required this.state,
    required this.iconColor,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String state;
  final Color iconColor;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? DudoColors.secondary : DudoColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.volume2, color: iconColor, size: 18),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: DudoColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              state,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  DudoTextStyles.sans(color: DudoColors.secondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.minutes, required this.onTap});

  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: DudoColors.surfaceLow,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$minutes 分钟',
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFFB8A88E),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
