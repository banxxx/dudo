import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookmarks/presentation/bookmarks_page.dart';
import '../../features/bookshelf/presentation/book_detail_page.dart';
import '../../features/bookshelf/presentation/bookshelf_library_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/reader/presentation/reader_page.dart';
import '../../features/reading_goal/presentation/reading_goal_page.dart';
import '../../features/reading_stats/presentation/reading_stats_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/settings/about/presentation/about_app_page.dart';
import '../../features/settings/read_aloud_settings/presentation/read_aloud_settings_page.dart';
import '../../features/settings/source_add/presentation/source_add_settings_page.dart';
import '../../features/settings/source_manage/presentation/source_manage_settings_page.dart';
import '../../features/settings/theme_settings/presentation/theme_settings_page.dart';
import '../../features/settings/typography_settings/presentation/typography_settings_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/home_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.bookmarks,
        name: AppRoutes.bookmarksName,
        builder: (_, __) => const BookmarksPage(),
      ),
      // Main scaffold with bottom navigation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookshelf,
                name: AppRoutes.bookshelfName,
                builder: (_, __) => const BookshelfLibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.searchName,
                builder: (_, __) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        name: AppRoutes.aboutAppName,
        builder: (_, __) => const AboutAppPage(),
      ),
      GoRoute(
        path: AppRoutes.readingStats,
        name: AppRoutes.readingStatsName,
        builder: (_, __) => const ReadingStatsPage(),
      ),
      GoRoute(
        path: AppRoutes.readingGoal,
        name: AppRoutes.readingGoalName,
        builder: (_, __) => const ReadingGoalPage(),
      ),
      GoRoute(
        path: AppRoutes.sourceSettings,
        name: AppRoutes.sourceSettingsName,
        builder: (_, __) => const SourceManageSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.sourceAdd,
        name: AppRoutes.sourceAddName,
        builder: (_, __) => const SourceAddSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        name: AppRoutes.themeSettingsName,
        builder: (_, __) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.typographySettings,
        name: AppRoutes.typographySettingsName,
        builder: (_, __) => const TypographySettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.readAloudSettings,
        name: AppRoutes.readAloudSettingsName,
        builder: (_, __) => const ReadAloudSettingsPage(),
      ),
      GoRoute(
        path: '${AppRoutes.bookDetail}/:bookId',
        name: AppRoutes.bookDetailName,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return BookDetailPage(bookId: bookId);
        },
      ),
      // Reader is a fullscreen route outside the shell.
      GoRoute(
        path: '${AppRoutes.reader}/:bookId',
        name: AppRoutes.readerName,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterIndex =
              int.tryParse(state.uri.queryParameters['chapter'] ?? '0') ?? 0;
          return ReaderPage(
            bookId: bookId,
            initialChapterIndex: chapterIndex,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: ErrorStateView(
        title: '页面不存在',
        message: '无法打开 ${state.uri}',
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('返回首页'),
        ),
      ),
    ),
  );
});

class AppRoutes {
  AppRoutes._();

  static const home = '/home';
  static const homeName = 'home';

  static const bookmarks = '/bookmarks';
  static const bookmarksName = 'bookmarks';

  static const bookshelf = '/bookshelf';
  static const bookshelfName = 'bookshelf';

  static const search = '/search';
  static const searchName = 'search';

  static const sources = '/sources';
  static const sourcesName = 'sources';

  static const profile = '/profile';
  static const profileName = 'profile';

  static const settings = '/settings';
  static const settingsName = 'settings';

  static const aboutApp = '/settings/about';
  static const aboutAppName = 'settings-about';

  static const readingStats = '/reading-stats';
  static const readingStatsName = 'reading-stats';

  static const readingGoal = '/reading-goal';
  static const readingGoalName = 'reading-goal';

  static const sourceSettings = '/settings/sources';
  static const sourceSettingsName = 'settings-sources';

  static const sourceAdd = '/settings/sources/add';
  static const sourceAddName = 'settings-sources-add';

  static const themeSettings = '/settings/theme';
  static const themeSettingsName = 'settings-theme';

  static const typographySettings = '/settings/typography';
  static const typographySettingsName = 'settings-typography';

  static const readAloudSettings = '/settings/read-aloud';
  static const readAloudSettingsName = 'settings-read-aloud';

  static const bookDetail = '/books';
  static const bookDetailName = 'book-detail';

  static const reader = '/reader';
  static const readerName = 'reader';
}
