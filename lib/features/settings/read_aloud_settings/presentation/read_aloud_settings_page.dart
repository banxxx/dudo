import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/tts/system_tts_settings.dart';
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

class _ReadAloudSettingsPageState extends ConsumerState<ReadAloudSettingsPage>
    with WidgetsBindingObserver {
  ReadAloudSettings? _settings;
  List<TtsVoice> _voices = const [];
  bool _loadingVoices = true;
  bool _voicesRequestInFlight = false;
  bool _voiceListExpanded = false;
  bool _previewing = false;
  double? _previewProgress;
  String? _previewError;
  bool _testing = false;
  String? _testMessage;
  bool? _testOk;
  Timer? _saveTimer;
  bool _dirty = false;
  ReadAloudSettingsRepository? _repository;
  ReadAloudPlayer? _player;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _onlineVoiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  /// Returning from the system voice-data screen usually means new voices were
  /// installed, so the list is refreshed instead of waiting for a page reopen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_current?.engine != ReadAloudEngine.system) return;
    unawaited(_loadVoices());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushSave();
    final player = _player;
    player?.bind();
    if (_previewing) unawaited(player?.stop());
    _urlController.dispose();
    _tokenController.dispose();
    _onlineVoiceController.dispose();
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
    _urlController.text = settings.onlineUrl ?? '';
    _tokenController.text = settings.onlineToken ?? '';
    _onlineVoiceController.text = settings.onlineVoice ?? '';
    setState(() => _settings = settings);
    unawaited(player.apply(settings));
    // The online engine has no device voices; asking it would just retry three
    // times against an empty answer.
    if (settings.engine == ReadAloudEngine.system) await _loadVoices();
  }

  ReadAloudSettings? get _current => _settings;

  void _updateField(
    ReadAloudSettings Function(ReadAloudSettings settings) change,
  ) {
    final settings = _current;
    if (settings == null) return;
    _update(change(settings));
  }

  /// The platform TTS engine often answers with an empty list right after the
  /// page opens (it is still connecting); retrying a few times avoids the page
  /// getting stuck with only the "system default" option.
  Future<void> _loadVoices() async {
    if (_voicesRequestInFlight) return;
    _voicesRequestInFlight = true;
    try {
      if (!_loadingVoices) setState(() => _loadingVoices = true);
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final voices = await _playerRef.voices();
          if (!mounted) return;
          if (voices.isNotEmpty) {
            final chinese = voices.where((voice) => voice.isChinese).toList();
            final shown = chinese.isEmpty ? voices.toList() : chinese;
            // A voice picked earlier may be filtered out (non-Chinese) or
            // missing from the device list; keep it visible so the page never
            // looks like nothing is selected.
            final selectedName = _current?.voiceName;
            if (selectedName != null &&
                shown.every((voice) => voice.name != selectedName)) {
              for (final voice in voices) {
                if (voice.name == selectedName) {
                  shown.add(voice);
                  break;
                }
              }
            }
            setState(() => _voices = shown);
            return;
          }
        } catch (_) {
          // Engine not ready yet; fall through to the retry delay.
        }
        if (!mounted) return;
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    } finally {
      _voicesRequestInFlight = false;
      if (mounted) setState(() => _loadingVoices = false);
    }
  }

  void _update(ReadAloudSettings next) {
    // A preview keeps speaking with the parameters it started with; leaving it
    // running while the page shows different values is misleading.
    final previous = _settings;
    final wasPreviewing = _previewing;
    final interfaceChanged = previous == null ||
        next.onlineUrl != previous.onlineUrl ||
        next.onlineToken != previous.onlineToken ||
        next.onlineVoice != previous.onlineVoice ||
        next.onlineFormat != previous.onlineFormat;
    setState(() {
      _settings = next;
      _previewing = false;
      _previewProgress = null;
      _previewError = null;
      // A connection result only describes the interface it was run against.
      if (interfaceChanged) {
        _testMessage = null;
        _testOk = null;
      }
    });
    if (wasPreviewing) unawaited(_playerRef.stop());
    if (next.engine == ReadAloudEngine.system && _voices.isEmpty) {
      unawaited(_loadVoices());
    }
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

  ReadAloudPlayer get _playerRef =>
      _player ?? ref.read<ReadAloudPlayer>(readAloudPlayerProvider);

  bool _canPreview(ReadAloudSettings settings) =>
      settings.engine == ReadAloudEngine.system ||
      onlineUrlError(settings.onlineUrl) == null;

  /// Explains why the preview is unavailable (or what went wrong) instead of
  /// letting the button flash a false "playing" state.
  String? get _previewMessage {
    final error = _previewError;
    if (error != null) return error;
    final settings = _settings;
    if (settings == null || settings.engine == ReadAloudEngine.system) {
      return null;
    }
    final urlError = onlineUrlError(settings.onlineUrl);
    if (urlError == null) return null;
    return (settings.onlineUrl ?? '').trim().isEmpty
        ? '填写在线接口地址后可试听'
        : urlError;
  }

  /// The user facing sentence for a failed request; known failures already
  /// carry a specific explanation from the transport.
  static String _failureText(Object error) =>
      error is AppException ? error.message : '请检查接口地址、访问令牌与网络';

  Future<void> _runConnectionTest() async {
    final settings = _settings;
    if (settings == null || _testing) return;
    final urlError = onlineUrlError(settings.onlineUrl);
    if (urlError != null) {
      setState(() {
        _testOk = false;
        _testMessage = urlError;
      });
      return;
    }
    if (_previewing) await _stopPreview();
    setState(() {
      _testing = true;
      _testMessage = null;
      _testOk = null;
    });
    try {
      await _playerRef.testOnlineConnection(settings);
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testOk = true;
        _testMessage = '连接成功，接口返回了音频';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testOk = false;
        _testMessage = '连接失败：${_failureText(error)}';
      });
    }
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _stopPreview();
      return;
    }
    final settings = _settings;
    if (settings == null) return;
    if (!_canPreview(settings)) {
      setState(() => _previewError = null);
      return;
    }
    await _startPreview();
  }

  Future<void> _stopPreview() async {
    if (!_previewing) return;
    setState(() {
      _previewing = false;
      _previewProgress = null;
    });
    await _playerRef.stop();
  }

  Future<void> _startPreview() async {
    final settings = _settings;
    if (settings == null || !_canPreview(settings)) return;
    final player = _playerRef;
    setState(() {
      _previewing = true;
      _previewProgress = null;
      _previewError = null;
    });
    player.bind(
      onCompleted: () {
        if (!mounted) return;
        setState(() {
          _previewing = false;
          _previewProgress = null;
        });
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() {
          _previewing = false;
          _previewProgress = null;
          _previewError = '试听失败：${_failureText(error)}';
        });
      },
      onProgress: (progress) {
        if (!mounted || !_previewing) return;
        setState(() => _previewProgress = progress);
      },
    );
    await player.apply(settings);
    await player.play(const [_previewText]);
  }

  /// Picking a voice only saves the choice: browsing the list stays silent and
  /// the sample plays when the user taps 试听.
  void _selectVoice(TtsVoice? voice) {
    final settings = _current;
    if (settings == null) return;
    _update(
      voice == null
          ? settings.copyWith(clearVoiceName: true)
          : settings.copyWith(voiceName: voice.name, voiceLocale: voice.locale),
    );
  }

  TtsVoice? _selectedVoice(String? name) {
    if (name == null) return null;
    for (final voice in _voices) {
      if (voice.name == name) return voice;
    }
    return null;
  }

  String get _previewTitle {
    final settings = _settings;
    if (settings == null) return '系统默认';
    if (settings.engine == ReadAloudEngine.online) return '在线音色';
    final voice = _selectedVoice(settings.voiceName);
    if (voice != null) return voice.displayName;
    if (settings.voiceName == null) return '系统默认';
    return settings.voiceLocale ?? '系统语音';
  }

  String get _previewSource {
    final settings = _settings;
    if (settings == null) return '系统语音 · 跟随系统设置';
    if (settings.engine == ReadAloudEngine.online) return '接口实时合成 · 需联网';
    final voice = _selectedVoice(settings.voiceName);
    if (voice != null) return voice.voiceMeta;
    if (settings.voiceName == null) return '系统语音 · 跟随系统设置';
    return '系统语音 · ${settings.voiceLocale ?? '跟随系统设置'}';
  }

  Future<void> _openSystemTtsSettings() async {
    final opened = await ref.read(systemTtsSettingsProvider).open();
    if (!mounted) return;
    if (opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('无法打开系统语音设置，请手动前往系统设置 → 语音合成'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final isOnline = settings?.engine == ReadAloudEngine.online;
    final rateAdjustable = settings == null ||
        settings.engine != ReadAloudEngine.online ||
        settings.onlineFormat == OnlineTtsFormat.json;
    final subtitle = isOnline
        ? '接入返回音频的在线接口'
        : _voiceListExpanded
            ? '从系统语音中选择朗读声音'
            : '选择声音并调整朗读体验';
    return SettingsDetailScaffold(
      header: SettingsDetailHeader(
        eyebrow: '阅读体验',
        title: '阅读朗读',
        subtitle: subtitle,
      ),
      children: [
        const SizedBox(height: 14),
        if (settings == null)
          const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _VoicePreviewPlayer(
            title: _previewTitle,
            source: _previewSource,
            playing: _previewing,
            progress: _previewProgress,
            enabled: _canPreview(settings),
            message: _previewMessage,
            rateLabel: _rateLabel(settings.speechRate),
            onToggle: _togglePreview,
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('朗读引擎'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _EngineChoice(
                  label: '系统语音',
                  state: '离线 · 设备音色',
                  icon: LucideIcons.smartphone,
                  selected: settings.engine == ReadAloudEngine.system,
                  onTap: () {
                    _update(
                      settings.copyWith(engine: ReadAloudEngine.system),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EngineChoice(
                  label: '在线引擎',
                  state: '接口合成 · 需联网',
                  icon: LucideIcons.cloud,
                  selected: settings.engine == ReadAloudEngine.online,
                  onTap: () {
                    _update(
                      settings.copyWith(engine: ReadAloudEngine.online),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (settings.engine == ReadAloudEngine.system) ...[
            const SettingsSectionTitle('声音'),
            const SizedBox(height: 10),
            _VoiceSection(
              voices: _voices,
              loading: _loadingVoices,
              selectedName: settings.voiceName,
              expanded: _voiceListExpanded,
              onToggle: () => setState(
                () => _voiceListExpanded = !_voiceListExpanded,
              ),
              onSelect: _selectVoice,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              key: const ValueKey('read-aloud-system-tts-settings'),
              onTap: _openSystemTtsSettings,
              behavior: HitTestBehavior.opaque,
              child: SettingsOptionRow(
                icon: LucideIcons.settings,
                title: '系统语音设置',
                description: '安装或管理设备的中文语音数据',
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: DudoColors.outline,
                  size: 16,
                ),
                height: 68,
              ),
            ),
          ] else
            _OnlineEngineFields(
              settings: settings,
              urlController: _urlController,
              tokenController: _tokenController,
              voiceController: _onlineVoiceController,
              urlError: (settings.onlineUrl ?? '').trim().isEmpty
                  ? null
                  : onlineUrlError(settings.onlineUrl),
              testing: _testing,
              testMessage: _testMessage,
              testOk: _testOk,
              onTest: _runConnectionTest,
              onUrlChanged: (value) => _updateField(
                (current) => current.copyWith(
                  onlineUrl: value,
                  clearOnlineUrl: value.trim().isEmpty,
                ),
              ),
              onTokenChanged: (value) => _updateField(
                (current) => current.copyWith(
                  onlineToken: value,
                  clearOnlineToken: value.trim().isEmpty,
                ),
              ),
              onVoiceChanged: (value) => _updateField(
                (current) => current.copyWith(
                  onlineVoice: value,
                  clearOnlineVoice: value.trim().isEmpty,
                ),
              ),
              onFormatChanged: (format) => _updateField(
                (current) => current.copyWith(onlineFormat: format),
              ),
            ),
          const SizedBox(height: 14),
          SettingsMeterControl(
            label: '语速',
            icon: LucideIcons.gauge,
            value: rateAdjustable ? _rateLabel(settings.speechRate) : '文本模式不发送',
            color: rateAdjustable ? DudoColors.primary : DudoColors.secondary,
            fraction: (settings.speechRate - 0.5) / 1.5,
            minValue: 0.5,
            maxValue: 2.0,
            onChanged: rateAdjustable
                ? (value) {
                    _update(
                      settings.copyWith(
                        speechRate: _roundToStep(value, 0.1),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 10),
          SettingsMeterControl(
            label: '音调',
            icon: LucideIcons.music2,
            value: settings.engine == ReadAloudEngine.online
                ? '由服务端决定'
                : _pitchLabel(settings.pitch),
            color: settings.engine == ReadAloudEngine.online
                ? DudoColors.secondary
                : DudoColors.accent,
            fraction: settings.engine == ReadAloudEngine.online
                ? 0
                : (settings.pitch - 0.5) / 1.5,
            minValue: 0.5,
            maxValue: 2.0,
            // The HTTP contract only carries text/voice/rate; a pitch slider
            // that changes nothing would be misleading.
            onChanged: settings.engine == ReadAloudEngine.online
                ? null
                : (value) {
                    _update(settings.copyWith(pitch: _roundToStep(value, 0.1)));
                  },
          ),
          const SizedBox(height: 10),
          SettingsMeterControl(
            label: '音量',
            icon: LucideIcons.volume2,
            value: '${(settings.volume * 100).round()}%',
            color: DudoColors.secondary,
            fraction: settings.volume,
            onChanged: (value) {
              _update(settings.copyWith(volume: _roundToStep(value, 0.05)));
            },
          ),
          const SizedBox(height: 14),
          SettingsOptionRow(
            icon: LucideIcons.smartphone,
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
            height: 68,
          ),
          const SizedBox(height: 10),
          SettingsOptionRow(
            icon: LucideIcons.listIndentIncrease,
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
            height: 68,
          ),
          const SizedBox(height: 14),
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

class _EngineChoice extends StatelessWidget {
  const _EngineChoice({
    required this.label,
    required this.state,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String state;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? DudoColors.primary : DudoColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: selected ? DudoColors.primary : DudoColors.secondary,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DudoColors.primaryContainer,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: DudoColors.primary,
                      size: 12,
                    ),
                  )
                else
                  const SizedBox(width: 18, height: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              state,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineEngineFields extends StatelessWidget {
  const _OnlineEngineFields({
    required this.settings,
    required this.urlController,
    required this.tokenController,
    required this.voiceController,
    required this.urlError,
    required this.testing,
    required this.testMessage,
    required this.testOk,
    required this.onTest,
    required this.onUrlChanged,
    required this.onTokenChanged,
    required this.onVoiceChanged,
    required this.onFormatChanged,
  });

  final ReadAloudSettings settings;
  final TextEditingController urlController;
  final TextEditingController tokenController;
  final TextEditingController voiceController;
  final String? urlError;
  final bool testing;
  final String? testMessage;
  final bool? testOk;
  final VoidCallback onTest;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onTokenChanged;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<OnlineTtsFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('在线接口'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingField(
                key: const ValueKey('read-aloud-online-url'),
                label: '接口地址',
                hint: 'https://example.com/tts',
                controller: urlController,
                icon: LucideIcons.globe,
                keyboardType: TextInputType.url,
                onChanged: onUrlChanged,
                error: urlError,
              ),
              const SizedBox(height: 13),
              _SettingField(
                label: '访问令牌（可选）',
                hint: '以 Bearer Token 发送',
                controller: tokenController,
                icon: LucideIcons.keyRound,
                onChanged: onTokenChanged,
              ),
              const SizedBox(height: 13),
              _SettingField(
                label: '音色参数（可选）',
                hint: '如 zh-CN-XiaoxiaoNeural',
                controller: voiceController,
                icon: LucideIcons.audioLines,
                onChanged: onVoiceChanged,
              ),
              const SizedBox(height: 14),
              _TestConnectionButton(testing: testing, onTest: onTest),
              if (testMessage != null) ...[
                const SizedBox(height: 10),
                _TestStatusLine(message: testMessage!, ok: testOk),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '请求格式',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _FormatChip(
                    label: '文本',
                    selected: settings.onlineFormat == OnlineTtsFormat.text,
                    onTap: () => onFormatChanged(OnlineTtsFormat.text),
                  ),
                  const SizedBox(width: 8),
                  _FormatChip(
                    label: 'JSON',
                    selected: settings.onlineFormat == OnlineTtsFormat.json,
                    onTap: () => onFormatChanged(OnlineTtsFormat.json),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '接口按段落接收文本并返回 mp3/wav 音频，仅临时缓存当前段落；文本模式只发送正文，JSON 模式发送 text、voice、rate。',
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.error,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? error;

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
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
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
              prefixIcon: Icon(icon, size: 17, color: DudoColors.secondary),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: error == null ? DudoColors.outline : DudoColors.accent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: DudoColors.primary),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            key: const ValueKey('read-aloud-online-url-error'),
            style: DudoTextStyles.sans(
              color: DudoColors.accent,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class _TestConnectionButton extends StatelessWidget {
  const _TestConnectionButton({required this.testing, required this.onTest});

  final bool testing;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Material(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          key: const ValueKey('read-aloud-test-connection'),
          onTap: testing ? null : onTest,
          borderRadius: BorderRadius.circular(23),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                testing ? LucideIcons.loaderCircle : LucideIcons.plugZap,
                size: 16,
                color: testing ? DudoColors.secondary : DudoColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                testing ? '测试中…' : '测试连接',
                style: DudoTextStyles.sans(
                  color: testing ? DudoColors.secondary : DudoColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The outcome of the last connection test, so a bad endpoint is diagnosed
/// here instead of only failing when the reader starts.
class _TestStatusLine extends StatelessWidget {
  const _TestStatusLine({required this.message, required this.ok});

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

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DudoColors.primaryContainer : DudoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected ? DudoColors.accentMuted : DudoColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: DudoTextStyles.sans(
            color: selected ? DudoColors.primary : DudoColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _VoiceSection extends StatelessWidget {
  const _VoiceSection({
    required this.voices,
    required this.loading,
    required this.selectedName,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  final List<TtsVoice> voices;
  final bool loading;
  final String? selectedName;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<TtsVoice?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading && voices.isEmpty) {
      return Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DudoColors.surfaceLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '正在读取系统语音',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '正在向系统 TTS 引擎获取声音列表',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: DudoColors.secondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final selected = _findVoice(selectedName);
    final title = expanded ? '选择朗读声音' : (selected?.displayName ?? '系统默认');
    final meta = expanded
        ? '列表来自系统 TTS 引擎，选择后试听会使用该声音'
        : (selected?.voiceMeta ?? '跟随系统设置');

    return Container(
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          GestureDetector(
            key: const ValueKey('read-aloud-voice-toggle'),
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  _VoiceIconCircle(
                    icon: LucideIcons.audioLines,
                    fill: DudoColors.surfaceLow,
                    color: DudoColors.secondary,
                    size: 40,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DudoTextStyles.sans(
                            color: DudoColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: DudoColors.secondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  for (var i = 0; i < voices.length + 1; i++) ...[
                    _VoiceOption(
                      key: ValueKey('read-aloud-voice-$i'),
                      voice: i == 0 ? null : voices[i - 1],
                      selected: i == 0
                          ? selectedName == null
                          : voices[i - 1].name == selectedName,
                      onTap: () => onSelect(i == 0 ? null : voices[i - 1]),
                    ),
                    if (i < voices.length) const SizedBox(height: 8),
                  ],
                  if (voices.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '当前设备没有可用的系统语音，请先在系统设置的“文字转语音”中安装中文语音数据。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  TtsVoice? _findVoice(String? name) {
    if (name == null) return null;
    for (final voice in voices) {
      if (voice.name == name) return voice;
    }
    return null;
  }
}

class _VoiceOption extends StatelessWidget {
  const _VoiceOption({
    super.key,
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  final TtsVoice? voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = DudoColors.isDark;
    final fill = selected
        ? (dark ? DudoColors.primaryContainer : DudoColors.ink)
        : DudoColors.paperBackground;
    final stroke = selected
        ? (dark ? DudoColors.primaryContainerStrong : DudoColors.ink)
        : DudoColors.outlineVariant;
    final titleColor = selected
        ? (dark ? DudoColors.onPrimaryContainer : DudoColors.onInk)
        : DudoColors.textPrimary;
    final metaColor = selected
        ? (dark ? DudoColors.textSecondary : DudoColors.onInkMuted)
        : DudoColors.textSecondary;
    final iconFill = selected
        ? (dark
            ? DudoColors.primaryContainerStrong
            : DudoColors.onInk.withValues(alpha: 0.12))
        : DudoColors.surfaceLow;
    final iconColor = selected
        ? (dark ? DudoColors.primaryDark : DudoColors.primaryContainer)
        : DudoColors.secondary;
    final checkFill = dark ? DudoColors.primary : DudoColors.primaryContainer;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stroke),
        ),
        child: Row(
          children: [
            _VoiceIconCircle(
              icon: voice?.isNetwork ?? false
                  ? LucideIcons.wifi
                  : LucideIcons.volume2,
              fill: iconFill,
              color: iconColor,
              size: 36,
              iconSize: 17,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice?.displayName ?? '系统默认',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    voice?.voiceMeta ?? '跟随系统设置',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: metaColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? checkFill : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected ? checkFill : DudoColors.outline,
                ),
              ),
              child: selected
                  ? Icon(
                      LucideIcons.check,
                      size: 11,
                      color: dark ? DudoColors.ink : DudoColors.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceIconCircle extends StatelessWidget {
  const _VoiceIconCircle({
    required this.icon,
    required this.fill,
    required this.color,
    this.size = 36,
    this.iconSize = 16,
  });

  final IconData icon;
  final Color fill;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _VoicePreviewPlayer extends StatelessWidget {
  const _VoicePreviewPlayer({
    required this.title,
    required this.source,
    required this.playing,
    required this.progress,
    required this.enabled,
    required this.message,
    required this.rateLabel,
    required this.onToggle,
  });

  final String title;
  final String source;
  final bool playing;

  /// 0..1 playback position; `null` while the sample is still being prepared.
  final double? progress;
  final bool enabled;
  final String? message;
  final String rateLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final track = DudoColors.surface.withValues(alpha: 0.6);
    return Container(
      height: 188,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: const ValueKey('read-aloud-preview-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source,
                      key: const ValueKey('read-aloud-preview-source'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rateLabel,
                  style: DudoTextStyles.numeric(
                    color: DudoColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _previewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              GestureDetector(
                key: const ValueKey('read-aloud-preview-button'),
                onTap: enabled ? onToggle : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled
                        ? DudoColors.textPrimary
                        : DudoColors.outlineVariant,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    playing ? LucideIcons.pause : LucideIcons.play,
                    color:
                        enabled ? DudoColors.surfaceHigh : DudoColors.secondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: message != null
                    ? Text(
                        message!,
                        key: const ValueKey('read-aloud-preview-message'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 11,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 7,
                          child: !playing
                              ? Container(color: track)
                              // While the sample is still being prepared
                              // there is no position yet; once sound starts
                              // the bar follows the real playback position.
                              : progress == null
                                  ? LinearProgressIndicator(
                                      minHeight: 7,
                                      color: DudoColors.primary,
                                      backgroundColor: track,
                                    )
                                  : TweenAnimationBuilder<double>(
                                      // Progress arrives word by word (system)
                                      // or in ~200ms ticks (online); easing
                                      // between values keeps the bar smooth.
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: progress!,
                                      ),
                                      duration:
                                          const Duration(milliseconds: 240),
                                      curve: Curves.linear,
                                      builder: (context, value, _) =>
                                          LinearProgressIndicator(
                                        minHeight: 7,
                                        value: value,
                                        color: DudoColors.primary,
                                        backgroundColor: track,
                                      ),
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
