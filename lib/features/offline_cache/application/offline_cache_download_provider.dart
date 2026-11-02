import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/messages/app_message_service.dart';
import '../../reader_engine/application/reader_engine_providers.dart';
import '../domain/offline_cache_task.dart';
import 'offline_cache_download_controller.dart';
import 'offline_cache_provider.dart';
import 'offline_cache_settings_provider.dart';

final offlineCacheDownloadControllerProvider = StateNotifierProvider<
    OfflineCacheDownloadController, List<OfflineCacheTask>>(
  (ref) {
    final controller = OfflineCacheDownloadController(
      documentSource: () => ref.read(readerDocumentSourceProvider),
      concurrency: () =>
          ref.read(offlineCacheSettingsControllerProvider).concurrency,
      onCacheChanged: () => ref.invalidate(offlineCacheProvider),
      messageService: ref.read(appMessageServiceProvider),
    );
    ref.listen(offlineCacheSettingsControllerProvider, (previous, next) {
      if (previous?.concurrency != next.concurrency) controller.pump();
    });
    return controller;
  },
);
