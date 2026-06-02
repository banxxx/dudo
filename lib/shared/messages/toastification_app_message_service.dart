import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_tokens.dart';
import 'app_message.dart';
import 'app_message_card.dart';
import 'app_message_registry.dart';
import 'app_message_service.dart';

class ToastificationAppMessageService implements AppMessageService {
  final AppMessageRegistry<ToastificationItem> _registry =
      AppMessageRegistry<ToastificationItem>();

  @override
  void show(AppMessageRequest request) {
    final decision = _registry.prepare(request);
    switch (decision.action) {
      case AppMessageRegistryAction.ignore:
        return;
      case AppMessageRegistryAction.replace:
        final existing = decision.existing;
        if (existing != null) toastification.dismiss(existing);
      case AppMessageRegistryAction.show:
        break;
    }

    late final ToastificationItem item;
    item = toastification.showCustom(
      alignment: _alignment(request.position),
      animationDuration: AppMotion.medium,
      autoCloseDuration: request.effectiveDuration,
      callbacks: ToastificationCallbacks(
        onAutoCompleteCompleted: (_) => _registry.dismiss(decision.key),
        onDismissed: (_) => _registry.dismiss(decision.key),
        onCloseButtonTap: (_) => dismiss(decision.key),
      ),
      builder: (context, holder) {
        return AppMessageCard(
          request: request,
          onClose: request.dismissible ? () => dismiss(decision.key) : null,
        );
      },
    );
    _registry.markShown(decision.key, item);
  }

  @override
  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    show(AppMessageRequest(
      title: title ?? message,
      description: title == null ? null : message,
      kind: AppMessageKind.info,
      position: position,
      visualStyle: visualStyle,
      actionLabel: actionLabel,
      onAction: onAction,
      dedupeKey: dedupeKey,
    ));
  }

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
    show(AppMessageRequest(
      title: title ?? message,
      description: title == null ? null : message,
      kind: AppMessageKind.success,
      position: position,
      visualStyle: visualStyle,
      actionLabel: actionLabel,
      onAction: onAction,
      dedupeKey: dedupeKey,
    ));
  }

  @override
  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    show(AppMessageRequest(
      title: title ?? message,
      description: title == null ? null : message,
      kind: AppMessageKind.warning,
      position: position,
      visualStyle: visualStyle,
      actionLabel: actionLabel,
      onAction: onAction,
      dedupeKey: dedupeKey,
    ));
  }

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    show(AppMessageRequest(
      title: title ?? message,
      description: title == null ? null : message,
      kind: AppMessageKind.error,
      position: position,
      visualStyle: visualStyle,
      actionLabel: actionLabel,
      onAction: onAction,
      dedupeKey: dedupeKey,
    ));
  }

  @override
  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    show(AppMessageRequest(
      title: title,
      description: description,
      kind: AppMessageKind.loading,
      position: position,
      size: position == AppMessagePosition.center
          ? AppMessageSize.dialog
          : AppMessageSize.compact,
      visualStyle: visualStyle,
      actionLabel: actionLabel,
      onAction: onAction,
      dedupeKey: dedupeKey,
    ));
  }

  @override
  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
  }) {
    show(AppMessageRequest(
      title: title,
      description: description,
      kind: kind,
      position: AppMessagePosition.center,
      size: AppMessageSize.dialog,
      visualStyle: visualStyle,
      dedupeKey: dedupeKey,
      replaceExisting: replaceExisting,
    ));
  }

  @override
  void dismiss(String dedupeKey) {
    final item = _registry.dismiss(dedupeKey);
    if (item != null) {
      toastification.dismiss(item);
    }
  }

  @override
  void dismissAll() {
    for (final item in _registry.dismissAll()) {
      toastification.dismiss(item);
    }
  }
}

Alignment _alignment(AppMessagePosition position) {
  return switch (position) {
    AppMessagePosition.top => Alignment.topCenter,
    AppMessagePosition.center => Alignment.center,
    AppMessagePosition.bottom => Alignment.bottomCenter,
  };
}
