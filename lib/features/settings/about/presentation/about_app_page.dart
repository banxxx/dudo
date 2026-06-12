import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'platforms/android_about_app_page.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const AndroidAboutAppPage(),
      // Other platform styles will be added as their Pencil frames are built.
      _ => const AndroidAboutAppPage(),
    };
  }
}
