import 'package:flutter/foundation.dart';

/// The platforms Dudo ships on. The about page uses this instead of hardcoding
/// Android so the update section reads correctly on every target.
enum AboutPlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web;

  /// The install artifact this platform downloads, e.g. `Android 安装包`.
  String get packageLabel => switch (this) {
        AboutPlatform.android => 'Android 安装包',
        AboutPlatform.ios => 'iOS 版本',
        AboutPlatform.macos => 'macOS 版本',
        AboutPlatform.windows => 'Windows 版本',
        AboutPlatform.linux => 'Linux 版本',
        AboutPlatform.web => 'Web 应用',
      };
}

/// Maps a Flutter target platform onto the app's platform model. Web is handled
/// by the caller because `kIsWeb` is checked separately from the target.
AboutPlatform aboutPlatformFor(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.android => AboutPlatform.android,
    TargetPlatform.iOS => AboutPlatform.ios,
    TargetPlatform.macOS => AboutPlatform.macos,
    TargetPlatform.windows => AboutPlatform.windows,
    TargetPlatform.linux => AboutPlatform.linux,
    TargetPlatform.fuchsia => AboutPlatform.android,
  };
}
