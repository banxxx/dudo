import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMessageRegistry', () {
    test('shows first message for a key', () {
      final registry = AppMessageRegistry<int>();
      const request = AppMessageRequest(title: '保存成功', dedupeKey: 'save');

      final decision = registry.prepare(request);
      registry.markShown(decision.key, 1);

      expect(decision.action, AppMessageRegistryAction.show);
      expect(registry.contains('save'), isTrue);
    });

    test('ignores duplicate message by default', () {
      final registry = AppMessageRegistry<int>();
      const request = AppMessageRequest(title: '保存成功', dedupeKey: 'save');

      final first = registry.prepare(request);
      registry.markShown(first.key, 1);
      final duplicate = registry.prepare(request);

      expect(duplicate.action, AppMessageRegistryAction.ignore);
      expect(duplicate.existing, 1);
    });

    test('replaces duplicate message when requested', () {
      final registry = AppMessageRegistry<int>();
      const firstRequest = AppMessageRequest(title: '加载中', dedupeKey: 'load');
      const secondRequest = AppMessageRequest(
        title: '加载完成',
        dedupeKey: 'load',
        replaceExisting: true,
      );

      final first = registry.prepare(firstRequest);
      registry.markShown(first.key, 1);
      final second = registry.prepare(secondRequest);

      expect(second.action, AppMessageRegistryAction.replace);
      expect(second.existing, 1);
    });

    test('uses generated key when dedupe key is absent', () {
      const request = AppMessageRequest(
        title: '网络错误',
        description: '请稍后重试',
        kind: AppMessageKind.error,
        position: AppMessagePosition.top,
      );

      expect(
        request.effectiveKey,
        'error|top|compact|网络错误|请稍后重试',
      );
    });

    test('dismiss removes active handle', () {
      final registry = AppMessageRegistry<int>();
      const request = AppMessageRequest(title: '保存成功', dedupeKey: 'save');

      final decision = registry.prepare(request);
      registry.markShown(decision.key, 1);

      expect(registry.dismiss('save'), 1);
      expect(registry.contains('save'), isFalse);
    });
  });
}
