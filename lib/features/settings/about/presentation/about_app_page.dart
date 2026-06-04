import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/dudo_page_frame.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DudoColors.paperBackground,
      body: DudoPageFrame(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 18),
        constrainWidth: false,
        eager: true,
        children: [
          _TopActions(),
          SizedBox(height: 14),
          _AppIdentityCard(),
          SizedBox(height: 14),
          _SupportSection(),
          SizedBox(height: 14),
          _PrivacyCard(),
          SizedBox(height: 14),
          _AboutFooter(),
        ],
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
              icon: LucideIcons.chevronLeft, onTap: () => context.pop()),
          Text(
            '应用说明',
            style: DudoTextStyles.sans(
              color: DudoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          _CircleButton(icon: LucideIcons.share2, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

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
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outline),
          ),
          child: Icon(icon, color: DudoColors.secondary, size: 20),
        ),
      ),
    );
  }
}

class _AppIdentityCard extends StatelessWidget {
  const _AppIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudoColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2225251F),
            offset: Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: DudoColors.outlineVariant),
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
                        color: DudoColors.surfaceHigh,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0 · 内测版',
                      style: DudoTextStyles.sans(
                        color: DudoColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '一间安静的随身书房，用来整理书架、记录阅读，并保持舒服的阅读节奏。',
            style: DudoTextStyles.sans(
              color: DudoColors.outline,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('帮助与支持'),
        SizedBox(height: 8),
        _SupportRow(
          icon: LucideIcons.bookOpen,
          title: '使用说明',
          description: '了解导入、书架与阅读设置',
        ),
        SizedBox(height: 7),
        _SupportRow(
          icon: LucideIcons.messageCircle,
          title: '反馈与建议',
          description: '告诉我们遇到的问题或想法',
        ),
        SizedBox(height: 7),
        _SupportRow(
          icon: LucideIcons.fileText,
          title: '开源许可',
          description: '查看第三方库与版权说明',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: DudoTextStyles.sans(
        color: DudoColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: DudoColors.secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: DudoColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              color: Color(0xFFB8A88E), size: 18),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DudoColors.primaryContainerMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: DudoColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '隐私政策',
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '阅读记录、书签与高亮优先保存在本机；开启同步、导出或清理数据前，应用会给出明确提示。',
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '查看完整隐私政策',
                style: DudoTextStyles.sans(
                  color: DudoColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  color: DudoColors.primary, size: 18),
            ],
          ),
        ],
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
            color: DudoColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
