import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/messages/app_message_service.dart';
import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../shared/widgets/settings_detail_scaffold.dart';
import '../data/external_link_launcher.dart';
import '../domain/about_links.dart';
import 'widgets/about_doc_widgets.dart';

/// Feedback page. It deliberately does not open anything on entry: the email
/// is shown so the reader can send mail from their own client, and the GitHub
/// issue address is offered as an alternative.
class AboutFeedbackPage extends ConsumerWidget {
  const AboutFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsDetailScaffold(
      children: [
        const SettingsDetailHeader(
          eyebrow: '帮助与支持',
          title: '反馈与建议',
          showAction: false,
        ),
        const SizedBox(height: 14),
        const AboutDocIntro('遇到问题或有新的想法？可以通过下面的方式联系我们。'),
        const SizedBox(height: 14),
        _ContactCard(
          icon: LucideIcons.mail,
          title: '邮箱反馈',
          value: AboutLinks.email,
          description: '复制邮箱地址后，在任意邮件客户端发送邮件即可。',
          actions: [
            _ContactAction(
              icon: LucideIcons.copy,
              label: '复制邮箱',
              filled: true,
              onTap: () => _copy(
                context,
                ref,
                AboutLinks.email,
                '邮箱已复制，可在邮件客户端发送',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ContactCard(
          icon: LucideIcons.bug,
          title: 'GitHub Issues',
          value: AboutLinks.display(AboutLinks.feedback),
          description: '在项目仓库提交 Issue，方便跟踪进度与回复。',
          actions: [
            _ContactAction(
              icon: LucideIcons.copy,
              label: '复制链接',
              onTap: () => _copy(
                context,
                ref,
                AboutLinks.display(AboutLinks.feedback),
                '链接已复制',
              ),
            ),
            _ContactAction(
              icon: LucideIcons.externalLink,
              label: '打开',
              filled: true,
              onTap: () => _open(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const AboutDocSection(
          icon: LucideIcons.info,
          title: '让反馈更有效',
          body: '如果可以，请一并附上这些信息，能帮助我们更快定位问题：',
          bullets: [
            '应用版本号与设备型号',
            '出现问题时的操作步骤',
            '相关的书源名称或截图',
          ],
        ),
      ],
    );
  }

  Future<void> _copy(
    BuildContext context,
    WidgetRef ref,
    String text,
    String message,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      if (!context.mounted) return;
      ref.read(appMessageServiceProvider).warning(
        '复制失败，可手动选择地址复制',
        title: '复制失败',
        dedupeKey: 'about-feedback-copy',
      );
      return;
    }
    if (!context.mounted) return;
    ref.read(appMessageServiceProvider).success(
      message,
      dedupeKey: 'about-feedback-copy',
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final opened =
        await ref.read(externalLinkLauncherProvider).open(AboutLinks.feedback);
    if (!opened && context.mounted) {
      ref.read(appMessageServiceProvider).warning(
        '无法打开浏览器，可复制链接后手动访问',
        title: '打开失败',
        dedupeKey: 'about-feedback-open',
      );
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DudoColors.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: DudoColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: DudoTextStyles.sans(
                  color: DudoColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DudoColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DudoColors.outlineVariant),
            ),
            child: SelectableText(
              value,
              style: DudoTextStyles.numeric(
                color: DudoColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: DudoTextStyles.sans(
              color: DudoColors.secondaryDark,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground =
        filled ? DudoColors.primary : DudoColors.secondaryDark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: filled ? DudoColors.primaryContainer : DudoColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: filled ? DudoColors.primaryContainer : DudoColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
