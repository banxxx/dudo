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
import 'full_wrap_crop_page.dart';

class CoverStylePage extends StatefulWidget {
  const CoverStylePage({
    super.key,
    required this.book,
    required this.frontBytes,
    required this.sourceImageBytes,
    this.initialStyle,
  });

  final Book book;
  final Uint8List frontBytes;
  final Uint8List sourceImageBytes;
  final BookCoverStyle? initialStyle;

  @override
  State<CoverStylePage> createState() => _CoverStylePageState();
}

class _CoverStylePageState extends State<CoverStylePage> {
  late CoverSpineWidth _spineWidth;
  late CoverBackStyle _backStyle;
  Color? _spineColor;
  Color? _autoColor;
  bool _sampling = true;

  @override
  void initState() {
    super.initState();
    _spineWidth = widget.initialStyle?.spineWidth ?? CoverSpineWidth.standard;
    _backStyle = widget.initialStyle?.backStyle ?? CoverBackStyle.blur;
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
      );

  Future<void> _openColorPicker() async {
    final color = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x6625251F),
      builder: (_) => _ColorPickerSheet(
        selected: _spineColor ?? DudoColors.primary,
        sampled: _spineColor,
      ),
    );
    if (color == null || !mounted) return;
    setState(() => _spineColor = color);
  }

  Future<void> _importFullWrap() async {
    final result = await Navigator.of(context).push<CoverFlowResult>(
      MaterialPageRoute(
        builder: (_) => FullWrapCropPage(
          book: widget.book,
          imageBytes: widget.sourceImageBytes,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) Navigator.of(context).pop(result);
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '让封面立起来',
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '自动从封面取色，也可以手动调整书脊与封底。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PreviewCard(
                      child: Column(
                        children: [
                          BookWrapPreview(
                            frontBytes: widget.frontBytes,
                            title: widget.book.title,
                            author: widget.book.author,
                            intro: widget.book.intro,
                            style: _style,
                          ),
                          const SizedBox(height: 11),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var index = 0; index < 3; index++) ...[
                                if (index > 0)
                                  Container(
                                    width: 3,
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DudoColors.outline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  const ['封底', '书脊', '封面'][index],
                                  style: DudoTextStyles.sans(
                                    color: DudoColors.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '书脊',
                      trailing: _sampling
                          ? Text(
                              '取色中…',
                              style: DudoTextStyles.sans(
                                color: DudoColors.textSecondary,
                                fontSize: 10,
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ColorSwatch(
                                color: _autoColor ?? DudoColors.primary,
                                selected: _sameColor(
                                  _spineColor,
                                  _autoColor ?? DudoColors.primary,
                                ),
                                label: '自动',
                                onTap: () {
                                  if (_autoColor != null) {
                                    setState(() => _spineColor = _autoColor);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              for (final color in coverSpinePresets)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _ColorSwatch(
                                    color: color,
                                    selected: _sameColor(
                                      _spineColor,
                                      color,
                                    ),
                                    onTap: () =>
                                        setState(() => _spineColor = color),
                                  ),
                                ),
                              const Spacer(),
                              CoverFlowChip(
                                label: '取色',
                                selected: false,
                                icon: LucideIcons.pipette,
                                onTap: _openColorPicker,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '书脊宽度',
                            style: DudoTextStyles.sans(
                              color: DudoColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final width in CoverSpineWidth.values)
                                CoverFlowChip(
                                  label: width.label,
                                  selected: _spineWidth == width,
                                  onTap: () =>
                                      setState(() => _spineWidth = width),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '封底样式',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final style in CoverBackStyle.values)
                            CoverFlowChip(
                              label: style.label,
                              selected: _backStyle == style,
                              onTap: () => setState(() => _backStyle = style),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: DudoColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _importFullWrap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: DudoColors.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.panelsTopLeft,
                                color: DudoColors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '已有整幅书封图片？导入完整书封',
                                  style: DudoTextStyles.sans(
                                    color: DudoColors.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: DudoColors.secondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CoverFlowHint(
                      text: '书脊和封底会用于书封展开预览；书架与详情页显示正面封面。',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DudoColors.textPrimary,
                    side: BorderSide(color: DudoColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Text(
                    '上一步',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CoverFlowPrimaryButton(
                  label: '应用封面',
                  icon: LucideIcons.check,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameColor(Color? first, Color second) {
    if (first == null) return false;
    return first.toARGB32() == second.toARGB32();
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A25251F),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
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
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? DudoColors.textPrimary : DudoColors.surface,
                width: selected ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F25251F),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: selected
                ? Icon(
                    LucideIcons.check,
                    color: readableOn(color),
                    size: 14,
                  )
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 8.5,
              ),
            ),
          ],
        ],
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
