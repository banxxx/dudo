import 'package:dudo/features/settings/typography_settings/presentation/typography_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders and switches the font management design', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TypographySettingsPage(),
      ),
    );

    expect(find.text('阅读体验'), findsOneWidget);
    expect(find.text('字体管理'), findsNWidgets(2));
    expect(find.text('字体预览'), findsOneWidget);
    expect(find.text('内置字体和导入字体统一在这里选择'), findsOneWidget);
    expect(find.text('添加本地字体'), findsOneWidget);
    expect(find.text('霞鹜文楷'), findsOneWidget);
    expect(find.text('方正书宋'), findsOneWidget);

    await tester.tap(find.text('内置字体'));
    await tester.pumpAndSettle();

    expect(find.text('添加本地字体'), findsNothing);
    expect(find.text('思源宋体'), findsOneWidget);
    expect(find.text('系统黑体'), findsOneWidget);
    expect(find.text('Noto Serif SC'), findsOneWidget);

    await tester.tap(find.text('我的字体'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pumpAndSettle();

    expect(find.text('删除“方正书宋”？'), findsOneWidget);
    expect(find.text('FZShuSong.otf · 本地字体'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });
}
