import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/messages/app_message.dart';
import '../../../shared/messages/app_message_service.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_tokens.dart';
import '../application/bookshelf_providers.dart';
import '../data/book_cover_storage.dart';
import '../domain/book_cover_style.dart';
import 'cover_flow/cover_flow_chrome.dart';
import 'cover_flow/cover_flow_dialogs.dart';
import 'cover_flow/cover_flow_models.dart';
import 'cover_flow/front_cover_crop_page.dart';
import 'widgets/book_cover_artwork.dart';

class BookEditPage extends ConsumerStatefulWidget {
  const BookEditPage({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends ConsumerState<BookEditPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _introController = TextEditingController();
  final _imagePicker = ImagePicker();

  Book? _book;
  bool _initialized = false;
  bool _suppressDirty = false;
  String _baselineTitle = '';
  String _baselineAuthor = '';
  String _baselineIntro = '';

  Uint8List? _pendingFrontBytes;
  Uint8List? _pendingWrapBytes;
  BookCoverStyle? _pendingStyle;
  bool _clearCustomCover = false;

  bool _saving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_handleTextChanged);
    _authorController.addListener(_handleTextChanged);
    _introController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted || !_initialized || _suppressDirty) return;
    setState(() {});
  }

  void _ensureInitialized(Book book) {
    if (_initialized) return;
    _initialized = true;
    _book = book;
    _baselineTitle = book.title.trim();
    _baselineAuthor = book.author?.trim() ?? '';
    _baselineIntro = book.intro?.trim() ?? '';
    _suppressDirty = true;
    _titleController.text = book.title;
    _authorController.text = book.author ?? '';
    _introController.text = book.intro ?? '';
    _suppressDirty = false;
  }

  bool get _hasUnsavedChanges {
    if (!_initialized) return false;
    return _titleController.text.trim() != _baselineTitle ||
        _authorController.text.trim() != _baselineAuthor ||
        _introController.text.trim() != _baselineIntro ||
        _pendingFrontBytes != null ||
        _clearCustomCover;
  }

  bool get _hasCustomCover {
    final book = _book;
    if (_pendingFrontBytes != null) return true;
    if (_clearCustomCover) return false;
    return book?.customCoverPath?.trim().isNotEmpty == true;
  }

  Future<void> _changeCover() async {
    final action = await showCoverSourceSheet(context);
    if (!mounted || action == null) return;
    switch (action) {
      case CoverSourceAction.gallery:
        await _pickImage(ImageSource.gallery);
      case CoverSourceAction.camera:
        await _pickImage(ImageSource.camera);
      case CoverSourceAction.restore:
        await _restoreDefaultCover();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final book = _book;
    if (book == null) return;
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final result = await Navigator.of(context).push<CoverFlowResult>(
        MaterialPageRoute(
          builder: (_) => FrontCoverCropPage(
            book: book,
            imageBytes: bytes,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _pendingFrontBytes = result.frontBytes;
        _pendingWrapBytes = result.wrapBytes;
        _pendingStyle = result.style;
        _clearCustomCover = false;
      });
    } on PlatformException {
      if (!mounted) return;
      _message().error(
        source == ImageSource.camera ? '无法打开相机，请检查权限' : '无法打开相册，请检查权限',
        title: '选择图片失败',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-pick',
      );
    } catch (_) {
      if (!mounted) return;
      _message().error(
        '读取图片失败，请换一张试试',
        title: '选择图片失败',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-pick',
      );
    }
  }

  Future<void> _restoreDefaultCover() async {
    if (!_hasCustomCover) {
      _message().info(
        '当前已经是默认封面',
        title: '无需恢复',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-restore',
      );
      return;
    }
    final confirmed = await showRestoreCoverDialog(context);
    if (!mounted || confirmed != true) return;
    setState(() {
      _pendingFrontBytes = null;
      _pendingWrapBytes = null;
      _pendingStyle = null;
      _clearCustomCover = true;
    });
  }

  Future<bool> _save() async {
    final book = _book;
    if (book == null || _saving) return false;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _message().error(
        '书名不能为空',
        title: '无法保存',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-save',
      );
      return false;
    }

    setState(() => _saving = true);
    try {
      final storage = ref.read(bookCoverStorageProvider);
      var customCoverPath = book.customCoverPath;
      var customWrapPath = book.customWrapPath;
      var spineColor = book.coverSpineColor;
      var spineWidth = book.coverSpineWidth;
      var backStyle = book.coverBackStyle;

      if (_clearCustomCover) {
        await storage.deleteBookCovers(book.id);
        customCoverPath = null;
        customWrapPath = null;
        spineColor = null;
        spineWidth = null;
        backStyle = null;
      } else if (_pendingFrontBytes != null) {
        await storage.deleteBookCovers(book.id);
        customCoverPath =
            await storage.saveFrontCover(book.id, _pendingFrontBytes!);
        customWrapPath = _pendingWrapBytes == null
            ? null
            : await storage.saveWrapCover(book.id, _pendingWrapBytes!);
        final style = _pendingStyle;
        if (style != null) {
          spineColor = style.spineColor.toARGB32();
          spineWidth = style.spineWidth.storageValue;
          backStyle = style.backStyle.storageValue;
        }
      }

      final author = _authorController.text.trim();
      final intro = _introController.text.trim();
      await ref.read(bookshelfRepositoryProvider).updateBookProfile(
            bookId: book.id,
            title: title,
            author: author.isEmpty ? null : author,
            intro: intro.isEmpty ? null : intro,
            customCoverPath: customCoverPath,
            customWrapPath: customWrapPath,
            coverSpineColor: spineColor,
            coverSpineWidth: spineWidth,
            coverBackStyle: backStyle,
          );
      if (!mounted) return true;

      setState(() {
        _baselineTitle = title;
        _baselineAuthor = author;
        _baselineIntro = intro;
        _pendingFrontBytes = null;
        _pendingWrapBytes = null;
        _pendingStyle = null;
        _clearCustomCover = false;
      });
      _message().success(
        '书籍资料已保存',
        title: '保存成功',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-save',
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      _message().error(
        '请稍后重试',
        title: '保存失败',
        position: AppMessagePosition.top,
        dedupeKey: 'book-edit-save',
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestLeave() async {
    if (!_hasUnsavedChanges) {
      _popPage();
      return;
    }
    final action = await showUnsavedLeaveDialog(context);
    if (!mounted || action == null || action == LeaveEditAction.stay) return;
    if (action == LeaveEditAction.discard) {
      _leaveNow();
      return;
    }
    final saved = await _save();
    if (!mounted) return;
    if (saved) _leaveNow();
  }

  void _leaveNow() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _popPage();
    });
  }

  void _popPage() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('${AppRoutes.bookDetail}/${widget.bookId}');
    }
  }

  AppMessageService _message() => ref.read(appMessageServiceProvider);

  @override
  Widget build(BuildContext context) {
    final bookValue = ref.watch(bookByIdProvider(widget.bookId));

    return bookValue.when(
      data: (book) {
        if (book == null) {
          return _EditMessageScaffold(
            message: '这本书可能已经被删除',
            onBack: _popPage,
          );
        }
        _book = book;
        _ensureInitialized(book);
        return PopScope(
          canPop: !_hasUnsavedChanges || _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(_requestLeave());
          },
          child: _buildEditor(book),
        );
      },
      loading: () => Scaffold(
        backgroundColor: DudoColors.paperBackground,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DudoColors.primary,
            ),
          ),
        ),
      ),
      error: (_, __) => _EditMessageScaffold(
        message: '读取书籍资料失败',
        onBack: _popPage,
      ),
    );
  }

  Widget _buildEditor(Book book) {
    final previewTitle =
        _titleController.text.trim().isEmpty ? '书' : _titleController.text;
    final previewAuthor = _authorController.text.trim();

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _EditTopBar(
              saving: _saving,
              onBack: _requestLeave,
              onSave: () => unawaited(_save()),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOK PROFILE',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '编辑书籍资料',
                          style: DudoTextStyles.serif(
                            color: DudoColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '更新书名、作者、简介与封面。',
                          style: DudoTextStyles.sans(
                            color: DudoColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CoverCard(
                          preview: BookCoverArtwork(
                            title: previewTitle,
                            author: previewAuthor.isEmpty
                                ? book.author
                                : previewAuthor,
                            coverUrl: book.coverUrl,
                            customCoverPath: _clearCustomCover
                                ? null
                                : book.customCoverPath,
                            pendingBytes: _pendingFrontBytes,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hasCustomCover: _hasCustomCover,
                          onChangeCover: _changeCover,
                          onRestore: _restoreDefaultCover,
                        ),
                        const SizedBox(height: 12),
                        _EditFieldCard(
                          icon: LucideIcons.type,
                          label: '书名',
                          child: TextField(
                            controller: _titleController,
                            maxLines: 1,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('输入书名'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EditFieldCard(
                          icon: LucideIcons.userRound,
                          label: '作者',
                          child: TextField(
                            controller: _authorController,
                            maxLines: 1,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 14,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('未知作者'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EditFieldCard(
                          icon: LucideIcons.alignLeft,
                          label: '简介',
                          child: TextField(
                            controller: _introController,
                            minLines: 3,
                            maxLines: 6,
                            keyboardType: TextInputType.multiline,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 13.5,
                              height: 1.6,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('还没有简介'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BookInfoCard(book: book),
                        const SizedBox(height: 12),
                        const CoverFlowHint(
                          text: '保存后将同步到书架与书籍详情页封面。',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: CoverFlowPrimaryButton(
                label: '保存修改',
                icon: LucideIcons.check,
                loading: _saving,
                onPressed: () => unawaited(_save()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      hintText: hint,
      hintStyle: DudoTextStyles.sans(
        color: DudoColors.textSecondary.withValues(alpha: 0.7),
        fontSize: 13.5,
      ),
    );
  }
}

class _EditTopBar extends StatelessWidget {
  const _EditTopBar({
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            _TopCircleButton(
              icon: LucideIcons.arrowLeft,
              onTap: onBack,
              background: DudoColors.surface,
              foreground: DudoColors.textPrimary,
            ),
            const Spacer(),
            _TopCircleButton(
              icon: LucideIcons.check,
              onTap: onSave,
              background: DudoColors.primaryContainer,
              foreground: DudoColors.primaryDark,
              loading: saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Icon(icon, color: foreground, size: 19),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.preview,
    required this.hasCustomCover,
    required this.onChangeCover,
    required this.onRestore,
  });

  final Widget preview;
  final bool hasCustomCover;
  final VoidCallback onChangeCover;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 108,
            height: 148,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: preview,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '书籍封面',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasCustomCover
                        ? '正在使用自定义封面，会同步到书架和书籍详情页。'
                        : '使用书源封面或自动生成的封面。',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textSecondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Material(
                        color: DudoColors.ink,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onChangeCover,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.imagePlus,
                                  color: DudoColors.onInk,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '更换封面',
                                  style: DudoTextStyles.sans(
                                    color: DudoColors.onInk,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (hasCustomCover)
                        TextButton(
                          onPressed: onRestore,
                          style: TextButton.styleFrom(
                            foregroundColor: DudoColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '恢复默认',
                            style: DudoTextStyles.sans(
                              color: DudoColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}

class _EditFieldCard extends StatelessWidget {
  const _EditFieldCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DudoColors.secondary, size: 13),
              const SizedBox(width: 6),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final source = book.localPath == null ? '在线书源' : '本地文件';
    final started = book.lastChapterIndex > 0 || book.lastReadPosition > 0;
    final progress = !started
        ? '还未开始'
        : '已读第 ${book.lastChapterIndex + 1} 章';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        children: [
          _InfoRow(label: '来源', value: source),
          const SizedBox(height: 9),
          _InfoRow(label: '阅读进度', value: progress),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: DudoTextStyles.sans(
            color: DudoColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: DudoTextStyles.sans(
            color: DudoColors.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EditMessageScaffold extends StatelessWidget {
  const _EditMessageScaffold({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: SafeArea(
        child: Column(
          children: [
            _EditTopBar(
              saving: false,
              onBack: onBack,
              onSave: () {},
            ),
            Expanded(
              child: Center(
                child: Text(
                  message,
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 14,
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
