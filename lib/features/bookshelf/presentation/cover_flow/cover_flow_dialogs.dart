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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DudoColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '更换封面',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '选择封面来源，选图后进入裁剪。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _SourceRow(
            icon: LucideIcons.image,
            title: '从相册选择',
            description: '支持 JPG / PNG，建议 2:3 竖图',
            onTap: () => Navigator.of(context).pop(CoverSourceAction.gallery),
          ),
          const _SourceDivider(),
          _SourceRow(
            icon: LucideIcons.camera,
            title: '拍一张',
            description: '拍摄后进入裁剪',
            onTap: () => Navigator.of(context).pop(CoverSourceAction.camera),
          ),
          const _SourceDivider(),
          _SourceRow(
            icon: LucideIcons.rotateCcw,
            title: '恢复默认封面',
            description: '移除当前自定义封面',
            destructive: true,
            onTap: () => Navigator.of(context).pop(CoverSourceAction.restore),
          ),
          const SizedBox(height: 28),
          Material(
            color: DudoColors.surfaceLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                height: 44,
                child: Center(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceDivider extends StatelessWidget {
  const _SourceDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Divider(
        height: 1,
        thickness: 1,
        color: DudoColors.outlineVariant,
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
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFA5503F) : DudoColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFF4D6CE)
                      : DudoColors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent, size: 18),
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
                        color: destructive
                            ? const Color(0xFFA5503F)
                            : DudoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: destructive
                            ? const Color(0xCCA5503F)
                            : DudoColors.secondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: destructive
                    ? const Color(0xFFA5503F)
                    : DudoColors.secondary,
                size: 16,
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DialogIcon(
            icon: LucideIcons.rotateCcw,
            color: Color(0xFFA5503F),
            background: Color(0xFFF4D6CE),
          ),
          const SizedBox(height: 12),
          const _DialogTitle('恢复默认封面？'),
          const SizedBox(height: 5),
          const _DialogBody(
            '当前自定义封面会被移除，书架和详情页将恢复为系统生成的封面。',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: _DialogActionButton(
                  label: '取消',
                  foregroundColor: DudoColors.textSecondary,
                  backgroundColor: DudoColors.surface,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: _DialogActionButton(
                  label: '恢复默认',
                  foregroundColor: DudoColors.onInk,
                  backgroundColor: const Color(0xFFA5503F),
                  onTap: () => Navigator.of(context).pop(true),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DialogIcon(
            icon: LucideIcons.triangleAlert,
            color: Color(0xFFB98242),
            background: Color(0xFFF3E7D2),
          ),
          const SizedBox(height: 12),
          const _DialogTitle('离开编辑？'),
          const SizedBox(height: 5),
          const _DialogBody(
            '当前修改还没有保存。直接离开会丢失这次修改。',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: _DialogActionButton(
                  label: '直接离开',
                  foregroundColor: const Color(0xFFA5503F),
                  backgroundColor: DudoColors.surface,
                  onTap: () =>
                      Navigator.of(context).pop(LeaveEditAction.discard),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: _DialogActionButton(
                  label: '保存并离开',
                  foregroundColor: DudoColors.onInk,
                  backgroundColor: DudoColors.ink,
                  onTap: () => Navigator.of(context).pop(LeaveEditAction.save),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
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
                  fontSize: 12,
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
  const _DialogCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 310,
        padding: padding,
        decoration: BoxDecoration(
          color: DudoColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: DudoTextStyles.sans(
        color: DudoColors.textSecondary,
        fontSize: 12,
        height: 1.5,
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: DudoTextStyles.sans(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
