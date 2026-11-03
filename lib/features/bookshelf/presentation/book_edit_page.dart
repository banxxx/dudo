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
import 'widgets/book_3d_artwork.dart';
import 'widgets/book_artwork_renderer.dart';
import 'widgets/book_cover_artwork.dart';
import 'widgets/photoreal_book_artwork.dart';

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
  bool _baselineShowCoverText = true;
  bool _showCoverText = true;

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
    _baselineShowCoverText = book.coverShowText;
    _showCoverText = book.coverShowText;
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
        _showCoverText != _baselineShowCoverText ||
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
            showText: _showCoverText,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _pendingFrontBytes = result.frontBytes;
        _pendingWrapBytes = result.wrapBytes;
        _pendingStyle = result.style;
        _showCoverText = result.style.showText;
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
      _showCoverText = true;
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
      var showCoverText = _showCoverText;

      if (_clearCustomCover) {
        await storage.deleteBookCovers(book.id);
        customCoverPath = null;
        customWrapPath = null;
        spineColor = null;
        spineWidth = null;
        backStyle = null;
        showCoverText = true;
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
            coverShowText: showCoverText,
          );
      if (!mounted) return true;

      setState(() {
        _baselineTitle = title;
        _baselineAuthor = author;
        _baselineIntro = intro;
        _baselineShowCoverText = showCoverText;
        _showCoverText = showCoverText;
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

  Widget _previewArtwork(
    Book book, {
    required String title,
    required String author,
  }) {
    final customCover = _clearCustomCover ? null : book.customCoverPath;
    final spineColor = _coverSpineColor(book);
    final fallback = Book3DArtwork(
      width: 108,
      height: 148,
      spineColor: spineColor ?? DudoColors.primary,
      spineTitle: title,
      spineAuthor: author,
      showSpineText: _showCoverText,
      child: BookCoverArtwork(
        title: title,
        author: author,
        coverUrl: book.coverUrl,
        customCoverPath: customCover,
        pendingBytes: _pendingFrontBytes,
        borderRadius: BorderRadius.zero,
        showTitleOverlay: _showCoverText,
      ),
    );
    final hasUserCover = _pendingFrontBytes != null ||
        (customCover != null && customCover.isNotEmpty);
    return PhotorealBookArtwork(
      spec: BookArtworkSpec(
        width: 108,
        height: 148,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        title: title,
        author: author,
        coverPath: customCover,
        coverUrl: book.coverUrl,
        pendingBytes: _pendingFrontBytes,
        spineColor: spineColor,
        spineWidth: _coverSpineWidth(book),
        showSpineText: _showCoverText,
        showCoverType: hasUserCover && _showCoverText,
      ),
      fallback: fallback,
    );
  }

  Widget _buildEditor(Book book) {
    final previewTitle =
        _titleController.text.trim().isEmpty ? '书' : _titleController.text;
    final previewAuthor = _authorController.text.trim();
    final chapterCount =
        ref.watch(bookChapterCountProvider(widget.bookId)).valueOrNull;

    return Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _EditTopBar(onBack: _requestLeave),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      6,
                      20,
                      18 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOK PROFILE',
                          style: DudoTextStyles.sans(
                            color: DudoColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '编辑书籍资料',
                          style: DudoTextStyles.serif(
                            color: DudoColors.textPrimary,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '整理书名、作者、封面与简介，让书架中的信息保持准确。',
                          style: DudoTextStyles.sans(
                            color: DudoColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CoverCard(
                          preview: _previewArtwork(
                            book,
                            title: previewTitle,
                            author: previewAuthor.isEmpty
                                ? (book.author ?? '')
                                : previewAuthor,
                          ),
                          onChangeCover: _changeCover,
                        ),
                        if (_hasCustomCover) ...[
                          const SizedBox(height: 10),
                          _CoverTextToggle(
                            value: _showCoverText,
                            onChanged: (value) =>
                                setState(() => _showCoverText = value),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _EditFieldCard(
                          icon: LucideIcons.bookOpen,
                          label: '书名',
                          child: TextField(
                            controller: _titleController,
                            maxLines: 1,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('输入书名'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EditFieldCard(
                          icon: LucideIcons.userPen,
                          label: '作者',
                          child: TextField(
                            controller: _authorController,
                            maxLines: 1,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('未知作者'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _EditInfoField(
                                icon: LucideIcons.database,
                                label: '来源',
                                value: book.localPath == null ? '在线书源' : '本地书库',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _EditInfoField(
                                icon: LucideIcons.chartNoAxesColumn,
                                label: '阅读状态',
                                value: _readingStatus(book, chapterCount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _EditFieldCard(
                          icon: LucideIcons.notebookText,
                          label: '简介',
                          verticalPadding: 12,
                          child: TextField(
                            controller: _introController,
                            minLines: 3,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                            style: DudoTextStyles.sans(
                              color: DudoColors.textPrimary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            cursorColor: DudoColors.primary,
                            decoration: _fieldDecoration('还没有简介'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _EditSyncHint(),
                        const SizedBox(height: 12),
                        CoverFlowPrimaryButton(
                          label: '保存修改',
                          icon: LucideIcons.check,
                          loading: _saving,
                          radius: 22,
                          labelSize: 15,
                          labelWeight: FontWeight.w700,
                          // The button's own InkWell feedback is off and the
                          // action plays one click, so a save can never sound
                          // like it ran several times.
                          enableFeedback: false,
                          onPressed: () {
                            unawaited(
                              SystemSound.play(SystemSoundType.click),
                            );
                            unawaited(_save());
                          },
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
    );
  }

  /// Null means the spine is sampled from the cover, exactly like the detail
  /// page, so the preview and the book it returns to stay in step.
  Color? _coverSpineColor(Book book) {
    final pending = _pendingStyle?.spineColor;
    if (pending != null) return pending;
    final stored = book.coverSpineColor;
    return stored == null ? null : Color(stored);
  }

  CoverSpineWidth _coverSpineWidth(Book book) {
    return _pendingStyle?.spineWidth ??
        CoverSpineWidth.fromStorage(book.coverSpineWidth);
  }

  String _readingStatus(Book book, int? chapterCount) {
    final started = book.lastChapterIndex > 0 || book.lastReadPosition > 0;
    if (!started) return '未开始';
    if (chapterCount == null || chapterCount <= 0) return '阅读中';
    final progress = (((book.lastChapterIndex + 1) / chapterCount) * 100)
        .round()
        .clamp(1, 100);
    return '阅读中 $progress%';
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
  const _EditTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _TopCircleButton(
              icon: LucideIcons.arrowLeft,
              onTap: onBack,
              background: DudoColors.surface,
              foreground: DudoColors.textPrimary,
              borderColor: Colors.transparent,
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
    required this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: borderColor),
    );
    return Material(
      color: background,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.preview,
    required this.onChangeCover,
  });

  final Widget preview;
  final VoidCallback onChangeCover;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 108, height: 148, child: preview),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 148,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '书籍封面',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '建议使用竖版封面，系统会同步用于书架卡片与阅读页顶部。',
                    style: DudoTextStyles.sans(
                      color: DudoColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Material(
                    color: DudoColors.ink,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: onChangeCover,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.imagePlus,
                              color: DudoColors.onInk,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '更换封面',
                              style: DudoTextStyles.sans(
                                color: DudoColors.onInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _CoverTextToggle extends StatelessWidget {
  const _CoverTextToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.type, size: 17, color: DudoColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '封面文字',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '在封面和书脊上显示书名与作者；图片自带文字时可关闭。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CoverFlowSwitch(value: value, onChanged: onChanged),
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
    this.verticalPadding = 11,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DudoColors.secondary, size: 15),
              const SizedBox(width: 7),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _EditInfoField extends StatelessWidget {
  const _EditInfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DudoColors.secondary, size: 15),
              const SizedBox(width: 7),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSyncHint extends StatelessWidget {
  const _EditSyncHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DudoColors.primaryContainerMuted,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              LucideIcons.sparkles,
              color: DudoColors.primaryDark,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '保存后立即同步',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '书架、详情页和阅读进度中的书籍基础信息会一起更新。',
                  style: DudoTextStyles.sans(
                    color: DudoColors.primaryDark,
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
            _EditTopBar(onBack: onBack),
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
