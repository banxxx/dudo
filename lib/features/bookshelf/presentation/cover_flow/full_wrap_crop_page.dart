import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../data/cover_image_tools.dart';
import '../../domain/book_cover_style.dart';
import 'cover_crop_view.dart';
import 'cover_flow_chrome.dart';
import 'cover_flow_models.dart';

class FullWrapCropPage extends StatefulWidget {
  const FullWrapCropPage({
    super.key,
    required this.book,
    required this.imageBytes,
  });

  final Book book;
  final Uint8List imageBytes;

  @override
  State<FullWrapCropPage> createState() => _FullWrapCropPageState();
}

class _FullWrapCropPageState extends State<FullWrapCropPage> {
  final CoverCropController _controller = CoverCropController();
  CoverSpineWidth _spineWidth = CoverSpineWidth.standard;
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      final wrapBytes = await _controller.capture();
      final frontStart = fullWrapFrontStart(_spineWidth);
      final frontFraction = fullWrapFrontFraction(_spineWidth);
      final frontBytes = await cropCoverImage(
        wrapBytes,
        Rect.fromLTWH(frontStart, 0, frontFraction, 1),
      );
      final spineColor = await averageCoverColor(
        wrapBytes,
        region: Rect.fromLTWH(
          fullWrapBackFraction,
          0,
          _spineWidth.wrapFraction,
          1,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        CoverFlowResult(
          frontBytes: frontBytes,
          wrapBytes: wrapBytes,
          style: BookCoverStyle(
            spineColor: spineColor,
            spineWidth: _spineWidth,
            backStyle: CoverBackStyle.blur,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成整幅书封失败，请重试')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
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
              title: '调整整幅书封',
              badge: '高级',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '整幅书封',
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '一张图同时包含封底、书脊和封面。拖动与缩放对齐分区。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoverFlowStage(
                      aspectRatio: fullWrapAspect,
                      child: CoverCropView(
                        bytes: widget.imageBytes,
                        aspectRatio: fullWrapAspect,
                        controller: _controller,
                        overlayBuilder: (_) => _WrapGuides(
                          spineWidth: _spineWidth,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '书脊宽度',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 11,
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
                    const SizedBox(height: 12),
                    CoverZoomRow(controller: _controller),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CoverSmallAction(
                          icon: LucideIcons.rotateCw,
                          label: '旋转',
                          onTap: _controller.rotate,
                        ),
                        const SizedBox(width: 8),
                        CoverSmallAction(
                          icon: LucideIcons.rotateCcw,
                          label: '重置位置',
                          onTap: _controller.resetPosition,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoverFlowHint(
                text: '整幅书封会同时作为封面、书脊和封底；应用后不再单独调整。',
              ),
              const SizedBox(height: 10),
              CoverFlowPrimaryButton(
                label: '应用封面',
                icon: LucideIcons.check,
                loading: _applying,
                onPressed: _apply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrapGuides extends StatelessWidget {
  const _WrapGuides({required this.spineWidth});

  final CoverSpineWidth spineWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final back = width * fullWrapBackFraction;
        final spine = width * spineWidth.wrapFraction;
        final front = back + spine;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _WrapGuidesPainter(
                back: back,
                front: front,
                height: constraints.maxHeight,
              ),
            ),
            const Positioned(
              top: 8,
              left: 8,
              child: _ZoneLabel('封底'),
            ),
            Positioned(
              top: 8,
              left: (back + spine / 2 - 13).clamp(0.0, width - 26),
              child: const _ZoneLabel('书脊'),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: _ZoneLabel('封面'),
            ),
          ],
        );
      },
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xA625251F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: DudoTextStyles.sans(
          color: const Color(0xFFFFF8EA),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WrapGuidesPainter extends CustomPainter {
  _WrapGuidesPainter({
    required this.back,
    required this.front,
    required this.height,
  });

  final double back;
  final double front;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final spineFill = Paint()..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawRect(Rect.fromLTRB(back, 0, front, height), spineFill);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(back, 0), Offset(back, height), line);
    canvas.drawLine(Offset(front, 0), Offset(front, height), line);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(15),
      ),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _WrapGuidesPainter oldDelegate) {
    return oldDelegate.back != back || oldDelegate.front != front;
  }
}
