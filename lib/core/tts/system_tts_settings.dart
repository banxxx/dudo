import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the platform screen where system voice data is installed and
/// managed; devices without one report `false`.
abstract interface class SystemTtsSettings {
  Future<bool> open();
}

class PlatformSystemTtsSettings implements SystemTtsSettings {
  const PlatformSystemTtsSettings();

  static const _channel = MethodChannel('dudo.system/settings');

  @override
  Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('openTtsSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final systemTtsSettingsProvider = Provider<SystemTtsSettings>(
  (ref) => const PlatformSystemTtsSettings(),
);
