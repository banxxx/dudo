import 'dart:async';

import 'package:dudo/features/settings/start_page_settings/application/start_page_settings_provider.dart';
import 'package:dudo/features/settings/start_page_settings/data/start_page_settings_repository.dart';
import 'package:dudo/features/settings/start_page_settings/domain/start_page_settings.dart';
import 'package:dudo/features/settings/start_page_settings/presentation/start_page_settings_page.dart';
import 'package:dudo/shared/widgets/dudo_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders the four shell tabs and marks the saved one',
      (tester) async {
    final repository = _FakeStartPageSettingsRepository();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('启动页面'), findsOneWidget);
    expect(find.text('启动预览'), findsOneWidget);
    expect(find.text('选择启动页'), findsOneWidget);
    // The selected page is named once in the preview and once on its card.
    expect(find.text('首页'), findsNWidgets(2));
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('启动页会在下次打开应用时生效。'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-page-home')),
        matching: find.byIcon(LucideIcons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking another page saves it and moves the check',
      (tester) async {
    final repository = _FakeStartPageSettingsRepository();

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-page-search')));
    await tester.pumpAndSettle();

    expect(repository.saved.last.page, StartPage.search);
    // The preview follows the new selection.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-page-preview')),
        matching: find.text('搜索'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-page-search')),
        matching: find.byIcon(LucideIcons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-page-home')),
        matching: find.byIcon(LucideIcons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('shows the skeleton until the saved page arrives',
      (tester) async {
    final repository = _PendingStartPageSettingsRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(_wrap(repository));
    await tester.pump();

    expect(find.byType(DudoSkeleton), findsWidgets);
    expect(find.text('选择启动页'), findsNothing);
  });
}

Widget _wrap(StartPageSettingsRepository repository) {
  return ProviderScope(
    overrides: [
      startPageSettingsRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: StartPageSettingsPage()),
  );
}

class _FakeStartPageSettingsRepository implements StartPageSettingsRepository {
  _FakeStartPageSettingsRepository({
    StartPageSettings settings = const StartPageSettings(),
  }) : _settings = settings;

  StartPageSettings _settings;
  final StreamController<StartPageSettings> _updates =
      StreamController<StartPageSettings>.broadcast();
  final List<StartPageSettings> saved = [];

  @override
  Future<StartPageSettings> load() async => _settings;

  @override
  Future<void> save(StartPageSettings settings) async {
    _settings = settings;
    saved.add(settings);
    _updates.add(settings);
  }

  @override
  Stream<StartPageSettings> watch() async* {
    yield _settings;
    yield* _updates.stream;
  }
}

class _PendingStartPageSettingsRepository
    implements StartPageSettingsRepository {
  final StreamController<StartPageSettings> _controller =
      StreamController<StartPageSettings>();

  @override
  Future<StartPageSettings> load() async => StartPageSettings.defaults();

  @override
  Future<void> save(StartPageSettings settings) async {}

  @override
  Stream<StartPageSettings> watch() => _controller.stream;

  Future<void> close() => _controller.close();
}
