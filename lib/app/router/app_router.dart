import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookmarks/presentation/bookmarks_page.dart';
import '../../features/bookshelf/presentation/bookshelf_library_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/reader/presentation/reader_page.dart';
import '../../features/reading_stats/presentation/reading_stats_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/settings/presentation/settings_detail_pages.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/home_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
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
                routes: [
                  GoRoute(
                    path: AppRoutes.bookmarksRelative,
                    name: AppRoutes.bookmarksName,
                    builder: (_, __) => const BookmarksPage(),
                  ),
                ],
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
        path: AppRoutes.readingStats,
        name: AppRoutes.readingStatsName,
        builder: (_, __) => const ReadingStatsPage(),
      ),
      GoRoute(
        path: AppRoutes.sourceSettings,
        name: AppRoutes.sourceSettingsName,
        builder: (_, __) => const SourceManageSettingsPage(),
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

  static const bookmarksRelative = 'bookmarks';
  static const bookmarks = '$home/$bookmarksRelative';
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

  static const readingStats = '/reading-stats';
  static const readingStatsName = 'reading-stats';

  static const sourceSettings = '/settings/sources';
  static const sourceSettingsName = 'settings-sources';

  static const themeSettings = '/settings/theme';
  static const themeSettingsName = 'settings-theme';

  static const typographySettings = '/settings/typography';
  static const typographySettingsName = 'settings-typography';

  static const readAloudSettings = '/settings/read-aloud';
  static const readAloudSettingsName = 'settings-read-aloud';

  static const reader = '/reader';
  static const readerName = 'reader';
}
