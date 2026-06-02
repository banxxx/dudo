import 'package:dudo/features/profile/presentation/profile_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Pencil F1 profile design', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfilePage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('我的'), findsOneWidget);
    expect(find.text('读'), findsOneWidget);
    expect(find.text('纸上旅人'), findsOneWidget);
    expect(find.text('本月已阅读 12 小时，收藏 38 本书'), findsOneWidget);
    expect(find.text('静读会员'), findsOneWidget);
    expect(find.text('12h'), findsOneWidget);
    expect(find.text('本月阅读'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('五月阅读目标'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('距离 20 小时目标还差 4 小时 24 分钟。'), findsOneWidget);
    expect(find.text('书房工具'), findsOneWidget);
    expect(find.text('阅读记录'), findsOneWidget);
    expect(find.text('查看每日阅读曲线'), findsOneWidget);
    expect(find.text('离线缓存'), findsOneWidget);
    expect(find.text('管理已下载章节'), findsOneWidget);
    expect(find.text('笔记摘录'), findsOneWidget);
    expect(find.text('整理高亮与想法'), findsOneWidget);
    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('云端保持最新'), findsOneWidget);

    final title = tester.widget<Text>(find.text('我的'));
    expect(title.style?.color, DudoColors.textPrimary);
    expect(title.style?.fontSize, 28);
    expect(title.style?.fontWeight, FontWeight.w700);

    final identityCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('纸上旅人'),
            matching: find.byType(Container),
          )
          .last,
    );
    final identityDecoration = identityCard.decoration! as BoxDecoration;
    expect(identityCard.constraints?.maxHeight, 138);
    expect(identityCard.padding, const EdgeInsets.all(16));
    expect(identityDecoration.color, DudoColors.textPrimary);
    expect(identityDecoration.borderRadius, BorderRadius.circular(26));

    final avatar = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('读'),
            matching: find.byType(Container),
          )
          .first,
    );
    final avatarDecoration = avatar.decoration! as BoxDecoration;
    expect(avatar.constraints?.maxWidth, 76);
    expect(avatar.constraints?.maxHeight, 76);
    expect(avatarDecoration.color, DudoColors.primaryContainer);
    expect(avatarDecoration.borderRadius, BorderRadius.circular(38));

    final name = tester.widget<Text>(find.text('纸上旅人'));
    expect(name.style?.color, DudoColors.surfaceHigh);
    expect(name.style?.fontSize, 24);
    expect(name.style?.fontWeight, FontWeight.w700);

    final bio = tester.widget<Text>(find.text('本月已阅读 12 小时，收藏 38 本书'));
    expect(bio.style?.color, DudoColors.outline);
    expect(bio.style?.fontSize, 12);
    expect(bio.style?.height, 1.4);

    final stats = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('本月阅读'),
            matching: find.byType(Container),
          )
          .last,
    );
    final statsDecoration = stats.decoration! as BoxDecoration;
    expect(stats.constraints?.maxHeight, 72);
    expect(stats.padding, const EdgeInsets.all(10));
    expect(statsDecoration.color, DudoColors.surface);
    expect(statsDecoration.borderRadius, BorderRadius.circular(24));
    expect(statsDecoration.border?.top.color, DudoColors.outlineVariant);

    final statValue = tester.widget<Text>(find.text('12h'));
    expect(statValue.style?.color, DudoColors.textPrimary);
    expect(statValue.style?.fontSize, 22);
    expect(statValue.style?.fontWeight, FontWeight.w700);

    final statLabel = tester.widget<Text>(find.text('本月阅读'));
    expect(statLabel.style?.color, DudoColors.secondary);
    expect(statLabel.style?.fontSize, 11);

    final goalCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('五月阅读目标'),
            matching: find.byType(Container),
          )
          .last,
    );
    final goalDecoration = goalCard.decoration! as BoxDecoration;
    expect(goalCard.padding, const EdgeInsets.all(13));
    expect(goalDecoration.color, DudoColors.primaryContainer);
    expect(goalDecoration.borderRadius, BorderRadius.circular(24));

    final percent = tester.widget<Text>(find.text('78%'));
    expect(percent.style?.color, DudoColors.primary);
    expect(percent.style?.fontSize, 16);
    expect(percent.style?.fontWeight, FontWeight.w700);

    final toolRow = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('阅读记录'),
            matching: find.byType(Container),
          )
          .last,
    );
    final toolDecoration = toolRow.decoration! as BoxDecoration;
    expect(toolRow.constraints?.maxHeight, 56);
    expect(toolRow.padding, const EdgeInsets.symmetric(horizontal: 12));
    expect(toolDecoration.color, DudoColors.surface);
    expect(toolDecoration.borderRadius, BorderRadius.circular(18));
    expect(toolDecoration.border?.top.color, DudoColors.outlineVariant);

    final toolTitle = tester.widget<Text>(find.text('阅读记录'));
    expect(toolTitle.style?.color, DudoColors.textPrimary);
    expect(toolTitle.style?.fontSize, 14);
    expect(toolTitle.style?.fontWeight, FontWeight.w600);

    final toolDescription = tester.widget<Text>(find.text('查看每日阅读曲线'));
    expect(toolDescription.style?.color, DudoColors.secondary);
    expect(toolDescription.style?.fontSize, 11);
  });
}
