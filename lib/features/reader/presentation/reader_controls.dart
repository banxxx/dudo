import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_theme.dart';

/// Top + bottom overlay controls that appear when the reader is tapped.
class ReaderControls extends StatelessWidget {
  const ReaderControls({
    super.key,
    required this.onClose,
    required this.onBack,
    required this.palette,
    required this.onPaletteChanged,
  });

  final VoidCallback onClose;
  final VoidCallback onBack;
  final ReaderPalette palette;
  final ValueChanged<ReaderPalette> onPaletteChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: onBack,
                    ),
                    const Spacer(),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(LucideIcons.bookmarkPlus),
                      onPressed: () {},
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(LucideIcons.volume2),
                      onPressed: () {},
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(LucideIcons.moreVertical),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PaletteSelector(
                      current: palette,
                      onChanged: onPaletteChanged,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ToolButton(
                          icon: LucideIcons.bookOpenText,
                          label: '目录',
                          onPressed: () {},
                        ),
                        _ToolButton(
                          icon: LucideIcons.type,
                          label: '排版',
                          onPressed: () {},
                        ),
                        _ToolButton(
                          icon: LucideIcons.sunMoon,
                          label: '亮度',
                          onPressed: () {},
                        ),
                        _ToolButton(
                          icon: LucideIcons.settings,
                          label: '更多',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteSelector extends StatelessWidget {
  const _PaletteSelector({required this.current, required this.onChanged});
  final ReaderPalette current;
  final ValueChanged<ReaderPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReaderTheme.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = ReaderTheme.presets[i];
          final selected = p.background == current.background;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text('A', style: TextStyle(color: p.foreground)),
            ),
          );
        },
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
