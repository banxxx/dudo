part of '../../../reader_controls.dart';

// 主题样式选项数据：只描述选项展示所需的信息，避免渲染层散落硬编码。

class _ThemeStyleOption {
  const _ThemeStyleOption({
    required this.label,
    required this.palette,
    required this.swatchColor,
    required this.fillColor,
    required this.textColor,
    required this.selectedTextColor,
    required this.borderColor,
  });

  final String label;
  final ReaderPalette palette;
  final Color swatchColor;
  final Color fillColor;
  final Color textColor;
  final Color selectedTextColor;
  final Color borderColor;
}
