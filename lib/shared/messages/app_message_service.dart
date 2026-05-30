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
  });

  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
  });

  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
  });

  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
  });

  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
  });

  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
  });

  void dismiss(String dedupeKey);

  void dismissAll();
}
