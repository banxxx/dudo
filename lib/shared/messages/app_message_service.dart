import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_message.dart';
import 'toastification_app_message_service.dart';

final appMessageServiceProvider = Provider<AppMessageService>((ref) {
  return ToastificationAppMessageService();
});

abstract class AppMessageService {
  void show(AppMessageRequest request);

  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  });

  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  });

  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  });

  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  });

  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  });

  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
  });

  void dismiss(String dedupeKey);

  void dismissAll();
}
