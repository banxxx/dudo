part of '../../reader_controls.dart';

class _PageTurnPanel extends StatefulWidget {
  const _PageTurnPanel({
    required this.metrics,
    required this.palette,
    required this.selectedMode,
    required this.volumePageTurnEnabled,
    required this.onModeChanged,
    required this.onVolumePageTurnChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderTurnMode selectedMode;
  final bool volumePageTurnEnabled;
  final ValueChanged<ReaderTurnMode> onModeChanged;
  final ValueChanged<bool> onVolumePageTurnChanged;

  @override
  State<_PageTurnPanel> createState() => _PageTurnPanelState();
}

class _PageTurnPanelState extends State<_PageTurnPanel> {
  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final modes = <_PageTurnModeData>[
      const _PageTurnModeData(
        mode: ReaderTurnMode.simulated,
        icon: LucideIcons.bookOpen,
      ),
      const _PageTurnModeData(
        mode: ReaderTurnMode.cover,
        icon: LucideIcons.layers,
      ),
      const _PageTurnModeData(
        mode: ReaderTurnMode.slide,
        icon: LucideIcons.moveHorizontal,
      ),
      const _PageTurnModeData(
        mode: ReaderTurnMode.scroll,
        icon: LucideIcons.scrollText,
      ),
      const _PageTurnModeData(
        mode: ReaderTurnMode.paged,
        icon: LucideIcons.ban,
      ),
    ];
    return _FloatingPanel(
      key: const ValueKey('reader-page-turn-panel'),
      metrics: widget.metrics,
      top: 474,
      height: 206,
      padding: EdgeInsets.all(metrics.s(16)),
      palette: widget.palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('翻页方式',
              style: DudoTextStyles.serif(
                  color: context.readerControls.text.primary,
                  fontSize: metrics.s(22),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: metrics.s(12)),
          SizedBox(
            height: metrics.s(76),
            child: Row(
              children: [
                for (var i = 0; i < modes.length; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(6)),
                  _PageTurnModeCard(
                    metrics: metrics,
                    data: modes[i],
                    selected: modes[i].mode == widget.selectedMode,
                    onTap: () => widget.onModeChanged(modes[i].mode),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: metrics.s(12)),
          _VolumePageTurnRow(
            metrics: metrics,
            enabled: widget.volumePageTurnEnabled,
            onChanged: widget.onVolumePageTurnChanged,
          ),
        ],
      ),
    );
  }
}

class _PageTurnModeData {
  const _PageTurnModeData({
    required this.mode,
    required this.icon,
  });

  final ReaderTurnMode mode;
  final IconData icon;
}

class _PageTurnModeCard extends StatelessWidget {
  const _PageTurnModeCard({
    required this.metrics,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final _PageTurnModeData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? context.readerControls.action.accentSoft
        : context.readerControls.surface.panelHigh;
    final borderColor = selected
        ? context.readerControls.action.accent
        : context.readerControls.surface.outline;
    final iconColor = selected
        ? context.readerControls.action.accent
        : context.readerControls.text.secondary;
    final labelColor = selected
        ? context.readerControls.text.accentText
        : context.readerControls.text.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: metrics.s(60),
        height: metrics.s(76),
        child: Container(
          padding: EdgeInsets.only(
            top: metrics.s(12),
            left: metrics.s(8),
            right: metrics.s(8),
            bottom: metrics.s(10),
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(metrics.s(18)),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(data.icon, size: metrics.s(18), color: iconColor),
              SizedBox(height: metrics.s(8)),
              Text(
                data.mode.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: DudoTextStyles.sans(
                  color: labelColor,
                  fontSize:
                      metrics.s(data.mode == ReaderTurnMode.paged ? 11.5 : 12),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ReaderTurnModeLabel on ReaderTurnMode {
  String get label {
    return switch (this) {
      ReaderTurnMode.simulated => '仿真',
      ReaderTurnMode.cover => '覆盖',
      ReaderTurnMode.slide => '滑动',
      ReaderTurnMode.scroll => '滚动',
      ReaderTurnMode.paged => '无动画',
    };
  }
}

class _VolumePageTurnRow extends StatelessWidget {
  const _VolumePageTurnRow({
    required this.metrics,
    required this.enabled,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.s(42),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '音量翻页',
                  style: DudoTextStyles.sans(
                    color: context.readerControls.text.primary,
                    fontSize: metrics.s(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: metrics.s(4)),
                Text(
                  '使用音量键切换上一页 / 下一页',
                  style: DudoTextStyles.sans(
                    color: context.readerControls.text.secondary,
                    fontSize: metrics.s(11),
                  ),
                ),
              ],
            ),
          ),
          _VolumePageTurnSwitch(
            metrics: metrics,
            enabled: enabled,
            onTap: () => onChanged(!enabled),
          ),
        ],
      ),
    );
  }
}

class _VolumePageTurnSwitch extends StatelessWidget {
  const _VolumePageTurnSwitch({
    required this.metrics,
    required this.enabled,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: metrics.s(54),
        height: metrics.s(30),
        padding: EdgeInsets.all(metrics.s(3)),
        decoration: BoxDecoration(
          color: enabled
              ? context.readerControls.action.accent
              : context.readerControls.surface.outline,
          borderRadius: BorderRadius.circular(metrics.s(15)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: metrics.s(24),
            height: metrics.s(24),
            decoration: BoxDecoration(
              color: context.readerControls.surface.panel,
              borderRadius: BorderRadius.circular(metrics.s(12)),
              boxShadow: [
                BoxShadow(
                  color: context.readerControls.surface.shadow,
                  blurRadius: metrics.s(5),
                  offset: Offset(0, metrics.s(2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
