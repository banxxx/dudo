import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

enum _FontSource { local, builtIn }

class TypographySettingsPage extends StatefulWidget {
  const TypographySettingsPage({super.key});

  @override
  State<TypographySettingsPage> createState() => _TypographySettingsPageState();
}

class _TypographySettingsPageState extends State<TypographySettingsPage> {
  _FontSource _source = _FontSource.local;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '字体管理',
          showAction: false,
        ),
        const SizedBox(height: 14),
        const _ReadingPreview(),
        const SizedBox(height: 14),
        _FontManagementSection(
          source: _source,
          onSourceChanged: (source) => setState(() => _source = source),
          onDeleteFont: () => _showDeleteFontSheet(context),
        ),
      ],
    );
  }
}

class _ReadingPreview extends StatelessWidget {
  const _ReadingPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '字体预览',
                      style: DudoTextStyles.sans(
                        color: DudoColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '中文阅读 · 当前阅读字体',
                      style: DudoTextStyles.sans(
                        color: DudoColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '使用中',
                  style: DudoTextStyles.sans(
                    color: DudoColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '她仰望着夜空，宇宙像一张深色纸页，所有星辰都在沉默地等待被阅读。',
            style: DudoTextStyles.serif(
              color: DudoColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontManagementSection extends StatelessWidget {
  const _FontManagementSection({
    required this.source,
    required this.onSourceChanged,
    required this.onDeleteFont,
  });

  final _FontSource source;
  final ValueChanged<_FontSource> onSourceChanged;
  final VoidCallback onDeleteFont;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '字体管理',
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '内置字体和导入字体统一在这里选择',
          style: DudoTextStyles.sans(color: DudoColors.secondary, fontSize: 11),
        ),
        const SizedBox(height: 10),
        _FontSourceTabs(source: source, onChanged: onSourceChanged),
        const SizedBox(height: 10),
        if (source == _FontSource.local) ...[
          const _ImportFontEntry(),
          const SizedBox(height: 10),
          const _FontCard(
            name: '霞鹜文楷',
            description: 'LXGWWenKai-Regular.ttf',
            selected: true,
            badge: '本地',
          ),
          const SizedBox(height: 10),
          _FontCard(
            name: '方正书宋',
            description: 'FZShuSong.otf',
            onDelete: onDeleteFont,
          ),
        ] else ...[
          const _FontCard(
            name: '思源宋体',
            description: '适合长时间中文阅读',
            selected: true,
            badge: '内置',
          ),
          const SizedBox(height: 10),
          const _FontCard(
            name: '系统黑体',
            description: '跟随设备默认无衬线字体',
            badge: '内置',
          ),
          const SizedBox(height: 10),
          const _FontCard(
            name: 'Noto Serif SC',
            description: '清晰稳定的中文衬线字体',
            badge: '内置',
          ),
        ],
      ],
    );
  }
}

class _FontSourceTabs extends StatelessWidget {
  const _FontSourceTabs({required this.source, required this.onChanged});

  final _FontSource source;
  final ValueChanged<_FontSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FontSourceTab(
              label: '内置字体',
              selected: source == _FontSource.builtIn,
              onTap: () => onChanged(_FontSource.builtIn),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _FontSourceTab(
              label: '我的字体',
              selected: source == _FontSource.local,
              onTap: () => onChanged(_FontSource.local),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontSourceTab extends StatelessWidget {
  const _FontSourceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: AppMotion.short,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? DudoColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: selected ? DudoColors.textPrimary : DudoColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportFontEntry extends StatelessWidget {
  const _ImportFontEntry();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.primaryContainerStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DudoColors.surfaceHigh,
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              LucideIcons.folderPlus,
              color: DudoColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加本地字体',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '支持 .ttf、.otf 文件，导入后立即可用',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.primaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: DudoColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.name,
    required this.description,
    this.selected = false,
    this.badge,
    this.onDelete,
  });

  final String name;
  final String description;
  final bool selected;
  final String? badge;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? DudoColors.primaryDark : DudoColors.secondary;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: selected ? DudoColors.primaryContainer : DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? DudoColors.primaryContainerStrong
              : DudoColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? DudoColors.surfaceHigh : DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(LucideIcons.fileType, color: foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DudoTextStyles.sans(
                          color: DudoColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 7),
                      _FontBadge(badge!, selected: selected),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(color: foreground, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (selected)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: DudoColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.check,
                color: DudoColors.surfaceHigh,
                size: 15,
              ),
            )
          else if (onDelete != null)
            Material(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(15),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    LucideIcons.trash2,
                    color: DudoColors.secondary,
                    size: 17,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FontBadge extends StatelessWidget {
  const _FontBadge(this.text, {required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? DudoColors.surfaceHigh : DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: DudoTextStyles.sans(
          color: selected ? DudoColors.primary : DudoColors.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Future<void> _showDeleteFontSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: DudoColors.textPrimary.withValues(alpha: 0.2),
    isScrollControlled: true,
    builder: (context) => const _DeleteFontSheet(),
  );
}

class _DeleteFontSheet extends StatelessWidget {
  const _DeleteFontSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: DudoColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: DudoColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E5C9),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: Color(0xFFA0612B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '删除“方正书宋”？',
                        style: DudoTextStyles.sans(
                          color: DudoColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '字体文件会从本机移除，不影响书籍内容。',
                        style: DudoTextStyles.sans(
                          color: DudoColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DudoColors.paperBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DudoColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.fileType,
                    color: DudoColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FZShuSong.otf · 本地字体',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: DudoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: '取消',
                      background: DudoColors.surfaceLow,
                      foreground: DudoColors.secondary,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetButton(
                      label: '删除',
                      background: const Color(0xFFA0612B),
                      foreground: DudoColors.surfaceHigh,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
