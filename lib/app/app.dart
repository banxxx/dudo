import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/theme_settings/application/theme_settings_provider.dart';
import '../features/settings/theme_settings/domain/theme_settings.dart';
import '../shared/l10n/app_localizations.dart';
import '../shared/messages/app_message_host.dart';
import '../shared/theme/app_tokens.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/dudo_palette.dart';
import 'router/app_router.dart';

/// Root widget for the dudo app.
class DudoApp extends ConsumerWidget {
  const DudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final asyncThemeSettings = ref.watch(themeSettingsProvider);
    final themeSettings =
        asyncThemeSettings.valueOrNull ?? ThemeSettings.lastKnown;
    // Remember for the next launch so it starts with the right palette.
    if (asyncThemeSettings.valueOrNull != null) {
      ThemeSettings.remember(asyncThemeSettings.valueOrNull!);
    }

    // The palette the pages read through `DudoColors.x`. Installed here before
    // the tree below builds, so a mode/accent change restyles every page.
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final paletteBrightness = switch (themeSettings.mode) {
      DudoThemeMode.paper => Brightness.light,
      DudoThemeMode.dark => Brightness.dark,
      DudoThemeMode.system => platformBrightness,
    };
    DudoColors.use(
      paletteBrightness == Brightness.dark
          ? DudoPalette.dark(themeSettings.accent)
          : DudoPalette.light(themeSettings.accent),
    );

    final themeMode = switch (themeSettings.mode) {
      DudoThemeMode.paper => ThemeMode.light,
      DudoThemeMode.dark => ThemeMode.dark,
      DudoThemeMode.system => ThemeMode.system,
    };

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme = AppTheme.lightScheme(
          lightDynamic,
          seedColor: themeSettings.accent.swatch,
        );
        final ColorScheme darkScheme = AppTheme.darkScheme(
          darkDynamic,
          seedColor: themeSettings.accent.swatch,
        );

        return MaterialApp.router(
          title: 'dudo',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          themeMode: themeMode,
          theme: AppTheme.build(lightScheme),
          darkTheme: AppTheme.build(darkScheme),
          locale: const Locale('zh', 'CN'),
          builder: (context, child) {
            final theme = Theme.of(context);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
              ),
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: AppMessageHost(
                  routeInformationProvider: router.routeInformationProvider,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
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
