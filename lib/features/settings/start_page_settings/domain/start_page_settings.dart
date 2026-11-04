/// The main tabs the app can open on launch.
///
/// Only the four tabs that live in the bottom-navigation shell are offered:
/// starting on a pushed page such as 书签 or 阅读历史 would leave the app
/// without a tab bar and with a back stack that exits immediately.
enum StartPage {
  home,
  bookshelf,
  search,
  profile;

  /// Label used by the settings row and the picker list.
  String get label => switch (this) {
        StartPage.home => '首页',
        StartPage.bookshelf => '书架',
        StartPage.search => '搜索',
        StartPage.profile => '我的',
      };

  /// One-line explanation shown under the label in the picker.
  String get description => switch (this) {
        StartPage.home => '继续阅读、推荐与今日进度',
        StartPage.bookshelf => '本地藏书与在线书源',
        StartPage.search => '搜索书源与作品',
        StartPage.profile => '阅读目标、统计与设置',
      };
}

/// Persisted choice of the page shown when the app starts.
///
/// The router reads [lastKnown] when it is first built. `main()` loads the
/// saved value before `runApp` and calls [remember], so the first frame already
/// lands on the chosen tab instead of flashing the home page.
class StartPageSettings {
  const StartPageSettings({this.page = StartPage.home});

  static const String preferenceKey = 'start_page.settings';

  static StartPageSettings? _lastKnown;

  static StartPageSettings get lastKnown =>
      _lastKnown ?? StartPageSettings.defaults();

  static void remember(StartPageSettings settings) => _lastKnown = settings;

  final StartPage page;

  factory StartPageSettings.defaults() => const StartPageSettings();

  StartPageSettings copyWith({StartPage? page}) {
    return StartPageSettings(page: page ?? this.page);
  }

  Map<String, Object?> toJson() {
    return {'page': page.name};
  }

  /// Tolerant decode: a missing or unknown page falls back to the home tab.
  factory StartPageSettings.fromJson(Object? json) {
    if (json is! Map) return StartPageSettings.defaults();
    final name = json['page'];
    if (name is String) {
      for (final page in StartPage.values) {
        if (page.name == name) return StartPageSettings(page: page);
      }
    }
    return StartPageSettings.defaults();
  }

  @override
  bool operator ==(Object other) {
    return other is StartPageSettings && other.page == page;
  }

  @override
  int get hashCode => page.hashCode;
}
