import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/messages/app_message.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../application/reader_font_providers.dart';
import '../data/reader_font_repository.dart';
import '../domain/reader_font.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

enum _FontSource { local, builtIn }

const _fontSnackDedupeKey = 'typography-settings-snack';

class TypographySettingsPage extends ConsumerStatefulWidget {
  const TypographySettingsPage({super.key});

  @override
  ConsumerState<TypographySettingsPage> createState() =>
      _TypographySettingsPageState();
}

class _TypographySettingsPageState
    extends ConsumerState<TypographySettingsPage> {
  _FontSource _source = _FontSource.local;
  late final AppMessageService _messageService;
  bool _importing = false;
  final Set<String> _deletingFontIds = <String>{};

  @override
  void initState() {
    super.initState();
    _messageService = ref.read(appMessageServiceProvider);
  }

  @override
  void dispose() {
    _messageService.dismiss(_fontSnackDedupeKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryValue = ref.watch(readerFontLibraryControllerProvider);
    final library = libraryValue.valueOrNull;

    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '阅读体验',
          title: '字体管理',
          showAction: false,
        ),
        const SizedBox(height: 14),
        _ReadingPreview(font: library?.selectedFont),
        const SizedBox(height: 14),
        _FontManagementSection(
          source: _source,
          libraryValue: libraryValue,
          importing: _importing,
          deletingFontIds: _deletingFontIds,
          onSourceChanged: (source) => setState(() => _source = source),
          onImportFont: _importFont,
          onSelectFont: _selectFont,
          onDeleteFont: _deleteFont,
        ),
      ],
    );
  }

  Future<void> _importFont() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final font = await ref
          .read(readerFontLibraryControllerProvider.notifier)
          .importFont();
      if (!mounted || font == null) return;
      _showFontSnack(
        '已导入「${font.displayName}」，可在列表中启用',
        kind: AppMessageKind.success,
      );
    } on ReaderFontImportException catch (error) {
      if (!mounted) return;
      _showFontSnack(error.message, kind: AppMessageKind.error);
    } catch (_) {
      if (!mounted) return;
      _showFontSnack('字体导入失败', kind: AppMessageKind.error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _selectFont(ReaderFont font) async {
    await ref
        .read(readerFontLibraryControllerProvider.notifier)
        .selectFont(font.familyKey);
    if (!mounted) return;
    _showFontSnack(
      '已启用「${font.displayName}」',
      kind: AppMessageKind.success,
    );
  }

  Future<void> _deleteFont(ReaderFont font) async {
    final shouldDelete = await _showDeleteFontSheet(context, font);
    if (!mounted || !shouldDelete) return;
    if (_deletingFontIds.contains(font.id)) return;

    setState(() => _deletingFontIds.add(font.id));
    try {
      await ref
          .read(readerFontLibraryControllerProvider.notifier)
          .deleteFont(font.id);
      if (!mounted) return;
      _showFontSnack(
        '已删除「${font.displayName}」',
        kind: AppMessageKind.success,
      );
    } catch (_) {
      if (!mounted) return;
      _showFontSnack('字体删除失败', kind: AppMessageKind.error);
    } finally {
      if (mounted) {
        setState(() => _deletingFontIds.remove(font.id));
      }
    }
  }

  void _showFontSnack(
    String message, {
    required AppMessageKind kind,
  }) {
    _messageService.show(
      AppMessageRequest(
        title: message,
        kind: kind,
        position: AppMessagePosition.bottom,
        visualStyle: AppMessageVisualStyle.snack,
        dedupeKey: _fontSnackDedupeKey,
        replaceExisting: true,
        dismissible: false,
      ),
    );
  }
}

class _ReadingPreview extends StatelessWidget {
  const _ReadingPreview({this.font});

  final ReaderFont? font;

  @override
  Widget build(BuildContext context) {
    final fontFamily = font?.familyKey ?? DudoFonts.serifSc;

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
                      font == null
                          ? '中文阅读 · 当前阅读字体'
                          : '中文阅读 · ${font!.displayName}',
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
            style: TextStyle(
              fontFamily: fontFamily,
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
    required this.libraryValue,
    required this.importing,
    required this.deletingFontIds,
    required this.onSourceChanged,
    required this.onImportFont,
    required this.onSelectFont,
    required this.onDeleteFont,
  });

  final _FontSource source;
  final AsyncValue<ReaderFontLibrary> libraryValue;
  final bool importing;
  final Set<String> deletingFontIds;
  final ValueChanged<_FontSource> onSourceChanged;
  final VoidCallback onImportFont;
  final ValueChanged<ReaderFont> onSelectFont;
  final ValueChanged<ReaderFont> onDeleteFont;

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
        libraryValue.when(
          loading: () => const _FontLibraryLoading(),
          error: (error, _) => _FontLibraryError(error: error),
          data: (library) {
            final fonts = source == _FontSource.local
                ? library.importedFonts
                : library.builtinFonts;
            return Column(
              children: [
                if (source == _FontSource.local) ...[
                  _ImportFontEntry(
                    loading: importing,
                    onTap: onImportFont,
                  ),
                  const SizedBox(height: 10),
                ],
                if (fonts.isEmpty)
                  const _EmptyFontLibrary()
                else
                  for (final font in fonts) ...[
                    _FontCard(
                      font: font,
                      selected: font.familyKey == library.selectedFamilyKey,
                      deleting: deletingFontIds.contains(font.id),
                      onSelect: () => onSelectFont(font),
                      onDelete:
                          font.canDelete ? () => onDeleteFont(font) : null,
                    ),
                    if (font != fonts.last) const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
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
  const _ImportFontEntry({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudoColors.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
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
                      '支持 .ttf、.otf 文件，导入后可在列表中启用',
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
              AnimatedSwitcher(
                duration: AppMotion.short,
                child: loading
                    ? const SizedBox(
                        key: ValueKey('font-import-loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        key: ValueKey('font-import-arrow'),
                        LucideIcons.chevronRight,
                        color: DudoColors.primary,
                        size: 18,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.font,
    this.selected = false,
    this.deleting = false,
    required this.onSelect,
    this.onDelete,
  });

  final ReaderFont font;
  final bool selected;
  final bool deleting;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? DudoColors.primaryDark : DudoColors.secondary;
    final description = font.isBuiltin
        ? _builtinDescription(font)
        : '${font.originalFileName ?? font.displayName} · ${_formatFileSize(font.fileSize)}';

    return Material(
      color: selected ? DudoColors.primaryContainer : DudoColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: deleting ? null : onSelect,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
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
                  color:
                      selected ? DudoColors.surfaceHigh : DudoColors.surfaceLow,
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
                            font.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _FontBadge(font.isBuiltin ? '内置' : '本地',
                            selected: selected),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          DudoTextStyles.sans(color: foreground, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (deleting)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (selected)
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
                    onTap: deleting ? null : onDelete,
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
        ),
      ),
    );
  }

  String _builtinDescription(ReaderFont font) {
    return switch (font.familyKey) {
      DudoFonts.sansSc => '清晰稳定的中文无衬线字体',
      _ => '适合长时间中文阅读的衬线字体',
    };
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '本地字体';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

class _FontLibraryLoading extends StatelessWidget {
  const _FontLibraryLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FontLibraryError extends StatelessWidget {
  const _FontLibraryError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return _FontInfoBox(
      icon: LucideIcons.circleAlert,
      title: '字体库加载失败',
      description: error.toString(),
    );
  }
}

class _EmptyFontLibrary extends StatelessWidget {
  const _EmptyFontLibrary();

  @override
  Widget build(BuildContext context) {
    return const _FontInfoBox(
      icon: LucideIcons.fileType,
      title: '还没有导入字体',
      description: '添加 .ttf 或 .otf 后，可以在这里选择和删除。',
    );
  }
}

class _FontInfoBox extends StatelessWidget {
  const _FontInfoBox({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: DudoColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

Future<bool> _showDeleteFontSheet(BuildContext context, ReaderFont font) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: DudoColors.textPrimary.withValues(alpha: 0.2),
    isScrollControlled: true,
    builder: (context) => _DeleteFontSheet(font: font),
  );
  return result ?? false;
}

class _DeleteFontSheet extends StatelessWidget {
  const _DeleteFontSheet({required this.font});

  final ReaderFont font;

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
                        '删除“${font.displayName}”？',
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
                      '${font.originalFileName ?? font.displayName} · 本地字体',
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
                      onTap: () => Navigator.of(context).pop(true),
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
