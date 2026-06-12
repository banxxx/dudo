import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../shared/theme/app_fonts.dart';
import '../../../../../shared/theme/app_tokens.dart';

enum AndroidUpdateDisplayState {
  beforeCheck,
  hasUpdate,
}

const _lucideGitHubIcon = IconData(
  57574,
  fontFamily: 'Lucide',
  fontPackage: 'lucide_icons_flutter',
);

class AndroidAboutAppPage extends StatefulWidget {
  const AndroidAboutAppPage({
    super.key,
    this.initialUpdateState = AndroidUpdateDisplayState.beforeCheck,
  });

  final AndroidUpdateDisplayState initialUpdateState;

  @override
  State<AndroidAboutAppPage> createState() => _AndroidAboutAppPageState();
}

class _AndroidAboutAppPageState extends State<AndroidAboutAppPage> {
  late AndroidUpdateDisplayState _updateState;

  @override
  void initState() {
    super.initState();
    _updateState = widget.initialUpdateState;
  }

  void _checkForUpdates() {
    setState(() => _updateState = AndroidUpdateDisplayState.hasUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AndroidAboutColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          children: [
            const _AndroidTopActions(),
            const SizedBox(height: 14),
            const _AndroidAppIdentityCard(),
            const SizedBox(height: 14),
            _AndroidUpdateSection(
              state: _updateState,
              onCheckUpdates: _checkForUpdates,
            ),
            const SizedBox(height: 14),
            const _AndroidSupportSection(),
            const SizedBox(height: 14),
            const _AndroidListRow(
              icon: LucideIcons.shieldCheck,
              title: '隐私政策',
              description: '查看阅读记录、书签与高亮的数据说明',
            ),
            const SizedBox(height: 14),
            const _AndroidAboutFooter(),
          ],
        ),
      ),
    );
  }
}

class _AndroidTopActions extends StatelessWidget {
  const _AndroidTopActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AndroidCircleButton(
            icon: LucideIcons.chevronLeft,
            onTap: () => context.pop(),
          ),
          Text(
            '应用说明',
            style: DudoTextStyles.sans(
              color: _AndroidAboutColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          _AndroidCircleButton(icon: LucideIcons.share2, onTap: () {}),
        ],
      ),
    );
  }
}

class _AndroidCircleButton extends StatelessWidget {
  const _AndroidCircleButton({required this.icon, required this.onTap});

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
            color: _AndroidAboutColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _AndroidAboutColors.outlineStrong),
          ),
          child: Icon(icon, color: _AndroidAboutColors.secondary, size: 20),
        ),
      ),
    );
  }
}

class _AndroidAppIdentityCard extends StatelessWidget {
  const _AndroidAppIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AndroidAboutColors.text,
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
          _AndroidAppIdentityHeader(),
          SizedBox(height: 12),
          Text(
            '一间安静的随身书房，用来整理书架、记录阅读，并保持舒服的阅读节奏。',
            style: TextStyle(
              fontFamily: DudoFonts.sansSc,
              color: _AndroidAboutColors.outlineStrong,
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

class _AndroidAppIdentityHeader extends StatelessWidget {
  const _AndroidAppIdentityHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AndroidAboutColors.logoSurface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _AndroidAboutColors.outline),
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
                  color: _AndroidAboutColors.logoSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0 · 内测版',
                style: DudoTextStyles.sans(
                  color: _AndroidAboutColors.outlineStrong,
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

class _AndroidUpdateSection extends StatelessWidget {
  const _AndroidUpdateSection({
    required this.state,
    required this.onCheckUpdates,
  });

  final AndroidUpdateDisplayState state;
  final VoidCallback onCheckUpdates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AndroidSectionTitle('应用更新'),
        const SizedBox(height: 8),
        _AndroidUpdateCard(state: state, onCheckUpdates: onCheckUpdates),
      ],
    );
  }
}

class _AndroidUpdateCard extends StatelessWidget {
  const _AndroidUpdateCard({
    required this.state,
    required this.onCheckUpdates,
  });

  final AndroidUpdateDisplayState state;
  final VoidCallback onCheckUpdates;

  bool get _hasUpdate => state == AndroidUpdateDisplayState.hasUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AndroidAboutColors.updateSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AndroidAboutColors.updateOutline),
      ),
      child: Column(
        children: [
          _AndroidUpdateHeader(
            icon: _hasUpdate ? LucideIcons.packageCheck : LucideIcons.package,
            title: _hasUpdate ? '发现新版本' : '检查应用更新',
            description: _hasUpdate
                ? '下载最新安装包，或查看项目仓库中的版本说明。'
                : '联网检查是否有新的 Android 安装包可用。',
          ),
          const SizedBox(height: 12),
          _AndroidVersionPanel(
            remoteLabel: _hasUpdate ? '最新版本' : '远端版本',
            remoteVersion: _hasUpdate ? 'v0.1.1' : '待检测',
            showNewBadge: _hasUpdate,
          ),
          const SizedBox(height: 12),
          _AndroidActionRow(
            left: _AndroidUpdateButton.primary(
              icon: _hasUpdate ? LucideIcons.download : LucideIcons.download,
              label: _hasUpdate ? '立即下载' : '检测更新',
              backgroundColor: _AndroidAboutColors.darkButton,
              foregroundColor: _AndroidAboutColors.buttonLightText,
              shadowColor: const Color(0x40000000),
              onTap: _hasUpdate ? null : onCheckUpdates,
            ),
            right: const _AndroidUpdateButton.primary(
              icon: _lucideGitHubIcon,
              label: '仓库地址',
              backgroundColor: _AndroidAboutColors.brownButton,
              foregroundColor: _AndroidAboutColors.repoText,
              shadowColor: Color(0x668A6432),
            ),
          ),
          const SizedBox(height: 12),
          _AndroidActionRow(
            left: _AndroidUpdateButton.secondary(
              icon: LucideIcons.refreshCw,
              label: '检测更新',
              onTap: onCheckUpdates,
            ),
            right: _AndroidUpdateButton.secondary(
              icon: LucideIcons.listChecks,
              label: '查看日志',
              onTap: () => _showAndroidChangelogSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidUpdateHeader extends StatelessWidget {
  const _AndroidUpdateHeader({
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
            color: _AndroidAboutColors.iconTile,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _AndroidAboutColors.outline),
          ),
          child: Icon(icon, color: _AndroidAboutColors.packageIcon, size: 23),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DudoTextStyles.sans(
                  color: _AndroidAboutColors.updateTitle,
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
                  color: _AndroidAboutColors.updateDescription,
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

class _AndroidVersionPanel extends StatelessWidget {
  const _AndroidVersionPanel({
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
        color: _AndroidAboutColors.versionPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AndroidAboutColors.versionOutline),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _AndroidVersionCell(
              label: '当前版本',
              version: 'v0.1.0',
              versionColor: _AndroidAboutColors.versionText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _AndroidAboutColors.versionArrowBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.arrowRight,
              color: _AndroidAboutColors.packageIcon,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AndroidVersionCell(
              label: remoteLabel,
              version: remoteVersion,
              versionColor: showNewBadge
                  ? _AndroidAboutColors.remoteVersionText
                  : _AndroidAboutColors.pendingText,
              showNewBadge: showNewBadge,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidVersionCell extends StatelessWidget {
  const _AndroidVersionCell({
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
            color: _AndroidAboutColors.versionLabel,
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
                  color: _AndroidAboutColors.remoteVersionText,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'NEW',
                  style: DudoTextStyles.numeric(
                    color: _AndroidAboutColors.buttonLightText,
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

class _AndroidActionRow extends StatelessWidget {
  const _AndroidActionRow({required this.left, required this.right});

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

class _AndroidUpdateButton extends StatelessWidget {
  const _AndroidUpdateButton.primary({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.shadowColor,
    this.onTap,
  })  : height = 48,
        borderColor = null;

  const _AndroidUpdateButton.secondary({
    required this.icon,
    required this.label,
    this.onTap,
  })  : height = 42,
        backgroundColor = _AndroidAboutColors.secondaryButton,
        foregroundColor = _AndroidAboutColors.secondaryButtonText,
        borderColor = _AndroidAboutColors.secondaryButtonOutline,
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

Future<void> _showAndroidChangelogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6625251F),
    builder: (context) => const _AndroidChangelogSheet(),
  );
}

class _AndroidChangelogSheet extends StatelessWidget {
  const _AndroidChangelogSheet();

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
          color: _AndroidAboutColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: _AndroidAboutColors.outline),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x2225251F),
              offset: Offset(0, -12),
              blurRadius: 30,
            ),
          ],
        ),
        child: const Column(
          children: [
            _AndroidSheetHandle(),
            SizedBox(height: 14),
            _AndroidChangelogHeader(),
            SizedBox(height: 14),
            _AndroidChangelogSummary(),
            SizedBox(height: 14),
            Expanded(child: _AndroidChangelogList()),
            SizedBox(height: 14),
            _AndroidChangelogActions(),
          ],
        ),
      ),
    );
  }
}

class _AndroidSheetHandle extends StatelessWidget {
  const _AndroidSheetHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: _AndroidAboutColors.outlineStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _AndroidChangelogHeader extends StatelessWidget {
  const _AndroidChangelogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _AndroidAboutColors.text,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            LucideIcons.listChecks,
            color: _AndroidAboutColors.logoSurface,
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
                  color: _AndroidAboutColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dudo 0.1.1 · 2026/06/07',
                style: DudoTextStyles.sans(
                  color: _AndroidAboutColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: _AndroidAboutColors.surfaceLow,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                LucideIcons.x,
                color: _AndroidAboutColors.secondary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AndroidChangelogSummary extends StatelessWidget {
  const _AndroidChangelogSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AndroidAboutColors.page,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AndroidAboutColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本次更新重点',
            style: DudoTextStyles.sans(
              color: _AndroidAboutColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '改善阅读器稳定性，补齐应用说明、隐私说明与开源分发相关入口。',
            style: DudoTextStyles.sans(
              color: _AndroidAboutColors.secondaryDark,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidChangelogList extends StatelessWidget {
  const _AndroidChangelogList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        return _AndroidChangelogGroupView(
            group: _androidChangelogGroups[index]);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemCount: _androidChangelogGroups.length,
    );
  }
}

class _AndroidChangelogGroupView extends StatelessWidget {
  const _AndroidChangelogGroupView({required this.group});

  final _AndroidChangelogGroup group;

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
              decoration: const BoxDecoration(
                color: DudoColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              group.title,
              style: DudoTextStyles.sans(
                color: _AndroidAboutColors.text,
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
                    color: _AndroidAboutColors.secondaryDark,
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

class _AndroidChangelogActions extends StatelessWidget {
  const _AndroidChangelogActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AndroidSheetActionButton(
            label: '知道了',
            backgroundColor: _AndroidAboutColors.text,
            foregroundColor: _AndroidAboutColors.logoSurface,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 8),
        _AndroidSheetActionButton(
          width: 108,
          label: '查看 GitHub',
          backgroundColor: _AndroidAboutColors.surfaceLow,
          foregroundColor: _AndroidAboutColors.secondary,
          borderColor: _AndroidAboutColors.outlineStrong,
          onTap: () {},
        ),
      ],
    );
  }
}

class _AndroidSheetActionButton extends StatelessWidget {
  const _AndroidSheetActionButton({
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

class _AndroidChangelogGroup {
  const _AndroidChangelogGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

const _androidChangelogGroups = [
  _AndroidChangelogGroup(
    title: '阅读体验',
    items: [
      '优化章节翻页时的状态同步',
      '降低连续翻页导致的误触概率',
    ],
  ),
  _AndroidChangelogGroup(
    title: '应用说明',
    items: [
      '新增应用更新检测模块',
      '隐私政策入口改为统一列表样式',
    ],
  ),
  _AndroidChangelogGroup(
    title: '开源分发',
    items: [
      'Android 支持下载 APK 后覆盖安装',
      'iOS 提供 GitHub Releases 跳转与链接复制',
    ],
  ),
  _AndroidChangelogGroup(
    title: '修复',
    items: [
      '修复部分小屏设备下的文字拥挤',
      '调整卡片阴影和描边层级',
    ],
  ),
];

class _AndroidSupportSection extends StatelessWidget {
  const _AndroidSupportSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AndroidSectionTitle('帮助与支持'),
        SizedBox(height: 8),
        _AndroidListRow(
          icon: LucideIcons.bookOpen,
          title: '使用说明',
          description: '了解导入、书架与阅读设置',
        ),
        SizedBox(height: 7),
        _AndroidListRow(
          icon: LucideIcons.messageCircle,
          title: '反馈与建议',
          description: '告诉我们遇到的问题或想法',
        ),
        SizedBox(height: 7),
        _AndroidListRow(
          icon: LucideIcons.fileText,
          title: '开源许可',
          description: '查看第三方库与版权说明',
        ),
      ],
    );
  }
}

class _AndroidSectionTitle extends StatelessWidget {
  const _AndroidSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(
        color: _AndroidAboutColors.text,
        fontSize: text == '应用更新' ? 16 : 17,
        fontWeight: FontWeight.w600,
        height: text == '应用更新' ? 1.45 : null,
        letterSpacing: text == '应用更新' ? 0.2 : null,
      ),
    );
  }
}

class _AndroidListRow extends StatelessWidget {
  const _AndroidListRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _AndroidAboutColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AndroidAboutColors.outline),
          ),
          child: Row(
            children: [
              Icon(icon, color: _AndroidAboutColors.secondary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DudoTextStyles.sans(
                        color: _AndroidAboutColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: _AndroidAboutColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: _AndroidAboutColors.chevron,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidAboutFooter extends StatelessWidget {
  const _AndroidAboutFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Center(
        child: Text(
          'Dudo · 2026',
          style: DudoTextStyles.sans(
            color: _AndroidAboutColors.secondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AndroidAboutColors {
  const _AndroidAboutColors._();

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
