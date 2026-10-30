import 'package:dudo/features/settings/about/data/external_link_launcher.dart';
import 'package:dudo/features/settings/about/domain/about_links.dart';
import 'package:dudo/features/settings/about/presentation/about_feedback_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget host(_FakeLauncher launcher, _FakeMessages messages) {
    return ProviderScope(
      overrides: [
        externalLinkLauncherProvider.overrideWithValue(launcher),
        appMessageServiceProvider.overrideWithValue(messages),
      ],
      child: const MaterialApp(home: AboutFeedbackPage()),
    );
  }

  testWidgets('shows the mailbox and issue tracker without leaving the app', (
    tester,
  ) async {
    await tester.pumpWidget(host(_FakeLauncher(), _FakeMessages()));

    expect(find.text(AboutLinks.email), findsOneWidget);
    expect(find.text(AboutLinks.display(AboutLinks.feedback)), findsOneWidget);
    expect(find.text('复制邮箱'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('打开'), findsOneWidget);
  });

  testWidgets('copying the mailbox confirms without opening a mail client', (
    tester,
  ) async {
    final launcher = _FakeLauncher();
    final messages = _FakeMessages();
    await tester.pumpWidget(host(launcher, messages));

    await tester.tap(find.text('复制邮箱'));
    await tester.pumpAndSettle();

    expect(messages.successes, ['邮箱已复制，可在邮件客户端发送']);
    expect(launcher.opened, isEmpty);
  });

  testWidgets('opening GitHub issues uses the external launcher', (
    tester,
  ) async {
    final launcher = _FakeLauncher();
    await tester.pumpWidget(host(launcher, _FakeMessages()));

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(launcher.opened, [AboutLinks.feedback]);
  });
}

class _FakeLauncher implements ExternalLinkLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class _FakeMessages implements AppMessageService {
  final successes = <String>[];

  @override
  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    successes.add(message);
  }

  @override
  void dismiss(String dedupeKey) {}

  @override
  void dismissAll() {}

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void show(AppMessageRequest request) {}

  @override
  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
  }) {}

  @override
  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}
}
