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
            // A full wrap is already a finished layout with its own lettering.
            showText: false,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拖动整幅书封，参考线对应封底 / 书脊 / 封面。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CoverFlowCropStage(
                      bytes: widget.imageBytes,
                      aspectRatio: fullWrapAspect,
                      controller: _controller,
                      stageHeightFactor: 400 / 350,
                      frameWidthFactor: 320 / 350,
                      stageOverlayBuilder: (_, frame) => _WrapOverlay(
                        frame: frame,
                        spineWidth: _spineWidth,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '书脊宽度',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        for (final width in CoverSpineWidth.values) ...[
                          SizedBox(
                            width: 56,
                            child: CoverFlowChip(
                              label: width.label,
                              selected: _spineWidth == width,
                              height: 28,
                              radius: 14,
                              fontSize: 11,
                              onTap: () =>
                                  setState(() => _spineWidth = width),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        Text(
                          '参考线随之移动',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CoverZoomRow(controller: _controller),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CoverSmallAction(
                            icon: LucideIcons.rotateCw,
                            label: '旋转 90°',
                            onTap: _controller.rotate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CoverSmallAction(
                            icon: LucideIcons.rotateCcw,
                            label: '重置位置',
                            onTap: _controller.resetPosition,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}

class _WrapOverlay extends StatelessWidget {
  const _WrapOverlay({
    required this.frame,
    required this.spineWidth,
  });

  final Rect frame;
  final CoverSpineWidth spineWidth;

  @override
  Widget build(BuildContext context) {
    final back = frame.width * fullWrapBackFraction;
    final front = back + frame.width * spineWidth.wrapFraction;
    final labelTop = frame.top - 28;
    final spineCenter = frame.left + (back + front) / 2;
    final frontStart = fullWrapFrontStart(spineWidth);
    final frontCenter =
        frame.left + frame.width * (frontStart + (1 - frontStart) / 2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: frame.left,
          top: frame.top,
          width: frame.width,
          height: frame.height,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WrapGuidesPainter(
                back: back,
                front: front,
                height: frame.height,
              ),
            ),
          ),
        ),
        Positioned(
          top: labelTop,
          left: frame.left,
          child: const _ZoneLabel('封底'),
        ),
        Positioned(
          top: labelTop,
          left: spineCenter - 20,
          child: const _ZoneLabel('书脊'),
        ),
        Positioned(
          top: labelTop,
          left: frontCenter - 20,
          child: const _ZoneLabel('封面'),
        ),
      ],
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC25251F),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: DudoTextStyles.sans(
          color: const Color(0xCCFFF8EA),
          fontSize: 8,
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
  }

  @override
  bool shouldRepaint(covariant _WrapGuidesPainter oldDelegate) {
    return oldDelegate.back != back || oldDelegate.front != front;
  }
}
