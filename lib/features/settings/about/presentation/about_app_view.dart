import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../data/external_link_launcher.dart';
import '../domain/about_links.dart';
import '../domain/about_platform.dart';

enum AboutUpdateDisplayState {
  beforeCheck,
  hasUpdate,
}

class AboutAppView extends ConsumerStatefulWidget {
  const AboutAppView({
    super.key,
    this.platform = AboutPlatform.android,
    this.initialUpdateState = AboutUpdateDisplayState.beforeCheck,
  });

  final AboutPlatform platform;
  final AboutUpdateDisplayState initialUpdateState;

  @override
  ConsumerState<AboutAppView> createState() => _AboutAppViewState();
}

class _AboutAppViewState extends ConsumerState<AboutAppView> {
  late AboutUpdateDisplayState _updateState;

  @override
  void initState() {
    super.initState();
    _updateState = widget.initialUpdateState;
  }

  void _checkForUpdates() {
    setState(() => _updateState = AboutUpdateDisplayState.hasUpdate);
  }

  Future<void> _openExternal(Uri uri, {required String failureTitle}) async {
    final opened = await ref.read(externalLinkLauncherProvider).open(uri);
    if (!opened && mounted) {
      ref.read(appMessageServiceProvider).warning(
        '无法打开浏览器，可手动访问 ${AboutLinks.display(uri)}',
        title: failureTitle,
        dedupeKey: 'about-external-link',
      );
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share('Dudo · 一间安静的随身书房\n${AboutLinks.repository}');
    } catch (_) {
      if (!mounted) return;
      ref.read(appMessageServiceProvider).warning(
        '当前环境暂不支持系统分享',
        title: '分享失败',
        dedupeKey: 'about-share',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AboutColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          children: [
            _AboutTopActions(onShare: _shareApp),
            const SizedBox(height: 14),
            const _AboutAppIdentityCard(),
            const SizedBox(height: 14),
            _AboutUpdateSection(
              platform: widget.platform,
              state: _updateState,
              onCheckUpdates: _checkForUpdates,
              onOpenRepository: () => _openExternal(
                AboutLinks.repository,
                failureTitle: '打开仓库地址失败',
              ),
            ),
            const SizedBox(height: 14),
            _AboutSupportSection(
              onOpenGuide: () => context.push(AppRoutes.aboutGuide),
              onFeedback: () => context.push(AppRoutes.aboutFeedback),
              onShowLicenses: () => context.push(AppRoutes.aboutLicenses),
            ),
            const SizedBox(height: 14),
            _AboutListRow(
              icon: LucideIcons.shieldCheck,
              title: '隐私政策',
              description: '查看阅读记录、书签与高亮的数据说明',
              onTap: () => context.push(AppRoutes.aboutPrivacy),
            ),
            const SizedBox(height: 14),
            const _AboutFooter(),
          ],
        ),
      ),
    );
  }
}

class _AboutTopActions extends StatelessWidget {
  const _AboutTopActions({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AboutCircleButton(
            icon: LucideIcons.chevronLeft,
            onTap: () => context.pop(),
          ),
          Text(
            '应用说明',
            style: DudoTextStyles.sans(
              color: _AboutColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          _AboutCircleButton(icon: LucideIcons.share2, onTap: onShare),
        ],
      ),
    );
  }
}

class _AboutCircleButton extends StatelessWidget {
  const _AboutCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AboutColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _AboutColors.outlineStrong),
          ),
          child: Icon(icon, color: _AboutColors.secondary, size: 20),
        ),
      ),
    );
  }
}

class _AboutAppIdentityCard extends StatelessWidget {
  const _AboutAppIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AboutColors.text,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutAppIdentityHeader(),
          SizedBox(height: 12),
          Text(
            '一间安静的随身书房，用来整理书架、记录阅读，并保持舒服的阅读节奏。',
            style: TextStyle(
              fontFamily: DudoFonts.sansSc,
              color: _AboutColors.outlineStrong,
              fontSize: 12,
              height: 1.4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutAppIdentityHeader extends StatelessWidget {
  const _AboutAppIdentityHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AboutColors.logoSurface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _AboutColors.outline),
          ),
          child: Text(
            '读',
            style: DudoTextStyles.serif(
              color: DudoColors.primary,
              fontSize: 33,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dudo',
                style: DudoTextStyles.serif(
                  color: _AboutColors.logoSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0 · 内测版',
                style: DudoTextStyles.sans(
                  color: _AboutColors.outlineStrong,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutUpdateSection extends StatelessWidget {
  const _AboutUpdateSection({
    required this.platform,
    required this.state,
    required this.onCheckUpdates,
    required this.onOpenRepository,
  });

  final AboutPlatform platform;
  final AboutUpdateDisplayState state;
  final VoidCallback onCheckUpdates;
  final VoidCallback onOpenRepository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AboutSectionTitle('应用更新'),
        const SizedBox(height: 8),
        _AboutUpdateCard(
          platform: platform,
          state: state,
          onCheckUpdates: onCheckUpdates,
          onOpenRepository: onOpenRepository,
        ),
      ],
    );
  }
}

class _AboutUpdateCard extends StatelessWidget {
  const _AboutUpdateCard({
    required this.platform,
    required this.state,
    required this.onCheckUpdates,
    required this.onOpenRepository,
  });

  final AboutPlatform platform;
  final AboutUpdateDisplayState state;
  final VoidCallback onCheckUpdates;
  final VoidCallback onOpenRepository;

  bool get _hasUpdate => state == AboutUpdateDisplayState.hasUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AboutColors.updateSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AboutColors.updateOutline),
      ),
      child: Column(
        children: [
          _AboutUpdateHeader(
            icon: _hasUpdate ? LucideIcons.packageCheck : LucideIcons.package,
            title: _hasUpdate ? '发现新版本' : '检查应用更新',
            description: _hasUpdate
                ? '下载最新安装包，或查看项目仓库中的版本说明。'
                : '联网检查是否有新的 ${platform.packageLabel} 可用。',
          ),
          const SizedBox(height: 12),
          _AboutVersionPanel(
            remoteLabel: _hasUpdate ? '最新版本' : '远端版本',
            remoteVersion: _hasUpdate ? 'v0.1.1' : '待检测',
            showNewBadge: _hasUpdate,
          ),
          const SizedBox(height: 12),
          _AboutActionRow(
            left: _AboutUpdateButton.primary(
              icon: _hasUpdate ? LucideIcons.download : LucideIcons.download,
              label: _hasUpdate ? '立即下载' : '检测更新',
              backgroundColor: _AboutColors.darkButton,
              foregroundColor: _AboutColors.buttonLightText,
              shadowColor: const Color(0x40000000),
              onTap: _hasUpdate ? null : onCheckUpdates,
            ),
            right: _AboutUpdateButton.primary(
              icon: LucideIcons.gitBranch,
              label: '仓库地址',
              backgroundColor: _AboutColors.brownButton,
              foregroundColor: _AboutColors.repoText,
              shadowColor: const Color(0x668A6432),
              onTap: onOpenRepository,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _AboutUpdateButton.secondary(
              icon: LucideIcons.listChecks,
              label: '查看日志',
              onTap: () => _showAboutChangelogSheet(
                context,
                onOpenRepository: onOpenRepository,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutUpdateHeader extends StatelessWidget {
  const _AboutUpdateHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AboutColors.iconTile,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _AboutColors.outline),
          ),
          child: Icon(icon, color: _AboutColors.packageIcon, size: 23),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DudoTextStyles.sans(
                  color: _AboutColors.updateTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: _AboutColors.updateDescription,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutVersionPanel extends StatelessWidget {
  const _AboutVersionPanel({
    required this.remoteLabel,
    required this.remoteVersion,
    required this.showNewBadge,
  });

  final String remoteLabel;
  final String remoteVersion;
  final bool showNewBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _AboutColors.versionPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AboutColors.versionOutline),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _AboutVersionCell(
              label: '当前版本',
              version: 'v0.1.0',
              versionColor: _AboutColors.versionText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _AboutColors.versionArrowBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.arrowRight,
              color: _AboutColors.packageIcon,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AboutVersionCell(
              label: remoteLabel,
              version: remoteVersion,
              versionColor: showNewBadge
                  ? _AboutColors.remoteVersionText
                  : _AboutColors.pendingText,
              showNewBadge: showNewBadge,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutVersionCell extends StatelessWidget {
  const _AboutVersionCell({
    required this.label,
    required this.version,
    required this.versionColor,
    this.showNewBadge = false,
  });

  final String label;
  final String version;
  final Color versionColor;
  final bool showNewBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: DudoTextStyles.numeric(
            color: _AboutColors.versionLabel,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                version,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.numeric(
                  color: versionColor,
                  fontSize: 18,
                  fontWeight: showNewBadge ? FontWeight.w900 : FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            if (showNewBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                decoration: BoxDecoration(
                  color: _AboutColors.remoteVersionText,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'NEW',
                  style: DudoTextStyles.numeric(
                    color: _AboutColors.buttonLightText,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }
}

class _AboutUpdateButton extends StatelessWidget {
  const _AboutUpdateButton.primary({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.shadowColor,
    this.onTap,
  })  : height = 48,
        borderColor = null;

  const _AboutUpdateButton.secondary({
    required this.icon,
    required this.label,
    this.onTap,
  })  : height = 42,
        backgroundColor = _AboutColors.secondaryButton,
        foregroundColor = _AboutColors.secondaryButtonText,
        borderColor = _AboutColors.secondaryButtonOutline,
        shadowColor = null;

  final IconData icon;
  final String label;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(height == 48 ? 16 : 14),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(height == 48 ? 16 : 14),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height == 48 ? 16 : 14),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
            boxShadow: shadowColor == null
                ? null
                : [
                    BoxShadow(
                      color: shadowColor!,
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: height == 48 ? 18 : 16),
              const SizedBox(width: 7),
              Text(
                label,
                style: DudoTextStyles.numeric(
                  color: foregroundColor,
                  fontSize: height == 48 ? 14 : 13,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAboutChangelogSheet(
  BuildContext context, {
  required VoidCallback onOpenRepository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    builder: (context) =>
        _AboutChangelogSheet(onOpenRepository: onOpenRepository),
  );
}

class _AboutChangelogSheet extends StatelessWidget {
  const _AboutChangelogSheet({required this.onOpenRepository});

  final VoidCallback onOpenRepository;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = screenHeight * 0.76 > 620 ? 620.0 : screenHeight * 0.76;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: sheetHeight,
        padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
        decoration: const BoxDecoration(
          color: _AboutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: _AboutColors.outline),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x2225251F),
              offset: Offset(0, -12),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            const _AboutSheetHandle(),
            const SizedBox(height: 14),
            const _AboutChangelogHeader(),
            const SizedBox(height: 14),
            const _AboutChangelogSummary(),
            const SizedBox(height: 14),
            const Expanded(child: _AboutChangelogList()),
            const SizedBox(height: 14),
            _AboutChangelogActions(onOpenRepository: onOpenRepository),
          ],
        ),
      ),
    );
  }
}

class _AboutSheetHandle extends StatelessWidget {
  const _AboutSheetHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: _AboutColors.outlineStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _AboutChangelogHeader extends StatelessWidget {
  const _AboutChangelogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AboutColors.text,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            LucideIcons.listChecks,
            color: _AboutColors.logoSurface,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '更新日志',
                style: DudoTextStyles.sans(
                  color: _AboutColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dudo 0.1.1 · 2026/06/07',
                style: DudoTextStyles.sans(
                  color: _AboutColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: _AboutColors.surfaceLow,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                LucideIcons.x,
                color: _AboutColors.secondary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutChangelogSummary extends StatelessWidget {
  const _AboutChangelogSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AboutColors.page,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AboutColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本次更新重点',
            style: DudoTextStyles.sans(
              color: _AboutColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '改善阅读器稳定性，补齐应用说明、隐私说明与开源分发相关入口。',
            style: DudoTextStyles.sans(
              color: _AboutColors.secondaryDark,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutChangelogList extends StatelessWidget {
  const _AboutChangelogList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        return _AboutChangelogGroupView(
            group: _aboutChangelogGroups[index]);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemCount: _aboutChangelogGroups.length,
    );
  }
}

class _AboutChangelogGroupView extends StatelessWidget {
  const _AboutChangelogGroupView({required this.group});

  final _AboutChangelogGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:  BoxDecoration(
                color: DudoColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              group.title,
              style: DudoTextStyles.sans(
                color: _AboutColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final item in group.items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '· $item',
                  style: DudoTextStyles.sans(
                    color: _AboutColors.secondaryDark,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _AboutChangelogActions extends StatelessWidget {
  const _AboutChangelogActions({required this.onOpenRepository});

  final VoidCallback onOpenRepository;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AboutSheetActionButton(
            label: '知道了',
            backgroundColor: _AboutColors.text,
            foregroundColor: _AboutColors.logoSurface,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 8),
        _AboutSheetActionButton(
          width: 108,
          label: '查看 GitHub',
          backgroundColor: _AboutColors.surfaceLow,
          foregroundColor: _AboutColors.secondary,
          borderColor: _AboutColors.outlineStrong,
          onTap: onOpenRepository,
        ),
      ],
    );
  }
}

class _AboutSheetActionButton extends StatelessWidget {
  const _AboutSheetActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
    this.width,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final Color? borderColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Text(
            label,
            style: DudoTextStyles.sans(
              color: foregroundColor,
              fontSize: width == null ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    return width == null ? button : SizedBox(width: width, child: button);
  }
}

class _AboutChangelogGroup {
  const _AboutChangelogGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

const _aboutChangelogGroups = [
  _AboutChangelogGroup(
    title: '阅读体验',
    items: [
      '优化章节翻页时的状态同步',
      '降低连续翻页导致的误触概率',
    ],
  ),
  _AboutChangelogGroup(
    title: '应用说明',
    items: [
      '新增应用更新检测模块',
      '隐私政策入口改为统一列表样式',
    ],
  ),
  _AboutChangelogGroup(
    title: '开源分发',
    items: [
      '各平台支持安装包下载与覆盖安装',
      '支持 GitHub Releases 跳转与链接复制',
    ],
  ),
  _AboutChangelogGroup(
    title: '修复',
    items: [
      '修复部分小屏设备下的文字拥挤',
      '调整卡片阴影和描边层级',
    ],
  ),
];

class _AboutSupportSection extends StatelessWidget {
  const _AboutSupportSection({
    required this.onOpenGuide,
    required this.onFeedback,
    required this.onShowLicenses,
  });

  final VoidCallback onOpenGuide;
  final VoidCallback onFeedback;
  final VoidCallback onShowLicenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AboutSectionTitle('帮助与支持'),
        const SizedBox(height: 8),
        _AboutListRow(
          icon: LucideIcons.bookOpen,
          title: '使用说明',
          description: '了解导入、书架与阅读设置',
          onTap: onOpenGuide,
        ),
        const SizedBox(height: 7),
        _AboutListRow(
          icon: LucideIcons.messageCircle,
          title: '反馈与建议',
          description: '告诉我们遇到的问题或想法',
          onTap: onFeedback,
        ),
        const SizedBox(height: 7),
        _AboutListRow(
          icon: LucideIcons.fileText,
          title: '开源许可',
          description: '查看第三方库与版权说明',
          onTap: onShowLicenses,
        ),
      ],
    );
  }
}

class _AboutSectionTitle extends StatelessWidget {
  const _AboutSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(
        color: _AboutColors.text,
        fontSize: text == '应用更新' ? 16 : 17,
        fontWeight: FontWeight.w600,
        height: text == '应用更新' ? 1.45 : null,
        letterSpacing: text == '应用更新' ? 0.2 : null,
      ),
    );
  }
}

class _AboutListRow extends StatelessWidget {
  const _AboutListRow({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _AboutColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AboutColors.outline),
          ),
          child: Row(
            children: [
              Icon(icon, color: _AboutColors.secondary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DudoTextStyles.sans(
                        color: _AboutColors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: _AboutColors.secondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: _AboutColors.chevron,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Center(
        child: Text(
          'Dudo · 2026',
          style: DudoTextStyles.sans(
            color: _AboutColors.secondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AboutColors {
  const _AboutColors._();

  static const Color page = Color(0xFFF8F4EA);
  static const Color surface = Color(0xFFFFFBF2);
  static const Color surfaceLow = Color(0xFFF3ECDD);
  static const Color logoSurface = Color(0xFFFFF8EA);
  static const Color text = Color(0xFF25251F);
  static const Color secondary = Color(0xFF8A735A);
  static const Color secondaryDark = Color(0xFF5B4B39);
  static const Color outlineStrong = Color(0xFFD8CDBB);
  static const Color outline = Color(0xFFE7DCC8);
  static const Color chevron = Color(0xFFB8A88E);

  static const Color updateSurface = Color(0xFFFFFCF5);
  static const Color updateOutline = Color(0xFFE5D8C2);
  static const Color iconTile = Color(0xFFF7EFDF);
  static const Color packageIcon = Color(0xFF6B512E);
  static const Color updateTitle = Color(0xFF2E281F);
  static const Color updateDescription = Color(0xFF756A5A);
  static const Color versionPanel = Color(0xFFF8F0E1);
  static const Color versionOutline = Color(0xFFE8D9BF);
  static const Color versionArrowBg = Color(0xFFE7D5B6);
  static const Color versionLabel = Color(0xFF8A7D69);
  static const Color versionText = Color(0xFF3A3328);
  static const Color remoteVersionText = Color(0xFF2F2A22);
  static const Color pendingText = Color(0xFF6F6252);
  static const Color darkButton = Color(0xFF2F2A22);
  static const Color brownButton = Color(0xFF8B6230);
  static const Color buttonLightText = Color(0xFFFFF4DE);
  static const Color repoText = Color(0xFFFFF7E8);
  static const Color secondaryButton = Color(0xFFFBF6EA);
  static const Color secondaryButtonText = Color(0xFF5D513F);
  static const Color secondaryButtonOutline = Color(0xFFDCC9AA);
}
