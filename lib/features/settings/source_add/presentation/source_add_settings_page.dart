import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_router.dart';
import '../../../../features/bookshelf/application/bookshelf_providers.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';

class SourceAddSettingsPage extends ConsumerWidget {
  const SourceAddSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '内容与书源',
          title: '添加书源',
          showAction: false,
        ),
        const SizedBox(height: 14),
        _LocalBookImportCard(onImport: () => _importLocalBook(context, ref)),
        const SizedBox(height: 14),
        const SettingsSectionTitle('在线书源'),
        const SizedBox(height: 10),
        const _SourceAddressInput(),
        const SizedBox(height: 10),
        const _RuleFileImportRow(),
        const SizedBox(height: 14),
        const _ImportNoticeCard(),
      ],
    );
  }

  Future<void> _importLocalBook(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(localBookImportServiceProvider).importTxtBook();
    ref.invalidate(shelfBooksProvider);
    if (result != null && context.mounted) {
      context.go(AppRoutes.bookshelf);
    }
  }
}

class _LocalBookImportCard extends StatelessWidget {
  const _LocalBookImportCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceHigh.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  LucideIcons.fileUp,
                  color: DudoColors.surfaceHigh,
                  size: 28,
                ),
              ),
              Text(
                '推荐',
                style: DudoTextStyles.sans(
                  color: DudoColors.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '导入本地书籍文件',
            style: DudoTextStyles.serif(
              color: DudoColors.surfaceHigh,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '选择 TXT、EPUB 等文件，导入后直接加入书架。',
            style: DudoTextStyles.sans(
              color: DudoColors.outline,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: _DarkCardButton(
              label: '选择文件',
              icon: LucideIcons.arrowRight,
              onTap: onImport,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkCardButton extends StatelessWidget {
  const _DarkCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: DudoColors.surfaceHigh,
            borderRadius: AppRadius.full,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: DudoColors.textPrimary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceAddressInput extends StatelessWidget {
  const _SourceAddressInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const _SourceIconWrap(icon: LucideIcons.link),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '粘贴书源订阅地址',
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: DudoColors.secondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: DudoColors.primaryContainer,
              borderRadius: AppRadius.full,
            ),
            alignment: Alignment.center,
            child: Text(
              '添加',
              style: DudoTextStyles.sans(
                color: DudoColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleFileImportRow extends StatelessWidget {
  const _RuleFileImportRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const _SourceIconWrap(icon: LucideIcons.fileCode),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '导入规则文件',
                  style: DudoTextStyles.sans(
                    color: DudoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '适合已有书源配置文件',
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: DudoColors.outline,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SourceIconWrap extends StatelessWidget {
  const _SourceIconWrap({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: DudoColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: DudoColors.secondary, size: 18),
    );
  }
}

class _ImportNoticeCard extends StatelessWidget {
  const _ImportNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoticeTitle(),
          SizedBox(height: 7),
          _NoticeLine(
            dotColor: DudoColors.primary,
            text: '本地书会直接进入书架，在线书源会先进入校验。',
          ),
          SizedBox(height: 7),
          _NoticeLine(
            dotColor: DudoColors.primary,
            text: '校验通过后即可用于搜索、更新章节和加入书架。',
          ),
          SizedBox(height: 7),
          _NoticeLine(
            icon: LucideIcons.triangleAlert,
            iconColor: DudoColors.accent,
            text: '请只导入可信来源的本地文件和书源规则，未知资源可能包含失效链接、异常脚本或误导性内容。',
          ),
        ],
      ),
    );
  }
}

class _NoticeTitle extends StatelessWidget {
  const _NoticeTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '添加后会发生什么？',
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NoticeLine extends StatelessWidget {
  const _NoticeLine({
    required this.text,
    this.dotColor,
    this.icon,
    this.iconColor,
  });

  final String text;
  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          height: 18,
          child: icon == null
              ? Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

