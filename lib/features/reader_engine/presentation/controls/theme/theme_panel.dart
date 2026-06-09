part of '../../reader_controls.dart';

// 主题面板容器：只保留整体布局和共享色值，具体区块拆分到 models / sections / widgets。

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({
    required this.metrics,
    required this.palette,
    required this.brightness,
    required this.onPaletteChanged,
    required this.onBrightnessChanged,
  });

  static const _panelHeight = 360.0;

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final double brightness;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<double> onBrightnessChanged;

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
                    onBrightnessChanged: onBrightnessChanged,
                  ),
                  SizedBox(height: metrics.s(12)),
                  _ThemeToggleGroup(
                    metrics: metrics,
                    icon: LucideIcons.eyeOff,
                    title: '界面显示',
                    rows: const [
                      _ThemeToggleRowData(
                        title: '隐藏时间电量',
                        description: '阅读时隐藏顶部时间、电量与信号',
                        enabled: true,
                      ),
                      _ThemeToggleRowData(
                        title: '隐藏章节进度',
                        description: '不显示底部章节名和阅读进度',
                        enabled: false,
                      ),
                      _ThemeToggleRowData(
                        title: '隐藏系统状态栏',
                        description: '进入沉浸阅读时收起系统状态栏',
                        enabled: true,
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.s(12)),
                  _ThemeToggleGroup(
                    metrics: metrics,
                    icon: LucideIcons.hand,
                    title: '手势控制',
                    rows: const [
                      _ThemeToggleRowData(
                        title: '屏蔽手势导航键',
                        description: '降低误触返回、主页等系统手势概率',
                        enabled: false,
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
