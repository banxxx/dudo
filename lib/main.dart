import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/network/http_client.dart';
import 'core/tts/tts_service.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI styling — M3 prefers edge-to-edge.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Local storage initialization. `Hive.initFlutter()` resolves the documents
  // directory internally via path_provider so we don't have to pass it.
  await Hive.initFlutter();

  // DI bootstrap.
  await configureDependencies();

  // Network singleton. Swallow init errors so a transient FS problem
  // doesn't block app launch.
  try {
    await HttpClient.init();
  } catch (e, st) {
    log.w('HttpClient.init failed: $e\n$st');
  }

  // TTS / audio service bootstrap — safe-init: many desktop/test
  // environments don't have a TTS plugin and will throw MissingPluginException.
  try {
    await TtsService.instance.init();
  } catch (e, st) {
    log.w('TtsService.init failed (ignored): $e\n$st');
  }

  runApp(
    const ProviderScope(child: DudoApp()),
  );
}
