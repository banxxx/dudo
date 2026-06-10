part of '../../reader_controls.dart';

// 主题面板容器：只保留整体布局和共享色值，具体区块拆分到 models / sections / widgets。

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({
    required this.metrics,
    required this.palette,
    required this.brightness,
    required this.followSystemBrightness,
    required this.eyeComfortEnhanced,
    required this.timeBatteryHidden,
    required this.chapterProgressHidden,
    required this.systemStatusBarHidden,
    required this.pageEdgeHidden,
    required this.gestureNavigationBlocked,
    required this.onPaletteChanged,
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
  final double brightness;
  final bool followSystemBrightness;
  final bool eyeComfortEnhanced;
  final bool timeBatteryHidden;
  final bool chapterProgressHidden;
  final bool systemStatusBarHidden;
  final bool pageEdgeHidden;
  final bool gestureNavigationBlocked;
  final ValueChanged<ReaderPalette> onPaletteChanged;
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
    return _FloatingPanel(
      key: const ValueKey('reader-theme-panel'),
      metrics: metrics,
      top: 378,
      height: _panelHeight,
      palette: palette,
      padding: EdgeInsets.all(metrics.s(16)),
      child: Column(
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
                    onPaletteChanged: onPaletteChanged,
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
      ),
    );
  }
}
