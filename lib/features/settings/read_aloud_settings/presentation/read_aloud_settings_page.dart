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
            progress: _previewProgress,
            enabled: _canPreview(settings),
            message: _previewMessage,
            rateLabel: _rateLabel(settings.speechRate),
            onToggle: _togglePreview,
          ),
          const SizedBox(height: 14),
          const SettingsSectionTitle('朗读引擎'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EngineChoice(
                  label: '系统语音',
                  state: '离线 · 设备音色',
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
                  state: '更自然的音色',
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
            const SizedBox(height: 8),
            _VoiceGrid(
              voices: _voices,
              loading: _loadingVoices,
              selectedName: settings.voiceName,
              onSelect: _selectVoice,
            ),
            if (!_loadingVoices && _voices.isEmpty) ...[
              const SizedBox(height: 8),
              const SettingsTrailingValue(
                '当前设备没有可用的系统语音，请先在系统设置的“文字转语音”中安装中文语音数据。',
                color: DudoColors.secondary,
              ),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              key: const ValueKey('read-aloud-system-tts-settings'),
              onTap: _openSystemTtsSettings,
              behavior: HitTestBehavior.opaque,
              child: const SettingsOptionRow(
                title: '系统语音设置',
                description: '安装或管理设备的中文语音数据',
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: DudoColors.outline,
                  size: 16,
                ),
                height: 52,
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
            value: settings.engine == ReadAloudEngine.online
                ? '由服务端决定'
                : _pitchLabel(settings.pitch),
            color: DudoColors.accent,
            fraction: (settings.pitch - 0.5) / 1.5,
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
          if (settings.engine == ReadAloudEngine.online) ...[
            const SizedBox(height: 6),
            const SettingsTrailingValue(
              '在线音色的音调由接口服务端决定，此设置仅对系统语音生效。',
              color: DudoColors.secondary,
            ),
          ],
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

class _EngineChoice extends StatelessWidget {
  const _EngineChoice({
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? DudoColors.secondary : DudoColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? LucideIcons.check : LucideIcons.server,
                  color: selected ? DudoColors.primary : DudoColors.secondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              state,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 10,
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
        const SizedBox(height: 8),
        _SettingField(
          key: const ValueKey('read-aloud-online-url'),
          label: '接口地址',
          hint: 'https://example.com/tts',
          controller: urlController,
          keyboardType: TextInputType.url,
          onChanged: onUrlChanged,
          error: urlError,
        ),
        const SizedBox(height: 8),
        _SettingField(
          label: '访问令牌（可选）',
          hint: '以 Bearer Token 发送',
          controller: tokenController,
          onChanged: onTokenChanged,
        ),
        const SizedBox(height: 8),
        _SettingField(
          label: '音色（可选）',
          hint: '如 zh-CN-XiaoxiaoNeural',
          controller: voiceController,
          onChanged: onVoiceChanged,
        ),
        const SizedBox(height: 10),
        _TestConnectionRow(
          testing: testing,
          message: testMessage,
          ok: testOk,
          onTest: onTest,
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        const SettingsTrailingValue(
          '接口需直接返回音频（mp3/wav）。文本模式以 text/plain 提交正文；JSON 模式提交 {"text","voice","rate"}。',
          color: DudoColors.secondary,
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
    required this.onChanged,
    this.keyboardType,
    this.error,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: error == null ? DudoColors.outlineVariant : DudoColors.accent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: DudoTextStyles.sans(
                color: DudoColors.outline,
                fontSize: 12,
              ),
              border: InputBorder.none,
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                error!,
                key: const ValueKey('read-aloud-online-url-error'),
                style: DudoTextStyles.sans(
                  color: DudoColors.accent,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "测试连接" plus the outcome of the last attempt, so a bad endpoint is
/// diagnosed here instead of only failing when the reader starts.
class _TestConnectionRow extends StatelessWidget {
  const _TestConnectionRow({
    required this.testing,
    required this.message,
    required this.ok,
    required this.onTest,
  });

  final bool testing;
  final String? message;
  final bool? ok;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final color = switch (ok) {
      true => DudoColors.primary,
      false => DudoColors.accent,
      null => DudoColors.secondary,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: const ValueKey('read-aloud-test-connection'),
          onTap: testing ? null : onTest,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DudoColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: DudoColors.outlineVariant),
            ),
            child: Text(
              testing ? '测试中…' : '测试连接',
              style: DudoTextStyles.sans(
                color: testing ? DudoColors.secondary : DudoColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message ?? '',
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
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DudoColors.primaryContainer : DudoColors.surface,
          borderRadius: BorderRadius.circular(15),
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

class _VoiceGrid extends StatefulWidget {
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
  State<_VoiceGrid> createState() => _VoiceGridState();
}

class _VoiceGridState extends State<_VoiceGrid> {
  static const _itemWidth = 116.0;
  static const _itemGap = 10.0;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelection();
  }

  @override
  void didUpdateWidget(covariant _VoiceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedName != widget.selectedName ||
        oldWidget.voices.length != widget.voices.length) {
      _revealSelection();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Scrolls a selection that sits off-screen into view, so reopening the page
  /// shows which voice is actually in use.
  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final name = widget.selectedName;
      if (name == null) return;
      final index = widget.voices.indexWhere((voice) => voice.name == name);
      if (index < 0) return;
      // The leading "系统默认" chip occupies slot 0.
      final offset = (index + 1) * (_itemWidth + _itemGap);
      final position = _controller.position;
      if (offset >= position.pixels &&
          offset + _itemWidth <= position.pixels + position.viewportDimension) {
        return;
      }
      _controller.jumpTo(
        offset.clamp(0.0, position.maxScrollExtent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const SizedBox(
        height: 86,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final options = <TtsVoice?>[null, ...widget.voices];
    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: _itemGap),
        itemBuilder: (context, index) {
          final voice = options[index];
          final selected = voice?.name == widget.selectedName;
          return SizedBox(
            width: _itemWidth,
            child: _VoiceChoice(
              label: voice?.displayName ?? '系统默认',
              state: voice?.locale ?? '跟随系统',
              iconColor: selected ? DudoColors.primary : DudoColors.secondary,
              selected: selected,
              onTap: () => widget.onSelect(voice),
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
    required this.progress,
    required this.enabled,
    required this.message,
    required this.rateLabel,
    required this.onToggle,
  });

  final bool playing;

  /// 0..1 playback position; `null` while the sample is still being prepared.
  final double? progress;
  final bool enabled;
  final String? message;
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
                onTap: enabled ? onToggle : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: enabled
                        ? DudoColors.textPrimary
                        : DudoColors.outlineVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    playing ? LucideIcons.square : LucideIcons.play,
                    color:
                        enabled ? DudoColors.surfaceHigh : DudoColors.secondary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: !playing
                              ? Container(
                                  color: DudoColors.surface
                                      .withValues(alpha: 0.67),
                                )
                              // While the sample is still being prepared
                              // there is no position yet; once sound starts
                              // the bar follows the real playback position.
                              : progress == null
                                  ? LinearProgressIndicator(
                                      color: DudoColors.primary,
                                      backgroundColor: DudoColors.surface
                                          .withValues(alpha: 0.67),
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
                                        value: value,
                                        color: DudoColors.primary,
                                        backgroundColor: DudoColors.surface
                                            .withValues(alpha: 0.67),
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
              style: DudoTextStyles.sans(
                  color: DudoColors.secondary, fontSize: 10),
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
