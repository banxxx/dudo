import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/l10n/app_localizations.dart';
import '../shared/messages/app_message_host.dart';
import '../shared/theme/app_theme.dart';
import 'router/app_router.dart';

/// Root widget for the dudo app.
class DudoApp extends ConsumerWidget {
  const DudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme = AppTheme.lightScheme(lightDynamic);
        final ColorScheme darkScheme = AppTheme.darkScheme(darkDynamic);

        return MaterialApp.router(
          title: 'dudo',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          themeMode: ThemeMode.system,
          theme: AppTheme.build(lightScheme),
          darkTheme: AppTheme.build(darkScheme),
          locale: const Locale('zh', 'CN'),
          builder: (context, child) {
            return AppMessageHost(child: child ?? const SizedBox.shrink());
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
