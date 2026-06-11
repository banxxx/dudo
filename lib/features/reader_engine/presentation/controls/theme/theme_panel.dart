part of '../../reader_controls.dart';

// 主题面板容器：只保留整体布局和共享色值，具体区块拆分到 models / sections / widgets。

class _ThemePanel extends StatefulWidget {
  const _ThemePanel({
    required this.metrics,
    required this.palette,
    required this.backgroundPreference,
    required this.customBackgroundPreference,
    required this.brightness,
    required this.followSystemBrightness,
    required this.eyeComfortEnhanced,
    required this.timeBatteryHidden,
    required this.chapterProgressHidden,
    required this.systemStatusBarHidden,
    required this.pageEdgeHidden,
    required this.gestureNavigationBlocked,
    required this.onPaletteChanged,
    required this.onBackgroundChanged,
    required this.onCustomBackgroundImport,
    required this.onBrightnessChanged,
    required this.onFollowSystemBrightnessChanged,
    required this.onEyeComfortEnhancedChanged,
    required this.onTimeBatteryHiddenChanged,
    required this.onChapterProgressHiddenChanged,
    required this.onSystemStatusBarHiddenChanged,
    required this.onPageEdgeHiddenChanged,
    required this.onGestureNavigationBlockedChanged,
  });

  static const _panelHeight = 360.0;

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference backgroundPreference;
  final ReaderBackgroundPreference? customBackgroundPreference;
  final double brightness;
  final bool followSystemBrightness;
  final bool eyeComfortEnhanced;
  final bool timeBatteryHidden;
  final bool chapterProgressHidden;
  final bool systemStatusBarHidden;
  final bool pageEdgeHidden;
  final bool gestureNavigationBlocked;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<ReaderBackgroundPreference> onBackgroundChanged;
  final Future<void> Function() onCustomBackgroundImport;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onFollowSystemBrightnessChanged;
  final ValueChanged<bool> onEyeComfortEnhancedChanged;
  final ValueChanged<bool> onTimeBatteryHiddenChanged;
  final ValueChanged<bool> onChapterProgressHiddenChanged;
  final ValueChanged<bool> onSystemStatusBarHiddenChanged;
  final ValueChanged<bool> onPageEdgeHiddenChanged;
  final ValueChanged<bool> onGestureNavigationBlockedChanged;

  @override
  State<_ThemePanel> createState() => _ThemePanelState();
}

class _ThemePanelState extends State<_ThemePanel> {
  static const _panelHeight = _ThemePanel._panelHeight;

  bool _showCustomBackgroundPage = false;

  @override
  void didUpdateWidget(covariant _ThemePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundPreference.type != ReaderBackgroundType.customImage &&
        _showCustomBackgroundPage) {
      _showCustomBackgroundPage = false;
    }
  }

  void _openCustomBackgroundPage() {
    setState(() {
      _showCustomBackgroundPage = true;
    });
  }

  void _closeCustomBackgroundPage() {
    setState(() {
      _showCustomBackgroundPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingPanel(
      key: const ValueKey('reader-theme-panel'),
      metrics: widget.metrics,
      top: 378,
      height: _panelHeight,
      palette: widget.palette,
      padding: EdgeInsets.all(widget.metrics.s(16)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: _showCustomBackgroundPage
            ? _CustomBackgroundSettingsPage(
                key: const ValueKey('reader-custom-background-settings-page'),
                metrics: widget.metrics,
                palette: widget.palette,
                preference: widget.backgroundPreference,
                onBack: _closeCustomBackgroundPage,
                onChangeImage: widget.onCustomBackgroundImport,
                onChanged: widget.onBackgroundChanged,
                onApply: _closeCustomBackgroundPage,
              )
            : _ThemePanelHome(
                key: const ValueKey('reader-theme-panel-home'),
                metrics: widget.metrics,
                palette: widget.palette,
                backgroundPreference: widget.backgroundPreference,
                customBackgroundPreference: widget.customBackgroundPreference,
                brightness: widget.brightness,
                followSystemBrightness: widget.followSystemBrightness,
                eyeComfortEnhanced: widget.eyeComfortEnhanced,
                timeBatteryHidden: widget.timeBatteryHidden,
                chapterProgressHidden: widget.chapterProgressHidden,
                systemStatusBarHidden: widget.systemStatusBarHidden,
                pageEdgeHidden: widget.pageEdgeHidden,
                gestureNavigationBlocked: widget.gestureNavigationBlocked,
                onPaletteChanged: widget.onPaletteChanged,
                onBackgroundChanged: widget.onBackgroundChanged,
                onCustomBackgroundImport: widget.onCustomBackgroundImport,
                onCustomBackgroundEdit: _openCustomBackgroundPage,
                onBrightnessChanged: widget.onBrightnessChanged,
                onFollowSystemBrightnessChanged:
                    widget.onFollowSystemBrightnessChanged,
                onEyeComfortEnhancedChanged: widget.onEyeComfortEnhancedChanged,
                onTimeBatteryHiddenChanged: widget.onTimeBatteryHiddenChanged,
                onChapterProgressHiddenChanged:
                    widget.onChapterProgressHiddenChanged,
                onSystemStatusBarHiddenChanged:
                    widget.onSystemStatusBarHiddenChanged,
                onPageEdgeHiddenChanged: widget.onPageEdgeHiddenChanged,
                onGestureNavigationBlockedChanged:
                    widget.onGestureNavigationBlockedChanged,
              ),
      ),
    );
  }
}

class _ThemePanelHome extends StatelessWidget {
  const _ThemePanelHome({
    super.key,
    required this.metrics,
    required this.palette,
    required this.backgroundPreference,
    required this.customBackgroundPreference,
    required this.brightness,
    required this.followSystemBrightness,
    required this.eyeComfortEnhanced,
    required this.timeBatteryHidden,
    required this.chapterProgressHidden,
    required this.systemStatusBarHidden,
    required this.pageEdgeHidden,
    required this.gestureNavigationBlocked,
    required this.onPaletteChanged,
    required this.onBackgroundChanged,
    required this.onCustomBackgroundImport,
    required this.onCustomBackgroundEdit,
    required this.onBrightnessChanged,
    required this.onFollowSystemBrightnessChanged,
    required this.onEyeComfortEnhancedChanged,
    required this.onTimeBatteryHiddenChanged,
    required this.onChapterProgressHiddenChanged,
    required this.onSystemStatusBarHiddenChanged,
    required this.onPageEdgeHiddenChanged,
    required this.onGestureNavigationBlockedChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference backgroundPreference;
  final ReaderBackgroundPreference? customBackgroundPreference;
  final double brightness;
  final bool followSystemBrightness;
  final bool eyeComfortEnhanced;
  final bool timeBatteryHidden;
  final bool chapterProgressHidden;
  final bool systemStatusBarHidden;
  final bool pageEdgeHidden;
  final bool gestureNavigationBlocked;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<ReaderBackgroundPreference> onBackgroundChanged;
  final Future<void> Function() onCustomBackgroundImport;
  final VoidCallback onCustomBackgroundEdit;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onFollowSystemBrightnessChanged;
  final ValueChanged<bool> onEyeComfortEnhancedChanged;
  final ValueChanged<bool> onTimeBatteryHiddenChanged;
  final ValueChanged<bool> onChapterProgressHiddenChanged;
  final ValueChanged<bool> onSystemStatusBarHiddenChanged;
  final ValueChanged<bool> onPageEdgeHiddenChanged;
  final ValueChanged<bool> onGestureNavigationBlockedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: metrics.s(34),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '阅读主题',
              style: DudoTextStyles.serif(
                color: context.readerControls.themePicker.ink,
                fontSize: metrics.s(22),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: metrics.s(12)),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemeStyleGroup(
                  metrics: metrics,
                  palette: palette,
                  backgroundPreference: backgroundPreference,
                  customBackgroundPreference: customBackgroundPreference,
                  onPaletteChanged: onPaletteChanged,
                  onBackgroundChanged: onBackgroundChanged,
                  onCustomBackgroundImport: onCustomBackgroundImport,
                  onCustomBackgroundEdit: onCustomBackgroundEdit,
                ),
                SizedBox(height: metrics.s(12)),
                _BrightnessEyeGroup(
                  metrics: metrics,
                  brightness: brightness,
                  followSystemBrightness: followSystemBrightness,
                  eyeComfortEnhanced: eyeComfortEnhanced,
                  onBrightnessChanged: onBrightnessChanged,
                  onFollowSystemBrightnessChanged:
                      onFollowSystemBrightnessChanged,
                  onEyeComfortEnhancedChanged: onEyeComfortEnhancedChanged,
                ),
                SizedBox(height: metrics.s(12)),
                _ThemeToggleGroup(
                  metrics: metrics,
                  icon: LucideIcons.eyeOff,
                  title: '界面显示',
                  rows: [
                    _ThemeToggleRowData(
                      title: '隐藏时间电量',
                      description: '阅读时隐藏底部时间与电量',
                      enabled: timeBatteryHidden,
                      onChanged: onTimeBatteryHiddenChanged,
                    ),
                    _ThemeToggleRowData(
                      title: '隐藏章节进度',
                      description: '不显示底部章节名和阅读进度',
                      enabled: chapterProgressHidden,
                      onChanged: onChapterProgressHiddenChanged,
                    ),
                    _ThemeToggleRowData(
                      title: '隐藏系统状态栏',
                      description: '关闭后正文会避开顶部系统状态栏',
                      enabled: systemStatusBarHidden,
                      onChanged: onSystemStatusBarHiddenChanged,
                    ),
                    _ThemeToggleRowData(
                      title: '隐藏页边线',
                      description: '隐藏正文左侧的页面边缘装饰线',
                      enabled: pageEdgeHidden,
                      onChanged: onPageEdgeHiddenChanged,
                    ),
                  ],
                ),
                SizedBox(height: metrics.s(12)),
                _ThemeToggleGroup(
                  metrics: metrics,
                  icon: LucideIcons.hand,
                  title: '手势控制',
                  rows: [
                    _ThemeToggleRowData(
                      title: '屏蔽手势导航键',
                      description: '阻止边缘返回手势退出阅读页',
                      enabled: gestureNavigationBlocked,
                      onChanged: onGestureNavigationBlockedChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
