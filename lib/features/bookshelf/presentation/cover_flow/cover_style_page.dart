import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../data/cover_image_tools.dart';
import '../../domain/book_cover_style.dart';
import 'book_wrap_preview.dart';
import 'cover_flow_chrome.dart';
import 'cover_flow_models.dart';

class CoverStylePage extends StatefulWidget {
  const CoverStylePage({
    super.key,
    required this.book,
    required this.frontBytes,
    this.initialStyle,
    this.initialShowText = true,
  });

  final Book book;
  final Uint8List frontBytes;
  final BookCoverStyle? initialStyle;
  final bool initialShowText;

  @override
  State<CoverStylePage> createState() => _CoverStylePageState();
}

class _CoverStylePageState extends State<CoverStylePage> {
  late CoverSpineWidth _spineWidth;
  late CoverBackStyle _backStyle;
  late bool _showText;
  Color? _spineColor;
  Color? _autoColor;
  bool _sampling = true;

  @override
  void initState() {
    super.initState();
    _spineWidth = widget.initialStyle?.spineWidth ?? CoverSpineWidth.standard;
    _backStyle = widget.initialStyle?.backStyle ?? CoverBackStyle.blur;
    _showText = widget.initialStyle?.showText ?? widget.initialShowText;
    _spineColor = widget.initialStyle?.spineColor;
    _sampleColor();
  }

  Future<void> _sampleColor() async {
    if (_spineColor != null) {
      setState(() {
        _autoColor = _spineColor;
        _sampling = false;
      });
      return;
    }
    final color = await averageCoverColor(
      widget.frontBytes,
      region: const Rect.fromLTWH(0, 0, 0.12, 1),
    );
    if (!mounted) return;
    setState(() {
      _autoColor = color;
      _spineColor = color;
      _sampling = false;
    });
  }

  BookCoverStyle get _style => BookCoverStyle(
        spineColor: _spineColor ?? DudoColors.primary,
        spineWidth: _spineWidth,
        backStyle: _backStyle,
        showText: _showText,
      );

  Future<void> _openColorPicker() async {
    final color = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x6625251F),
      builder: (_) => _ColorPickerSheet(
        selected: _spineColor ?? DudoColors.primary,
        sampled: _autoColor,
      ),
    );
    if (color == null || !mounted) return;
    setState(() => _spineColor = color);
  }

  void _apply() {
    Navigator.of(context).pop(
      CoverFlowResult(frontBytes: widget.frontBytes, style: _style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CoverFlowTopBar(
              title: '书脊与封底',
              stepLabel: '2 / 2',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '整本书封预览；书脊和封底会自动生成。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PreviewCard(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '书封展开预览',
                              style: DudoTextStyles.sans(
                                color: DudoColors.secondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final height = math.min(
                                195.0,
                                constraints.maxWidth / fullWrapAspect,
                              );
                              final width = height * fullWrapAspect;
                              return Column(
                                children: [
                                  BookWrapPreview(
                                    frontBytes: widget.frontBytes,
                                    title: widget.book.title,
                                    author: widget.book.author,
                                    intro: widget.book.intro,
                                    style: _style,
                                    showText: _showText,
                                    height: height,
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: width,
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: _WrapLegend(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '封面文字',
                      note: '图片自带文字时可关闭',
                      contentGap: 8,
                      bottomPadding: 12,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.type,
                            size: 16,
                            color: DudoColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '在封面与书脊上显示书名、作者。',
                              style: DudoTextStyles.sans(
                                color: DudoColors.textSecondary,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CoverFlowSwitch(
                            value: _showText,
                            onChanged: (value) =>
                                setState(() => _showText = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '书脊',
                      note: _sampling ? '取色中…' : '默认从封面取色',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final color in coverSpinePresets) ...[
                                _ColorSwatch(
                                  color: color,
                                  selected: _sameColor(_spineColor, color),
                                  onTap: () =>
                                      setState(() => _spineColor = color),
                                ),
                                const SizedBox(width: 10),
                              ],
                              const Spacer(),
                              _PickColorChip(onTap: _openColorPicker),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '宽度',
                                style: DudoTextStyles.sans(
                                  color: DudoColors.secondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              for (final width in CoverSpineWidth.values) ...[
                                SizedBox(
                                  width: 56,
                                  child: CoverFlowChip(
                                    label: width.label,
                                    selected: _spineWidth == width,
                                    height: 26,
                                    radius: 13,
                                    fontSize: 11,
                                    onTap: () =>
                                        setState(() => _spineWidth = width),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '封底',
                      note: '用于书封展开预览',
                      contentGap: 8,
                      bottomPadding: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (var index = 0;
                                  index < CoverBackStyle.values.length;
                                  index++) ...[
                                if (index > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: CoverFlowChip(
                                    label: CoverBackStyle.values[index].label,
                                    selected:
                                        _backStyle == CoverBackStyle.values[index],
                                    onTap: () => setState(
                                      () => _backStyle =
                                          CoverBackStyle.values[index],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '封底不会出现在书架封面中。',
                            style: DudoTextStyles.sans(
                              color: DudoColors.secondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 112,
                          child: _BackActionButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CoverFlowPrimaryButton(
                            label: '应用封面',
                            icon: LucideIcons.check,
                            onPressed: _apply,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameColor(Color? first, Color second) {
    if (first == null) return false;
    return first.toARGB32() == second.toARGB32();
  }
}

class _WrapLegend extends StatelessWidget {
  const _WrapLegend();

  @override
  Widget build(BuildContext context) {
    final style = DudoTextStyles.sans(
      color: DudoColors.secondary,
      fontSize: 9.5,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('封底 · 自动生成', style: style),
        const SizedBox(width: 12),
        Text('书脊 · 自动取色', style: style),
        const SizedBox(width: 12),
        Text('封面 · 已裁剪', style: style),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.note,
    this.contentGap = 10,
    this.bottomPadding = 14,
  });

  final String title;
  final Widget child;
  final String? note;
  final double contentGap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              if (note != null)
                Text(
                  note!,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          SizedBox(height: contentGap),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? DudoColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(
                LucideIcons.check,
                color: readableOn(color),
                size: 14,
              )
            : null,
      ),
    );
  }
}

class _PickColorChip extends StatelessWidget {
  const _PickColorChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.pipette, color: DudoColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                '取色',
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackActionButton extends StatelessWidget {
  const _BackActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.arrowLeft, color: DudoColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '上一步',
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
                  fontSize: 14,
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

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.selected, this.sampled});

  final Color selected;
  final Color? sampled;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      if (sampled != null) sampled!,
      ...coverSpinePresets,
      const Color(0xFF2E3B2C),
      const Color(0xFF6F6B61),
      const Color(0xFFC9A46A),
      const Color(0xFFA5503F),
      const Color(0xFF4E6273),
      const Color(0xFF7D5A7A),
      const Color(0xFFE7DCC8),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: DudoColors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择书脊颜色',
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '从封面取色，或选一个相近的颜色。',
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in colors)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(color),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.toARGB32() == selected.toARGB32()
                              ? DudoColors.textPrimary
                              : DudoColors.surface,
                          width: 2,
                        ),
                      ),
                      child: color.toARGB32() == selected.toARGB32()
                          ? Icon(
                              LucideIcons.check,
                              color: readableOn(color),
                              size: 17,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
