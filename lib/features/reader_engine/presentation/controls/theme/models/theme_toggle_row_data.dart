part of '../../../reader_controls.dart';

// 开关行数据：集中描述文案与选中状态，便于后续接入真实设置。

class _ThemeToggleRowData {
  const _ThemeToggleRowData({
    required this.title,
    required this.description,
    required this.enabled,
    this.onChanged,
  });

  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
}
