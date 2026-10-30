import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/widgets/settings_detail_scaffold.dart';
import 'widgets/about_doc_widgets.dart';

/// In-app privacy policy. The wording is grounded in what the app actually
/// does: everything is local, and the only network calls are to sources and
/// services the reader adds or configures.
class AboutPrivacyPage extends StatelessWidget {
  const AboutPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '关于',
          title: '隐私政策',
          showAction: false,
        ),
        SizedBox(height: 14),
        AboutDocIntro('Dudo 是一款以本地阅读为核心的应用。下面说明本应用会处理哪些数据、'
            '在什么情况下联网，以及你可以如何删除这些数据。'),
        SizedBox(height: 14),
        AboutDocSection(
          icon: LucideIcons.hardDrive,
          title: '数据保存在本机',
          body: '书籍、章节、阅读进度、书签、高亮、笔记、导入的字体以及各项设置，'
              '都保存在设备本地（SQLite / Hive / SharedPreferences）。'
              '本应用没有账号系统，也不会把这些内容上传到任何服务器。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.globe,
          title: '联网时会发生什么',
          body: '只有在以下情况才会发起网络请求，且请求直接发往对应的第三方网站，'
              '不经过开发者搭建的中转服务器：',
          bullets: [
            '搜索、目录与正文：访问你导入并启用的书源网站',
            '封面与图片：从书源或书籍信息中提供的地址加载',
            '离线下载：按你的请求下载章节内容',
            '阅读朗读：调用你配置的在线语音合成地址（如使用在线音色）',
            '导入书源：校验你粘贴的书源地址是否可访问',
          ],
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.lock,
          title: '设备权限',
          body: '本应用只申请与功能直接相关的权限：',
          bullets: [
            '网络：访问书源、封面与在线语音合成',
            '前台服务与媒体播放：阅读朗读时在后台继续播放，并显示播放控制通知',
            '唤醒锁：朗读过程中保持设备运行',
          ],
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.package,
          title: '第三方组件',
          body: '本应用使用了若干开源库（如 Flutter、Drift、Dio 等）。'
              '完整的第三方组件与版权说明可在「开源许可」中查看。'
              '这些库本身不会收集你的阅读数据。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.trash2,
          title: '删除你的数据',
          body: '卸载应用会删除全部本地数据。也可以在「设置 → 缓存与存储」中清理缓存、'
              '封面或数据库内容，而无需卸载应用。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.messageCircle,
          title: '政策更新与联系',
          body: '若本政策有调整，会随版本更新在本页说明。'
              '如对数据处理有疑问，欢迎通过「反馈与建议」与我们联系。',
        ),
        SizedBox(height: 14),
        AboutDocFooter('最后更新：2026-10-31'),
      ],
    );
  }
}
