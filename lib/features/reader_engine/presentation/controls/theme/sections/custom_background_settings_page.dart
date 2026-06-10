part of '../../../reader_controls.dart';

class _CustomBackgroundSettingsPage extends StatelessWidget {
  const _CustomBackgroundSettingsPage({
    super.key,
    required this.metrics,
    required this.palette,
    required this.preference,
    required this.onBack,
    required this.onChangeImage,
    required this.onChanged,
    required this.onApply,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference preference;
  final VoidCallback onBack;
  final Future<void> Function() onChangeImage;
  final ValueChanged<ReaderBackgroundPreference> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: metrics.s(44),
          child: Row(
            children: [
              _CustomBackgroundIconButton(
                metrics: metrics,
                icon: LucideIcons.chevronLeft,
                onTap: onBack,
              ),
              SizedBox(width: metrics.s(10)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自定义图片背景',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: picker.ink,
                        fontSize: metrics.s(19),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '阅读背景 / 图片设置',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: picker.muted,
                        fontSize: metrics.s(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: metrics.s(10)),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomBackgroundSummaryRow(
                  metrics: metrics,
                  preference: preference,
                  onChangeImage: onChangeImage,
                ),
                SizedBox(height: metrics.s(12)),
                _CustomBackgroundCropPreview(
                  metrics: metrics,
                  palette: palette,
                  preference: preference,
                ),
                SizedBox(height: metrics.s(12)),
                _CustomBackgroundDisplayModeSection(
                  metrics: metrics,
                  preference: preference,
                  onChanged: onChanged,
                ),
                SizedBox(height: metrics.s(12)),
                _CustomBackgroundDisplayAreaSection(
                  metrics: metrics,
                  preference: preference,
                  onChanged: onChanged,
                ),
                SizedBox(height: metrics.s(12)),
                _CustomBackgroundEffectSection(
                  metrics: metrics,
                  preference: preference,
                  onChanged: onChanged,
                ),
                SizedBox(height: metrics.s(12)),
                _CustomBackgroundApplyButton(
                  metrics: metrics,
                  onTap: onApply,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomBackgroundIconButton extends StatelessWidget {
  const _CustomBackgroundIconButton({
    required this.metrics,
    required this.icon,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(17)),
        onTap: onTap,
        child: Ink(
          width: metrics.s(34),
          height: metrics.s(34),
          decoration: BoxDecoration(
            color: picker.paper,
            borderRadius: BorderRadius.circular(metrics.s(17)),
            border: Border.all(color: picker.surfaceLine, width: metrics.s(1)),
          ),
          child: Icon(icon, size: metrics.s(18), color: picker.muted),
        ),
      ),
    );
  }
}

class _CustomBackgroundSummaryRow extends StatelessWidget {
  const _CustomBackgroundSummaryRow({
    required this.metrics,
    required this.preference,
    required this.onChangeImage,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderBackgroundPreference preference;
  final Future<void> Function() onChangeImage;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Container(
      height: metrics.s(56),
      padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
      decoration: BoxDecoration(
        color: picker.greenSoft,
        borderRadius: BorderRadius.circular(metrics.s(20)),
      ),
      child: Row(
        children: [
          Container(
            width: metrics.s(36),
            height: metrics.s(36),
            decoration: BoxDecoration(
              color: picker.panel,
              borderRadius: BorderRadius.circular(metrics.s(18)),
            ),
            child: Icon(
              LucideIcons.image,
              size: metrics.s(18),
              color: picker.green,
            ),
          ),
          SizedBox(width: metrics.s(10)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _backgroundName(preference),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: picker.ink,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_fitLabel(preference.fit)} · ${_alignmentLabel(preference.alignment)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: picker.muted,
                    fontSize: metrics.s(10),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.s(10)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(metrics.s(14)),
              onTap: () {
                onChangeImage();
              },
              child: Ink(
                width: metrics.s(46),
                height: metrics.s(28),
                decoration: BoxDecoration(
                  color: picker.panel,
                  borderRadius: BorderRadius.circular(metrics.s(14)),
                ),
                child: Center(
                  child: Text(
                    '更换',
                    style: DudoTextStyles.sans(
                      color: picker.green,
                      fontSize: metrics.s(11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBackgroundCropPreview extends StatelessWidget {
  const _CustomBackgroundCropPreview({
    required this.metrics,
    required this.palette,
    required this.preference,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference preference;

  @override
  Widget build(BuildContext context) {
    final cropWidth = metrics.s(126);
    final sideMask = metrics.s(100);
    return ClipRRect(
      borderRadius: BorderRadius.circular(metrics.s(24)),
      child: SizedBox(
        height: metrics.s(196),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ReaderBackgroundLayer(
              palette: palette,
              background: preference,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: sideMask,
              child: ColoredBox(
                color: context.readerControls.themePicker.ink
                    .withValues(alpha: 0.44),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sideMask,
              child: ColoredBox(
                color: context.readerControls.themePicker.ink
                    .withValues(alpha: 0.44),
              ),
            ),
            Center(
              child: Container(
                width: cropWidth,
                height: metrics.s(164),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(metrics.s(18)),
                  border: Border.all(
                    color: const Color(0xFFFFF8EA),
                    width: metrics.s(2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: sideMask + metrics.s(20),
              top: metrics.s(46),
              width: metrics.s(86),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CustomPreviewLine(metrics: metrics, width: 78),
                  SizedBox(height: metrics.s(7)),
                  _CustomPreviewLine(metrics: metrics, width: 64),
                  SizedBox(height: metrics.s(7)),
                  _CustomPreviewLine(metrics: metrics, width: 84),
                  SizedBox(height: metrics.s(7)),
                  _CustomPreviewLine(metrics: metrics, width: 58),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPreviewLine extends StatelessWidget {
  const _CustomPreviewLine({
    required this.metrics,
    required this.width,
  });

  final _ReaderOverlayMetrics metrics;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.s(width),
      height: metrics.s(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(metrics.s(2)),
      ),
    );
  }
}

class _CustomBackgroundDisplayModeSection extends StatelessWidget {
  const _CustomBackgroundDisplayModeSection({
    required this.metrics,
    required this.preference,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderBackgroundPreference preference;
  final ValueChanged<ReaderBackgroundPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final selected = _modeName(preference.fit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '展示模式',
          style: DudoTextStyles.sans(
            color: picker.ink,
            fontSize: metrics.s(13),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: metrics.s(8)),
        SizedBox(
          height: metrics.s(34),
          child: Row(
            children: [
              _CustomModeChip(
                metrics: metrics,
                label: '裁剪',
                selected: selected == '裁剪',
                onTap: () => onChanged(
                  preference.copyWith(fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: metrics.s(6)),
              _CustomModeChip(
                metrics: metrics,
                label: '适应',
                selected: selected == '适应',
                onTap: () => onChanged(
                  preference.copyWith(fit: BoxFit.contain),
                ),
              ),
              SizedBox(width: metrics.s(6)),
              _CustomModeChip(
                metrics: metrics,
                label: '平铺',
                selected: selected == '平铺',
                onTap: () => onChanged(
                  preference.copyWith(fit: BoxFit.none),
                ),
              ),
              SizedBox(width: metrics.s(6)),
              _CustomModeChip(
                metrics: metrics,
                label: '拉伸',
                selected: selected == '拉伸',
                onTap: () => onChanged(
                  preference.copyWith(fit: BoxFit.fill),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomModeChip extends StatelessWidget {
  const _CustomModeChip({
    required this.metrics,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '展示模式$label',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? picker.ink : picker.paper,
              borderRadius: BorderRadius.circular(metrics.s(17)),
              border: Border.all(
                color: selected ? picker.ink : picker.surfaceLine,
                width: metrics.s(1),
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: selected ? picker.panel : picker.muted,
                  fontSize: metrics.s(12),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomBackgroundDisplayAreaSection extends StatelessWidget {
  const _CustomBackgroundDisplayAreaSection({
    required this.metrics,
    required this.preference,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderBackgroundPreference preference;
  final ValueChanged<ReaderBackgroundPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final selected = _verticalAreaName(preference.alignment);
    return SizedBox(
      height: metrics.s(96),
      child: Row(
        children: [
          _CustomFocusGrid(
            metrics: metrics,
            selected: preference.alignment,
            onChanged: (alignment) => onChanged(
              preference.copyWith(alignment: alignment),
            ),
          ),
          SizedBox(width: metrics.s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '展示区域',
                  style: DudoTextStyles.sans(
                    color: picker.ink,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: metrics.s(2)),
                Text(
                  _alignmentLabel(preference.alignment),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: picker.ink,
                    fontSize: metrics.s(17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: metrics.s(6)),
                SizedBox(
                  height: metrics.s(28),
                  child: Row(
                    children: [
                      _CustomAreaChip(
                        metrics: metrics,
                        label: '顶部',
                        selected: selected == '顶部',
                        onTap: () => onChanged(
                          preference.copyWith(alignment: Alignment.topCenter),
                        ),
                      ),
                      SizedBox(width: metrics.s(6)),
                      _CustomAreaChip(
                        metrics: metrics,
                        label: '居中',
                        selected: selected == '居中',
                        onTap: () => onChanged(
                          preference.copyWith(alignment: Alignment.center),
                        ),
                      ),
                      SizedBox(width: metrics.s(6)),
                      _CustomAreaChip(
                        metrics: metrics,
                        label: '底部',
                        selected: selected == '底部',
                        onTap: () => onChanged(
                          preference.copyWith(
                              alignment: Alignment.bottomCenter),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBackgroundEffectSection extends StatelessWidget {
  const _CustomBackgroundEffectSection({
    required this.metrics,
    required this.preference,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderBackgroundPreference preference;
  final ValueChanged<ReaderBackgroundPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final blurValue =
        (preference.blurRadius / ReaderBackgroundPreference.maxBlurRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final opacityValue = preference.opacity.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: EdgeInsets.all(metrics.s(10)),
      decoration: BoxDecoration(
        color: picker.paper.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(metrics.s(20)),
        border: Border.all(
          color: picker.surfaceLine.withValues(alpha: 0.72),
          width: metrics.s(1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: metrics.s(15),
                color: picker.muted,
              ),
              SizedBox(width: metrics.s(6)),
              Text(
                '图片效果',
                style: DudoTextStyles.sans(
                  color: picker.ink,
                  fontSize: metrics.s(13),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(9)),
          _CustomBackgroundToggle(
            metrics: metrics,
            title: '灰度',
            description: '降低图片色彩干扰',
            enabled: preference.grayscaleEnabled,
            onChanged: (value) => onChanged(
              preference.copyWith(grayscaleEnabled: value),
            ),
          ),
          SizedBox(height: metrics.s(10)),
          _CustomBackgroundSlider(
            metrics: metrics,
            label: '透明',
            value: opacityValue,
            valueLabel: '${(opacityValue * 100).round()}%',
            onChanged: (value) => onChanged(
              preference.copyWith(opacity: value),
            ),
          ),
          SizedBox(height: metrics.s(10)),
          _CustomBackgroundSlider(
            metrics: metrics,
            label: '模糊强度',
            value: blurValue,
            valueLabel: preference.blurRadius <= 0
                ? '关'
                : preference.blurRadius.toStringAsFixed(0),
            onChanged: (value) => onChanged(
              preference.copyWith(
                blurRadius: value * ReaderBackgroundPreference.maxBlurRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBackgroundToggle extends StatelessWidget {
  const _CustomBackgroundToggle({
    required this.metrics,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(16)),
        onTap: () => onChanged(!enabled),
        child: Ink(
          height: metrics.s(46),
          padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
          decoration: BoxDecoration(
            color: picker.panel,
            borderRadius: BorderRadius.circular(metrics.s(16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: picker.ink,
                        fontSize: metrics.s(12),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: picker.muted,
                        fontSize: metrics.s(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _ThemeStaticSwitch(metrics: metrics, enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomBackgroundSlider extends StatelessWidget {
  const _CustomBackgroundSlider({
    required this.metrics,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final double value;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final clamped = value.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: picker.ink,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: DudoTextStyles.sans(
                color: picker.muted,
                fontSize: metrics.s(11),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.s(8)),
        LayoutBuilder(
          builder: (context, constraints) {
            void updateFromOffset(double dx) {
              onChanged((dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble());
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  updateFromOffset(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  updateFromOffset(details.localPosition.dx),
              child: SizedBox(
                height: metrics.s(24),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: metrics.s(7),
                      decoration: BoxDecoration(
                        color: picker.surfaceLine,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: clamped == 0 ? 0.0001 : clamped,
                      child: Container(
                        height: metrics.s(7),
                        decoration: BoxDecoration(
                          color: picker.green,
                          borderRadius: AppRadius.full,
                        ),
                      ),
                    ),
                    Positioned(
                      left: ((constraints.maxWidth - metrics.s(20)) * clamped)
                          .toDouble(),
                      child: Container(
                        width: metrics.s(20),
                        height: metrics.s(20),
                        decoration: BoxDecoration(
                          color: picker.panel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: picker.green,
                            width: metrics.s(2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: picker.ink.withValues(alpha: 0.14),
                              blurRadius: metrics.s(6),
                              offset: Offset(0, metrics.s(2)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CustomFocusGrid extends StatelessWidget {
  const _CustomFocusGrid({
    required this.metrics,
    required this.selected,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final Alignment selected;
  final ValueChanged<Alignment> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    const rows = [
      [
        (Alignment.topLeft, '左上'),
        (Alignment.topCenter, '顶部'),
        (Alignment.topRight, '右上'),
      ],
      [
        (Alignment.centerLeft, '左侧'),
        (Alignment.center, '居中'),
        (Alignment.centerRight, '右侧'),
      ],
      [
        (Alignment.bottomLeft, '左下'),
        (Alignment.bottomCenter, '底部'),
        (Alignment.bottomRight, '右下'),
      ],
    ];
    return Container(
      width: metrics.s(94),
      height: metrics.s(94),
      padding: EdgeInsets.all(metrics.s(7)),
      decoration: BoxDecoration(
        color: picker.paper.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(metrics.s(20)),
        border: Border.all(color: const Color(0xFFE7DCC8), width: metrics.s(1)),
      ),
      child: Column(
        children: [
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            Expanded(
              child: Row(
                children: [
                  for (var columnIndex = 0;
                      columnIndex < rows[rowIndex].length;
                      columnIndex++) ...[
                    _FocusCell(
                      metrics: metrics,
                      label: rows[rowIndex][columnIndex].$2,
                      selected: selected == rows[rowIndex][columnIndex].$1,
                      onTap: () => onChanged(rows[rowIndex][columnIndex].$1),
                    ),
                    if (columnIndex < rows[rowIndex].length - 1)
                      SizedBox(width: metrics.s(5)),
                  ],
                ],
              ),
            ),
            if (rowIndex < rows.length - 1) SizedBox(height: metrics.s(5)),
          ],
        ],
      ),
    );
  }
}

class _FocusCell extends StatelessWidget {
  const _FocusCell({
    required this.metrics,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '展示区域$label',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? picker.green : picker.paper,
              borderRadius: BorderRadius.circular(metrics.s(8)),
              border: Border.all(
                color: selected ? picker.panel : picker.surfaceLine,
                width: metrics.s(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAreaChip extends StatelessWidget {
  const _CustomAreaChip({
    required this.metrics,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '展示区域$label',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? picker.greenSoft : picker.paper,
              borderRadius: BorderRadius.circular(metrics.s(14)),
              border: Border.all(
                color: selected ? picker.greenLine : picker.surfaceLine,
                width: metrics.s(1),
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: selected ? picker.green : picker.muted,
                  fontSize: metrics.s(11),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomBackgroundApplyButton extends StatelessWidget {
  const _CustomBackgroundApplyButton({
    required this.metrics,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.s(22)),
        onTap: onTap,
        child: Ink(
          height: metrics.s(46),
          decoration: BoxDecoration(
            color: picker.ink,
            borderRadius: BorderRadius.circular(metrics.s(22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.check,
                color: picker.panel,
                size: metrics.s(16),
              ),
              SizedBox(width: metrics.s(7)),
              Text(
                '应用到阅读页',
                style: DudoTextStyles.sans(
                  color: picker.panel,
                  fontSize: metrics.s(13),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _backgroundName(ReaderBackgroundPreference preference) {
  final path = preference.filePath ?? preference.assetPath;
  if (path == null || path.isEmpty) return '自定义图片';
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty);
  if (parts.isEmpty) return '自定义图片';
  final name = parts.last;
  if (name.length <= 18) return name;
  return '${name.substring(0, 8)}...${name.substring(name.length - 7)}';
}

String _fitLabel(BoxFit fit) {
  return switch (fit) {
    BoxFit.cover => '裁剪填充',
    BoxFit.contain => '完整适应',
    BoxFit.fill => '拉伸铺满',
    BoxFit.fitWidth => '适应宽度',
    BoxFit.fitHeight => '适应高度',
    BoxFit.none => '平铺重复',
    BoxFit.scaleDown => '缩小适应',
  };
}

String _modeName(BoxFit fit) {
  return switch (fit) {
    BoxFit.contain ||
    BoxFit.fitWidth ||
    BoxFit.fitHeight ||
    BoxFit.scaleDown =>
      '适应',
    BoxFit.fill => '拉伸',
    BoxFit.none => '平铺',
    _ => '裁剪',
  };
}

String _alignmentLabel(Alignment alignment) {
  if (alignment.y < -0.3 && alignment.x < -0.3) return '左上取景';
  if (alignment.y < -0.3 && alignment.x > 0.3) return '右上取景';
  if (alignment.y < -0.3) return '顶部取景';
  if (alignment.y > 0.3 && alignment.x < -0.3) return '左下取景';
  if (alignment.y > 0.3 && alignment.x > 0.3) return '右下取景';
  if (alignment.y > 0.3) return '底部取景';
  if (alignment.x < -0.3) return '左侧取景';
  if (alignment.x > 0.3) return '右侧取景';
  return '居中取景';
}

String _verticalAreaName(Alignment alignment) {
  if (alignment.y < -0.3) return '顶部';
  if (alignment.y > 0.3) return '底部';
  return '居中';
}
