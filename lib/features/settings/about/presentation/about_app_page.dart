import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/about_platform.dart';
import 'about_app_view.dart';

/// Entry point for the "应用说明" page. It resolves the current platform once
/// and hands it to the shared view so the update section can describe the right
/// install artifact instead of always assuming Android.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = kIsWeb
        ? AboutPlatform.web
        : aboutPlatformFor(defaultTargetPlatform);
    return AboutAppView(platform: platform);
  }
}
