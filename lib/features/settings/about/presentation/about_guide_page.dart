import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/widgets/settings_detail_scaffold.dart';
import 'widgets/about_doc_widgets.dart';

/// In-app usage guide. The steps mirror the actual navigation labels in the
/// app so a reader can follow them without guessing.
class AboutGuidePage extends StatelessWidget {
  const AboutGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      children: [
        SettingsDetailHeader(
          eyebrow: '帮助与支持',
          title: '使用说明',
          showAction: false,
        ),
        SizedBox(height: 14),
        AboutDocIntro('从导入第一本书开始，几步就能把随身书房搭起来。'),
        SizedBox(height: 14),
        AboutDocSection(
          icon: LucideIcons.library,
          title: '添加书源或本地书籍',
          body: '打开「设置 → 内容与书源 → 书源管理」，点击「添加书源」。'
              '可以粘贴在线书源地址、导入书源文件，或选择本地文件直接加入书架。',
          bullets: [
            '在线书源需为 Legado 兼容的 JSON 格式',
            '本地导入目前支持 TXT 文件，导入后会直接出现在书架',
          ],
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.search,
          title: '找书与收藏',
          body: '底部「搜索」页会跨已启用的书源查找作品，打开书籍详情后点击「加入书架」。'
              '书架页集中管理收藏、阅读进度与缓存。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.bookOpen,
          title: '开始阅读',
          body: '首页的「继续阅读」或书架中的书籍都能直接打开阅读器。'
              '阅读时轻点屏幕中间可呼出阅读菜单，再点空白处收起。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.type,
          title: '调整阅读体验',
          body: '「设置 → 阅读体验」可以调整主题与外观、字体管理与阅读朗读；'
              '阅读器内的排版面板也能即时修改字号、行距与背景。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.highlighter,
          title: '书签、高亮与笔记',
          body: '阅读时选中文字即可添加高亮或笔记。'
              '「我的 → 笔记摘录」与「书签」页集中查看所有记录。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.download,
          title: '离线缓存与自动更新',
          body: '书籍详情页可下载章节供离线阅读。'
              '「设置 → 书架更新」可配置自动拉取频率、仅 Wi-Fi 与章节更新提醒。',
        ),
        SizedBox(height: 10),
        AboutDocSection(
          icon: LucideIcons.shieldCheck,
          title: '数据与隐私',
          body: '阅读进度、书签、高亮与各项设置默认只保存在本机。'
              '数据同步目前只保存同步偏好，尚未连接云端账号。',
        ),
        SizedBox(height: 14),
        AboutDocFooter('内容会随版本更新，欢迎通过「反馈与建议」补充。'),
      ],
    );
  }
}
