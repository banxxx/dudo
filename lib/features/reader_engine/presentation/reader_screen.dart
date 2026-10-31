import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/app_router.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../reading_stats/application/reading_stats_provider.dart';
import '../../reading_stats/data/reading_session_recorder.dart';
import '../../settings/read_aloud_settings/application/read_aloud_player.dart';
import '../../settings/read_aloud_settings/application/read_aloud_settings_provider.dart';
import '../../settings/read_aloud_settings/data/read_aloud_settings_repository.dart';
import '../../settings/read_aloud_settings/domain/read_aloud_settings.dart';
import '../../settings/typography_settings/application/reader_font_providers.dart';
import '../application/reader_background_providers.dart';
import '../application/reader_engine_providers.dart';
import '../application/reader_engine_state.dart';
import '../application/reader_preferences_provider.dart';
import '../controller/reader_session_controller.dart';
import '../controller/reader_tts_controller.dart';
import '../controller/reader_viewport_controller.dart';
import '../data/reader_preferences_repository.dart';
import '../domain/reader_annotation.dart';
import '../domain/reader_background.dart';
import '../domain/reader_catalog_item.dart';
import '../domain/reader_chapter.dart';
import '../domain/reader_insets.dart';
import '../domain/reader_location.dart';
import '../domain/reader_overlay_mode.dart';
import '../domain/reader_preferences.dart';
import '../domain/reader_range.dart';
import '../domain/reader_reading_time.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_session_tracker.dart';
import '../domain/reader_theme.dart';
import '../domain/reader_turn_mode.dart';
import '../domain/reader_viewport_state.dart';
import '../layout/reader_layout_cache.dart';
import '../layout/reader_layout_engine.dart';
import 'layout/reader_chrome_layout.dart';
import 'layout/reader_page_metrics.dart';
import 'reader_controls.dart';
import 'reader_viewport.dart';
import 'widgets/reader_background.dart';
import 'widgets/reader_brightness_overlay.dart';
import 'widgets/reader_eye_comfort_overlay.dart';
import 'widgets/reader_progress.dart';
import 'widgets/reader_volume_page_turn_listener.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    this.initialChapterIndex = 0,
    this.initialOffset = 0,
  });

  final String bookId;
  final int initialChapterIndex;

  /// Character offset inside [initialChapterIndex] to open at, used when
  /// jumping to a bookmark.
  final int initialOffset;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  static const int _catalogPageSize = 200;
  static const double _systemLightBrightness = 1;
  static const double _systemDarkBrightness = 0.62;

  ReaderSessionController? _controller;
  Future<void>? _initialization;
  Size? _lastViewportSize;
  EdgeInsets? _lastViewportPadding;
  String? _lastSelectedFontFamily;
  final ReaderLayoutCache _layoutCache = ReaderLayoutCache(maximumEntries: 96);
  bool _controllerRefreshScheduled = false;

  ReaderOverlayMode _overlayMode = ReaderOverlayMode.hidden;
  ReaderPalette _palette = ReaderTheme.parchment;
  double _fontSize = 19;
  double _lineHeight = 1.72;
  double _paragraphSpacing = 15;
  double _pageHorizontalMargin = ReaderSettings.defaultPageHorizontalMargin;
  bool _firstLineIndentEnabled = true;
  bool _textEnhancementEnabled = false;
  double _brightness = 1;
  bool _followSystemBrightness = false;
  bool _eyeComfortEnhanced = false;
  bool _timeBatteryHidden = false;
  bool _chapterProgressHidden = false;
  bool _systemStatusBarHidden = true;
  bool _pageEdgeHidden = false;
  bool _gestureNavigationBlocked = true;
  bool _allowRoutePop = false;
  bool _volumePageTurnEnabled = true;
  ReaderTurnMode _turnMode = ReaderTurnMode.slide;
  bool _isListening = false;
  bool _isReadAloudPaused = false;
  int _volumePageTurnRequestId = 0;
  int _volumePageTurnDirection = 0;
  List<ReaderCatalogItem> _catalogItems = const [];
  bool _catalogLoading = false;
  DateTime? _readingSessionStartedAt;
  ReadingSessionRecorder? _readingSessionRecorder;
  final ReadingSessionTracker _sessionTracker = ReadingSessionTracker();
  ReaderPreferences? _preferences;
  ReaderPreferencesRepository? _preferencesRepository;
  Timer? _preferencesSaveTimer;
  bool _preferencesDirty = false;
  ReadAloudSettings _readAloudSettings = ReadAloudSettings.defaults();
  ReadAloudSettingsRepository? _readAloudRepository;
  ReadAloudPlayer? _readAloudPlayer;
  List<ReaderTtsSegment> _ttsSegments = const [];
  Timer? _readAloudTimer;
  bool _readAloudTimerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSystemUiMode();
    unawaited(_loadPreferences());
    unawaited(_loadReadAloudSettings());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUiMode());
  }

  @override
  void dispose() {
    _readAloudTimer?.cancel();
    final readAloudPlayer = _readAloudPlayer;
    if (readAloudPlayer != null) {
      readAloudPlayer.bind();
      unawaited(readAloudPlayer.stop());
    }
    _flushPreferences();
    unawaited(_flushReadingSession());
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    });
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    ReaderPreferences preferences;
    try {
      final repository = ref.read(readerPreferencesRepositoryProvider);
      _preferencesRepository = repository;
      preferences = await repository.load();
    } catch (error, stackTrace) {
      log.w(
        '[reader] failed to load preferences',
        error: error,
        stackTrace: stackTrace,
      );
      preferences = ReaderPreferences.defaults();
    }
    if (!mounted) return;
    setState(() => _applyPreferences(preferences));
    _syncSystemUiMode();
  }

  void _applyPreferences(ReaderPreferences preferences) {
    _preferences = preferences;
    _palette = preferences.palette;
    _fontSize = preferences.fontSize;
    _lineHeight = preferences.lineHeight;
    _paragraphSpacing = preferences.paragraphSpacing;
    _pageHorizontalMargin = preferences.pageHorizontalMargin;
    _firstLineIndentEnabled = preferences.firstLineIndentEnabled;
    _textEnhancementEnabled = preferences.textEnhancementEnabled;
    _turnMode = preferences.turnMode;
    _followSystemBrightness = preferences.followSystemBrightness;
    _brightness = preferences.followSystemBrightness
        ? _brightnessForSystemMode()
        : preferences.brightness;
    _eyeComfortEnhanced = preferences.eyeComfortEnhanced;
    _timeBatteryHidden = preferences.timeBatteryHidden;
    _chapterProgressHidden = preferences.chapterProgressHidden;
    _systemStatusBarHidden = preferences.systemStatusBarHidden;
    _pageEdgeHidden = preferences.pageEdgeHidden;
    _gestureNavigationBlocked = preferences.gestureNavigationBlocked;
    _volumePageTurnEnabled = preferences.volumePageTurnEnabled;
  }

  /// Snapshots the current settings and writes them after a short debounce so
  /// dragging a slider only costs one write.
  void _schedulePreferencesSave() {
    if (_preferencesRepository == null) return;

    _preferences = ReaderPreferences(
      paletteId: _palette.id,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      paragraphSpacing: _paragraphSpacing,
      pageHorizontalMargin: _pageHorizontalMargin,
      firstLineIndentEnabled: _firstLineIndentEnabled,
      textEnhancementEnabled: _textEnhancementEnabled,
      turnMode: _turnMode,
      brightness: _brightness,
      followSystemBrightness: _followSystemBrightness,
      eyeComfortEnhanced: _eyeComfortEnhanced,
      timeBatteryHidden: _timeBatteryHidden,
      chapterProgressHidden: _chapterProgressHidden,
      systemStatusBarHidden: _systemStatusBarHidden,
      pageEdgeHidden: _pageEdgeHidden,
      gestureNavigationBlocked: _gestureNavigationBlocked,
      volumePageTurnEnabled: _volumePageTurnEnabled,
    );
    _preferencesDirty = true;
    _preferencesSaveTimer?.cancel();
    _preferencesSaveTimer =
        Timer(const Duration(milliseconds: 400), _flushPreferences);
  }

  void _flushPreferences() {
    _preferencesSaveTimer?.cancel();
    _preferencesSaveTimer = null;

    final preferences = _preferences;
    final repository = _preferencesRepository;
    if (!_preferencesDirty || preferences == null || repository == null) {
      return;
    }
    _preferencesDirty = false;
    unawaited(_savePreferences(repository, preferences));
  }

  Future<void> _savePreferences(
    ReaderPreferencesRepository repository,
    ReaderPreferences preferences,
  ) async {
    try {
      await repository.save(preferences);
    } catch (error, stackTrace) {
      log.w(
        '[reader] failed to save preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadReadAloudSettings() async {
    try {
      final repository = ref.read(readAloudSettingsRepositoryProvider);
      _readAloudRepository = repository;
      final settings = await repository.load();
      if (!mounted) return;
      setState(() => _readAloudSettings = settings);
    } catch (error, stackTrace) {
      log.w(
        '[reader] failed to load read-aloud settings',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _setListening(bool value) async {
    if (value) {
      // Resuming keeps the player's cursor, so pausing does not restart the
      // chapter (the system engine re-reads only the current paragraph).
      if (_isReadAloudPaused) {
        _isReadAloudPaused = false;
        if (mounted) setState(() => _isListening = true);
        await _readAloudPlayer?.resume();
        return;
      }
      await _startListening();
      return;
    }
    if (!_isListening) return;
    _isReadAloudPaused = true;
    if (mounted) setState(() => _isListening = false);
    await _readAloudPlayer?.pause();
  }

  Future<void> _startListening() async {
    final controller = _controller;
    final state = controller?.state;
    final viewport = state?.viewport;
    final location = state?.location;
    if (controller == null || viewport == null || location == null) {
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final chapter = _chapterItemForLocation(viewport, location).chapter;
    await _startListeningForChapter(chapter, controller);
  }

  Future<void> _startListeningForChapter(
    ReaderChapter chapter,
    ReaderSessionController controller,
  ) async {
    final segments = const ReaderTtsController().buildChapterSegments(chapter);
    if (segments.isEmpty) {
      if (mounted) setState(() => _isListening = false);
      return;
    }

    ReadAloudSettings settings;
    try {
      final repository = _readAloudRepository ??
          ref.read<ReadAloudSettingsRepository>(
            readAloudSettingsRepositoryProvider,
          );
      _readAloudRepository = repository;
      settings = await repository.load();
    } catch (error, stackTrace) {
      log.w(
        '[reader] failed to load read-aloud settings',
        error: error,
        stackTrace: stackTrace,
      );
      settings = _readAloudSettings;
    }
    if (!mounted) return;

    final player = ref.read(readAloudPlayerProvider);
    _readAloudSettings = settings;
    _readAloudPlayer = player;
    _ttsSegments = segments;
    _scheduleReadAloudTimer(settings);
    player.bind(
      onSegmentStarted: _onTtsSegmentStarted,
      onCompleted: _onTtsChapterCompleted,
      onFailed: _onTtsFailed,
    );
    setState(() => _isListening = true);
    await player.apply(settings);
    final bookTitle = controller.state.document?.title;
    await player.play(
      segments.map((segment) => segment.text).toList(),
      // Shown in the media notification / lock screen while playing.
      title:
          bookTitle == null ? chapter.title : '$bookTitle · ${chapter.title}',
    );
  }

  Future<void> _stopListening() async {
    _readAloudTimer?.cancel();
    _readAloudTimer = null;
    _readAloudTimerActive = false;
    _isReadAloudPaused = false;
    final player = _readAloudPlayer;
    player?.bind();
    await player?.stop();
    _ttsSegments = const [];
    if (mounted && _isListening) {
      setState(() => _isListening = false);
    }
  }

  /// Every segment failed (bad endpoint, offline); stop instead of leaving the
  /// panel stuck on "朗读中" with no sound.
  void _onTtsFailed(Object error) {
    if (!mounted) return;
    unawaited(_stopListening());
    // The online engine already knows why it failed (bad token, timeout, ...);
    // repeating that here saves the user a trip to the settings page.
    final message =
        error is AppException ? '朗读失败：${error.message}' : '朗读失败，请检查朗读设置或网络';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _scheduleReadAloudTimer(ReadAloudSettings settings) {
    _readAloudTimer?.cancel();
    _readAloudTimer = null;
    _readAloudTimerActive = false;
    if (!settings.timerEnabled) return;
    _readAloudTimerActive = true;
    _readAloudTimer = Timer(Duration(minutes: settings.timerMinutes), () {
      if (!mounted) return;
      unawaited(_stopListening());
    });
  }

  void _toggleReadAloudTimer() {
    if (_readAloudTimerActive) {
      _readAloudTimer?.cancel();
      _readAloudTimer = null;
      setState(() => _readAloudTimerActive = false);
      return;
    }
    setState(() => _readAloudTimerActive = true);
    _readAloudTimer = Timer(
      Duration(minutes: _readAloudSettings.timerMinutes),
      () {
        if (!mounted) return;
        unawaited(_stopListening());
      },
    );
  }

  Future<void> _onSpeechRateChanged(double rate) async {
    final next = _readAloudSettings.copyWith(speechRate: rate);
    setState(() => _readAloudSettings = next);
    final repository = _readAloudRepository;
    if (repository != null) unawaited(repository.save(next));

    final player = _readAloudPlayer;
    if (player == null) return;
    // Keep a paused session in sync so resuming uses the new speed.
    await player.apply(next);
    if (_isListening) await player.restartCurrent();
  }

  /// Keeps the visible page on the paragraph being spoken when the user turned
  /// on 段落跟读.
  void _onTtsSegmentStarted(int index) {
    if (!mounted || !_isListening) return;
    final controller = _controller;
    final viewport = controller?.state.viewport;
    final location = controller?.state.location;
    if (controller == null || viewport == null || location == null) return;
    if (!_readAloudSettings.paragraphFollowEnabled) return;
    if (index < 0 || index >= _ttsSegments.length) return;

    final start = _ttsSegments[index].range.start;
    if (start.chapterIndex != location.chapterIndex) return;
    if (_currentPageContains(viewport, location, start)) return;
    unawaited(controller.followReadAloudLocation(start));
  }

  bool _currentPageContains(
    ReaderViewportState viewport,
    ReaderLocation current,
    ReaderLocation target,
  ) {
    final pages = viewport.currentLayout.pages;
    if (pages.isEmpty) return false;
    final page = pages.firstWhere(
      (candidate) {
        final isLastPage = candidate.pageIndex == pages.last.pageIndex;
        final startsInPage = current.offset >= candidate.start.offset;
        final endsInPage = isLastPage
            ? current.offset <= candidate.end.offset
            : current.offset < candidate.end.offset;
        return startsInPage && endsInPage;
      },
      orElse: () => pages.last,
    );
    final isLastPage = page.pageIndex == pages.last.pageIndex;
    return target.offset >= page.start.offset &&
        (isLastPage
            ? target.offset <= page.end.offset
            : target.offset < page.end.offset);
  }

  Future<void> _onTtsChapterCompleted() async {
    if (!mounted || !_isListening) return;
    final controller = _controller;
    final document = controller?.state.document;
    final location = controller?.state.location;
    if (controller == null || document == null || location == null) {
      await _stopListening();
      return;
    }
    if (location.chapterIndex + 1 >= document.chapterCount) {
      await _stopListening();
      return;
    }

    await controller.goToNextChapter();
    if (!mounted || !_isListening) return;

    final state = controller.state;
    final viewport = state.viewport;
    final nextLocation = state.location;
    if (viewport == null || nextLocation == null) {
      await _stopListening();
      return;
    }
    setState(() => _overlayMode = ReaderOverlayMode.listening);
    final chapter = _chapterItemForLocation(viewport, nextLocation).chapter;
    await _startListeningForChapter(chapter, controller);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (!_followSystemBrightness || !mounted) return;
    setState(() => _brightness = _brightnessForSystemMode());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller?.state.loadStatus == ReaderLoadStatus.ready) {
        _startReadingSession();
      }
      return;
    }
    if (state == AppLifecycleState.paused &&
        _isListening &&
        !_readAloudSettings.backgroundEnabled) {
      unawaited(_setListening(false));
    }
    unawaited(_flushReadingSession());
  }

  /// Starts counting reading time for the stats screens. Time spent in the
  /// background is not counted because the session is flushed on pause.
  void _startReadingSession() {
    if (_readingSessionStartedAt != null) return;
    _readingSessionRecorder ??= ref.read(readingSessionRecorderProvider);
    _readingSessionStartedAt = DateTime.now();
  }

  Future<void> _flushReadingSession() async {
    final startedAt = _readingSessionStartedAt;
    final recorder = _readingSessionRecorder;
    _readingSessionStartedAt = null;
    if (startedAt == null || recorder == null) return;

    final endedAt = DateTime.now();
    if (endedAt.difference(startedAt).inSeconds <= 0) return;

    final delta = _sessionTracker.takeDelta();
    try {
      await recorder.record(
        bookId: widget.bookId,
        startedAt: startedAt,
        endedAt: endedAt,
        wordsRead: delta.characters,
        chaptersRead: delta.chapters,
      );
    } catch (error, stackTrace) {
      log.w(
        '[reader] failed to record reading session',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSystemUiMode();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the persisted appearance before the controller is created so
    // the first layout already uses the saved typography.
    if (_preferences == null) {
      return Scaffold(
        key: const ValueKey('reader-engine-screen'),
        backgroundColor: _palette.background,
        body: const SizedBox.expand(),
      );
    }

    final foreground = _palette.foreground;
    final selectedFontFamily =
        ref.watch(selectedReaderFontFamilyProvider).valueOrNull ??
            ReaderSettings.defaults().fontFamily;
    final backgroundState =
        ref.watch(readerBackgroundControllerProvider).valueOrNull ??
            ReaderBackgroundState.defaults();
    final backgroundPreference = backgroundState.current;
    final statusStyle = foreground.computeLuminance() > 0.5
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return PopScope(
      canPop: !_gestureNavigationBlocked || _allowRoutePop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusStyle.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          key: const ValueKey('reader-engine-screen'),
          extendBodyBehindAppBar: true,
          backgroundColor: _palette.background,
          body: ReaderVolumePageTurnListener(
            enabled: _volumePageTurnEnabled &&
                _overlayMode == ReaderOverlayMode.hidden,
            onPreviousPage: () => _requestVolumePageTurn(-1),
            onNextPage: () => _requestVolumePageTurn(1),
            child: SizedBox.expand(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  final safePadding = _readerSafePadding(context);
                  final chromeLayout =
                      ReaderChromeLayout.fromSize(size, safePadding);
                  final metrics = chromeLayout.metrics;
                  _ensureController(size, safePadding, selectedFontFamily);
                  return FutureBuilder<void>(
                    future: _initialization,
                    builder: (context, snapshot) {
                      final controller = _controller;
                      final state = controller?.state;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ReaderPaperBackground(
                            palette: _palette,
                            background: backgroundPreference,
                          ),
                          if (!_pageEdgeHidden)
                            ReaderSoftPageEdge(layout: chromeLayout),
                          if (controller == null ||
                              state == null ||
                              state.loadStatus == ReaderLoadStatus.loading)
                            Center(
                              child: _ReaderLoadingBar(
                                palette: _palette,
                                width: metrics.s(118),
                              ),
                            )
                          else if (state.loadStatus == ReaderLoadStatus.error)
                            Center(
                              child: Text(
                                '阅读器加载失败：${state.error}',
                                style: TextStyle(color: _palette.foreground),
                              ),
                            )
                          else
                            ..._readerLayers(
                              context: context,
                              metrics: metrics,
                              controller: controller,
                              state: state,
                              backgroundPreference: backgroundPreference,
                              customBackgroundPreference:
                                  backgroundState.custom,
                            ),
                          ReaderBrightnessOverlay(
                            brightness: _brightness,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _readerLayers({
    required BuildContext context,
    required ReaderPageMetrics metrics,
    required ReaderSessionController controller,
    required ReaderSessionState state,
    required ReaderBackgroundPreference backgroundPreference,
    required ReaderBackgroundPreference? customBackgroundPreference,
  }) {
    final document = state.document;
    final viewport = state.viewport;
    final location = state.location;
    if (document == null || viewport == null || location == null) {
      return [
        Center(
          child: Text('暂无正文', style: TextStyle(color: _palette.foreground)),
        ),
      ];
    }

    final isScrollMode = state.settings.turnMode == ReaderTurnMode.scroll;
    final displayItem = isScrollMode
        ? _chapterItemForLocation(viewport, location)
        : viewport.center;
    final chapter = displayItem.chapter;
    final remainingText = estimateReaderReadingTimeText(chapter.normalizedText);
    final chapterProgress = chapter.textLength <= 0
        ? 0.0
        : (location.offset / chapter.textLength).clamp(0.0, 1.0).toDouble();
    final fontLibraryValue = ref.watch(readerFontLibraryControllerProvider);
    final bookProgress = document.chapterCount <= 0
        ? 0.0
        : ((location.chapterIndex + chapterProgress) / document.chapterCount)
            .clamp(0.0, 1.0)
            .toDouble();
    final pageLabel = isScrollMode
        ? chapter.title
        : '${chapter.title} · ${_pageIndexFor(state) + 1}/'
            '${viewport.currentLayout.pages.length}';
    return [
      Positioned.fill(
        child: ReaderViewport(
          state: state,
          palette: _palette,
          backgroundPreference: backgroundPreference,
          controlsVisible: _overlayMode != ReaderOverlayMode.hidden,
          source: controller.source,
          layoutEngine: controller.viewportController.layoutEngine,
          viewportSize: controller.viewportSize,
          chapterCount: document.chapterCount,
          externalPageTurnRequestId: _volumePageTurnRequestId,
          externalPageTurnDirection: _volumePageTurnDirection,
          onContentTap: _toggleOverlay,
          onPreviousBoundary: () => _previousChapter(controller),
          onNextBoundary: () => _nextChapter(controller),
          onLocationChanged: (location) async {
            _sessionTracker.onLocationChanged(location, chapter.textLength);
            if (state.settings.turnMode == ReaderTurnMode.scroll) {
              await controller.reportUserLocation(location);
            } else if (location.chapterIndex != viewport.center.chapter.index) {
              await controller.scrollToLocation(location);
            } else {
              await controller.reportUserLocation(location);
            }
            if (mounted) setState(() {});
          },
        ),
      ),
      ReaderEyeComfortOverlay(
        enabled: _eyeComfortEnhanced,
        palette: _palette,
      ),
      if (_showsSecondaryMenuScrim)
        const Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Color(0x1A000000)),
          ),
        ),
      ReaderProgress(
        metrics: metrics,
        palette: _palette,
        pageLabel: pageLabel,
        progress: chapterProgress,
        hideTimeBattery: _timeBatteryHidden,
        hideChapterProgress: _chapterProgressHidden,
      ),
      ReaderControls(
        mode: _overlayMode,
        bookTitle: document.title,
        chapterLabel: chapter.title,
        chapterTitle: chapter.title,
        progress: bookProgress,
        remainingText: remainingText,
        palette: _palette,
        backgroundPreference: backgroundPreference,
        customBackgroundPreference: customBackgroundPreference,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        paragraphSpacing: _paragraphSpacing,
        pageHorizontalMargin: _pageHorizontalMargin,
        firstLineIndentEnabled: _firstLineIndentEnabled,
        textEnhancementEnabled: _textEnhancementEnabled,
        fontLibraryValue: fontLibraryValue,
        brightness: _brightness,
        followSystemBrightness: _followSystemBrightness,
        eyeComfortEnhanced: _eyeComfortEnhanced,
        timeBatteryHidden: _timeBatteryHidden,
        chapterProgressHidden: _chapterProgressHidden,
        systemStatusBarHidden: _systemStatusBarHidden,
        pageEdgeHidden: _pageEdgeHidden,
        gestureNavigationBlocked: _gestureNavigationBlocked,
        pageTurnMode: state.settings.turnMode,
        volumePageTurnEnabled: _volumePageTurnEnabled,
        isListening: _isListening,
        currentChapterIndex: location.chapterIndex,
        chapterCount: document.chapterCount,
        catalogItems: _catalogItems,
        catalogHasMore: false,
        catalogIsLoadingMore: _catalogLoading,
        onCatalogLoadMore: () => _loadCatalog(document.chapterCount),
        onBack: _leaveReader,
        onClose: () => _setOverlayMode(ReaderOverlayMode.controls),
        onModeChanged: (mode) {
          _setOverlayMode(mode);
          if (mode == ReaderOverlayMode.catalog) {
            _loadCatalog(document.chapterCount);
          }
        },
        onChapterSelected: (chapterIndex) async {
          await controller.jumpToChapter(chapterIndex);
          if (mounted) {
            setState(() => _overlayMode = ReaderOverlayMode.hidden);
          }
        },
        onPreviousChapter: location.chapterIndex <= 0
            ? null
            : () => _previousChapter(controller),
        onNextChapter: location.chapterIndex + 1 >= document.chapterCount
            ? null
            : () => _nextChapter(controller),
        onPaletteChanged: (palette) {
          setState(() => _palette = palette);
          _schedulePreferencesSave();
        },
        onBackgroundChanged: (background) {
          unawaited(
            ref.read(readerBackgroundControllerProvider.notifier).select(
                  background,
                ),
          );
        },
        onCustomBackgroundImport: _importCustomBackground,
        onFontSizeChanged: (value) => _updateFontSize(controller, state, value),
        onLineHeightChanged: (value) =>
            _updateLineHeight(controller, state, value),
        onParagraphSpacingChanged: (value) =>
            _updateParagraphSpacing(controller, state, value),
        onLineParagraphSpacingChanged: (lineHeight, paragraphSpacing) =>
            _updateLineParagraphSpacing(
          controller,
          lineHeight,
          paragraphSpacing,
        ),
        onPageHorizontalMarginChanged: (value) =>
            _updatePageHorizontalMargin(controller, value),
        onFontSelected: (font) {
          ref
              .read(readerFontLibraryControllerProvider.notifier)
              .selectFont(font.familyKey);
        },
        onManageFonts: () => context.push('/settings/typography'),
        onFirstLineIndentChanged: (value) =>
            _updateFirstLineIndent(controller, value),
        onTextEnhancementChanged: (value) =>
            _updateTextEnhancement(controller, value),
        onBrightnessChanged: (value) {
          setState(() {
            _followSystemBrightness = false;
            _brightness = value;
          });
          _schedulePreferencesSave();
        },
        onFollowSystemBrightnessChanged: (value) {
          setState(() {
            _followSystemBrightness = value;
            if (value) {
              _brightness = _brightnessForSystemMode();
            }
          });
          _schedulePreferencesSave();
        },
        onEyeComfortEnhancedChanged: (value) {
          setState(() => _eyeComfortEnhanced = value);
          _schedulePreferencesSave();
        },
        onTimeBatteryHiddenChanged: (value) {
          setState(() => _timeBatteryHidden = value);
          _schedulePreferencesSave();
        },
        onChapterProgressHiddenChanged: (value) {
          setState(() => _chapterProgressHidden = value);
          _schedulePreferencesSave();
        },
        onSystemStatusBarHiddenChanged: (value) {
          _updateSystemStatusBarHidden(value);
        },
        onPageEdgeHiddenChanged: (value) {
          setState(() => _pageEdgeHidden = value);
          _schedulePreferencesSave();
        },
        onGestureNavigationBlockedChanged: (value) {
          setState(() => _gestureNavigationBlocked = value);
          _schedulePreferencesSave();
        },
        onPageTurnModeChanged: (mode) async {
          setState(() => _turnMode = mode);
          _schedulePreferencesSave();
          await controller
              .updateSettings(state.settings.copyWith(turnMode: mode));
          if (mounted) {
            setState(() => _overlayMode = ReaderOverlayMode.hidden);
          }
        },
        onVolumePageTurnChanged: (value) {
          setState(() => _volumePageTurnEnabled = value);
          _schedulePreferencesSave();
        },
        onAddBookmark: () => unawaited(
          _addBookmark(
            bookId: widget.bookId,
            chapter: chapter,
            location: location,
          ),
        ),
        onShareChapter: () => unawaited(
          _shareChapter(
            bookTitle: document.title,
            chapter: chapter,
            location: location,
          ),
        ),
        onFeedback: _openFeedback,
        onUnavailableAction: _showUnavailableAction,
        onListeningChanged: (value) {
          unawaited(_setListening(value));
        },
        speechRate: _readAloudSettings.speechRate,
        timerActive: _readAloudTimerActive,
        onSpeechRateChanged: (rate) => unawaited(_onSpeechRateChanged(rate)),
        onTimerTapped: _toggleReadAloudTimer,
      ),
    ];
  }

  ReaderChapterWindowItem _chapterItemForLocation(
    ReaderViewportState viewport,
    ReaderLocation location,
  ) {
    if (viewport.center.chapter.index == location.chapterIndex) {
      return viewport.center;
    }
    final previous = viewport.previous;
    if (previous != null && previous.chapter.index == location.chapterIndex) {
      return previous;
    }
    final next = viewport.next;
    if (next != null && next.chapter.index == location.chapterIndex) {
      return next;
    }
    return viewport.center;
  }

  int _pageIndexFor(ReaderSessionState state) {
    final pages = state.viewport?.currentLayout.pages ?? const [];
    final location = state.location;
    if (pages.isEmpty || location == null) return 0;
    final page = pages.firstWhere(
      (page) {
        final isLastPage = page.pageIndex == pages.last.pageIndex;
        final startsInPage = location.offset >= page.start.offset;
        final endsInPage = isLastPage
            ? location.offset <= page.end.offset
            : location.offset < page.end.offset;
        return startsInPage && endsInPage;
      },
      orElse: () => pages.last,
    );
    return page.pageIndex;
  }

  Future<void> _previousChapter(ReaderSessionController controller) async {
    await controller.goToPreviousChapter();
    if (mounted) setState(() => _overlayMode = ReaderOverlayMode.hidden);
  }

  Future<void> _nextChapter(ReaderSessionController controller) async {
    await controller.goToNextChapter();
    if (mounted) setState(() => _overlayMode = ReaderOverlayMode.hidden);
  }

  Future<void> _updateFontSize(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    final fontSize = ReaderSettings.clampFontSize(value);
    setState(() => _fontSize = fontSize);
    _schedulePreferencesSave();
    await controller.updateSettings(
      state.settings.copyWith(
        fontSize: _scaledTextSize(fontSize),
        paragraphSpacing: _scaledParagraphSpacing(_paragraphSpacing),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateParagraphSpacing(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    final paragraphSpacing = ReaderSettings.clampParagraphSpacing(value);
    setState(() => _paragraphSpacing = paragraphSpacing);
    _schedulePreferencesSave();
    await controller.updateSettings(
      state.settings.copyWith(
        paragraphSpacing: _scaledParagraphSpacing(paragraphSpacing),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateLineParagraphSpacing(
    ReaderSessionController controller,
    double lineHeight,
    double paragraphSpacing,
  ) async {
    final clampedParagraphSpacing =
        ReaderSettings.clampParagraphSpacing(paragraphSpacing);
    setState(() {
      _lineHeight = lineHeight;
      _paragraphSpacing = clampedParagraphSpacing;
    });
    _schedulePreferencesSave();
    await controller.updateSettings(
      controller.state.settings.copyWith(
        lineHeight: lineHeight,
        paragraphSpacing: _scaledParagraphSpacing(clampedParagraphSpacing),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateLineHeight(
    ReaderSessionController controller,
    ReaderSessionState state,
    double value,
  ) async {
    setState(() => _lineHeight = value);
    _schedulePreferencesSave();
    await controller.updateSettings(state.settings.copyWith(lineHeight: value));
    if (mounted) setState(() {});
  }

  Future<void> _updatePageHorizontalMargin(
    ReaderSessionController controller,
    double value,
  ) async {
    final pageHorizontalMargin =
        ReaderSettings.clampPageHorizontalMargin(value);
    setState(() => _pageHorizontalMargin = pageHorizontalMargin);
    _schedulePreferencesSave();
    await controller.updateSettings(
      controller.state.settings.copyWith(
        pagePadding: _pagePaddingWithHorizontalMargin(pageHorizontalMargin),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateFirstLineIndent(
    ReaderSessionController controller,
    bool value,
  ) async {
    setState(() => _firstLineIndentEnabled = value);
    _schedulePreferencesSave();
    await controller.updateSettings(
      controller.state.settings.copyWith(firstLineIndentEnabled: value),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateTextEnhancement(
    ReaderSessionController controller,
    bool value,
  ) async {
    setState(() => _textEnhancementEnabled = value);
    _schedulePreferencesSave();
    await controller.updateSettings(
      controller.state.settings.copyWith(textEnhancementEnabled: value),
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadCatalog(int chapterCount) async {
    if (_catalogLoading || _catalogItems.isNotEmpty) return;
    setState(() => _catalogLoading = true);
    try {
      final page =
          await ref.read(readerDocumentSourceProvider).loadChapterMetas(
                bookId: widget.bookId,
                offset: 0,
                limit: chapterCount == 0 ? _catalogPageSize : chapterCount,
              );
      if (!mounted) return;
      setState(() {
        _catalogItems = [
          for (final item in page.items)
            ReaderCatalogItem(
              chapterIndex: item.index,
              title: item.title,
              subtitle: item.normalizedContentLength > 0
                  ? '约 ${item.normalizedContentLength} 字'
                  : '章节 ${item.index + 1}',
            ),
        ];
      });
    } finally {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  void _toggleOverlay() {
    _setOverlayMode(
      _overlayMode == ReaderOverlayMode.hidden
          ? ReaderOverlayMode.controls
          : ReaderOverlayMode.hidden,
    );
  }

  void _setOverlayMode(ReaderOverlayMode mode) {
    if (_overlayMode == mode) return;
    setState(() => _overlayMode = mode);
  }

  bool get _showsSecondaryMenuScrim {
    switch (_overlayMode) {
      case ReaderOverlayMode.typography:
      case ReaderOverlayMode.theme:
      case ReaderOverlayMode.listening:
      case ReaderOverlayMode.more:
      case ReaderOverlayMode.pageTurn:
        return true;
      case ReaderOverlayMode.hidden:
      case ReaderOverlayMode.controls:
      case ReaderOverlayMode.catalog:
        return false;
    }
  }

  void _requestVolumePageTurn(int direction) {
    if (!_volumePageTurnEnabled ||
        _overlayMode != ReaderOverlayMode.hidden ||
        direction == 0) {
      return;
    }
    setState(() {
      _volumePageTurnDirection = direction;
      _volumePageTurnRequestId++;
    });
  }

  ReaderSettings _initialSettings(
    Size size,
    EdgeInsets safePadding,
    String fontFamily,
  ) {
    final metrics = ReaderPageMetrics.fromSize(size);
    return ReaderSettings.defaults().copyWith(
      paletteId: _palette.id,
      fontFamily: fontFamily,
      fontSize: metrics.s(_fontSize),
      lineHeight: _lineHeight,
      turnMode: _turnMode,
      paragraphSpacing: metrics.s(_paragraphSpacing),
      pagePadding: _pagePaddingWithHorizontalMargin(
        _pageHorizontalMargin,
        size: size,
        safePadding: safePadding,
      ),
      firstLineIndentEnabled: _firstLineIndentEnabled,
      textEnhancementEnabled: _textEnhancementEnabled,
    );
  }

  ReaderInsets _readerContentInsets(Size size, EdgeInsets safePadding) {
    return ReaderChromeLayout.fromSize(size, safePadding).contentInsets;
  }

  EdgeInsets _readerSafePadding(BuildContext context) {
    // 隐藏系统状态栏只隐藏系统图标，不允许正文进入挖孔、刘海等顶部安全区域。
    return MediaQuery.viewPaddingOf(context);
  }

  double _scaledTextSize(double value) {
    final size = _lastViewportSize;
    if (size == null) return value;
    return ReaderPageMetrics.fromSize(size).s(value);
  }

  double _scaledParagraphSpacing(double paragraphSpacing) {
    final size = _lastViewportSize;
    if (size == null) return paragraphSpacing;
    return ReaderPageMetrics.fromSize(size).s(paragraphSpacing);
  }

  ReaderInsets _pagePaddingWithHorizontalMargin(
    double pageHorizontalMargin, {
    Size? size,
    EdgeInsets? safePadding,
  }) {
    final effectiveSize = size ?? _lastViewportSize;
    final effectivePadding = safePadding ?? _lastViewportPadding;
    if (effectiveSize == null || effectivePadding == null) {
      return ReaderSettings.defaults().pagePadding.copyWith(
            left: pageHorizontalMargin,
            right: pageHorizontalMargin,
          );
    }
    final baseInsets = _readerContentInsets(effectiveSize, effectivePadding);
    final delta = ReaderPageMetrics.fromSize(effectiveSize).s(
      pageHorizontalMargin - ReaderSettings.defaultPageHorizontalMargin,
    );
    return baseInsets.copyWith(
      left:
          (baseInsets.left + delta).clamp(0.0, effectiveSize.width).toDouble(),
      right:
          (baseInsets.right + delta).clamp(0.0, effectiveSize.width).toDouble(),
    );
  }

  void _ensureController(
    Size size,
    EdgeInsets safePadding,
    String fontFamily,
  ) {
    final existingController = _controller;
    if (existingController != null) {
      if (_lastViewportSize == size && _lastViewportPadding == safePadding) {
        _syncSelectedFontFamily(fontFamily);
        return;
      }
      if (_lastViewportSize == size) {
        _lastViewportPadding = safePadding;
        _syncSelectedFontFamily(fontFamily);
        _syncPagePadding(existingController, size, safePadding);
        return;
      }
    }
    _lastViewportSize = size;
    _lastViewportPadding = safePadding;
    _lastSelectedFontFamily = fontFamily;
    final source = ref.read(readerDocumentSourceProvider);
    final progressRepository = ref.read(readerProgressRepositoryProvider);
    final viewportController = ReaderViewportController(
      source: source,
      layoutEngine: const FlutterReaderLayoutEngine(),
      layoutCache: _layoutCache,
    );
    final controller = ReaderSessionController(
      bookId: widget.bookId,
      source: source,
      viewportController: viewportController,
      progressRepository: progressRepository,
      initialSettings: _initialSettings(size, safePadding, fontFamily),
      viewportSize: size,
      onStateChanged: _scheduleControllerRefresh,
    );
    _controller = controller;
    _initialization = controller.initialize().then((_) async {
      if (controller.state.loadStatus == ReaderLoadStatus.ready) {
        _startReadingSession();
      }
      if (widget.initialChapterIndex <= 0 && widget.initialOffset <= 0) return;
      await controller.scrollToLocation(
        ReaderLocation(
          bookId: widget.bookId,
          chapterIndex: widget.initialChapterIndex,
          offset: widget.initialOffset,
        ),
      );
    });
  }

  void _syncSelectedFontFamily(String fontFamily) {
    if (_lastSelectedFontFamily == fontFamily) return;
    _lastSelectedFontFamily = fontFamily;
    final controller = _controller;
    if (controller == null) return;
    unawaited(
      controller.updateSettings(
        controller.state.settings.copyWith(fontFamily: fontFamily),
      ),
    );
  }

  void _syncSystemUiMode() {
    if (_systemStatusBarHidden) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
  }

  void _updateSystemStatusBarHidden(bool value) {
    if (_systemStatusBarHidden == value) return;
    setState(() => _systemStatusBarHidden = value);
    _syncSystemUiMode();
    _schedulePreferencesSave();
  }

  Future<void> _addBookmark({
    required String bookId,
    required ReaderChapter chapter,
    required ReaderLocation location,
  }) async {
    final now = DateTime.now();
    final position = ReaderLocation(
      bookId: bookId,
      chapterIndex: location.chapterIndex,
      offset: location.offset,
    );
    final annotation = ReaderAnnotation(
      id: 'bookmark-${now.microsecondsSinceEpoch}',
      bookId: bookId,
      range: ReaderRange(start: position, end: position),
      type: ReaderAnnotationType.bookmark,
      preview: _bookmarkPreview(chapter.normalizedText, location.offset),
      createdAt: now,
    );

    try {
      await ref
          .read(readerAnnotationRepositoryProvider)
          .saveAnnotation(annotation);
    } catch (error) {
      if (!mounted) return;
      _showReaderMessage('加入书签失败：$error');
      return;
    }
    if (!mounted) return;
    _setOverlayMode(ReaderOverlayMode.hidden);
    _showReaderMessage('已加入书签');
  }

  String _bookmarkPreview(String text, int offset) =>
      _textSnippet(text, offset, maxLength: 80);

  /// A single-line excerpt starting at [offset], falling back to the chapter
  /// head when the offset sits on whitespace.
  String _textSnippet(String text, int offset, {required int maxLength}) {
    if (text.isEmpty) return '';
    final start = offset.clamp(0, text.length);
    final end = (start + maxLength).clamp(start, text.length);
    final snippet =
        text.substring(start, end).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (snippet.isNotEmpty) return snippet;

    final head = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return head.length <= maxLength ? head : head.substring(0, maxLength);
  }

  Future<void> _shareChapter({
    required String bookTitle,
    required ReaderChapter chapter,
    required ReaderLocation location,
  }) async {
    _setOverlayMode(ReaderOverlayMode.hidden);
    final snippet =
        _textSnippet(chapter.normalizedText, location.offset, maxLength: 220);
    final header = '《$bookTitle》· ${chapter.title}';
    final text = snippet.isEmpty ? header : '$header\n\n$snippet';
    try {
      await Share.share(text);
    } catch (error) {
      if (!mounted) return;
      _showReaderMessage('分享失败：$error');
    }
  }

  void _openFeedback() {
    _setOverlayMode(ReaderOverlayMode.hidden);
    context.push(AppRoutes.aboutFeedback);
  }

  void _showUnavailableAction(String label) {
    _setOverlayMode(ReaderOverlayMode.hidden);
    _showReaderMessage('$label将在后续版本提供');
  }

  void _showReaderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importCustomBackground() async {
    try {
      await ref
          .read(readerBackgroundControllerProvider.notifier)
          .importCustom();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.startsWith('Exception: ')
                ? message.replaceFirst('Exception: ', '')
                : message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _leaveReader() {
    if (_allowRoutePop) {
      context.pop();
      return;
    }
    setState(() => _allowRoutePop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  void _syncPagePadding(
    ReaderSessionController controller,
    Size size,
    EdgeInsets safePadding,
  ) {
    unawaited(
      controller.updateSettings(
        controller.state.settings.copyWith(
          pagePadding: _pagePaddingWithHorizontalMargin(
            _pageHorizontalMargin,
            size: size,
            safePadding: safePadding,
          ),
        ),
      ),
    );
  }

  double _brightnessForSystemMode() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark
        ? _systemDarkBrightness
        : _systemLightBrightness;
  }

  void _scheduleControllerRefresh() {
    if (_controllerRefreshScheduled) return;
    _controllerRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerRefreshScheduled = false;
      if (mounted) setState(() {});
    });
  }
}

class _ReaderLoadingBar extends StatelessWidget {
  const _ReaderLoadingBar({
    required this.palette,
    required this.width,
  });

  final ReaderPalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '阅读器加载中',
      child: SizedBox(
        width: width.clamp(96.0, 136.0),
        height: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            color: palette.accent,
            backgroundColor: palette.foreground.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
