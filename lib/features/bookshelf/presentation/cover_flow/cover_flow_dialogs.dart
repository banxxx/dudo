import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';

enum CoverSourceAction { gallery, camera, restore }

enum LeaveEditAction { discard, save, stay }

Future<CoverSourceAction?> showCoverSourceSheet(BuildContext context) {
  return showModalBottomSheet<CoverSourceAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: const Color(0x6625251F),
    builder: (_) => const _CoverSourceSheet(),
  );
}

Future<bool?> showRestoreCoverDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0x6625251F),
    builder: (_) => const _RestoreCoverDialog(),
  );
}

Future<LeaveEditAction?> showUnsavedLeaveDialog(BuildContext context) {
  return showDialog<LeaveEditAction>(
    context: context,
    barrierColor: const Color(0x6625251F),
    builder: (_) => const _UnsavedLeaveDialog(),
  );
}

class _CoverSourceSheet extends StatelessWidget {
  const _CoverSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DudoColors.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3325251F),
              offset: Offset(0, 18),
              blurRadius: 42,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DudoColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '更换封面',
              style: DudoTextStyles.serif(
                color: DudoColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '选择一张图片作为这本书的封面。',
              style: DudoTextStyles.sans(
                color: DudoColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _SourceRow(
              icon: LucideIcons.image,
              title: '从相册选择',
              description: '从手机照片中选择一张',
              onTap: () => Navigator.of(context).pop(CoverSourceAction.gallery),
            ),
            const SizedBox(height: 8),
            _SourceRow(
              icon: LucideIcons.camera,
              title: '拍一张',
              description: '用相机拍摄封面',
              onTap: () => Navigator.of(context).pop(CoverSourceAction.camera),
            ),
            const SizedBox(height: 8),
            _SourceRow(
              icon: LucideIcons.rotateCcw,
              title: '恢复默认封面',
              description: '回到自动生成的封面',
              onTap: () => Navigator.of(context).pop(CoverSourceAction.restore),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: DudoColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  '取消',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.surfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DudoColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: DudoColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: DudoColors.secondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestoreCoverDialog extends StatelessWidget {
  const _RestoreCoverDialog();

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DialogIcon(
            icon: LucideIcons.triangleAlert,
            color: Color(0xFFA5503F),
            background: Color(0xFFF4E2D8),
          ),
          const SizedBox(height: 14),
          Text(
            '恢复默认封面？',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前自定义封面会被移除，回到自动生成的封面。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DudoColors.textPrimary,
                      side: BorderSide(color: DudoColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA5503F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      '恢复默认',
                      style: DudoTextStyles.sans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnsavedLeaveDialog extends StatelessWidget {
  const _UnsavedLeaveDialog();

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DialogIcon(
            icon: LucideIcons.triangleAlert,
            color: Color(0xFFA5503F),
            background: Color(0xFFF4E2D8),
          ),
          const SizedBox(height: 14),
          Text(
            '离开编辑？',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前修改还没有保存。直接离开会丢失这次修改。',
            textAlign: TextAlign.center,
            style: DudoTextStyles.sans(
              color: DudoColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(LeaveEditAction.discard),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA5503F),
                      side: const BorderSide(color: Color(0xFFA5503F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      '直接离开',
                      style: DudoTextStyles.sans(
                        color: const Color(0xFFA5503F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(LeaveEditAction.save),
                    style: FilledButton.styleFrom(
                      backgroundColor: DudoColors.ink,
                      foregroundColor: DudoColors.onInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      '保存并离开',
                      style: DudoTextStyles.sans(
                        color: DudoColors.onInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(LeaveEditAction.stay),
              style: TextButton.styleFrom(
                foregroundColor: DudoColors.textSecondary,
              ),
              child: Text(
                '继续编辑',
                style: DudoTextStyles.sans(
                  color: DudoColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: 310,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        decoration: BoxDecoration(
          color: DudoColors.surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3325251F),
              offset: Offset(0, 22),
              blurRadius: 46,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
