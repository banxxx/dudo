import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import 'cover_crop_view.dart';
import 'cover_flow_chrome.dart';
import 'cover_flow_models.dart';
import 'cover_style_page.dart';
import 'full_wrap_crop_page.dart';

class FrontCoverCropPage extends StatefulWidget {
  const FrontCoverCropPage({
    super.key,
    required this.book,
    required this.imageBytes,
  });

  final Book book;
  final Uint8List imageBytes;

  @override
  State<FrontCoverCropPage> createState() => _FrontCoverCropPageState();
}

class _FrontCoverCropPageState extends State<FrontCoverCropPage> {
  final CoverCropController _controller = CoverCropController();
  CoverCropAspect _aspect = CoverCropAspect.portrait;
  bool _capturing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final frontBytes = await _controller.capture();
      if (!mounted) return;
      final result = await Navigator.of(context).push<CoverFlowResult>(
        MaterialPageRoute(
          builder: (_) => CoverStylePage(
            book: widget.book,
            frontBytes: frontBytes,
            sourceImageBytes: widget.imageBytes,
          ),
        ),
      );
      if (!mounted) return;
      if (result != null) Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('裁切失败，请重试')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openFullWrap() async {
    final result = await Navigator.of(context).push<CoverFlowResult>(
      MaterialPageRoute(
        builder: (_) => FullWrapCropPage(
          book: widget.book,
          imageBytes: widget.imageBytes,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) Navigator.of(context).pop(result);
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
              title: '调整封面',
              stepLabel: '1 / 2',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '裁切你的封面',
                      style: DudoTextStyles.serif(
                        color: DudoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '拖动图片调整位置，双指缩放。框内就是书架上的封面。',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoverFlowStage(
                      aspectRatio: _aspect.ratio,
                      child: CoverCropView(
                        key: ValueKey(_aspect),
                        bytes: widget.imageBytes,
                        aspectRatio: _aspect.ratio,
                        controller: _controller,
                        overlayBuilder: (_) => const _CropGridOverlay(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final aspect in CoverCropAspect.values)
                          CoverFlowChip(
                            label: aspect.label,
                            selected: _aspect == aspect,
                            onTap: () => setState(() => _aspect = aspect),
                          ),
                        CoverFlowChip(
                          label: '整幅书封',
                          selected: false,
                          icon: LucideIcons.panelsTopLeft,
                          onTap: _openFullWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                        const Spacer(),
                        Text(
                          '高级：可裁整幅书封',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 10.5,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoverFlowHint(
                text: '下一步可以设置书脊颜色、宽度和封底样式。',
              ),
              const SizedBox(height: 10),
              CoverFlowPrimaryButton(
                label: '下一步：书脊与封底',
                icon: LucideIcons.arrowRight,
                loading: _capturing,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropGridOverlay extends StatelessWidget {
  const _CropGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CropGridPainter());
  }
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 0.8;
    for (var index = 1; index <= 2; index++) {
      final x = size.width * index / 3;
      final y = size.height * index / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(15),
      ),
      border,
    );

    final handle = Paint()
      ..color = DudoColors.accentSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const length = 17.0;
    const inset = 7.0;
    final corners = [
      const (Offset(inset, inset), Offset(1, 1)),
      (Offset(size.width - inset, inset), const Offset(-1, 1)),
      (Offset(inset, size.height - inset), const Offset(1, -1)),
      (Offset(size.width - inset, size.height - inset), const Offset(-1, -1)),
    ];
    for (final (point, direction) in corners) {
      canvas.drawLine(
        point,
        point + Offset(length * direction.dx, 0),
        handle,
      );
      canvas.drawLine(
        point,
        point + Offset(0, length * direction.dy),
        handle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
