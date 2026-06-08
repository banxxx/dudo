part of '../../reader_controls.dart';

class _IconTapArea extends StatelessWidget {
  const _IconTapArea(
      {required this.tooltip,
      required this.icon,
      required this.color,
      required this.onTap});

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
