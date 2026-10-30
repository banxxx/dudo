import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../features/bookmarks/presentation/bookmarks_page.dart';
import '../../features/bookshelf/application/bookshelf_providers.dart';
import '../../features/bookshelf/presentation/book_detail_page.dart';
import '../../features/bookshelf/presentation/bookshelf_library_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/reader_engine/presentation/reader_screen.dart';
import '../../features/reading_goal/presentation/reading_goal_page.dart';
import '../../features/reading_stats/presentation/reading_stats_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/settings/about/presentation/about_app_page.dart';
import '../../features/settings/about/presentation/about_feedback_page.dart';
import '../../features/settings/about/presentation/about_guide_page.dart';
import '../../features/settings/about/presentation/about_licenses_page.dart';
import '../../features/settings/about/presentation/about_privacy_page.dart';
import '../../features/settings/data_sync_settings/presentation/data_sync_settings_page.dart';
import '../../features/settings/read_aloud_settings/presentation/read_aloud_settings_page.dart';
import '../../features/settings/shelf_update_settings/presentation/shelf_update_settings_page.dart';
import '../../features/settings/source_add/presentation/source_add_settings_page.dart';
import '../../features/settings/source_manage/presentation/source_manage_settings_page.dart';
import '../../features/settings/storage_settings/presentation/storage_settings_page.dart';
import '../../features/settings/theme_settings/application/theme_settings_provider.dart';
import '../../features/settings/theme_settings/presentation/theme_settings_page.dart';
import '../../features/settings/typography_settings/presentation/typography_settings_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/home_scaffold.dart';

/// Wraps a route page so it remounts when the colour palette changes.
///
/// `DudoColors` resolves through static getters, so `const` subtrees keep the
/// colours they were first built with unless their elements are recreated.
/// Watching the theme settings here (the builder itself is not re-run by the
/// router on an unrelated rebuild) rekeys this wrapper, which throws away the
/// page's elements and rebuilds every `const` descendant with the fresh
/// palette. The reader route opts out: remounting it would reset the
/// in-chapter reading position.
class _ThemedPage extends ConsumerWidget {
  const _ThemedPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeSettingsProvider);
    return KeyedSubtree(
      key: ValueKey(DudoColors.palette),
      child: child,
    );
  }
}

Widget _themed(Widget page) => _ThemedPage(child: page);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.bookmarks,
        name: AppRoutes.bookmarksName,
        builder: (_, __) => _themed(const BookmarksPage()),
      ),
      // Main scaffold with bottom navigation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (_, __) => _themed(const HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookshelf,
                name: AppRoutes.bookshelfName,
                builder: (_, __) => _themed(const BookshelfLibraryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.searchName,
                builder: (_, __) => _themed(const SearchPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (_, __) => _themed(const ProfilePage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (_, __) => _themed(const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        name: AppRoutes.aboutAppName,
        builder: (_, __) => _themed(const AboutAppPage()),
      ),
      GoRoute(
        path: AppRoutes.aboutGuide,
        name: AppRoutes.aboutGuideName,
        builder: (_, __) => _themed(const AboutGuidePage()),
      ),
      GoRoute(
        path: AppRoutes.aboutFeedback,
        name: AppRoutes.aboutFeedbackName,
        builder: (_, __) => _themed(const AboutFeedbackPage()),
      ),
      GoRoute(
        path: AppRoutes.aboutLicenses,
        name: AppRoutes.aboutLicensesName,
        builder: (_, __) => _themed(const AboutLicensesPage()),
      ),
      GoRoute(
        path: AppRoutes.aboutPrivacy,
        name: AppRoutes.aboutPrivacyName,
        builder: (_, __) => _themed(const AboutPrivacyPage()),
      ),
      GoRoute(
        path: AppRoutes.readingStats,
        name: AppRoutes.readingStatsName,
        builder: (_, __) => _themed(const ReadingStatsPage()),
      ),
      GoRoute(
        path: AppRoutes.readingGoal,
        name: AppRoutes.readingGoalName,
        builder: (_, __) => _themed(const ReadingGoalPage()),
      ),
      GoRoute(
        path: AppRoutes.sourceSettings,
        name: AppRoutes.sourceSettingsName,
        builder: (_, __) => _themed(const SourceManageSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.sourceAdd,
        name: AppRoutes.sourceAddName,
        builder: (_, __) => _themed(const SourceAddSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        name: AppRoutes.themeSettingsName,
        builder: (_, __) => _themed(const ThemeSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.typographySettings,
        name: AppRoutes.typographySettingsName,
        builder: (_, __) => _themed(const TypographySettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.readAloudSettings,
        name: AppRoutes.readAloudSettingsName,
        builder: (_, __) => _themed(const ReadAloudSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.storageSettings,
        name: AppRoutes.storageSettingsName,
        builder: (_, __) => _themed(const StorageSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.shelfUpdateSettings,
        name: AppRoutes.shelfUpdateSettingsName,
        builder: (_, __) => _themed(const ShelfUpdateSettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.dataSyncSettings,
        name: AppRoutes.dataSyncSettingsName,
        builder: (_, __) => _themed(const DataSyncSettingsPage()),
      ),
      GoRoute(
        path: '${AppRoutes.bookDetail}/:bookId',
        name: AppRoutes.bookDetailName,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return _themed(BookDetailPage(bookId: bookId));
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
          final offset =
              int.tryParse(state.uri.queryParameters['offset'] ?? '0') ?? 0;
          return ReaderScreen(
            bookId: bookId,
            initialChapterIndex: chapterIndex,
            initialOffset: offset,
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

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  late final ProviderSubscription<AsyncValue<List<Book>>>
      _shelfBooksSubscription;

  @override
  void initState() {
    super.initState();
    // Keep the shelf stream warm while the main shell is alive.
    _shelfBooksSubscription = ref.listenManual<AsyncValue<List<Book>>>(
      shelfBooksProvider,
      (_, __) {},
    );
  }

  @override
  void dispose() {
    _shelfBooksSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScaffold(navigationShell: widget.navigationShell);
  }
}

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

  static const aboutGuide = '/settings/about/guide';
  static const aboutGuideName = 'settings-about-guide';

  static const aboutFeedback = '/settings/about/feedback';
  static const aboutFeedbackName = 'settings-about-feedback';

  static const aboutLicenses = '/settings/about/licenses';
  static const aboutLicensesName = 'settings-about-licenses';

  static const aboutPrivacy = '/settings/about/privacy';
  static const aboutPrivacyName = 'settings-about-privacy';

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

  static const storageSettings = '/settings/storage';
  static const storageSettingsName = 'settings-storage';

  static const shelfUpdateSettings = '/settings/shelf-update';
  static const shelfUpdateSettingsName = 'settings-shelf-update';

  static const dataSyncSettings = '/settings/data-sync';
  static const dataSyncSettingsName = 'settings-data-sync';

  static const bookDetail = '/books';
  static const bookDetailName = 'book-detail';

  static const reader = '/reader';
  static const readerName = 'reader';
}
