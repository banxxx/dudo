import 'package:dudo/features/settings/about/domain/about_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every target platform onto the app platform model', () {
    expect(aboutPlatformFor(TargetPlatform.android), AboutPlatform.android);
    expect(aboutPlatformFor(TargetPlatform.iOS), AboutPlatform.ios);
    expect(aboutPlatformFor(TargetPlatform.macOS), AboutPlatform.macos);
    expect(aboutPlatformFor(TargetPlatform.windows), AboutPlatform.windows);
    expect(aboutPlatformFor(TargetPlatform.linux), AboutPlatform.linux);
    expect(aboutPlatformFor(TargetPlatform.fuchsia), AboutPlatform.android);
  });

  test('labels each platform with its install artifact', () {
    expect(AboutPlatform.android.packageLabel, 'Android 安装包');
    expect(AboutPlatform.ios.packageLabel, 'iOS 版本');
    expect(AboutPlatform.macos.packageLabel, 'macOS 版本');
    expect(AboutPlatform.windows.packageLabel, 'Windows 版本');
    expect(AboutPlatform.linux.packageLabel, 'Linux 版本');
    expect(AboutPlatform.web.packageLabel, 'Web 应用');
  });
}
