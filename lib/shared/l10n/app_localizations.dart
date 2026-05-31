import 'package:flutter/material.dart';

/// Lightweight in-app localization — Chinese (default) and English.
///
/// For a real product we'd wire up `gen_l10n` with .arb files. The map below
/// keeps the scaffold runnable without code generation.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('zh', 'CN'));
  }

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'zh': <String, String>{
      'appTitle': 'dudo 读物',
      'home': '首页',
      'bookshelf': '书架',
      'search': '搜索',
      'sources': '书源',
      'profile': '我的',
      'reader': '阅读器',
      'addBook': '添加书籍',
      'empty.bookshelf': '书架还空着，点击右下角搜索来添加一本书吧',
      'empty.sources': '尚未添加书源',
      'empty.search': '搜索书名或作者',
      'profile.settings': '设置',
      'profile.about': '关于 dudo',
      'profile.theme': '主题',
      'profile.tts': '语音朗读',
    },
    'en': <String, String>{
      'appTitle': 'dudo Reader',
      'home': 'Home',
      'bookshelf': 'Library',
      'search': 'Search',
      'sources': 'Sources',
      'profile': 'Profile',
      'reader': 'Reader',
      'addBook': 'Add book',
      'empty.bookshelf': 'Your library is empty. Tap the FAB to find a book.',
      'empty.sources': 'No book sources yet',
      'empty.search': 'Search by title or author',
      'profile.settings': 'Settings',
      'profile.about': 'About dudo',
      'profile.theme': 'Theme',
      'profile.tts': 'Text-to-speech',
    },
  };

  String _t(String key) {
    final String lang = locale.languageCode;
    return _strings[lang]?[key] ?? _strings['zh']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get home => _t('home');
  String get bookshelf => _t('bookshelf');
  String get search => _t('search');
  String get sources => _t('sources');
  String get profile => _t('profile');
  String get reader => _t('reader');
  String get addBook => _t('addBook');
  String get emptyBookshelf => _t('empty.bookshelf');
  String get emptySources => _t('empty.sources');
  String get emptySearch => _t('empty.search');
  String get profileSettings => _t('profile.settings');
  String get profileAbout => _t('profile.about');
  String get profileTheme => _t('profile.theme');
  String get profileTts => _t('profile.tts');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (Locale l) => l.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
