import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookshelf/presentation/bookshelf_library_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/reader/presentation/reader_page.dart';
import '../../features/search/presentation/search_page.dart';
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

  static const bookshelf = '/bookshelf';
  static const bookshelfName = 'bookshelf';

  static const search = '/search';
  static const searchName = 'search';

  static const sources = '/sources';
  static const sourcesName = 'sources';

  static const profile = '/profile';
  static const profileName = 'profile';

  static const reader = '/reader';
  static const readerName = 'reader';
}
