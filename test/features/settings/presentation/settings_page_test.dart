import 'package:dudo/features/settings/data_sync_settings/application/data_sync_settings_provider.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:dudo/features/settings/presentation/settings_page.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_settings_provider.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:dudo/features/settings/shelf_update_settings/application/shelf_update_settings_provider.dart';
import 'package:dudo/features/settings/shelf_update_settings/domain/shelf_update_settings.dart';
import 'package:dudo/features/settings/storage_settings/application/storage_usage_provider.dart';
import 'package:dudo/features/settings/storage_settings/domain/storage_usage.dart';
import 'package:dudo/features/settings/theme_settings/application/theme_settings_provider.dart';
import 'package:dudo/features/settings/theme_settings/domain/theme_settings.dart';
import 'package:dudo/features/settings/typography_settings/application/reader_font_providers.dart';
import 'package:dudo/features/settings/typography_settings/domain/reader_font.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Pencil F2 settings design', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeSettingsProvider.overrideWith(
            (_) => Stream.value(ThemeSettings.defaults()),
          ),
          readAloudSettingsProvider.overrideWith(
            (_) => Stream.value(
              ReadAloudSettings.defaults().copyWith(speechRate: 1.2),
            ),
          ),
          selectedReaderFontProvider.overrideWith(
            (_) async => ReaderBuiltinFonts.serifSc,
          ),
          shelfUpdateSettingsProvider.overrideWith(
            (_) => Stream.value(
              ShelfUpdateSettings.defaults().copyWith(
                frequency: ShelfUpdateFrequency.everyThreeDays,
              ),
            ),
          ),
          dataSyncSettingsProvider.overrideWith(
            (_) => Stream.value(DataSyncSettings.defaults()),
          ),
          storageUsageProvider.overrideWith(
            (_) async => const StorageUsage(
              items: [
                StorageUsageItem(
                  category: StorageCategory.database,
                  title: '阅读数据库',
                  description: '书籍、章节、书签与阅读记录',
                  bytes: 1288490188,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('偏好中心'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('调整阅读体验、书源与同步，让书房按你的习惯运转。'), findsOneWidget);
    expect(find.text('阅读体验'), findsOneWidget);
    expect(find.text('主题与外观'), findsOneWidget);
    expect(find.text('纸感、深色、跟随系统'), findsOneWidget);
    expect(find.text('松叶绿 · 纸色'), findsOneWidget);
    expect(find.text('字体管理'), findsOneWidget);
    expect(find.text('导入、选择和管理阅读字体'), findsOneWidget);
    expect(find.text('Noto Serif SC'), findsOneWidget);
    expect(find.text('阅读朗读'), findsOneWidget);
    expect(find.text('声音、语速、定时与后台播放'), findsOneWidget);
    expect(find.text('系统语音 · 1.2x'), findsOneWidget);
    expect(find.text('内容与书源'), findsOneWidget);
    expect(find.text('书架更新'), findsOneWidget);
    expect(find.text('更新频率、章节提醒和自动拉取'), findsOneWidget);
    expect(find.text('每 3 天'), findsOneWidget);
    expect(find.text('通用'), findsOneWidget);
    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('阅读进度、书签、高亮和设置'), findsOneWidget);
    expect(find.text('已开启'), findsOneWidget);
    expect(find.text('缓存与存储'), findsOneWidget);
    expect(find.text('封面缓存、语音与数据库'), findsOneWidget);
    expect(find.text('1.2GB'), findsOneWidget);

    final hero = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('偏好中心'),
            matching: find.byType(Container),
          )
          .last,
    );
    final heroDecoration = hero.decoration! as BoxDecoration;
    expect(hero.constraints?.maxHeight, 132);
    expect(hero.padding, const EdgeInsets.all(16));
    expect(heroDecoration.color, DudoColors.textPrimary);
    expect(heroDecoration.borderRadius, BorderRadius.circular(26));

    final eyebrow = tester.widget<Text>(find.text('偏好中心'));
    expect(eyebrow.style?.color, DudoColors.outline);
    expect(eyebrow.style?.fontSize, 12);
    expect(eyebrow.style?.fontWeight, FontWeight.w600);
    expect(eyebrow.style?.letterSpacing, 1.1);

    final title = tester.widget<Text>(find.text('设置'));
    expect(title.style?.color, DudoColors.surfaceHigh);
    expect(title.style?.fontSize, 28);
    expect(title.style?.fontWeight, FontWeight.w700);

    final description =
        tester.widget<Text>(find.text('调整阅读体验、书源与同步，让书房按你的习惯运转。'));
    expect(description.style?.color, DudoColors.outline);
    expect(description.style?.fontSize, 11);
    expect(description.style?.height, 1.35);

    final sectionTitle = tester.widget<Text>(find.text('阅读体验'));
    expect(sectionTitle.style?.color, DudoColors.textPrimary);
    expect(sectionTitle.style?.fontSize, 17);
    expect(sectionTitle.style?.fontWeight, FontWeight.w600);

    final row = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('主题与外观'),
            matching: find.byType(Container),
          )
          .last,
    );
    final rowDecoration = row.decoration! as BoxDecoration;
    expect(row.constraints?.maxHeight, 56);
    expect(row.padding, const EdgeInsets.symmetric(horizontal: 12));
    expect(rowDecoration.color, DudoColors.surface);
    expect(rowDecoration.borderRadius, BorderRadius.circular(18));
    expect(rowDecoration.border?.top.color, DudoColors.outlineVariant);

    final rowTitle = tester.widget<Text>(find.text('主题与外观'));
    expect(rowTitle.style?.color, DudoColors.textPrimary);
    expect(rowTitle.style?.fontSize, 14);
    expect(rowTitle.style?.fontWeight, FontWeight.w600);

    final rowDescription = tester.widget<Text>(find.text('纸感、深色、跟随系统'));
    expect(rowDescription.style?.color, DudoColors.secondary);
    expect(rowDescription.style?.fontSize, 11);

    final rowValue = tester.widget<Text>(find.text('松叶绿 · 纸色'));
    expect(rowValue.style?.color, DudoColors.secondary);
    expect(rowValue.style?.fontSize, 12);

    final syncValue = tester.widget<Text>(find.text('已开启'));
    expect(syncValue.style?.color, DudoColors.secondary);
    expect(syncValue.style?.fontSize, 12);
  });
}
