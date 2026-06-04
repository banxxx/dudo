import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/exceptions/error_handler.dart';
import 'core/network/http_client.dart';
import 'core/tts/tts_service.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    _bootstrap,
    (error, stackTrace) {
      ErrorHandler.handle(
        error,
        stackTrace,
        context: 'runZonedGuarded',
        fatal: true,
      );
    },
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorHandler.handle(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'FlutterError',
      fatal: true,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ErrorHandler.handle(
      error,
      stackTrace,
      context: 'PlatformDispatcher',
      fatal: true,
    );
    return true;
  };

  // System UI styling — M3 prefers edge-to-edge.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
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
    ErrorHandler.handle(e, st, context: 'HttpClient.init');
  }

  // TTS / audio service bootstrap — safe-init: many desktop/test
  // environments don't have a TTS plugin and will throw MissingPluginException.
  try {
    await TtsService.instance.init();
  } catch (e, st) {
    ErrorHandler.handle(e, st, context: 'TtsService.init');
  }

  runApp(
    const ProviderScope(child: DudoApp()),
  );
}
